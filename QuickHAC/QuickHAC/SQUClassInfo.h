//
//  SQUClassInfo.h
//  QuickHAC
//
//  Created by Tristan Seifert on 10/09/2013.
//  See README.MD for licensing and copyright information.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class SQUGradeCategory;

@interface SQUClassInfo : NSManagedObject

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * currentGrade;
@property (nonatomic, retain) NSNumber * period;
@property (nonatomic, retain) NSString * teacher;
@property (nonatomic, retain) NSOrderedSet *categories;
@end

@interface SQUClassInfo (CoreDataGeneratedAccessors)

- (void)insertObject:(SQUGradeCategory *)value inCategoriesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromCategoriesAtIndex:(NSUInteger)idx;
- (void)insertCategories:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeCategoriesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInCategoriesAtIndex:(NSUInteger)idx withObject:(SQUGradeCategory *)value;
- (void)replaceCategoriesAtIndexes:(NSIndexSet *)indexes withCategories:(NSArray *)values;
- (void)addCategoriesObject:(SQUGradeCategory *)value;
- (void)removeCategoriesObject:(SQUGradeCategory *)value;
- (void)addCategories:(NSOrderedSet *)values;
- (void)removeCategories:(NSOrderedSet *)values;
@end
