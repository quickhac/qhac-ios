//
//  SQUClassDetailHeaderCell.h
//  QuickHAC
//
//  Created by Tristan Seifert on 2/12/14.
//  Copyright (c) 2014 Squee! Apps. All rights reserved.
//

#import <UIKit/UIKit.h>

#define SQUClassDetailHeaderCellHeight 64

@class SQUCourse;
@interface SQUClassDetailHeaderCell : UITableViewCell {
	CALayer *_backgroundLayer;
	CATextLayer *_average;
	CATextLayer *_courseTitle;
	CATextLayer *_teacher;
	
	SQUCourse *_course;
	SQUCycle *_cycle;
}

@property (nonatomic, readwrite) SQUCycle *cycle;
@property (nonatomic, readwrite, setter = setCourse:) SQUCourse *course;

@end
