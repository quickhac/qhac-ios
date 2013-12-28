//
//  SQUCourse.h
//  QuickHAC
//
//  Created by Tristan Seifert on 12/28/13.
//  Copyright (c) 2013 Squee! Apps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class SQUCycle, SQUExam, SQUStudent;

@interface SQUCourse : NSManagedObject

@property (nonatomic, retain) NSString * courseCode;
@property (nonatomic, retain) NSNumber * isExcludedFromGPA;
@property (nonatomic, retain) NSNumber * isHonours;
@property (nonatomic, retain) NSNumber * period;
@property (nonatomic, retain) NSString * teacher_email;
@property (nonatomic, retain) NSString * teacher_name;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSOrderedSet *cycles;
@property (nonatomic, retain) SQUStudent *student;
@property (nonatomic, retain) NSOrderedSet *exams;
@end

@interface SQUCourse (CoreDataGeneratedAccessors)

- (void)insertObject:(SQUCycle *)value inCyclesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromCyclesAtIndex:(NSUInteger)idx;
- (void)insertCycles:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeCyclesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInCyclesAtIndex:(NSUInteger)idx withObject:(SQUCycle *)value;
- (void)replaceCyclesAtIndexes:(NSIndexSet *)indexes withCycles:(NSArray *)values;
- (void)addCyclesObject:(SQUCycle *)value;
- (void)removeCyclesObject:(SQUCycle *)value;
- (void)addCycles:(NSOrderedSet *)values;
- (void)removeCycles:(NSOrderedSet *)values;
- (void)insertObject:(SQUExam *)value inExamsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromExamsAtIndex:(NSUInteger)idx;
- (void)insertExams:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeExamsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInExamsAtIndex:(NSUInteger)idx withObject:(SQUExam *)value;
- (void)replaceExamsAtIndexes:(NSIndexSet *)indexes withExams:(NSArray *)values;
- (void)addExamsObject:(SQUExam *)value;
- (void)removeExamsObject:(SQUExam *)value;
- (void)addExams:(NSOrderedSet *)values;
- (void)removeExams:(NSOrderedSet *)values;
@end
