//
//  SQUDistrictManager.h
//  QuickHAC
//
//  Created by Tristan Seifert on 12/27/13.
//  See README.MD for licensing and copyright information.
//

#import <Foundation/Foundation.h>
#import "SQUDistrict.h"

#define kSQUDistrictManagerErrorInvalidDisambiguation 1000
#define kSQUDistrictManagerErrorInvalidDataReceived 2000
#define kSQUDistrictManagerErrorNoDataAvailable 3000

typedef void (^ SQUDistrictCallback)(NSError *error, id returnData);

@class AFHTTPRequestOperationManager;

@interface SQUDistrictManager : NSObject {
	NSMutableArray *_loadedDistricts;
	NSMutableArray *_initialisedDistricts;
	
	SQUDistrict *_currentDistrict;
	
	AFHTTPRequestOperationManager *_HTTPManager;
}

@property (nonatomic, readwrite, setter = setCurrentDistrict:) SQUDistrict *currentDistrict;

+ (SQUDistrictManager *) sharedInstance;
- (void) registerDistrict:(Class) district;

- (NSArray *) loadedDistricts;
- (BOOL) selectDistrictWithID:(NSInteger) districtID;
- (SQUDistrict *) districtWithID:(NSInteger) districtID;

// The methods below operate on the _currentDistrict.
- (void) performLoginRequestWithUser:(NSString *) username usingPassword:(NSString *) password andCallback:(SQUDistrictCallback) callback;
- (void) performDisambiguationRequestWithStudentID:(NSString *) sid andCallback:(SQUDistrictCallback) callback;
- (void) performAveragesRequestWithCallback:(SQUDistrictCallback) callback;
- (void) performClassGradesRequestWithCourseCode:(NSString *) course andCycle:(NSUInteger) cycle inSemester:(NSUInteger) semester andCallback:(SQUDistrictCallback) callback;
- (void) checkIfLoggedIn:(SQULoggedInCallback) callback;
- (NSArray *) cyclesWithDataAvailableForCourse:(NSString *) course;

@end
