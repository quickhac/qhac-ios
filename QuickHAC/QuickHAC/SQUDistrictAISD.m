//
//  SQUDistrictAISD.m
//  QuickHAC
//
//  Created by Tristan Seifert on 12/30/13.
//  See README.MD for licensing and copyright information.
//

#import "TFHpple.h"
#import "AFNetworking.h"

#import "SQUDistrictAISD.h"
#import "SQUDistrictManager.h"

@implementation SQUDistrictAISD

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
		_name = @"Austin ISD";
		_driver = @"gradespeed";
		_examWeight = 15.0f;
		
		_tableOffsets.title = 1;
		_tableOffsets.period = 2;
		_tableOffsets.grades = 3;
		
		_district_id = 2;
		
		_gpaOffset = 60.0;
		
		_studentIDLength = NSMakeRange(7, 8);
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
	dictionary[@"request"][@"URL"] = [NSURL URLWithString:@"https://gradespeed.austinisd.org/pc/default.aspx?DistrictID=227901"];
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
	dictionary[@"request"][@"URL"] = [NSURL URLWithString:@"https://gradespeed.austinisd.org/pc/default.aspx?DistrictID=227901"];
	dictionary[@"request"][@"method"] = @"POST";
	
	// Form fields (replicate login request in English language)
	dictionary[@"params"][@"ddlDistricts"] = @"";
	dictionary[@"params"][@"txtUserName"] = username;
	dictionary[@"params"][@"txtPassword"] = password;
	dictionary[@"params"][@"ddlLanguage"] = @"en";
	dictionary[@"params"][@"btnLogOn"] = @"Log On";
	
	dictionary[@"params"][@"__scrollLeft"] = @(0);
	dictionary[@"params"][@"__scrollTop"] = @(0);
	
	// ASP.NET fields
	dictionary[@"params"][@"__EVENTTARGET"] = @"";
	dictionary[@"params"][@"__EVENTARGUMENT"] = @"";
	dictionary[@"params"][@"__LASTFOCUS"] = @"";
	dictionary[@"params"][@"__VIEWSTATE"] = _loginASPNetInfo[@"__VIEWSTATE"];
	
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
	dictionary[@"request"][@"URL"] = [NSURL URLWithString:@"https://gradespeed.austinisd.org/pc/ParentMain.aspx"];
	dictionary[@"request"][@"method"] = @"POST";
	
	// Set up ASP.NET crap
	dictionary[@"params"][@"__EVENTTARGET"] = @"_ctl0$ddlStudents";
	dictionary[@"params"][@"__EVENTARGUMENT"] = @"";
	dictionary[@"params"][@"__LASTFOCUS"] = @"";
	dictionary[@"params"][@"__VIEWSTATE"] = _disambiguationASPNetInfo[@"__VIEWSTATE"];
	dictionary[@"params"][@"__EVENTVALIDATION"] = _disambiguationASPNetInfo[@"__EVENTVALIDATION"];

	dictionary[@"params"][@"__RUNEVENTTARGET"] = @"";
	dictionary[@"params"][@"__RUNEVENTARGUMENT"] = @"";
	dictionary[@"params"][@"__RUNEVENTARGUMENT2"] = @"";
	
	// Student ID
	dictionary[@"params"][@"_ctl0:ddlStudents"] = sid;
	
	// Miscellaneous form crap
	dictionary[@"params"][@"__scrollLeft"] = @(0);
	dictionary[@"params"][@"__scrollTop"] = @(0);
	
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
	dictionary[@"request"][@"URL"] = [NSURL URLWithString:@"https://gradespeed.austinisd.org/pc/ParentStudentGrades.aspx"];
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
	dictionary[@"request"][@"URL"] = [NSURL URLWithString:@"https://gradespeed.austinisd.org/pc/ParentStudentGrades.aspx"];
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
	TFHppleElement *form = [parser searchWithXPathQuery:@"//form[@name='Form1']"][0];
	
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
	if(!_disambiguationASPNetInfo) {
		_disambiguationASPNetInfo = [NSMutableDictionary new];
	} else {
		[_disambiguationASPNetInfo removeAllObjects];
	}
	
	// Set up a parser
	TFHpple *parser = [TFHpple hppleWithHTMLData:data];
	NSArray *forms = [parser searchWithXPathQuery:@"//form[@name='aspnetForm']"];

	// Prevent crash if login is invalid
	if(forms.count > 0) {
		TFHppleElement *form = forms[0];
		
		// Find children of the form
		NSArray *formChildren = [form childrenWithTagName:@"input"];
		
		for (TFHppleElement *input in formChildren) {
			if([input[@"name"] isEqualToString:@"__VIEWSTATE"]) {
				_disambiguationASPNetInfo[@"__VIEWSTATE"] = input[@"value"];
			} else if([input[@"name"] isEqualToString:@"__EVENTVALIDATION"]) {
				_disambiguationASPNetInfo[@"__EVENTVALIDATION"] = input[@"value"];
			}
		}
	} else {
		NSLog(@"WARNING: Login did not get good data, disambiguation may fail");
	}
}

/*
 * Called with the data returned by the login request to validate if the login
 * was a success.
 */
- (BOOL) didLoginSucceedWithLoginData:(NSData *) data {
	TFHpple *parser = [TFHpple hppleWithHTMLData:data];
	NSArray *forms = [parser searchWithXPathQuery:@"//form[@name='Form1']"];
	
	// Form1 is only on the login screen, so if it doesn't exist we're loggeed in
	if(forms.count == 0) {
		forms = [parser searchWithXPathQuery:@"//form[@name='aspnetForm']"];
		return (forms.count == 1);
	}
	
	return NO;
}

/*
 * Called with the data returned by the disambiguation request to evaluate if
 * the correct student was disambiguated.
 *
 * AISD doesn't have the list of students as a separate page, but a drop-down on
 * the main page. Therefore, as we scrape that to build the UI for student
 * selection, there shouldn't be a way disambiguation can fail.
 */
- (BOOL) didDisambiguationSucceedWithLoginData:(NSData *) data {
	return YES;
}


/*
 * Called to get the current login status.
 */
- (void) isLoggedInWithCallback:(SQULoggedInCallback) callback {
	AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
	manager.responseSerializer = [AFHTTPResponseSerializer serializer];
	
	[manager HEAD:@"https://gradespeed.austinisd.org/pc/ParentStudentGrades.aspx" parameters:nil success:^(AFHTTPRequestOperation *operation) {
		if(operation.response.statusCode == 200) {
			callback(YES);
		} else {
			callback(NO);
		}
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
