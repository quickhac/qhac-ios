//
//  SQUDistrict.m
//  QuickHAC
//
//  Created by Tristan Seifert on 12/27/13.
//  See README.MD for licensing and copyright information.
//

#import "SQUGradeManager.h"
#import "SQUCoreData.h"
#import "SQUDistrict.h"

@implementation SQUDistrict
@synthesize name = _name, driver = _driver, examWeight = _examWeight, tableOffsets = _tableOffsets, district_id = _district_id,  studentIDLength = _studentIDLength, hasMultipleStudents = _hasMultipleStudents, studentsOnAccount = _studentsOnAccount, districtDomain = _districtDomain;

/**
 * Builds a request to run directly before the login to, for example, fetch some
 * parameters from the form that are needed for the login process to complete
 * successfully. (Yes, ASP.NET, we're looking at you…)
 */
- (NSDictionary *) buildPreLoginRequestWithUserData:(id) userData {
	NSLog(@"%s(%i) %s: SQUDistrict method not overridden or no subclass used", __FILE__, __LINE__, __func__);
	return nil;
}

/**
 * This method would build a login request for the username and password given,
 * possibly using the user data, depending on district.
 */
- (NSDictionary *) buildLoginRequestWithUser:(NSString *) username usingPassword:(NSString *) password andUserData:(id) userData {
	NSLog(@"%s(%i) %s: SQUDistrict method not overridden or no subclass used", __FILE__, __LINE__, __func__);
	return nil;
}

/**
 * Build a request to disambiguate the student ID specified.
 */
- (NSDictionary *) buildDisambiguationRequestWithStudentID:(NSString *) sid andUserData:(id) userData {
	NSLog(@"%s(%i) %s: SQUDistrict method not overridden or no subclass used", __FILE__, __LINE__, __func__);
	return nil;
}

/**
 * Build a request to fetch the class averages for the currently logged-in
 * student ID.
 */
- (NSDictionary *) buildAveragesRequestWithUserData:(id) userData {
	NSLog(@"%s(%i) %s: SQUDistrict method not overridden or no subclass used", __FILE__, __LINE__, __func__);
	return nil;
}

/**
 * Builds a request to fetch the class grades for the specified course and
 * cycle.
 */
- (NSDictionary *) buildClassGradesRequestWithCourseCode:(NSString *) course andSemester:(NSUInteger) semester andCycle:(NSUInteger) cycle andUserData:(id) userData {
	NSLog(@"%s(%i) %s: SQUDistrict method not overridden or no subclass used", __FILE__, __LINE__, __func__);
	return nil;
}

/**
 * This method is called whenever the overall averages for all classes is 
 * updated, so the district code can perform internal housekeeping, like keeping
 * track of the URLs for specifc class grades information.
 */
- (void) updateDistrictStateWithClassGrades:(NSArray *) grade {
	NSLog(@"%s(%i) %s: SQUDistrict method not overridden or no subclass used", __FILE__, __LINE__, __func__);
}

/**
 * Called on completion of the pre-login request, if it is required, with the
 * data returned by the request.
 */
- (void) updateDistrictStateWithPreLoginData:(NSData *) data {
	NSLog(@"%s(%i) %s: SQUDistrict method not overridden or no subclass used", __FILE__, __LINE__, __func__);
}

/**
 * Called after the completion of the actual login request with the data that
 * the web server returned.
 */
- (void) updateDistrictStateWithPostLoginData:(NSData *) data {
	NSLog(@"%s(%i) %s: SQUDistrict method not overridden or no subclass used", __FILE__, __LINE__, __func__);
}

/**
 * Called with the data returned by the login request to validate if the login
 * was a success.
 */
- (BOOL) didLoginSucceedWithLoginData:(NSData *) data {
	NSLog(@"%s(%i) %s: SQUDistrict method not overridden or no subclass used", __FILE__, __LINE__, __func__);
	return NO;
}

/**
 * Called with the data returned by the disambiguation request to evaluate if
 * the correct student was disambiguated.
 */
- (BOOL) didDisambiguationSucceedWithLoginData:(NSData *) data {
	NSLog(@"%s(%i) %s: SQUDistrict method not overridden or no subclass used", __FILE__, __LINE__, __func__);
	return NO;
}

/**
 * Called to get the current login status.
 */
- (void) isLoggedInWithCallback:(SQULoggedInCallback) callback {
	NSLog(@"%s(%i) %s: SQUDistrict method not overridden or no subclass used", __FILE__, __LINE__, __func__);
}

/**
 * Called after the login request happens.
 */
- (void) doPostLoginRequestWithCallback:(SQUPostLoginCallback) callback {
	NSLog(@"%s(%i) %s: SQUDistrict method not overridden or no subclass used", __FILE__, __LINE__, __func__);
}

/**
 * Returns an array of cycles that have data available for a specific course.
 */
- (NSArray *) cyclesWithDataForCourse:(NSString *) courseCode {
	NSLog(@"%s(%i) %s: SQUDistrict method not overridden or no subclass used", __FILE__, __LINE__, __func__);
	return nil;
}

/**
 * Resets the internal district state.
 */
- (void) reset {
	NSLog(@"%s(%i) %s: SQUDistrict method not overridden or no subclass used", __FILE__, __LINE__, __func__);
}

/**
 * Allows the code toonly accept requests that come from the server.
 * @return The contents of a .cer file.
 */
- (NSArray *) districtSSLCertData {
	NSBundle *certBundle = [[NSBundle alloc] initWithURL:[[NSBundle mainBundle] URLForResource:@"DistrictCerts" withExtension:@"bundle"]];
	
	NSDictionary *info = [certBundle infoDictionary];
	NSDictionary *certInfo = nil;
	NSData *certData;
	
	// Search through the array for an entry matching this district.
	for(NSDictionary *cert in info[@"included_certificates"]) {
		if([cert[@"district_id"] integerValue] == _district_id) {
			certInfo = cert;
			break;
		}
	}
	
	// If no data was found, exit.
	if(!certInfo) return nil;
	if([certInfo[@"accept_any"] boolValue]) return nil;
	if([certInfo[@"do_pinning"] boolValue]) return nil;
	
	NSMutableArray *certs = [NSMutableArray new];
	
	// Load all specified certificates.
	for(NSString *certName in certInfo[@"certs"]) {
		NSURL *certURL = [certBundle URLForResource:certName withExtension:@"cer"];
		if(certURL) {
			certData = [NSData dataWithContentsOfURL:certURL];
			[certs addObject:certData];
		}
	}
	
	// Load all root certificates.
	NSArray *roots = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:[certBundle URLForResource:@"roots" withExtension:nil] includingPropertiesForKeys:nil options:0 error:nil];
	
	for(NSURL *root in roots) {
		certData = [NSData dataWithContentsOfURL:root];
		
		if(certData) {
			[certs addObject:certData];
		}
	}
	
	// Return only if we found a cert
	if(certs.count != 0) {
		return [NSArray arrayWithArray:certs];
	} else {
		return nil;
	}
}

/**
 * Callback from the District Manager™ to indicate that this district is now
 * the selected district.
 *
 * @warning If overridden in a subclass, it must call this method on its 
 * superclass.
 */
- (void) districtWasSelected:(SQUDistrict *) district {
	[[SQUGradeManager sharedInstance] selectDriverWithID:district.driver];
}

/**
 * Indicates whether the district supports fetching of attendance or not.
 *
 * @return Boolean indicating the above.
 */
- (BOOL) districtSupportsAttendance {
	NSLog(@"%s(%i) %s: SQUDistrict method not overridden or no subclass used", __FILE__, __LINE__, __func__);
	return NO;
}

/*
 * Indicates whether the district requires a post-login request or not.
 *
 * @return Boolean indicating the above.
 */
- (BOOL) hasPostLoginRequest {
	NSLog(@"%s(%i) %s: SQUDistrict method not overridden or no subclass used", __FILE__, __LINE__, __func__);
	return NO;
}

/**
 * Calculates the unweighted GPA on a 4.0 scale for the specified courses.
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
					gpa += fmin((semester.average.floatValue - 60.0) / 10.0, 4.0);
				} else {
					gpa += 0.0;
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
 * Calculates the weighted GPA for the specified courses.
 *
 * @param courses An array of SQUCourse objects.
 * @return The weighted GPA as an NSNumber object.
 */
- (NSNumber *) weightedGPAWithCourses:(NSArray *) courses {
	NSLog(@"%s(%i) %s: SQUDistrict method not overridden or no subclass used", __FILE__, __LINE__, __func__);
	return @0;
}

@end
