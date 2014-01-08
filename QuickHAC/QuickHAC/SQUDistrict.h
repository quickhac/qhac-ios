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

/**
 * Required protocol for all district subclasses.
 */
@class SQUDistrict;
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

// Security
- (NSArray *) districtSSLCertData;

// Capability determination
- (BOOL) districtSupportsAttendance;

// GPA caclulaation
- (NSNumber *) unweightedGPAWithCourses:(NSArray *) courses;
- (NSNumber *) weightedGPAWithCourses:(NSArray *) courses;

@optional
- (void) districtWasSelected:(SQUDistrict *) district;

@end

/**
 * Base district object implementing commonly-used methods for districts and
 * base behaviour that usually does not need to change.
 *
 * All methods will cause an error to be logged if not overridden.
 */
@interface SQUDistrict : NSObject <SQUDistrictProtocol> {
@public
	
@protected
	NSString *_driver;
	NSString *_name;
	float _examWeight;
	NSInteger _district_id;
	col_offsets_t _tableOffsets;
	double _gpaOffset;
	NSRange _studentIDLength;
	BOOL _hasMultipleStudents;
	NSMutableArray *_studentsOnAccount;
}

/// Gradebook driver in use by this district.
@property (readonly) NSString *driver;

/// Name of the district
@property (readonly) NSString *name;

/// Weight of an exam towards the semester average.
@property (readonly) float examWeight;

/// Unique numerical identifier for this district.
@property (readonly) NSInteger district_id;

/// Offsets in the gradebook table for certain data.
@property (readonly) col_offsets_t tableOffsets;

/// Offset for GPA.
@property (readonly) double gpaOffset;

/// Length of student ID.
@property (readonly) NSRange studentIDLength;

/// Indicator of if the account has more than one student associated with it.
@property (readonly) BOOL hasMultipleStudents;

/// If hasMultipleStudents is YES, this has some info on all students on the account.
@property (readonly) NSMutableArray *studentsOnAccount;

@end
