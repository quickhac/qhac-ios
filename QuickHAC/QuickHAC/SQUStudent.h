//
//  SQUStudent.h
//  QuickHAC
//
//  Created by Tristan Seifert on 1/11/14.
//  See README.MD for licensing and copyright information.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class SQUCourse;

@interface SQUStudent : NSManagedObject

@property (nonatomic, retain) NSNumber * cyclesPerSemester;
@property (nonatomic, retain) NSNumber * district;
@property (nonatomic, retain) NSString * hacUsername;
@property (nonatomic, retain) NSDate * lastAveragesUpdate;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * numSemesters;
@property (nonatomic, retain) NSString * school;
@property (nonatomic, retain) NSString * student_id;
@property (nonatomic, retain) NSString * avatar_path;
@property (nonatomic, retain) NSString * display_name;
@property (nonatomic, retain) NSOrderedSet *courses;
@end

@interface SQUStudent (CoreDataGeneratedAccessors)

- (void)insertObject:(SQUCourse *)value inCoursesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromCoursesAtIndex:(NSUInteger)idx;
- (void)insertCourses:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeCoursesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInCoursesAtIndex:(NSUInteger)idx withObject:(SQUCourse *)value;
- (void)replaceCoursesAtIndexes:(NSIndexSet *)indexes withCourses:(NSArray *)values;
- (void)addCoursesObject:(SQUCourse *)value;
- (void)removeCoursesObject:(SQUCourse *)value;
- (void)addCourses:(NSOrderedSet *)values;
- (void)removeCourses:(NSOrderedSet *)values;
@end
