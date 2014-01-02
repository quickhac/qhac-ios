//
//  SQUDistrictRRISD.m
//  QuickHAC
//
//  Created by Tristan Seifert on 12/27/13.
//  See README.MD for licensing and copyright information.
//

#import "TFHpple.h"
#import "AFNetworking.h"

#import "SQUDistrictRRISD.h"
#import "SQUDistrictManager.h"

@implementation SQUDistrictRRISD

/*
 * Called by the ObjC runtime when the class is loaded to register the district
 * with the District Manager.
 */
+ (void) load {
	[[SQUDistrictManager sharedInstance] registerDistrict:[self class]];
}

/*
 * When the district is initialised, this serves to set up the name and other
 * variables.
 */
- (id) init {
	if(self = [super init]) {
		_name = @"Round Rock ISD";
		_driver = @"gradespeed";
		_examWeight = 15.0f;
		
		_tableOffsets.title = 0;
		_tableOffsets.period = 1;
		_tableOffsets.grades = 2;
		
		_district_id = 1;
		
		_gpaOffset = 50.0;
		
		_studentIDLength = NSMakeRange(6, 6);
	}
	
	return self;
}

#pragma mark - Request building
/*
 * Builds a request to run directly before the login to, for example, fetch some
 * parameters from the form that are needed for the login process to complete
 * successfully. (Yes, ASP.NET, we're looking at you…)
 */
- (NSDictionary *) buildPreLoginRequestWithUserData:(id) userData {
	NSMutableDictionary *dictionary = [NSMutableDictionary new];
	dictionary[@"request"] = [NSMutableDictionary new];
	
	// Request information (URL, method, etc)
	dictionary[@"request"][@"URL"] = [NSURL URLWithString:@"https://accesscenter.roundrockisd.org/homeaccess/default.aspx"];
	dictionary[@"request"][@"method"] = @"GET";
	
	return dictionary;
}

/*
 * This method would build a login request for the username and password given,
 * possibly using the user data, depending on district.
 */
- (NSDictionary *) buildLoginRequestWithUser:(NSString *) username usingPassword:(NSString *) password andUserData:(id) userData {
	NSMutableDictionary *dictionary = [NSMutableDictionary new];
	dictionary[@"request"] = [NSMutableDictionary new];
	dictionary[@"params"] = [NSMutableDictionary new];
	
	// Request information (URL, method, etc)
	dictionary[@"request"][@"URL"] = [NSURL URLWithString:@"https://accesscenter.roundrockisd.org/homeaccess/default.aspx"];
	dictionary[@"request"][@"method"] = @"POST";
	
	// Form fields
	dictionary[@"params"][@"ctl00$plnMain$txtLogin"] = username;
	dictionary[@"params"][@"ctl00$plnMain$txtPassword"] = password;
	dictionary[@"params"][@"ctl00$plnMain$Submit1"] = @"Log In";
	dictionary[@"params"][@"ctl00$strHiddenPageTitle"] = @"";
	
	// ASP.NET fields
	dictionary[@"params"][@"__VIEWSTATE"] = _loginASPNetInfo[@"__VIEWSTATE"];
	dictionary[@"params"][@"__EVENTVALIDATION"] = _loginASPNetInfo[@"__EVENTVALIDATION"];
	dictionary[@"params"][@"__EVENTTARGET"] = @"";
	dictionary[@"params"][@"__EVENTARGUMENT"] = @"";
	
	return dictionary;
}

/*
 * Build a request to disambiguate the student ID specified.
 */
- (NSDictionary *) buildDisambiguationRequestWithStudentID:(NSString *) sid andUserData:(id) userData {
	NSMutableDictionary *dictionary = [NSMutableDictionary new];
	dictionary[@"request"] = [NSMutableDictionary new];
	dictionary[@"params"] = [NSMutableDictionary new];
	
	// Request information (URL, method, etc)
	dictionary[@"request"][@"URL"] = [NSURL URLWithString:@"https://accesscenter.roundrockisd.org/homeaccess/Student/DailySummary.aspx"];
	dictionary[@"request"][@"method"] = @"GET";
	
	// Set up GET parameters
	dictionary[@"params"][@"student_id"] = sid;
	
	return dictionary;
}

/*
 * Build a request to fetch the class averages for the currently logged-in
 * student ID.
 */
- (NSDictionary *) buildAveragesRequestWithUserData:(id) userData {
	NSMutableDictionary *dictionary = [NSMutableDictionary new];
	dictionary[@"request"] = [NSMutableDictionary new];
	
	// Request information (URL, method, etc)
	dictionary[@"request"][@"URL"] = [NSURL URLWithString:@"https://accesscenter.roundrockisd.org/homeaccess/Student/Gradespeed.aspx?target=https://gradebook.roundrockisd.org/pc/displaygrades.aspx"];
	dictionary[@"request"][@"method"] = @"GET";
	
	return dictionary;
}

/*
 * Builds a request to fetch the class grades for the specified course and
 * cycle.
 */
- (NSDictionary *) buildClassGradesRequestWithCourseCode:(NSString *) course andSemester:(NSUInteger) semester andCycle:(NSUInteger) cycle andUserData:(id) userData {
	NSMutableDictionary *dictionary = [NSMutableDictionary new];
	dictionary[@"request"] = [NSMutableDictionary new];
	dictionary[@"params"] = [NSMutableDictionary new];
	
	// Request information (URL, method, etc)
	dictionary[@"request"][@"URL"] = [NSURL URLWithString:@"https://gradebook.roundrockisd.org/pc/displaygrades.aspx"];
	dictionary[@"request"][@"method"] = @"GET";
	
	NSArray *semesterArray = _classToHashMap[course];
	if(!semesterArray) {
		NSLog(@"Could not find course %@ in hash map", course);
		return nil;
	}
	
	if(semester > semesterArray.count) {
		NSLog(@"Semester %u is out of range (got %u semesters)", semester, semesterArray.count);
		return nil;
	}

	NSArray *cycleArray = semesterArray[semester];
	if(cycle > cycleArray.count) {
		NSLog(@"Cycle %u is out of range (got %u cycles)", cycle, cycleArray.count);
		return nil;
	}
	
	if([cycleArray[cycle] length] == 0) {
		NSLog(@"There is no grade data available for cycle %u in semester %u for course %@",cycle,semester,course);
		return nil;
	}
	
	// Check the array for the course's cycle hash
	dictionary[@"params"][@"data"] = cycleArray[cycle];
	
	return dictionary;
}

#pragma mark - Data callbacks
/*
 * This method is called whenever the overall averages for all classes is
 * updated, so the district code can perform internal housekeeping, like keeping
 * track of the URLs for specifc class grades information.
 */
- (void) updateDistrictStateWithClassGrades:(NSArray *) grades {
	if(!_classToHashMap) {
		_classToHashMap = [NSMutableDictionary new];
	} else {
		[_classToHashMap removeAllObjects];
	}
	
	for(NSDictionary *class in grades) {
		NSMutableArray *semesterArray = [NSMutableArray new];
		
		for(NSDictionary *semester in class[@"semesters"]) {
			NSMutableArray *cycleArray = [NSMutableArray new];
			
			for(NSDictionary *cycle in semester[@"cycles"]) {
				[cycleArray addObject:cycle[@"urlHash"]];
			}
			
			[semesterArray addObject:cycleArray];
		}
		
		_classToHashMap[class[@"courseNum"]] = semesterArray;
	}
	
	// NSLog(@"Hash map: %@", _classToHashMap);
}

/*
 * Called on completion of the pre-login request, if it is required, with the
 * data returned by the request.
 */
- (void) updateDistrictStateWithPreLoginData:(NSData *) data {
	if(!_loginASPNetInfo) {
		_loginASPNetInfo = [NSMutableDictionary new];
	} else {
		[_loginASPNetInfo removeAllObjects];
	}
	
	// Set up a parser
	TFHpple *parser = [TFHpple hppleWithHTMLData:data];
	TFHppleElement *form = [parser searchWithXPathQuery:@"//form[@name='aspnetForm']"][0];
	
	// Find children of the form
	NSArray *formChildren = [form childrenWithTagName:@"input"];
	
	for (TFHppleElement *input in formChildren) {
		if([input[@"name"] isEqualToString:@"__VIEWSTATE"]) {
			_loginASPNetInfo[@"__VIEWSTATE"] = input[@"value"];
		} else if([input[@"name"] isEqualToString:@"__EVENTVALIDATION"]) {
			_loginASPNetInfo[@"__EVENTVALIDATION"] = input[@"value"];
		}
	}
}

/*
 * Called after the completion of the actual login request with the data that
 * the web server returned.
 */
- (void) updateDistrictStateWithPostLoginData:(NSData *) data {
	// NSLog(@"Login data: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
	TFHpple *parser = [TFHpple hppleWithHTMLData:data];
	NSArray *links = [parser searchWithXPathQuery:@"//*[@id='ctl00_plnMain_dgStudents']/tr/td/a"];
	
	// Parse the students in the table.
	if(links.count != 0) {
		if(_studentsOnAccount) {
			[_studentsOnAccount removeAllObjects];
		} else {
			_studentsOnAccount = [NSMutableArray new];
		}
		
		for(TFHppleElement *link in links) {
			NSString *studentID = [link[@"href"] componentsSeparatedByString:@"="][1];
			NSString *studentName = link.text;
			
			[_studentsOnAccount addObject:@{@"id":studentID, @"name":studentName}];
		}
	} else {
		_studentsOnAccount = nil;
	}
	
	_hasMultipleStudents = (links.count != 0);
}

/*
 * Called with the data returned by the login request to validate if the login
 * was a success.
 */
- (BOOL) didLoginSucceedWithLoginData:(NSData *) data {
	TFHpple *parser = [TFHpple hppleWithHTMLData:data];
	TFHppleElement *form = [parser searchWithXPathQuery:@"//form[@name='aspnetForm']"][0];
	
	/* 
	 * If the ASP form has a target of "default.aspx", we can assume the login
	 * failed. We can further check if this is the case by testing if the div
	 * with id "ctl00_plnMain_ValidationSummary1" contains any text.
	 */
	if([form[@"action"] isEqualToString:@"default.aspx"]) {
		NSArray *errorContainers = [parser searchWithXPathQuery:@"//div[@id='ctl00_plnMain_ValidationSummary1']"];
		
		if(errorContainers.count > 0) {
			TFHppleElement *validationErrorContainer = errorContainers[0];
			
			NSArray *children = [validationErrorContainer childrenWithTagName:@"font"];
			
			if(children.count > 0) {
				// NSLog(@"//div[@id='ctl00_plnMain_ValidationSummary1']: %@", children);
			}
			
			return NO;
		} else {
			NSLog(@"Got strange HTML: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
		}
	}
	
	return YES;
}

/*
 * Called with the data returned by the disambiguation request to evaluate if
 * the correct student was disambiguated.
 */
- (BOOL) didDisambiguationSucceedWithLoginData:(NSData *) data {
	TFHpple *parser = [TFHpple hppleWithHTMLData:data];
	TFHppleElement *content = [parser searchWithXPathQuery:@"//td[@id='ctl00_tdContent']"][0];
	
	NSArray *contentChildren = [content childrenWithTagName:@"p"];

	if(contentChildren.count == 0) return YES;
	
	return NO;
}


/*
 * Called to get the current login status.
 */
- (void) isLoggedInWithCallback:(SQULoggedInCallback) callback {
	AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
	manager.responseSerializer = [AFHTTPResponseSerializer serializer];
	
	[manager HEAD:@"https://accesscenter.roundrockisd.org/homeaccess/Student/Gradespeed.aspx?target=https://gradebook.roundrockisd.org/pc/displaygrades.aspx" parameters:nil success:^(AFHTTPRequestOperation *operation) {
		callback(YES);
	} failure:^(AFHTTPRequestOperation *operation, NSError *err) {
		if(operation.response.statusCode != 500) {
			NSLog(@"Log in error: %@", err);
		}
		
		callback(NO);
	}];
}

/*
 * Returns an array of cycles that have data available for a specific course.
 */
- (NSArray *) cyclesWithDataForCourse:(NSString *) courseCode {
	// Try to find the course in the map
	NSArray *semesterArray = _classToHashMap[courseCode];
	if(!semesterArray) {
		NSLog(@"Could not find course %@ in cycle -> hash map", courseCode);
		return nil;
	}
	
	// Build a list of all the cycles that have data
	NSMutableArray *result = [NSMutableArray new];
	NSUInteger cycleCount = 0;
	
	for(NSArray *semester in semesterArray) {
		for(NSString *hash in semester) {
			// If the hash is not nil and not zero length we have data
			if(hash && hash.length != 0) {
				[result addObject:@(cycleCount)];
			}
			
			cycleCount++;
		}
	}
	
	return result;
}

@end
