//
//  SQUAppDelegate.m
//  QuickHAC
//
//  Created by Tristan Seifert on 05/07/2013.
//  See README.MD for licensing and copyright information.
//

#import "SQUSidebarController.h"
#import "SQULoginSchoolSelector.h"
#import "SQUGradeOverviewController.h"
#import "SQUDistrictManager.h"
#import "SQUCoreData.h"
#import "SQUGradeManager.h"
#import "SQUTabletSidebarController.h"
#import "SQUTabletLoginController.h"
#import "SQUUIHelpers.h"
#import "SQUPushHandler.h"
#import "SQUColourScheme.h"
#import "SQUCrashHandler.h"
#import "SQUAppDelegate.h"

#import "PKRevealController.h"
#import "AFNetworkActivityIndicatorManager.h"
#import "NSManagedObjectModel+KCOrderedAccessorFix.h"
#import "SVProgressHUD.h"
#import "Lockbox.h"
#import "SQUSplitViewController.h"
#import "WYPopoverController.h"
#import "LTHPasscodeViewController.h"
#import "AFNetworking.h"

#ifdef DEBUG
#import "TestFlight.h"
#endif

@implementation SQUAppDelegate

static SQUAppDelegate *sharedDelegate = nil;

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (BOOL) application:(UIApplication *) application didFinishLaunchingWithOptions:(NSDictionary *) launchOptions {
	// TestFlight
#ifdef DEBUG
	[TestFlight takeOff:@"66bad5ef-ff19-45c7-8e02-038658335dfd"];
#endif
	
	// Initialise preferences defaults
	NSURL *defaultPreferencesURL = [[NSBundle mainBundle] URLForResource:@"settings_defaults" withExtension:@"plist"];
	NSDictionary *defaultPreferences = [NSDictionary dictionaryWithContentsOfURL:defaultPreferencesURL];
	NSAssert(defaultPreferences, @"Default preferences could not be loaded from URL %@", defaultPreferencesURL);
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultPreferences];
	
	// See if the user updated the app
	NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
	NSString *lastVersion = [[NSUserDefaults standardUserDefaults] stringForKey:@"lastAppVersion"];
	
	if(lastVersion) {
		if([lastVersion isEqualToString:appVersion]) {
			// not updated since last launch
		} else {
			NSLog(@"User updated from %@ to %@", lastVersion, appVersion);
			[[NSUserDefaults standardUserDefaults] setObject:appVersion forKey:@"lastAppVersion"];
			[[NSUserDefaults standardUserDefaults] synchronize];
		}
	} else {
		NSLog(@"User is running %@ for first time", appVersion);
		
		[[NSUserDefaults standardUserDefaults] setObject:appVersion forKey:@"lastAppVersion"];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
	
    // Used for the entire singleton thing
    sharedDelegate = self;
    
    _window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
   
	if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
		// Set up grade overview
		_rootViewController = [[SQUGradeOverviewController alloc] initWithStyle:UITableViewStylePlain];
		_navController = [[UINavigationController alloc] initWithRootViewController:_rootViewController];
		
		// Set up sidebar menu
		_sidebarController = [[SQUSidebarController alloc] init];
		_sidebarNavController = [[UINavigationController alloc] initWithRootViewController:_sidebarController];
		
		_sidebarController.overviewController = _rootViewController;
		
		// Set up drawer
		_drawerController = [PKRevealController revealControllerWithFrontViewController:_navController
																	 leftViewController:_sidebarNavController
																	rightViewController:nil];
		_drawerController.animationDuration = 0.25;
		
		// Set up UIWindow
		_window.rootViewController = _drawerController;
		
		// UI control theming
		[[UINavigationBar appearance] setTintColor:UIColorFromRGB(kSQUColourTitle)];
		[[UINavigationBar appearance] setBarTintColor:UIColorFromRGB(kSQUColourNavbarBG)];
		[[UINavigationBar appearance] setBackgroundColor:UIColorFromRGB(kSQUColourNavbarBG)];
		[[UINavigationBar appearance] setTitleTextAttributes:@{
															   NSForegroundColorAttributeName: UIColorFromRGB(kSQUColourTitle),
															   NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Medium" size:0.0],
															   }];
		[[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"navbar_bg"] forBarMetrics:UIBarMetricsDefault];
		
		// Light status bar
		[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
		
		// Popover
		
		WYPopoverBackgroundView* popoverAppearance = [WYPopoverBackgroundView appearance];
		[popoverAppearance setFillTopColor:UIColorFromRGB(kSQUColourNavbarBG)];
		[popoverAppearance setFillBottomColor:UIColorFromRGB(kSQUColourNavbarBG)];
	} else {
		// Set up iPad UI
		_ipadSidebar = [[SQUTabletSidebarController alloc] initWithStyle:UITableViewStyleGrouped];
		_ipadSidebarWrapper = [[UINavigationController alloc] initWithRootViewController:_ipadSidebar];
		
		// Initialise split view
		_ipadSplitController = [[SQUSplitViewController alloc] init];
		_ipadSplitController.delegate = self;
		_ipadSplitController.presentsWithGesture = YES;
		_ipadSplitController.viewControllers = @[_ipadSidebarWrapper, [[UINavigationController alloc] init]];
		
		_window.rootViewController = _ipadSplitController;
		
		// Set up iPad appearances
		[[UINavigationBar appearance] setTintColor:UIColorFromRGB(kSQUColourTitle)];
		[[UINavigationBar appearance] setBarTintColor:UIColorFromRGB(kSQUColourNavbarBG)];
		[[UINavigationBar appearance] setBackgroundColor:UIColorFromRGB(kSQUColourNavbarBG)];
		[[UINavigationBar appearance] setTitleTextAttributes:@{
															   NSForegroundColorAttributeName: UIColorFromRGB(kSQUColourTitle),
															   NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Medium" size:0.0],
															   }];
		[[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"navbar_bg"] forBarMetrics:UIBarMetricsDefault];
	}
	
    _window.backgroundColor = UIColorFromRGB(0xECF0F1);
	[_window makeKeyAndVisible];
	
	// Install crash handler
	BOOL pendingCrashReport = [[SQUCrashHandler sharedInstance]
							   installCrashHandlerWithRootView:_rootViewController];
	
	// TODO: Check if user enabled push
	if(false) {
		[[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeBadge|
		 UIRemoteNotificationTypeSound|
		 UIRemoteNotificationTypeAlert];
		[[SQUPushHandler sharedInstance] initialisePush];
	}
	
	// Set up automagical network indicator management
	[[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
	
	// Check for students in the database
    NSManagedObjectContext *context = [self managedObjectContext];
    NSError *db_err = nil;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"SQUStudent" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    NSArray *students = [context executeFetchRequest:fetchRequest error:&db_err];
    
    // If there is at least one student object, we're logged in.
    if(students.count == 0) {
		if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
			SQULoginSchoolSelector *loginController = [[SQULoginSchoolSelector alloc] initWithStyle:UITableViewStyleGrouped];
			[_navController presentViewController:[[UINavigationController alloc] initWithRootViewController:loginController] animated:NO completion:NULL];
		} else {
			// iPad login UI
			SQUTabletLoginController *loginController = [[SQUTabletLoginController alloc] init];
			[_ipadSplitController presentViewController:[[UINavigationController alloc] initWithRootViewController:loginController] animated:NO completion:NULL];
		}
    } else {
		// Show the passcode lock, if passcode is enabled
/*		if([[NSUserDefaults standardUserDefaults] boolForKey:@"passcodeEnabled"]) {
			[[LTHPasscodeViewController sharedUser] setDelegate:self];
			[[LTHPasscodeViewController sharedUser] showLockScreenWithAnimation:YES];
		}*/
		
		NSUInteger selectedStudent = [students indexOfObject:[[SQUGradeManager sharedInstance] getSelectedStudent]];
		
		// Ensure that the index is in bounds
		if(selectedStudent > students.count) {
			selectedStudent = 0;
			[[SQUGradeManager sharedInstance] changeSelectedStudent:students[selectedStudent]];
		} else {
			[[SQUGradeManager sharedInstance] changeSelectedStudent:students[selectedStudent]];
		}
		
        SQUStudent *student = students[selectedStudent];
        
        // Fetch username/pw from keychain
        NSString *username, *password, *studentID;
        
		username = student.hacUsername;
        password = [Lockbox stringForKey:username];
		studentID = student.student_id;
        
		// This ensures we can see cached data while the new data is fetched
		if(![[SQUDistrictManager sharedInstance] selectDistrictWithID:student.district.integerValue]) {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Invalid District", nil) message:NSLocalizedString(@"The student record selected is not using a district supported by qHAC.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
			[alert show];
			
			// Delete from the database
			[context deleteObject:student];
			
			// Pop up the login controller.
			SQULoginSchoolSelector *loginController = [[SQULoginSchoolSelector alloc] initWithStyle:UITableViewStyleGrouped];
			[_navController presentViewController:[[UINavigationController alloc] initWithRootViewController:loginController] animated:NO completion:NULL];
		} else {
			[[SQUGradeManager sharedInstance] setStudent:student];
			[[SQUDistrictManager sharedInstance] selectDistrictWithID:student.district.integerValue];
			[[NSNotificationCenter defaultCenter] postNotificationName:SQUGradesDataUpdatedNotification object:nil];
		}
		
		// Update data if there's no pending crash report
		if(!pendingCrashReport) {
			// Ask the current district instance to do a log in to validate our session is still valid
			[[SQUDistrictManager sharedInstance] performLoginRequestWithUser:username usingPassword:password andCallback:^(NSError *error, id returnData) {
				if(!error) {
					if(!returnData) {
						[SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Wrong Credentials", nil)];
						
						// Tell the user what happened
						UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error Authenticating", nil) message:NSLocalizedString(@"Your username or password were rejected by HAC. Please update your password, if it was changed, and try again.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:/*NSLocalizedString(@"Settings", nil),*/ nil];
						alert.tag = kSQUAlertChangePassword;
						[alert show];
					} else {
						// Login succeeded, so we can do a fetch of grades.
						[[SQUGradeManager sharedInstance] fetchNewClassGradesFromServerWithDoneCallback:^(NSError *err) {
							[[NSNotificationCenter defaultCenter] postNotificationName:SQUGradesDataUpdatedNotification object:nil];
						}];
					}
				} else {
					[SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Error", nil)];
					
					UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error Authenticating", nil) message:error.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
					[alert show];
				}
			}];
		} else {
			// Just show cached data.
			NSLog(@"Have crash report, showing cached data");
			[[NSNotificationCenter defaultCenter] postNotificationName:SQUGradesDataUpdatedNotification object:nil];
		}
    }
	
    return YES;
}

#pragma mark - Application delegate
- (void) applicationWillResignActive:(UIApplication *) application {

}

- (void) applicationDidBecomeActive:(UIApplication *) application {
	
}

- (void) applicationWillTerminate:(UIApplication *) application {
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

#pragma mark - Push Notifications
- (void) application:(UIApplication *) application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *) deviceToken {
	[[SQUPushHandler sharedInstance] registerWithPushToken:deviceToken];
}

- (void) application:(UIApplication *) application didFailToRegisterForRemoteNotificationsWithError:(NSError *) error {
	NSLog(@"Registration error: %@", error);
}

// {"key":"302696248015a91d0be31cf1d557d8908b366a0c8eecd7acb7c096d8c46760fb","apns_content_available":1,"custom":"i,112840"}

#pragma mark - CoreData Stack
- (void) saveContext {
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
	
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
             // Replace this implementation with code to handle the error appropriately.
             // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
            NSLog(@"Unresolved CoreData error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *) managedObjectContext {
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *) managedObjectModel {
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"QuickHAC" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
	
	/*
	 * This is needed to fix the one-to-many relationships which are broken in
	 * CoreData. (see rdar://10114310)
	 */
	[_managedObjectModel kc_generateOrderedSetAccessors];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *) persistentStoreCoordinator {
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"QuickHAC.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:@{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES} error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
#ifdef DEBUG
        [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Database Error" message:[NSString stringWithFormat:@"The database was erased due to an error loading it.\n%@", error.description] delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
        [alert show];
		
		// Re-create the database.
		[_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:@{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES} error:&error];
#else
        NSLog(@"Unresolved database error: %@, %@", error, [error userInfo]);
        abort();
#endif
    }
    
    return _persistentStoreCoordinator;
}

#pragma mark - Helper Methods
// Returns the URL to the application's Documents directory.
- (NSURL *) applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

+ (SQUAppDelegate *) sharedDelegate {
    return sharedDelegate;
}

#pragma mark - Alert view callbacks
- (void) alertView:(UIAlertView *) alertView clickedButtonAtIndex:(NSInteger) buttonIndex {
	switch(alertView.tag) {
		case kSQUAlertChangePassword:
			NSLog(@"Change password alert");
			break;
			
		default:
			break;
	}
}

#pragma mark - Passcode lock
- (void) maxNumberOfFailedAttemptsReached {
	NSLog(@"Maximum passcode attempts reached.");
	exit(-1);
}

- (void) splitViewController:(UISplitViewController*) svc willHideViewController:(UIViewController *) aViewController withBarButtonItem:(UIBarButtonItem *) barButtonItem forPopoverController:(UIPopoverController*) pc {
	barButtonItem.title = NSLocalizedString(@"Sidebar", nil);
	UINavigationController *nav = svc.viewControllers[1];
	nav.topViewController.navigationItem.leftBarButtonItem = barButtonItem;
}

- (void) splitViewController:(UISplitViewController *) svc willShowViewController:(UIViewController *) aViewController invalidatingBarButtonItem:(UIBarButtonItem *) barButtonItem {
	UINavigationController *nav = svc.viewControllers[1];
	nav.topViewController.navigationItem.leftBarButtonItem = nil;
}

@end
