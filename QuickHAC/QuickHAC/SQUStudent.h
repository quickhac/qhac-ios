//
//  SQUStudent.h
//  QuickHAC
//
//  Created by Tristan Seifert on 12/27/13.
//  Copyright (c) 2013 Squee! Apps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class SQUCourse;

@interface SQUStudent : NSManagedObject

@property (nonatomic, retain) NSNumber * district;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * student_id;
@property (nonatomic, retain) NSString * hacUsername;
@property (nonatomic, retain) NSSet *courses;
@end

@interface SQUStudent (CoreDataGeneratedAccessors)

- (void)addCoursesObject:(SQUCourse *)value;
- (void)removeCoursesObject:(SQUCourse *)value;
- (void)addCourses:(NSSet *)values;
- (void)removeCourses:(NSSet *)values;

@end
