//
//  SQUCycle.h
//  QuickHAC
//
//  Created by Tristan Seifert on 12/28/13.
//  Copyright (c) 2013 Squee! Apps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class SQUCategory, SQUCourse;

@interface SQUCycle : NSManagedObject

@property (nonatomic, retain) NSNumber * average;
@property (nonatomic, retain) NSNumber * cycleIndex;
@property (nonatomic, retain) NSDate * last_updated;
@property (nonatomic, retain) NSNumber * semester;
@property (nonatomic, retain) NSSet *categories;
@property (nonatomic, retain) SQUCourse *course;
@end

@interface SQUCycle (CoreDataGeneratedAccessors)

- (void)addCategoriesObject:(SQUCategory *)value;
- (void)removeCategoriesObject:(SQUCategory *)value;
- (void)addCategories:(NSSet *)values;
- (void)removeCategories:(NSSet *)values;

@end
