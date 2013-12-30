//
//  SQUDistrict.m
//  QuickHAC
//
//  Created by Tristan Seifert on 12/27/13.
//  See README.MD for licensing and copyright information.
//

#import "SQUDistrict.h"

@implementation SQUDistrict
@synthesize name = _name, driver = _driver, examWeight = _examWeight, tableOffsets = _tableOffsets, district_id = _district_id, studentIDLength = _studentIDLength;
/*
 * Builds a request to run directly before the login to, for example, fetch some
 * parameters from the form that are needed for the login process to complete
 * successfully. (Yes, ASP.NET, we're looking at you…)
 */
- (NSDictionary *) buildPreLoginRequestWithUserData:(id) userData {
	NSLog(@"%s(%i) %s: SQUDistrict method not overridden or no subclass used", __FILE__, __LINE__, __func__);
	return nil;
}

/*
 * This method would build a login request for the username and password given,
 * possibly using the user data, depending on district.
 */
- (NSDictionary *) buildLoginRequestWithUser:(NSString *) username usingPassword:(NSString *) password andUserData:(id) userData {
	NSLog(@"%s(%i) %s: SQUDistrict method not overridden or no subclass used", __FILE__, __LINE__, __func__);
	return nil;
}

/*
 * Build a request to disambiguate the student ID specified.
 */
- (NSDictionary *) buildDisambiguationRequestWithStudentID:(NSString *) sid andUserData:(id) userData {
	NSLog(@"%s(%i) %s: SQUDistrict method not overridden or no subclass used", __FILE__, __LINE__, __func__);
	return nil;
}

/*
 * Build a request to fetch the class averages for the currently logged-in
 * student ID.
 */
- (NSDictionary *) buildAveragesRequestWithUserData:(id) userData {
	NSLog(@"%s(%i) %s: SQUDistrict method not overridden or no subclass used", __FILE__, __LINE__, __func__);
	return nil;
}

/*
 * Builds a request to fetch the class grades for the specified course and
 * cycle.
 */
- (NSDictionary *) buildClassGradesRequestWithCourseCode:(NSString *) course andSemester:(NSUInteger) semester andCycle:(NSUInteger) cycle andUserData:(id) userData {
	NSLog(@"%s(%i) %s: SQUDistrict method not overridden or no subclass used", __FILE__, __LINE__, __func__);
	return nil;
}

/*
 * This method is called whenever the overall averages for all classes is 
 * updated, so the district code can perform internal housekeeping, like keeping
 * track of the URLs for specifc class grades information.
 */
- (void) updateDistrictStateWithClassGrades:(NSArray *) grade {
	NSLog(@"%s(%i) %s: SQUDistrict method not overridden or no subclass used", __FILE__, __LINE__, __func__);
}

/*
 * Called on completion of the pre-login request, if it is required, with the
 * data returned by the request.
 */
- (void) updateDistrictStateWithPreLoginData:(NSData *) data {
	NSLog(@"%s(%i) %s: SQUDistrict method not overridden or no subclass used", __FILE__, __LINE__, __func__);
}

/*
 * Called after the completion of the actual login request with the data that
 * the web server returned.
 */
- (void) updateDistrictStateWithPostLoginData:(NSData *) data {
	NSLog(@"%s(%i) %s: SQUDistrict method not overridden or no subclass used", __FILE__, __LINE__, __func__);
}

/*
 * Called with the data returned by the login request to validate if the login
 * was a success.
 */
- (BOOL) didLoginSucceedWithLoginData:(NSData *) data {
	NSLog(@"%s(%i) %s: SQUDistrict method not overridden or no subclass used", __FILE__, __LINE__, __func__);
	return NO;
}

/*
 * Called with the data returned by the disambiguation request to evaluate if
 * the correct student was disambiguated.
 */
- (BOOL) didDisambiguationSucceedWithLoginData:(NSData *) data {
	NSLog(@"%s(%i) %s: SQUDistrict method not overridden or no subclass used", __FILE__, __LINE__, __func__);
	return NO;
}

/*
 * Called to get the current login status.
 */
- (void) isLoggedInWithCallback:(SQULoggedInCallback) callback {
	NSLog(@"%s(%i) %s: SQUDistrict method not overridden or no subclass used", __FILE__, __LINE__, __func__);
}

/*
 * Returns an array of cycles that have data available for a specific course.
 */
- (NSArray *) cyclesWithDataForCourse:(NSString *) courseCode {
	NSLog(@"%s(%i) %s: SQUDistrict method not overridden or no subclass used", __FILE__, __LINE__, __func__);
	return nil;
}

@end
