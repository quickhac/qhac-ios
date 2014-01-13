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
@class SQUSidebarSwitcherButton;
@class SQUUserSwitcherView;

#define SQUSidebarControllerShowSidebarMessage @"SQUSidebarControllerShowSidebarMessage"
#define SQUSidebarControllerShowOverview @"SQUSidebarControllerShowOverview"
#define SQUSidebarControllerToggleUserSwitcher @"SQUSidebarControllerToggleUserSwitcher"

@interface SQUSidebarController : UIViewController <UITableViewDataSource, UITableViewDelegate> {
	NSIndexPath *selectedItem;
	
	SQUGradeOverviewController *_overview;
	NSIndexPath *_lastSelection;
	
	UIView *_topView;
	SQUSidebarSwitcherButton *_switcherButton;
	UIButton *_settingsButton;
	UITableView *_tableView;
	SQUUserSwitcherView *_switcher;
}

@property (nonatomic, readwrite, strong) SQUGradeOverviewController *overviewController;

- (void) showCourseOverviewForCourse:(SQUCourse *) course;

@end
