//
//  SQUCourse.h
//  QuickHAC
//
//  Created by Tristan Seifert on 1/13/14.
//  See README.MD for licensing and copyright information.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class SQUCycle, SQUSemester, SQUStudent;

@interface SQUCourse : NSManagedObject

@property (nonatomic, retain) NSString * courseCode;
@property (nonatomic, retain) NSNumber * isExcludedFromGPA;
@property (nonatomic, retain) NSNumber * isHonours;
@property (nonatomic, retain) NSNumber * period;
@property (nonatomic, retain) NSString * teacher_email;
@property (nonatomic, retain) NSString * teacher_name;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSOrderedSet *cycles;
@property (nonatomic, retain) NSOrderedSet *semesters;
@property (nonatomic, retain) SQUStudent *student;
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
- (void)insertObject:(SQUSemester *)value inSemestersAtIndex:(NSUInteger)idx;
- (void)removeObjectFromSemestersAtIndex:(NSUInteger)idx;
- (void)insertSemesters:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeSemestersAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInSemestersAtIndex:(NSUInteger)idx withObject:(SQUSemester *)value;
- (void)replaceSemestersAtIndexes:(NSIndexSet *)indexes withSemesters:(NSArray *)values;
- (void)addSemestersObject:(SQUSemester *)value;
- (void)removeSemestersObject:(SQUSemester *)value;
- (void)addSemesters:(NSOrderedSet *)values;
- (void)removeSemesters:(NSOrderedSet *)values;
@end
