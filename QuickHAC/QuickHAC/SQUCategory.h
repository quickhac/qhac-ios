//
//  SQUCategory.h
//  QuickHAC
//
//  Created by Tristan Seifert on 12/29/13.
//  Copyright (c) 2013 Squee! Apps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class SQUAssignment, SQUCycle;

@interface SQUCategory : NSManagedObject

@property (nonatomic, retain) NSNumber * average;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * weight;
@property (nonatomic, retain) NSNumber * is100PtsBased;
@property (nonatomic, retain) NSOrderedSet *assignments;
@property (nonatomic, retain) SQUCycle *cycle;
@end

@interface SQUCategory (CoreDataGeneratedAccessors)

- (void)insertObject:(SQUAssignment *)value inAssignmentsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromAssignmentsAtIndex:(NSUInteger)idx;
- (void)insertAssignments:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeAssignmentsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInAssignmentsAtIndex:(NSUInteger)idx withObject:(SQUAssignment *)value;
- (void)replaceAssignmentsAtIndexes:(NSIndexSet *)indexes withAssignments:(NSArray *)values;
- (void)addAssignmentsObject:(SQUAssignment *)value;
- (void)removeAssignmentsObject:(SQUAssignment *)value;
- (void)addAssignments:(NSOrderedSet *)values;
- (void)removeAssignments:(NSOrderedSet *)values;
@end
