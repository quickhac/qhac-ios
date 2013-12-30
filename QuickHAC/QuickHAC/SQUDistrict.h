//
//  SQUDistrict.h
//  QuickHAC
//
//  Created by Tristan Seifert on 12/27/13.
//  See README.MD for licensing and copyright information.
//

#import <Foundation/Foundation.h>

typedef void (^ SQULoggedInCallback)(BOOL isLoggedIn);

typedef struct {
	NSUInteger semesters;
	NSUInteger cyclesPerSemester;
} semester_params_t;

typedef struct {
	NSUInteger title;
	NSUInteger grades;
	NSUInteger period;
} col_offsets_t;

/*
 * Required protocol for all district subclasses.
 */
@protocol SQUDistrictProtocol <NSObject>

@required
// request builders
- (NSDictionary *) buildPreLoginRequestWithUserData:(id) userData;
- (NSDictionary *) buildLoginRequestWithUser:(NSString *) username usingPassword:(NSString *) password andUserData:(id) userData;
- (NSDictionary *) buildDisambiguationRequestWithStudentID:(NSString *) sid andUserData:(id) userData;
- (NSDictionary *) buildAveragesRequestWithUserData:(id) userData;
- (NSDictionary *) buildClassGradesRequestWithCourseCode:(NSString *) course andSemester:(NSUInteger) semester andCycle:(NSUInteger) cycle andUserData:(id) userData;

// callbacks
- (void) updateDistrictStateWithClassGrades:(NSArray *) grades;
- (void) updateDistrictStateWithPreLoginData:(NSData *) data;
- (void) updateDistrictStateWithPostLoginData:(NSData *) data;

// Validation
- (BOOL) didLoginSucceedWithLoginData:(NSData *) data;
- (BOOL) didDisambiguationSucceedWithLoginData:(NSData *) data;

// Network requests/etc
- (void) isLoggedInWithCallback:(SQULoggedInCallback) callback;

// Cycle validation
- (NSArray *) cyclesWithDataForCourse:(NSString *) courseCode;

@end

/*
 * Base district object implementing commonly-used methods for districts and
 * base behaviour that usually does not need to change.
 */
@interface SQUDistrict : NSObject <SQUDistrictProtocol> {
@public
	
@protected
	NSString *_driver;
	NSString *_name;
	float _examWeight;
	NSInteger _district_id;
	col_offsets_t _tableOffsets;
}

@property (readonly) NSString *driver;
@property (readonly) NSString *name;
@property (readonly) float examWeight;
@property (readonly) NSInteger district_id;
@property (readonly) col_offsets_t tableOffsets;

@end
