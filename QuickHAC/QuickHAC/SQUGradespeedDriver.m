//
//  SQUGradespeedDriver.m
//  QuickHAC
//
//  Created by Tristan Seifert on 1/2/14.
//  See README.MD for licensing and copyright information.
//

#import "SQUDistrict.h"
#import "SQUGradeManager.h"
#import "SQUGradespeedDriver.h"

#import "TFHpple.h"

#pragma mark HTML parser additions
// Category on TFHppleElement for table
@interface TFHppleElement (TableSupport)
- (NSString *) getColumnContentsWithClass:(NSString *) class;
@end

@implementation TFHppleElement (TableSupport)
- (NSString *) getColumnContentsWithClass:(NSString *) class{
	NSArray *children = [self childrenWithClassName:class];
	if(children.count == 0) return @"";
	
	return [children[0] text];
}
@end

#pragma mark - Driver init
@implementation SQUGradespeedDriver
+ (void) load {
	[[SQUGradeManager sharedInstance] registerDriver:NSClassFromString(@"SQUGradespeedDriver")];
}

- (id) init {
	self = [super init];
	
	if(self) {
		_identifier = @"gradespeed";
		_gradespeedDateFormatter = [NSDateFormatter new];
		[_gradespeedDateFormatter setDateFormat:@"MMM-dd"];
	}
	
	return self;
}

#pragma mark - Helper methods
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
		returnValue[@"urlHash"] = (__bridge id)(CFURLCreateStringByReplacingPercentEscapes(NULL, (CFStringRef) [gradeLinkURL substringWithRange:range], CFSTR("")));
	} else {
		returnValue[@"urlHash"] = @"";
	}
	
	// handle letter grades
	if(average == 0 && returnValue[@"urlHash"]) {
		returnValue[@"letterGrade"] = [cell.children[0] text];
	}
	
	returnValue[@"index"] = [NSNumber numberWithUnsignedInteger:index];
	returnValue[@"average"] = [NSNumber numberWithUnsignedInteger:average];
	
	return returnValue;
}

- (NSDictionary *) parseSemesterWithDistrict:(SQUDistrict *) district andSemesterCells:(NSArray *) cells andSemester:(NSUInteger) semester andSemesterParams:(semester_params_t) semParams {
	NSMutableArray *cycles = [NSMutableArray new];
	NSMutableDictionary *returnValue = [NSMutableDictionary new];
	
	NSInteger examGrade = -1, semesterAverage = -1;
	BOOL examIsExempt = NO;
	
	// Parse cycles
	for (NSUInteger i = 0; i < semParams.cyclesPerSemester; i++) {
		cycles[i] = [self parseCycleWithDistrict:district andCell:cells[i] andIndex:i];
	}
	
	// Elementary students don't have exams or semester averages because they're noobs
	if(semParams.cyclesPerSemester != 4) {
		// Parse exam grade
		TFHppleElement *exam = cells[semParams.cyclesPerSemester];
		
		// Check if we have children (exam grades are wrapped in a <span>)
		if(exam.hasChildren) {
			exam = exam.children[0];
			
			// Is the exam exempt?
			if([exam.text isEqualToString:@"EX"] || [exam.text isEqualToString:@"Exc"]) {
				examIsExempt = YES;
			} else if(exam.text != nil) {
				// Is there a valid integer in that field?
				if([[NSScanner scannerWithString:exam.text] scanInt:NULL]) {
					examGrade = [exam.text integerValue];
				}
			}
		}
		
		// Parse semester average
		TFHppleElement *semAvgCell = cells[semParams.cyclesPerSemester+1];
		
		// Semester averages are wrapped in a <span> as well
		if(semAvgCell.hasChildren) {
			semAvgCell = semAvgCell.children[0];
			
			if(semAvgCell.text != nil) {
				semesterAverage = [semAvgCell.text integerValue];
			}
		}
	} else {
		examGrade = semesterAverage = -2;
	}
	
	// Produce return value
	returnValue[@"cycles"] = cycles;
	returnValue[@"index"] = [NSNumber numberWithUnsignedInteger:semester];
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
			NSArray *components = [base64Decoded componentsSeparatedByString:@"|"];
			
			return components[3];
		}
	}
	
	return nil;
}

/**
 * Processes a row of the overall gradebook, i.e. a class.
 */
- (NSDictionary *) parseCourseWithDistrict:(SQUDistrict *) district andTableRow:(TFHppleElement *) row andSemesterParams:(semester_params_t) semParams {
	NSMutableDictionary *dict = [NSMutableDictionary new];
	NSMutableArray *semesters = [NSMutableArray new];
	
	// Get cells and teacher cell
	NSArray *cells = [row childrenWithTagName:@"td"];
	TFHppleElement *teacherLink = [[row childrenWithClassName:@"TeacherNameCell"][0] children][0];
	
	// Ignore GPA cell
	if([cells[district.tableOffsets.title] text].length < 4) {
		NSLog(@"Ignoring invalid course title (shorter than 4 chars)");
		return nil;
	}
	
	// If we detect 4 cycles/semester
	if(semParams.cyclesPerSemester != 4) {
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
	} else {
		// Process the student as an elementary student.
		NSMutableArray *semesterCells = [NSMutableArray new];
		NSUInteger cellOffset = district.tableOffsets.grades;
		
		for(NSUInteger j = 0; j < semParams.cyclesPerSemester; j++) {
			semesterCells[j] = cells[cellOffset + j];
		}
		
		// Get information for this semester.
		semesters[0] = [self parseSemesterWithDistrict:district andSemesterCells:semesterCells andSemester:0 andSemesterParams:semParams];
	}
	
	NSString *courseCode = [self getCourseNumberForDistrict:district andCells:cells];
	
	dict[@"title"] = [cells[district.tableOffsets.title] text];
	dict[@"period"] = [NSNumber numberWithInteger:[[cells[district.tableOffsets.period] text] integerValue]];
	dict[@"teacherName"] = [teacherLink text];
	dict[@"teacherEmail"] = [teacherLink[@"href"] substringFromIndex:7];
	dict[@"semesters"] = semesters;
	
	// Put an empty string in the dictionary if there's no course code
	if(courseCode) {
		dict[@"courseNum"] = courseCode;
	} else {
		// Ignore known non-graded periods
		if([dict[@"title"] rangeOfString:@"ADVISORY"].location != NSNotFound) {
			return nil;
		} else if([dict[@"title"] rangeOfString:@"Homeroom"].location != NSNotFound) {
			return nil;
		}
		
		dict[@"courseNum"] = @"";
	}
	
	return dict;
}

/**
 * Parses the class averages from the gradebook.
 *
 * @param district: District to use for parsing.
 * @param string: Gradebook HTML.
 * @return Averages for all courses the student is enrolled in.
 */
- (NSArray *) parseAveragesForDistrict:(SQUDistrict *) district withData:(NSData *) data {
	TFHpple *parser = [TFHpple hppleWithHTMLData:data];
	
	NSMutableArray *averages = [NSMutableArray new];
	
#ifndef DEBUG
	@try {
#endif
		// Find table
		TFHppleElement *table = [parser peekAtSearchWithXPathQuery:@"//table[@class='DataTable']"];
				
		// Ensure there's a table
		if(!table) {
			// [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"There is no .DataTable in the document.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil] show];
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
		
		semester_params_t semesterParams = {
			.semesters = sem,
			.cyclesPerSemester = cyc
		};
		
		// Treat elementary schools as 1 semester with 4 cycles
		if(sem > cyc) {
			semesterParams.semesters = 1;
			semesterParams.cyclesPerSemester = sem;
		}
		
		// Iterate the rows
		for (TFHppleElement *row in rows) {
			// Ignore all rows that do not contain data
			if([row[@"class"] isEqualToString:@"DataRow"] || [row[@"class"] isEqualToString:@"DataRowAlt"]) {
				@try {
					NSDictionary *classInfo = [self parseCourseWithDistrict:district andTableRow:row andSemesterParams:semesterParams];
					
					// Don't insert nil
					if(classInfo) {
						[averages addObject:classInfo];
					}
				}
				@catch (NSException *exception) {
					NSLog(@"something broke %@", exception);
				}
			}
		}
#ifndef DEBUG
	}
	@catch (NSException *exception) {
		NSLog(@"Parse error: %@", exception);
		return nil;
	}
#endif
	
	// NSLog(@"Averages: %@", averages);
	
	return averages;
}

#pragma mark - Category parsing
- (NSDictionary *) parseAssignmentWithRow:(TFHppleElement *) row andIs100Pts:(BOOL) is100Pts {
	NSMutableDictionary *dict = [NSMutableDictionary new];
	
	// Extract some data
	float ptsEarnedNum, weight;
	BOOL extraCredit = NO;
	
	NSString *title = [row getColumnContentsWithClass:@"AssignmentName"];
	NSString *dueDate = [row getColumnContentsWithClass:@"DateDue"];
	NSString *assignedDate = [row getColumnContentsWithClass:@"DateAssigned"];
	NSString *note = [row getColumnContentsWithClass:@"AssignmentNote"];
	NSString *ptsEarned = [row getColumnContentsWithClass:@"AssignmentGrade"];
	float ptsPossibleNum = is100Pts ? 100.0 : [row getColumnContentsWithClass:@"AssignmentPointsPossible"].floatValue;
	
	/*
	 * Process the ptsEarned value to see if the assignment has been inputted
	 * with a weight. It would then look like this:
	 *
	 * 88x0.6
	 * 90x0.2
	 * 100x0.2
	 *
	 * The first number is the actual points earned, whereas the second is the
	 * weight of the assignment. If not specified, we assume a weight of 1.
	 */
	if(ptsEarned.length != 0) {
		if(NSEqualRanges(NSMakeRange(NSNotFound,0),[ptsEarned rangeOfString:@"x"])) {
			// The assignment has no weight specified.
			ptsEarnedNum = ptsEarned.floatValue;
			weight = 1.0;
		} else {
			NSArray *split = [ptsEarned componentsSeparatedByString:@"x"];
			ptsEarnedNum = [split[0] floatValue];
			weight = [split[1] floatValue];
		}
		
		// Check if the assignment is marked as missing (wrapped in <del> tags)
		if(!NSEqualRanges(NSMakeRange(NSNotFound, 0), [ptsEarned rangeOfString:@"del"])) {
			ptsEarnedNum = 0;
			NSLog(@"squelchmatron");
		}
	} else {
		ptsEarnedNum = -1;
		weight = 1.0;
	}
	
	/*
	 * GradeSpeed is a bit stupid and doesn't explicitly mark assignments as
	 * extra credit, so we run a string compare on the assignment title and note
	 * to determine if it is, in fact, extra credit.
	 */
	
	BOOL temp = NO;
	
	if(note.length > 0) {
		temp = !NSEqualRanges(NSMakeRange(NSNotFound, 0), [note rangeOfString:@"extra credit" options:NSCaseInsensitiveSearch]);
	}
	
	extraCredit = !NSEqualRanges(NSMakeRange(NSNotFound, 0), [title rangeOfString:@"extra credit" options:NSCaseInsensitiveSearch]) || temp;
	
	// Shove everything in the dictionary.
	dict[@"title"] = title;
	dict[@"dueDate"] = [_gradespeedDateFormatter dateFromString:dueDate];
	dict[@"assignedDate"] = [_gradespeedDateFormatter dateFromString:assignedDate];
	dict[@"ptsEarned"] = @(ptsEarnedNum);
	dict[@"ptsPossible"] = @(ptsPossibleNum);
	dict[@"weight"] = @(weight);
	dict[@"isOutOf100"] = @((ptsPossibleNum == 100) ? true : false);
	dict[@"note"] = !note ? @"" : note;
	dict[@"extraCredit"] = @(extraCredit);
	
	return dict;
}

- (NSDictionary *) parseCategory:(SQUDistrict *) district withName:(NSString *) name andTable:(TFHppleElement *) table {
	NSMutableDictionary *category = [NSMutableDictionary new];
	
	// Attempt to fetch the weight for each category
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^(.*) - (\\d+)%$" options:NSRegularExpressionCaseInsensitive error:nil];
	
	NSArray *catNameMatches = [regex matchesInString:name options:0 range:NSMakeRange(0, name.length)];
	if(catNameMatches.count == 0) {
		regex = [NSRegularExpression regularExpressionWithPattern:@"^(.*) - Each assignment counts (\\d+)" options:NSRegularExpressionCaseInsensitive error:nil];
		catNameMatches = [regex matchesInString:name options:0 range:NSMakeRange(0, name.length)];
	}
	
	// Locate category header
	TFHppleElement *header = [table childrenWithClassName:@"TableHeader"][0];
	
	// Figure out if assignments are out of 100 points.
	BOOL is100Pts = ([header childrenWithClassName:@"AssignmentGrade"].count == 1);
	
	// Find all rows
	NSArray *rows = [table childrenWithTagName:@"tr"];
	NSMutableArray *assignments = [NSMutableArray arrayWithArray:[table childrenWithClassName:@"DataRow"]];
	[assignments addObjectsFromArray:[table childrenWithClassName:@"DataRowAlt"]];
	
	// Find the average cell.
	TFHppleElement *averageRow = rows[rows.count-1];
	NSArray *averageCells = [averageRow childrenWithTagName:@"td"];
	TFHppleElement *averageCell;
	
	for(TFHppleElement *column in averageCells) {
		if(!NSEqualRanges([column.text rangeOfString:@"Average"], NSMakeRange(NSNotFound, 0))) {
			averageCell = averageCells[[averageCells indexOfObject:column] + 1];
			break;
		}
	}
	
	// Parse the assignments found.
	NSMutableArray *assignmentInfo = [NSMutableArray new];
	
	for(TFHppleElement *row in assignments) {
		NSDictionary *assignment = [self parseAssignmentWithRow:row andIs100Pts:is100Pts];
		
		[assignmentInfo addObject:assignment];
	}
	
	// Populate dictionary
	category[@"average"] = [NSNumber numberWithFloat:averageCell.text.floatValue];
	category[@"weight"] = [NSNumber numberWithFloat:[[name substringWithRange:[catNameMatches[0] rangeAtIndex:2]] floatValue]];
	category[@"name"] = [name substringWithRange:[catNameMatches[0] rangeAtIndex:1]];
	category[@"bonus"] = @(0);
	category[@"assignments"] = assignmentInfo;
	category[@"is100PtsBased"] = @(is100Pts);
	
	return category;
}

/**
 * Parses the assignments in a class.
 *
 * @param district: District to use in parsing.
 * @param string: Gradebook HTML.
 * @return Categories and assignments for the class.
 */
- (NSDictionary *) getClassGradesForDistrict:(SQUDistrict *) district withData:(NSData *) data {
	NSMutableDictionary *grades = [NSMutableDictionary new];
	
	TFHpple *parser = [TFHpple hppleWithHTMLData:data];
	
#ifndef DEBUG
	@try {
#endif
		NSMutableArray *tables = [NSMutableArray arrayWithArray:[parser searchWithXPathQuery:@"//table[@class='DataTable']"]];
		if(tables.count == 0) return nil;
		
		[tables removeObjectAtIndex:0];
		
		NSArray *categoryTitles = [parser searchWithXPathQuery:@"//span[@class='CategoryName']"];
		
		// If this isn't true, we've got issues
		NSAssert(tables.count == categoryTitles.count,
				 @"Found %lu tables, but only %lu categories", (unsigned long) tables.count,
				 (unsigned long) categoryTitles.count);
		
		// Extract current average
		TFHppleElement *currentAverage = [parser searchWithXPathQuery:@"//p[@class='CurrentAverage']"][0];
		grades[@"average"] = [NSNumber numberWithInteger:[[currentAverage.text componentsSeparatedByString:@":"][1] integerValue]];
		
		// Process each of the categories
		NSMutableArray *categories = [NSMutableArray new];
		NSUInteger i = 0;
		
		for(TFHppleElement *table in tables) {
			TFHppleElement *nameHeader = [categoryTitles objectAtIndex:i];
			NSDictionary *dict = [self parseCategory:district withName:nameHeader.text andTable:table];
			[categories addObject:dict];
			i++;
		}
		
		grades[@"categories"] = categories;
#ifndef DEBUG
	} @catch (NSException *e) {
		NSLog(@"Error while parsing categories: %@", e);
		return nil;
	}
#endif
	
	//NSLog(@"%@", grades);
	
	return grades;
}

#pragma mark - User-interface support
/**
 * @param district: District to use for parsing.
 * @param string: Gradebook HTML.
 * @return Student's name.
 */
- (NSString *) getStudentNameForDistrict:(SQUDistrict *) district withData:(NSData *) data{
	TFHpple *parser = [TFHpple hppleWithHTMLData:data];
	NSArray *matches = [parser searchWithXPathQuery:@"//span[@class='StudentName']"];
	
	if(matches.count != 0) {
		TFHppleElement *studentName = matches[0];
		return studentName.text;
	}
	
	return @"";
}

/**
 * @param district: District to use for parsing.
 * @param string: Gradebook HTML.
 * @return School attended by the student.
 */
- (NSString *) getStudentSchoolForDistrict:(SQUDistrict *) district withData:(NSData *) data {
	TFHpple *parser = [TFHpple hppleWithHTMLData:data];
	NSArray *matches = [parser searchWithXPathQuery:@"//*[@id='_ctl0_tdMainContent']/div"];
	
	if(matches.count != 0) {
		TFHppleElement *header = matches[0];
		
		// Find text inside parenthesis
		NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\((.*?)\\)" options:NSRegularExpressionCaseInsensitive error:nil];
		NSRange range = [[regex firstMatchInString:header.text options:0 range:NSMakeRange(0, header.text.length)] rangeAtIndex:1];
		
		// Make sure the range is valid before trying to use it
		if(!NSEqualRanges(range, NSMakeRange(NSNotFound, 0))) {
			return [header.text substringWithRange:range];
		} else {
			return @"";
		}
	}
	
	return @"";
}

@end
