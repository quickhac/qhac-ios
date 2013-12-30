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

@end
