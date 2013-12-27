//
//  SQUCourse.h
//  QuickHAC
//
//  Created by Tristan Seifert on 12/27/13.
//  Copyright (c) 2013 Squee! Apps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class SQUCycle, SQUStudent;

@interface SQUCourse : NSManagedObject

@property (nonatomic, retain) NSNumber * period;
@property (nonatomic, retain) NSString * teacher_email;
@property (nonatomic, retain) NSString * teacher_string;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * isHonours;
@property (nonatomic, retain) NSNumber * isExcludedFromGPA;
@property (nonatomic, retain) NSSet *cycles;
@property (nonatomic, retain) SQUStudent *student;
@end

@interface SQUCourse (CoreDataGeneratedAccessors)

- (void)addCyclesObject:(SQUCycle *)value;
- (void)removeCyclesObject:(SQUCycle *)value;
- (void)addCycles:(NSSet *)values;
- (void)removeCycles:(NSSet *)values;

@end
