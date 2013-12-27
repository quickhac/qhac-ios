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
			/*// Set up the JS contexts
			_jsVirtualMachine = [[JSVirtualMachine alloc] init];
			_jsContext = [[JSContext alloc] initWithVirtualMachine:_jsVirtualMachine];
			
			// Set up exception handler
			_jsContext.exceptionHandler = ^(JSContext *context, JSValue *exception) {
				context.exception = exception;
				NSLog(@"Unhandled exception in context %@: %@", context, exception);
			};
			
			// Load in env.js
			NSError *err = nil;
			NSURL *pathOfScript = [[NSBundle mainBundle] URLForResource:@"env" withExtension:@"js"];
			NSString *loadedScript = [NSString stringWithContentsOfURL:pathOfScript encoding:NSUTF8StringEncoding error:&err];
			
			if(err) {
				NSLog(@"Error loading env.js (URL = %@): %@", pathOfScript, err);
			} else {
				JSValue *returnValue = [_jsContext evaluateScript:loadedScript];
				NSLog(@"Loaded env.js: %@", returnValue);
			}
			
			// Load qhac.js into the context
			pathOfScript = [[NSBundle mainBundle] URLForResource:@"qhac" withExtension:@"js"];
			loadedScript = [NSString stringWithContentsOfURL:pathOfScript encoding:NSUTF8StringEncoding error:&err];
			
			if(err) {
				NSLog(@"Error loading qhac.js (URL = %@): %@", pathOfScript, err);
			} else {
				JSValue *returnValue = [_jsContext evaluateScript:loadedScript];
				NSLog(@"Loaded qhac.js: %@", returnValue);
			}*/
        }
		
        
        return self;
    }
}

#pragma mark - Private DOM parsing interfaces
- (NSDictionary *) parseCycleWithDistrict:(void *) district andCell:(TFHppleElement *) cell andIndex:(NSUInteger) index {
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

- (NSDictionary *) parseSemesterWithDistrict:(void *) district andSemesterCells:(NSArray *) cells andSemester:(NSUInteger) semester andSemesterParams:(semester_params_t) semParams {
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

- (NSDictionary *) parseCourseWithDistrict:(void *) district andTableRow:(TFHppleElement *) row andSemesterParams:(semester_params_t) semParams {
	NSMutableDictionary *dict = [NSMutableDictionary new];
	NSMutableArray *semesters = [NSMutableArray new];

	// Get cells and teacher cell
	NSArray *cells = [row childrenWithTagName:@"td"];
	TFHppleElement *teacherLink = [[row childrenWithClassName:@"TeacherNameCell"][0] children][0];
	
	// Build a list of cells in a semester
	for (NSUInteger i = 0; i < semParams.semesters; i++) {
		NSMutableArray *semesterCells = [NSMutableArray new];
		NSUInteger cellOffset = 2 + (i * (semParams.cyclesPerSemester + 2));
		
		for(NSUInteger j = 0; j < semParams.cyclesPerSemester + 2; j++) {
			semesterCells[j] = cells[cellOffset + j];
		}
		
		// Get information for this semester.
		semesters[i] = [self parseSemesterWithDistrict:district andSemesterCells:semesterCells andSemester:i andSemesterParams:semParams];
	}
	
	dict[@"title"] = [cells[0] text];
	dict[@"teacherName"] = [teacherLink text];
	dict[@"teacherEmail"] = teacherLink[@"href"];
	dict[@"semesters"] = semesters;
	
	return dict;
}

#pragma mark - Grade parsing
- (NSArray *) parseAveragesForDistrict:(void *) district withString:(NSString *) string {
	NSData *htmlData = [string dataUsingEncoding:NSUTF8StringEncoding];
	TFHpple *parser = [TFHpple hppleWithHTMLData:htmlData];
	
	NSMutableArray *averages = [NSMutableArray new];
	
#ifndef DEBUG
	@try {
#endif
		// Find table
		TFHppleElement *table = [parser searchWithXPathQuery:@"//table[@class='DataTable']"][0];
		
		// Find the rows inside the table
		NSArray *rows = [table childrenWithTagName:@"tr"];
		
		// Calculate semesters and cycles
#warning Change to calculate cycles and semesters
		semester_params_t semesterParams = {
			.semesters = 2,
			.cyclesPerSemester = 3
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
	
	NSLog(@"Averages: %@", averages);
	
	return averages;
}

- (NSString *) getStudentNameForDistrict:(void *) district withString:(NSString *) string {
	// GradeParser.getStudentName(district, doc)
	return @"";
}

- (NSDictionary *) getClassGradesForDistrict:(void *) district withString:(NSString *) string {
	// GradeParser.parseClassGrades(district, doc, urlHash, semesterIndex, cycleIndex)
	return nil;
}

@end