//
//  SQUAppDelegate.m
//  QuickHAC
//
//  Created by Tristan Seifert on 05/07/2013.
//  See README.MD for licensing and copyright information.
//

#import "SQUSidebarController.h"
#import "SQUAppDelegate.h"
#import "SQULoginSchoolSelector.h"
#import "SQUGradeOverviewController.h"
#import "SQUDistrictManager.h"
#import "SQUStudent.h"
#import "SQUGradeManager.h"
#import "NSManagedObjectModel+KCOrderedAccessorFix.h"

#import "PKRevealController.h"
#import "AFNetworkActivityIndicatorManager.h"
#import "SVProgressHUD.h"
#import "Lockbox.h"

@implementation SQUAppDelegate

static SQUAppDelegate *sharedDelegate = nil;

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (BOOL) application:(UIApplication *) application didFinishLaunchingWithOptions:(NSDictionary *) launchOptions {
    // Used for the entire singleton thing
    sharedDelegate = self;
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
   
	// Set up grade overview
    _rootViewController = [[SQUGradeOverviewController alloc] initWithStyle:UITableViewStylePlain];
    _navController = [[UINavigationController alloc] initWithRootViewController:_rootViewController];
    
	// Set up sidebar menu
	_sidebarController = [[SQUSidebarController alloc] initWithStyle:UITableViewStylePlain];
	_sidebarNavController = [[UINavigationController alloc] initWithRootViewController:_sidebarController];
	
	// Set up drawer
	_drawerController = [PKRevealController revealControllerWithFrontViewController:_navController
																 leftViewController:_sidebarNavController
																rightViewController:nil];
    _drawerController.animationDuration = 0.25;
	
    // Set up UIWindow
    self.window.rootViewController = _drawerController;
    self.window.backgroundColor = [UIColor darkGrayColor];
    [self.window makeKeyAndVisible];
	
	// Set up automagical network indicator management
	[[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
	
	// Check for students in the database
    NSManagedObjectContext *context = [self managedObjectContext];
    NSError *db_err = nil;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"SQUStudent" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    NSArray *students = [context executeFetchRequest:fetchRequest error:&db_err];
    
    // If there is at least one student object, we're logged in.
    if(students.count == 0) {
        SQULoginSchoolSelector *loginController = [[SQULoginSchoolSelector alloc] initWithStyle:UITableViewStyleGrouped];
        [_navController presentViewController:[[UINavigationController alloc] initWithRootViewController:loginController] animated:NO completion:NULL];
    } else {
		// Select first student
        SQUStudent *student = students[0];
        
        // Fetch username/pw from keychain
        NSString *username, *password, *studentID;
        
		username = student.hacUsername;
        password = [Lockbox stringForKey:username];
		studentID = student.student_id;
        
		[[SQUGradeManager sharedInstance] setStudent:student];
		[[NSNotificationCenter defaultCenter] postNotificationName:SQUGradesDataUpdatedNotification object:nil];
		
		// Validate the student object.
		dispatch_async(dispatch_get_main_queue(), ^{
			if(![[SQUDistrictManager sharedInstance] selectDistrictWithID:student.district.integerValue]) {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Invalid District", nil) message:NSLocalizedString(@"The student record selected is not using a district supported by qHAC.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
				[alert show];
				
				// Delete from the database
				[context deleteObject:student];
				
				// Pop up the login controller.
				SQULoginSchoolSelector *loginController = [[SQULoginSchoolSelector alloc] initWithStyle:UITableViewStyleGrouped];
				[_navController presentViewController:[[UINavigationController alloc] initWithRootViewController:loginController] animated:NO completion:NULL];
			} else { // We found a district, so log in so we may update grades
				// Ask the current district instance to do a log in to validate we're still valid
				[[SQUDistrictManager sharedInstance] performLoginRequestWithUser:username usingPassword:password andCallback:^(NSError *error, id returnData){
					if(!error) {
						if(!returnData) {
							[SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Wrong Credentials", nil)];
							
							// Tell the user what happened
							UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error Authenticating", nil) message:NSLocalizedString(@"Your username or password were rejected by HAC. Please update your password, if it was changed, and try again.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:NSLocalizedString(@"Settings", nil), nil];
							alert.tag = kSQUAlertChangePassword;
							[alert show];
						} else {
							// Login succeeded, so we can do a fetch of grades.
							[[SQUGradeManager sharedInstance] fetchNewClassGradesFromServerWithDoneCallback:NULL];
						}
					} else {
						[SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Error", nil)];
						
						UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error Authenticating", nil) message:error.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
						[alert show];
					}
				}];
			}
		});
    }
    
    // Put other initialisation here so this function can return faster (UI can display)
    dispatch_async(dispatch_get_main_queue(), ^{
		NSLog(@"Fetches: %@", [[NSUserDefaults standardUserDefaults] arrayForKey:@"fetchList"]);
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
    [self saveContext];
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {
	NSMutableArray *array = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] arrayForKey:@"fetchList"]];
	[array addObject:[NSDate new]];
	[[NSUserDefaults standardUserDefaults] setObject:array forKey:@"fetchList"];
	
	// Send notification of update
	UILocalNotification *notification = [[UILocalNotification alloc]  init];
    notification.fireDate = [NSDate dateWithTimeIntervalSinceNow:10];
    notification.timeZone = [NSTimeZone localTimeZone];
    notification.alertBody = @"QHAC Update";
    notification.soundName = UILocalNotificationDefaultSoundName;
    notification.applicationIconBadgeNumber = [[NSUserDefaults standardUserDefaults] integerForKey:@"fetches"]+1;
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];

	// Update counter
	[[NSUserDefaults standardUserDefaults] setInteger:[[NSUserDefaults standardUserDefaults] integerForKey:@"fetches"]+1 forKey:@"fetches"];
	[[NSUserDefaults standardUserDefaults] synchronize];

	completionHandler(UIBackgroundFetchResultNewData);
}

#pragma mark - CoreData Stack
- (void) saveContext {
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
             // Replace this implementation with code to handle the error appropriately.
             // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
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

@end
