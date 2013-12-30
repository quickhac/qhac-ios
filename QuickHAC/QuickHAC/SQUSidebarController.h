//
//  SQUSidebarController.h
//  QuickHAC
//
//  Created by Tristan Seifert on 12/27/13.
//  See README.MD for licensing and copyright information.
//

#import <UIKit/UIKit.h>

@class SQUCourse;
@class SQUGradeOverviewController;
@class SQUSettingsViewController;

@interface SQUSidebarController : UITableViewController {
	NSIndexPath *selectedItem;
	
	SQUGradeOverviewController *_overview;
	SQUSettingsViewController *_settings;
}

@property (nonatomic, readwrite, strong) SQUGradeOverviewController *overviewController;

- (void) showCourseOverviewForCourse:(SQUCourse *) course;

@end
