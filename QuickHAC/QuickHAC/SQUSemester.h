//
//  SQUSemester.h
//  QuickHAC
//
//  Created by Tristan Seifert on 12/28/13.
//  Copyright (c) 2013 Squee! Apps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class SQUCourse;

@interface SQUSemester : NSManagedObject

@property (nonatomic, retain) NSNumber * examGrade;
@property (nonatomic, retain) NSNumber * examIsExempt;
@property (nonatomic, retain) NSNumber * semester;
@property (nonatomic, retain) NSNumber * average;
@property (nonatomic, retain) SQUCourse *course;

@end
