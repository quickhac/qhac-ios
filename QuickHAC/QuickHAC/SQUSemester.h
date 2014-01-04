//
//  SQUSemester.h
//  QuickHAC
//
//  Created by Tristan Seifert on 1/3/14.
//  See README.MD for licensing and copyright information.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class SQUCourse;

@interface SQUSemester : NSManagedObject

@property (nonatomic, retain) NSNumber * average;
@property (nonatomic, retain) NSNumber * examGrade;
@property (nonatomic, retain) NSNumber * examIsExempt;
@property (nonatomic, retain) NSNumber * semester;
@property (nonatomic, retain) NSNumber * changedSinceLastFetch;
@property (nonatomic, retain) NSNumber * preChangeGrade;
@property (nonatomic, retain) SQUCourse *course;

@end
