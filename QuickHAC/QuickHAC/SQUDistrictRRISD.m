//
//  SQUDistrictRRISD.m
//  QuickHAC
//
//  Created by Tristan Seifert on 12/27/13.
//  See README.MD for licensing and copyright information.
//

#import <AFNetworking/AFHTTPRequestOperation.h>
#import <AFNetworking/AFHTTPRequestOperationManager.h>

#import "TFHpple.h"
#import "TFHppleElement.h"

#import "SQUCoreData.h"
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
		_driver = @"plus360";
		_examWeight = 15.0f;
		
		_tableOffsets.title = 0;
		_tableOffsets.period = 1;
		_tableOffsets.grades = 2;
		
		_district_id = 1;
		
		_studentIDLength = NSMakeRange(6, 6);
		
		_districtDomain = @"accesscenter.roundrockisd.org";
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
	return nil;
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
	dictionary[@"request"][@"URL"] = [NSURL URLWithString:@"https://accesscenter.roundrockisd.org/HomeAccess/Account/LogOn?ReturnUrl=/HomeAccess/"];
	dictionary[@"request"][@"method"] = @"POST";
	
	// Form fields
	dictionary[@"params"][@"LogOnDetails.UserName"] = username;
	dictionary[@"params"][@"LogOnDetails.Password"] = password;
	
	// This field seems to be some kind of district indicator
	dictionary[@"params"][@"Database"] = @"10";
	
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
	dictionary[@"request"][@"URL"] = [NSURL URLWithString:@"https://accesscenter.roundrockisd.org/HomeAccess/Frame/StudentPicker"];
	dictionary[@"request"][@"method"] = @"POST";
	
	// Set up POST parameters
	dictionary[@"params"][@"studentId"] = sid;
	dictionary[@"params"][@"url"] = @"/HomeAccess/Home/SchoolLinks";
	
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
	dictionary[@"request"][@"URL"] = [NSURL URLWithString:@"https://accesscenter.roundrockisd.org/HomeAccess/Content/Student/Assignments.aspx"];
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
	dictionary[@"request"][@"URL"] = [NSURL URLWithString:@"https://accesscenter.roundrockisd.org/HomeAccess/Content/Student/Assignments.aspx"];
	dictionary[@"request"][@"method"] = @"GET";
	
	NSArray *semesterArray = _classToHashMap[course];
	if(!semesterArray) {
		NSLog(@"Could not find course %@ in hash map", course);
		return nil;
	}
	
	if(semester > semesterArray.count) {
		NSLog(@"Semester %lu is out of range (got %lu semesters)", (unsigned long)semester, (unsigned long)semesterArray.count);
		return nil;
	}

	NSArray *cycleArray = semesterArray[semester];
	if(cycle > cycleArray.count) {
		NSLog(@"Cycle %lu is out of range (got %lu cycles)", (unsigned long)cycle, (unsigned long)cycleArray.count);
		return nil;
	}
	
	if([cycleArray[cycle] length] == 0) {
		NSLog(@"There is no grade data available for cycle %lu in semester %lu for course %@",
			  (unsigned long)cycle, (unsigned long) semester, course);
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
		if(class[@"courseNum"]) {
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
	
	// NSLog(@"Hash map: %@", _classToHashMap);
}

/*
 * Called on completion of the pre-login request, if it is required, with the
 * data returned by the request.
 */
- (void) updateDistrictStateWithPreLoginData:(NSData *) data {
	
}

/**
 * We need a request after login.
 */
- (BOOL) hasPostLoginRequest {
	return YES;
}

/**
 * Perform the post-login request.
 */
- (void) doPostLoginRequestWithCallback:(SQUPostLoginCallback) callback {
	// Called on success of the operation (200 OK)
	void (^success)(AFHTTPRequestOperation*operation, id responseObject) =
	^(AFHTTPRequestOperation*operation, id responseObject) {
		TFHpple *parser = [TFHpple hppleWithHTMLData:responseObject];
		
		// Set up array
		if(_studentsOnAccount) {
			[_studentsOnAccount removeAllObjects];
		} else {
			_studentsOnAccount = [NSMutableArray new];
		}
		
		// Find the rows
		NSArray *rows = [parser searchWithXPathQuery:@"//*[@id='StudentPicker']/label"];
		
		for (TFHppleElement *row in rows) {
			@try {
				// Find the radio
				TFHppleElement *radio = [row searchWithXPathQuery:@"//*[@id='studentId']"][0];
				NSString *studentID = radio[@"value"];
				
				// Extract the span holding the name
				TFHppleElement *nameField = [row searchWithXPathQuery:@"//*/div/span[1]"][0];
				NSString *name = nameField.text;
				
				// Insert into array
				[_studentsOnAccount addObject:@{@"id"	: studentID,
												@"name"	: name}];
			}
			
			// Handle cases in which the HTML is malformed
			@catch (NSException *exception) {
				NSLog(@"whoops %@", exception);
				callback([NSError errorWithDomain:SQUDistrictRRISDErrorDomain
											 code:kSQUDistrictRRISDErrorInvalidDisambiguateHTML
										 userInfo:nil]);
				return;
			}
		}
		
		_hasMultipleStudents = (_studentsOnAccount.count > 1);
		
		// Request succeeded
		callback(nil);
	};
	
	// Called if the request fails for some reason (500, network error, etc)
	void (^fail)(AFHTTPRequestOperation*operation, NSError *error) =
	^(AFHTTPRequestOperation*operation, NSError *error) {
		if(operation.response.statusCode == 500) {			
			_hasMultipleStudents = NO;
			
			// Set up the students array anyways
			if(_studentsOnAccount) {
				[_studentsOnAccount removeAllObjects];
			} else {
				_studentsOnAccount = [NSMutableArray new];
			}
			
			callback(nil);
		} else {
			callback(error);
		}
	};
	
	// do request pls
	AFHTTPRequestOperationManager *man = [SQUDistrictManager sharedInstance].HTTPManager;
	
	[man GET:@"https://accesscenter.roundrockisd.org/HomeAccess/Frame/StudentPicker"
  parameters:@{} success:success failure:fail];
}

/*
 * Called after the completion of the actual login request with the data that
 * the web server returned.
 *
 * What this does is send a request to the student picker URL at
 * "https://accesscenter.roundrockisd.org/HomeAccess/Frame/StudentPicker" and
 * parses its HTML to determine whether there is multiple students, their names,
 * and so forth.
 */
- (void) updateDistrictStateWithPostLoginData:(NSData *) data {
	
}

/*
 * Called with the data returned by the login request to validate if the login
 * was a success.
 */
- (BOOL) didLoginSucceedWithLoginData:(NSData *) data {
	TFHpple *parser = [TFHpple hppleWithHTMLData:data];
	TFHppleElement *e = [parser peekAtSearchWithXPathQuery:
						 @"//*[@class='validation-summary-errors']"];
	
	/* 
	 * If the "validation-summary-errors" div exists in the page, the login
	 * failed.
	 */
	return (e != nil) ? NO : YES;
}

/*
 * Called with the data returned by the disambiguation request to evaluate if
 * the correct student was disambiguated.
 *
 * Since we have no way of knowing whether this succeeded or not, we just
 * assume it did, since it would imply that the login was successful.
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
	
	[manager HEAD:@"https://accesscenter.roundrockisd.org/HomeAccess/Content/Student/Assignments.aspx" parameters:nil success:^(AFHTTPRequestOperation *operation) {
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


/**
 * Calculates the unweighted GPA on a 4.0 scale for the specified courses.
 *
 * The GPA is approximated using the formula y = .1255x - 7.8467
 *
 * @param courses An array of SQUCourse objects.
 * @return The unweighted GPA as an NSNumber object.
 */
- (NSNumber *) unweightedGPAWithCourses:(NSArray *) courses {
	float gpa = 0;
	float num_classes = 0;
	
	// Process all classes
	for (SQUCourse *course in courses) {
		// Process all semesters
		for(NSUInteger i = 0; i < course.student.numSemesters.unsignedIntegerValue; i++) {
			SQUSemester *semester = course.semesters[i];
			
			// Ignore a course if there's no grade for it.
			if(semester.average.integerValue != -1) {
				// Ignore grades below 70
				if(semester.average.floatValue >= 70.0) {
					//gpa += fmin((semester.average.floatValue - 60.0) / 10.0, 4.0);
					// gpa += (.1255 * (semester.average.floatValue)) - 7.8467;
					if(semester.average.floatValue > 90) {
						gpa += 4.0;
					} else if(semester.average.floatValue < 90 && semester.average.floatValue >= 80) {
						gpa += 3.0;
					} else if(semester.average.floatValue < 80 && semester.average.floatValue < 74) {
						gpa += 2.0;
					} else if(semester.average.floatValue <= 74) {
						gpa += 1.0;
					}
				}
				
				num_classes++;
			}
		}
	}
	
	// Divide by number of classes
	gpa /= num_classes;
	
	return @(gpa);
}


/**
 * Returns the grade point (between 6.0 and 0.0) for a floating-point average,
 * and taking into account if the course is an honours class or not.
 *
 * With RRISD, honours courses are a 6.0 for a 100, and 5.0 for a 100 in non-
 * honours courses.
 *
 * @param grade The average, between 100 and 0 inclusive.
 * @param honours Whether the class is honours or not.
 * @return A floating-point grade point.
 */
- (float) getGradePointForAverage:(float) average andHonours:(BOOL) honours {
	if(average < 70) {
		return 0.0;
	}
	
	float gpa;
	
	// Calculate grade point
	if(honours) {
		gpa = (average - 40.0) / 10.0;
	} else {
		gpa = (average - 50.0) / 10.0;
	}
	
	// Limit grade to be no less than 0.0
	gpa = fmaxf(0, gpa);
	
	return gpa;
}

/**
 * Calculates the weighted GPA for the specified courses.
 *
 * @param courses An array of SQUCourse objects.
 * @return The weighted GPA as an NSNumber object.
 */
- (NSNumber *) weightedGPAWithCourses:(NSArray *) courses {
	float gpa = 0;
	float num_classes = 0;
	
	// Process all classes
	for (SQUCourse *course in courses) {
		// Process all semesters
		for(NSUInteger i = 0; i < course.student.numSemesters.unsignedIntegerValue; i++) {
			SQUSemester *semester = course.semesters[i];
			
			// Ignore a course if there's no grade for it.
			if(semester.average.integerValue != -1) {
				gpa += [self getGradePointForAverage:semester.average.floatValue andHonours:course.isHonours.boolValue];
				num_classes++;
			}
		}
	}
	
	// Divide by number of classes
	gpa /= num_classes;
	
	return @(gpa);
}

@end