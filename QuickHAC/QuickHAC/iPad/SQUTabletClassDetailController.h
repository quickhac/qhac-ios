//
//  SQUTabletClassDetailController.h
//  QuickHAC
//
//  Created by Tristan Seifert on 2/22/14.
//  See README.MD for licensing and copyright information.
//

#import <UIKit/UIKit.h>

@class SQUCourse;
@interface SQUTabletClassDetailController : UITableViewController {
	SQUCourse *_course;
}

@property (nonatomic, readwrite) SQUCourse *course;

@end
