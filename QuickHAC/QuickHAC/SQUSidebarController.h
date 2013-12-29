//
//  SQUSidebarController.h
//  QuickHAC
//
//  Created by Tristan Seifert on 12/27/13.
//  Copyright (c) 2013 Squee! Apps. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SQUCourse;
@class SQUGradeOverviewController;

@interface SQUSidebarController : UITableViewController {
	NSIndexPath *selectedItem;
	
	SQUGradeOverviewController *_overview;
}

@property (nonatomic, readwrite, strong) SQUGradeOverviewController *overviewController;

- (void) showCourseOverviewForCourse:(SQUCourse *) course;

@end
