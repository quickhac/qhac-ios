//
//  SQUExam.h
//  QuickHAC
//
//  Created by Tristan Seifert on 12/28/13.
//  Copyright (c) 2013 Squee! Apps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class SQUCourse;

@interface SQUExam : NSManagedObject

@property (nonatomic, retain) NSNumber * grade;
@property (nonatomic, retain) NSNumber * isExempt;
@property (nonatomic, retain) NSNumber * semester;
@property (nonatomic, retain) SQUCourse *course;

@end
