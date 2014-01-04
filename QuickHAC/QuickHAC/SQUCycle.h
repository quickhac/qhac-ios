//
//  SQUCycle.h
//  QuickHAC
//
//  Created by Tristan Seifert on 1/3/14.
//  See README.MD for licensing and copyright information.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class SQUCategory, SQUCourse;

@interface SQUCycle : NSManagedObject

@property (nonatomic, retain) NSNumber * average;
@property (nonatomic, retain) NSNumber * cycleIndex;
@property (nonatomic, retain) NSNumber * dataAvailableInGradebook;
@property (nonatomic, retain) NSDate * last_updated;
@property (nonatomic, retain) NSNumber * semester;
@property (nonatomic, retain) NSNumber * changedSinceLastFetch;
@property (nonatomic, retain) NSNumber * preChangeGrade;
@property (nonatomic, retain) NSOrderedSet *categories;
@property (nonatomic, retain) SQUCourse *course;
@end

@interface SQUCycle (CoreDataGeneratedAccessors)

- (void)insertObject:(SQUCategory *)value inCategoriesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromCategoriesAtIndex:(NSUInteger)idx;
- (void)insertCategories:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeCategoriesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInCategoriesAtIndex:(NSUInteger)idx withObject:(SQUCategory *)value;
- (void)replaceCategoriesAtIndexes:(NSIndexSet *)indexes withCategories:(NSArray *)values;
- (void)addCategoriesObject:(SQUCategory *)value;
- (void)removeCategoriesObject:(SQUCategory *)value;
- (void)addCategories:(NSOrderedSet *)values;
- (void)removeCategories:(NSOrderedSet *)values;
@end
