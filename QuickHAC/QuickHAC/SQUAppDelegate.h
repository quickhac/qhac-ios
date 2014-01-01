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
@class MGSplitViewController;
@class SQUTabletSidebarController;

@interface SQUAppDelegate : UIResponder <UIApplicationDelegate, UIAlertViewDelegate, LTHPasscodeViewControllerDelegate> {
    UINavigationController *_navController;
    SQUGradeOverviewController *_rootViewController;
	
	UINavigationController *_sidebarNavController;
	SQUSidebarController *_sidebarController;
	
	PKRevealController *_drawerController;
	
	MGSplitViewController *_ipadSplitController;
	
	SQUTabletSidebarController *_ipadSidebar;
	UINavigationController *_ipadSidebarWrapper;
	UINavigationController *_ipadContentWrapper;
}

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void) saveContext;
- (NSURL *)applicationDocumentsDirectory;

- (NSManagedObjectContext *) managedObjectContext;

+ (SQUAppDelegate *) sharedDelegate;

@end
