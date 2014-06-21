//
//  SQUAppDelegate.h
//  QuickHAC
//
//  Created by Tristan Seifert on 05/07/2013.
//  See README.MD for licensing and copyright information.
//

#import <UIKit/UIKit.h>
#import "PKRevealController.h"
#import "LTHPasscodeViewController.h"

#define kSQUAlertChangePassword 1

@class SQUGradeOverviewController;
@class SQUSidebarController;
@class SQUTabletSidebarController;
@class SQUSplitViewController;

@interface SQUAppDelegate : UIResponder <UIApplicationDelegate, UIAlertViewDelegate, LTHPasscodeViewControllerDelegate, UISplitViewControllerDelegate> {
    UINavigationController *_navController;
    SQUGradeOverviewController *_rootViewController;
	
	UINavigationController *_sidebarNavController;
	SQUSidebarController *_sidebarController;
	
	PKRevealController *_drawerController;
	
	SQUSplitViewController *_ipadSplitController;
	
	SQUTabletSidebarController *_ipadSidebar;
	UINavigationController *_ipadSidebarWrapper;
	UINavigationController *_ipadContentWrapper;
}

@property (strong, nonatomic) UIWindow *window;

+ (SQUAppDelegate *) sharedDelegate;

@end
