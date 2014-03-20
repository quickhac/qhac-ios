//
//  SQUClassDetailHeaderCell.h
//  QuickHAC
//
//  Created by Tristan Seifert on 2/12/14.
//  See README.MD for licensing and copyright information.
//

#import <UIKit/UIKit.h>

#define SQUClassDetailHeaderCellHeight 64

@class SQUCourse;
@interface SQUClassDetailHeaderCell : UITableViewCell {
	CALayer *_backgroundLayer;
	CATextLayer *_average;
	CATextLayer *_courseTitle;
	CATextLayer *_teacher;
	
	__strong SQUCourse *_course;
	__strong SQUCycle *_cycle;
}

@property (nonatomic, readwrite, strong) SQUCycle *cycle;
@property (nonatomic, readwrite, setter = setCourse:) SQUCourse *course;

@end
