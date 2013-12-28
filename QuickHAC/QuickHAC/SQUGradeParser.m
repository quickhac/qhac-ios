//
//  SQUGradeParser.m
//  QuickHAC
//
//  Interfaces with the GradeParser object in qhac-common's library to parse the
//	data returned by HAC into something usable.
//
//  Created by Tristan Seifert on 12/26/13.
//  See README.MD for licensing and copyright information.
//

#import <JavaScriptCore/JavaScriptCore.h>

#import "TFHpple.h"
#import "SQUGradeParser.h"
#import "SQUDistrict.h"
#import "SQUDistrict.h"

static SQUGradeParser *_sharedInstance = nil;

@implementation SQUGradeParser

#pragma mark - Singleton
+ (SQUGradeParser *) sharedInstance {
    @synchronized (self) {
        if (_sharedInstance == nil) {
            _sharedInstance = [[self alloc] init];
        }
    }
    
    return _sharedInstance;
}

+ (id) allocWithZone:(NSZone *) zone {
    @synchronized(self) {
        if (_sharedInstance == nil) {
            _sharedInstance = [super allocWithZone:zone];
            return _sharedInstance;
        }
    }
    
    return nil;
}

- (id) copyWithZone:(NSZone *) zone {
    return self;
}

- (id) init {
    @synchronized(self) {
        if(self = [super init]) {

        }
		      
        return self;
    }
}

#pragma mark - Private DOM parsing interfaces
- (NSDictionary *) parseCycleWithDistrict:(SQUDistrict *) district andCell:(TFHppleElement *) cell andIndex:(NSUInteger) index {
	// Try to find a link inside the cell
	NSArray *links = [cell childrenWithTagName:@"a"];
	
	// If there's no link, no average is available for this cycle
	if(!links.count) {
		return [NSDictionary dictionaryWithObjects:@[[NSNumber numberWithUnsignedInteger:index], [NSNumber numberWithUnsignedInteger:NAN], @""] forKeys:@[@"index", @"average", @"urlHash"]];
	}
	
	// Fetch the grade from the cell
	NSInteger average = [[cell.children[0] text] integerValue];
	
	// Get the link to access cycle grades
	NSString *gradeLinkURL = links[0][@"href"];
	
	// Use a regex to get the URL hash
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\?data=([\\w\\d%]*)" options:NSRegularExpressionCaseInsensitive error:nil];
	
	NSRange range = [[regex firstMatchInString:gradeLinkURL options:0 range:NSMakeRange(0, gradeLinkURL.length)] rangeAtIndex:1];
	
	NSMutableDictionary *returnValue = [NSMutableDictionary new];
	
	// Make sure the range is valid before trying to use it
	if(!NSEqualRanges(range, NSMakeRange(NSNotFound, 0))) {
		returnValue[@"urlHash"] = [gradeLinkURL substringWithRange:range];
	} else {
		returnValue[@"urlHash"] = @"";
	}
	
	returnValue[@"index"] = [NSNumber numberWithUnsignedInteger:index];
	returnValue[@"average"] = [NSNumber numberWithUnsignedInteger:average];
	
	return returnValue;
}

- (NSDictionary *) parseSemesterWithDistrict:(SQUDistrict *) district andSemesterCells:(NSArray *) cells andSemester:(NSUInteger) semester andSemesterParams:(semester_params_t) semParams {
	NSMutableArray *cycles = [NSMutableArray new];
	NSMutableDictionary *returnValue = [NSMutableDictionary new];
	
	// Parse cycles
	for (NSUInteger i = 0; i < semParams.cyclesPerSemester; i++) {
		cycles[i] = [self parseCycleWithDistrict:district andCell:cells[i] andIndex:i];
	}
	
	// Parse exam grade
	NSInteger examGrade = -1;
	BOOL examIsExempt = NO;
	
	TFHppleElement *exam = cells[semParams.cyclesPerSemester];
	
	// Check if we have children (exam grades are wrapped in a <span>)
	if(exam.hasChildren) {
		exam = exam.children[0];
		
		if([exam.text isEqualToString:@"EX"] || [exam.text isEqualToString:@"Exc"]) {
			examIsExempt = YES;
		} else if(exam.text != nil) {
			examGrade = [exam.text integerValue];
		}
	}
	
	// Parse semester average
	NSInteger semesterAverage = -1;
	TFHppleElement *semAvgCell = cells[semParams.cyclesPerSemester+1];
	
	// Semester averages are wrapped in a <span> as well
	if(semAvgCell.hasChildren) {
		semAvgCell = semAvgCell.children[0];
		
		if(semAvgCell.text != nil) {
			semesterAverage = [semAvgCell.text integerValue];
		}
	}
	
	// Produce return value
	returnValue[@"index"] = [NSNumber numberWithUnsignedInteger:semester];
	returnValue[@"cycles"] = cycles;
	returnValue[@"examIsExempt"] = [NSNumber numberWithBool:examIsExempt];
	returnValue[@"examGrade"] = [NSNumber numberWithInteger:examGrade];
	returnValue[@"semesterAverage"] = [NSNumber numberWithInteger:semesterAverage];
	
	return returnValue;
}

- (NSString *) getCourseNumberForDistrict:(SQUDistrict *) district andCells:(NSArray *) columns {
	for(NSUInteger i = district.tableOffsets.grades; i < columns.count; i++) {
		NSArray *links = [columns[i] childrenWithTagName:@"a"];
		
		// If there's a link, get the part after "data"
		if(links.count > 0) {
			TFHppleElement *link = links[0];
			NSString *data = [link[@"href"] componentsSeparatedByString:@"data="][1];
			NSString *urlDecoded = (NSString *) CFBridgingRelease(CFURLCreateStringByReplacingPercentEscapes(NULL, (CFStringRef) data, CFSTR("")));
			NSString *base64Decoded = [[NSString alloc] initWithData:[[NSData alloc] initWithBase64EncodedString:urlDecoded options:0] encoding:NSUTF8StringEncoding];
			
			return [base64Decoded componentsSeparatedByString:@"|"][3];
		}
	}
	
	return nil;
}

- (NSDictionary *) parseCourseWithDistrict:(SQUDistrict *) district andTableRow:(TFHppleElement *) row andSemesterParams:(semester_params_t) semParams {
	NSMutableDictionary *dict = [NSMutableDictionary new];
	NSMutableArray *semesters = [NSMutableArray new];

	// Get cells and teacher cell
	NSArray *cells = [row childrenWithTagName:@"td"];
	TFHppleElement *teacherLink = [[row childrenWithClassName:@"TeacherNameCell"][0] children][0];
	
	// Build a list of cells in a semester
	for (NSUInteger i = 0; i < semParams.semesters; i++) {
		NSMutableArray *semesterCells = [NSMutableArray new];
		NSUInteger cellOffset = district.tableOffsets.grades + (i * (semParams.cyclesPerSemester + 2));
		
		for(NSUInteger j = 0; j < semParams.cyclesPerSemester + 2; j++) {
			semesterCells[j] = cells[cellOffset + j];
		}
		
		// Get information for this semester.
		semesters[i] = [self parseSemesterWithDistrict:district andSemesterCells:semesterCells andSemester:i andSemesterParams:semParams];
	}
	
	dict[@"title"] = [cells[district.tableOffsets.title] text];
	dict[@"period"] = [NSNumber numberWithInteger:[[cells[district.tableOffsets.period] text] integerValue]];
	dict[@"teacherName"] = [teacherLink text];
	dict[@"teacherEmail"] = [teacherLink[@"href"] substringFromIndex:7];
	dict[@"semesters"] = semesters;
	dict[@"courseNum"] = [self getCourseNumberForDistrict:district andCells:cells];
	
	return dict;
}

#pragma mark - Grade parsing
- (NSArray *) parseAveragesForDistrict:(SQUDistrict *) district withString:(NSString *) string {
	NSData *htmlData = [string dataUsingEncoding:NSUTF8StringEncoding];
	TFHpple *parser = [TFHpple hppleWithHTMLData:htmlData];
	
	NSMutableArray *averages = [NSMutableArray new];
	
#ifndef DEBUG
	@try {
#endif
		// Find table
		NSArray *tables = [parser searchWithXPathQuery:@"//table[@class='DataTable']"];
		TFHppleElement *table = nil;
		
		if(tables.count > 0) {
			table = tables[0];
		} else {
			return nil;
		}
		
		// Find the rows inside the table
		NSArray *rows = [table childrenWithTagName:@"tr"];
		
		// Calculate semesters and cycles
		TFHppleElement *tableHeader = [table childrenWithClassName:@"TableHeader"][0];
		NSArray *headerCells = [tableHeader childrenWithTagName:@"th"];
		NSString *semesterCellString = [headerCells[headerCells.count - 1] text];
		NSString *cycleCellString = [headerCells[headerCells.count - 3] text];
		
		NSUInteger sem = NSNotFound; NSUInteger cyc = NSNotFound;
		
		// Find number of semesters
		sem = [[semesterCellString componentsSeparatedByString:@" "][1] integerValue];
		
		// Do same for number of cycles
		cyc = [[cycleCellString componentsSeparatedByString:@" "][1] integerValue] / sem;
		
		NSLog(@"Semesters: %u\nCycles: %u", sem, cyc);
		
		NSAssert(sem < 3, @"Too many semesters, calculated %u", sem);
		NSAssert(cyc < 5, @"Too many grading cycles, calculated %u", cyc);
	
		semester_params_t semesterParams = {
			.semesters = sem,
			.cyclesPerSemester = cyc
		};
		
		// Iterate the rows
		for (TFHppleElement *row in rows) {
			// Ignore all rows that do not contain data
			if([row[@"class"] isEqualToString:@"DataRow"] || [row[@"class"] isEqualToString:@"DataRowAlt"]) {
				NSDictionary *classInfo = [self parseCourseWithDistrict:district andTableRow:row andSemesterParams:semesterParams];
				[averages addObject:classInfo];
			}
		}
#ifndef DEBUG
	}
	@catch (NSException *exception) {
		NSLog(@"Parse error: %@", exception);
		return nil;
	}
#endif
	
	//NSLog(@"Averages: %@", averages);
	
	return averages;
}

- (NSString *) getStudentNameForDistrict:(SQUDistrict *) district withString:(NSString *) string {
	// GradeParser.getStudentName(district, doc)
	return @"";
}

- (NSDictionary *) getClassGradesForDistrict:(SQUDistrict *) district withString:(NSString *) string {
	// GradeParser.parseClassGrades(district, doc, urlHash, semesterIndex, cycleIndex)
	return nil;
}

#pragma mark - User-interface support
// warning: contains magical numbers and some kind of black magic
+ (UIColor *) colourizeGrade:(float) grade {
    // Makes sure asianness cannot be negative
    NSUInteger asianness_limited = MAX(2, 0);
    
    // interpolate a hue gradient and convert to rgb
    float h, s, v;
    
    // determine color. ***MAGIC DO NOT TOUCH UNDER ANY CIRCUMSTANCES***
    if (grade > 100) {
        h = 0.13055;
        s = 0;
        v = 1;
    } else if (grade < 0) {
        h = 0;
        s = 1;
        v = 0.86945;
    } else {
        h = MIN(0.25 * pow(grade / 100, asianness_limited), 0.13056);
        s = 1 - pow(grade / 100, asianness_limited * 2);
        v = 0.86945 + h;
    }
    
    // apply hue transformation
	//    h += hue;
	//    h %= 1;
	//    if (h < 0) h += 1;
    
    return [UIColor colorWithHue:h saturation:s brightness:v alpha:1.0];
}

@end