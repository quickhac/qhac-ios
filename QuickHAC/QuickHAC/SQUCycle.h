//
//  SQUCycle.h
//  QuickHAC
//
//  Created by Tristan Seifert on 12/27/13.
//  Copyright (c) 2013 Squee! Apps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface SQUCycle : NSManagedObject

@property (nonatomic, retain) NSNumber * average;
@property (nonatomic, retain) NSNumber * index;
@property (nonatomic, retain) NSDate * last_updated;
@property (nonatomic, retain) NSSet *categories;
@property (nonatomic, retain) NSManagedObject *course;
@end

@interface SQUCycle (CoreDataGeneratedAccessors)

- (void)addCategoriesObject:(NSManagedObject *)value;
- (void)removeCategoriesObject:(NSManagedObject *)value;
- (void)addCategories:(NSSet *)values;
- (void)removeCategories:(NSSet *)values;

@end
