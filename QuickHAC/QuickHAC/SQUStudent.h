//
//  SQUStudent.h
//  QuickHAC
//
//  Created by Tristan Seifert on 10/09/2013.
//  See README.MD for licensing and copyright information.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class SQUClassInfo;

@interface SQUStudent : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * district;
@property (nonatomic, retain) NSString * student_id;
@property (nonatomic, retain) NSOrderedSet *classes;
@end

@interface SQUStudent (CoreDataGeneratedAccessors)

- (void)insertObject:(SQUClassInfo *)value inClassesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromClassesAtIndex:(NSUInteger)idx;
- (void)insertClasses:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeClassesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInClassesAtIndex:(NSUInteger)idx withObject:(SQUClassInfo *)value;
- (void)replaceClassesAtIndexes:(NSIndexSet *)indexes withClasses:(NSArray *)values;
- (void)addClassesObject:(SQUClassInfo *)value;
- (void)removeClassesObject:(SQUClassInfo *)value;
- (void)addClasses:(NSOrderedSet *)values;
- (void)removeClasses:(NSOrderedSet *)values;
@end
