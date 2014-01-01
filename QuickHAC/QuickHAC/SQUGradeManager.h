//
//  SQUGradeManager.h
//  QuickHAC
//
//  Created by Tristan Seifert on 12/27/13.
//  See README.MD for licensing and copyright information.
//

#import <Foundation/Foundation.h>

#define SQUGradesDataUpdatedNotification @"SQUGradesDataUpdatedNotification"
#define SQUStudentsUpdatedNotification @"SQUStudentsUpdatedNotification"

typedef enum {
	kSQUGPATypeUnweighted = 0, // 4.0 scale (regular)
	kSQUGPATypeWeighted = 1 // 5.0/6.0 scale, depending on district (default)
} SQUGPAType;

@class SQUStudent;
@interface SQUGradeManager : NSObject {
	SQUStudent *_student;
	
	NSManagedObjectContext *_coreDataMOContext;
}

@property (nonatomic, readwrite, strong) SQUStudent *student;
@property (nonatomic, readonly, getter = getCoursesForCurrentStudent) NSOrderedSet *courses;

+ (SQUGradeManager *) sharedInstance;

- (NSOrderedSet *) getCoursesForCurrentStudent;

- (void) fetchNewClassGradesFromServerWithDoneCallback:(void (^)(NSError *)) callback;
- (void) updateCurrentStudentWithClassAverages:(NSArray *) classAvgs;

- (void) fetchNewCycleGradesFromServerForCourse:(NSString *) course withCycle:(NSUInteger) cycle andSemester:(NSUInteger) semester andDoneCallback:(void (^)(NSError *)) callback;
- (void) updateCurrentStudentWithClassGrades:(NSDictionary *) classGrades forClass:(NSString *) class andCycle:(NSUInteger) numCycle andSemester:(NSUInteger) numSemester;

- (NSNumber *) calculateGPAType:(SQUGPAType) type forCourses:(NSArray *) courses;

@end
