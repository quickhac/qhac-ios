//
//  SQUCategory.h
//  QuickHAC
//
//  Created by Tristan Seifert on 12/27/13.
//  Copyright (c) 2013 Squee! Apps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class SQUAssignment, SQUCycle;

@interface SQUCategory : NSManagedObject

@property (nonatomic, retain) NSNumber * average;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * weight;
@property (nonatomic, retain) SQUCycle *cycle;
@property (nonatomic, retain) NSSet *assignments;
@end

@interface SQUCategory (CoreDataGeneratedAccessors)

- (void)addAssignmentsObject:(SQUAssignment *)value;
- (void)removeAssignmentsObject:(SQUAssignment *)value;
- (void)addAssignments:(NSSet *)values;
- (void)removeAssignments:(NSSet *)values;

@end
