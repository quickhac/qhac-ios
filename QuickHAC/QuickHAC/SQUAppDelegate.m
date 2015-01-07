//
//  SQUAppDelegate.m
//  QuickHAC
//
//  Created by Tristan Seifert on 05/07/2013.
//  See README.MD for licensing and copyright information.
//

#import "SQUPersistence.h"
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

#import "LTHPasscodeViewController.h"
#import "PKRevealController.h"
#import "AFNetworkActivityIndicatorManager.h"
#import <KVNProgress.h>
#import "Lockbox.h"
#import "SQUSplitViewController.h"
#import "WYPopoverController.h"
#import "LTHPasscodeViewController.h"
#import "AFNetworking.h"

#ifdef DEBUG
#import "TestFlight.h"
#endif

@interface SQUAppDelegate ()

- (void) setUpUI;

@end

@implementation SQUAppDelegate

static SQUAppDelegate *sharedDelegate = nil;

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
		
		// clear passcode when re-installing the app
		[LTHPasscodeViewController deletePasscode];
	}
	
    // Used for the entire singleton thing
    sharedDelegate = self;

    _window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
   
	[self setUpUI];
	
    _window.backgroundColor = UIColorFromRGB(0xECF0F1);
	[_window makeKeyAndVisible];
	
	[LTHPasscodeViewController sharedUser].maxNumberOfAllowedFailedAttempts = 10;
	
	// passcode lock
	if([LTHPasscodeViewController doesPasscodeExist]) {
		[[LTHPasscodeViewController sharedUser] showLockScreenWithAnimation:NO
																 withLogout:NO
															 andLogoutTitle:nil];
	}
	
	// Install crash handler
	__block BOOL pendingCrashReport = [[SQUCrashHandler sharedInstance]
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
	
	dispatch_async(dispatch_get_main_queue(), ^{
		// Check for students in the database
		NSManagedObjectContext *context = [[SQUPersistence sharedInstance] managedObjectContext];
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
			NSString *username, *password/*, *studentID*/;
			
			username = student.hacUsername;
			password = [Lockbox stringForKey:username];
			//studentID = student.student_id;
			
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
			
			// Ensure current user isn't corrupted
			if(!username || !password) {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Invalid Data", nil) message:NSLocalizedString(@"The current user contains invalid data, and therefore cached data is being shown. Please re-install QuickHAC.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
				[alert show];
				
				pendingCrashReport = YES;
			}
			
			// Update data if there's no pending crash report
			if(!pendingCrashReport) {
				// Ask the current district instance to do a log in to validate our session is still valid
				[[SQUDistrictManager sharedInstance] performLoginRequestWithUser:username usingPassword:password andCallback:^(NSError *error, id returnData) {
					if(!error) {
						if(!returnData) {
							[KVNProgress showErrorWithStatus:NSLocalizedString(@"Wrong Credentials", nil)];
							
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
						[KVNProgress showErrorWithStatus:NSLocalizedString(@"Error", nil)];
						
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
	});
	
    return YES;
}

#pragma mark - Application delegate
- (void) applicationWillResignActive:(UIApplication *) application {

}

- (void) applicationDidBecomeActive:(UIApplication *) application {
	
}

- (void) applicationWillTerminate:(UIApplication *) application {
    // Saves changes in the application's managed object context before the application terminates.
    [[SQUPersistence sharedInstance] saveContext];
}

#pragma mark - Push Notifications
- (void) application:(UIApplication *) application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *) deviceToken {
	[[SQUPushHandler sharedInstance] registerWithPushToken:deviceToken];
}

- (void) application:(UIApplication *) application didFailToRegisterForRemoteNotificationsWithError:(NSError *) error {
	NSLog(@"Registration error: %@", error);
}

// {"key":"302696248015a91d0be31cf1d557d8908b366a0c8eecd7acb7c096d8c46760fb","apns_content_available":1,"custom":"i,112840"}

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

#pragma mark - UI
/**
 * Creates the controllers for the user interface.
 */
- (void) setUpUI {
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
	
	// configure the KVNProgress appearance
	KVNProgressConfiguration *configuration = [[KVNProgressConfiguration alloc] init];
	
	configuration.successColor = UIColorFromRGB(kSQUColourEmerald);
	configuration.errorColor = UIColorFromRGB(kSQUColourAlizarin);
	configuration.fullScreen = YES;
	
	[KVNProgress setConfiguration:configuration];
}

@end
