//
//  SQUAppDelegate.m
//  QuickHAC
//
//  Created by Tristan Seifert on 05/07/2013.
//  See README.MD for licensing and copyright information.
//

#import "SQUAppDelegate.h"
#import "SQULoginSchoolSelector.h"
#import "SQUGradeOverviewController.h"
#import "SQUGradeParser.h"

#import "SQUStudent.h"

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
   
    _rootViewController = [[SQUGradeOverviewController alloc] initWithStyle:UITableViewStylePlain];
    
    _navController = [[UINavigationController alloc] initWithRootViewController:_rootViewController];
    
    // Set up UIWindow
    self.window.rootViewController = _navController;
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    [application setMinimumBackgroundFetchInterval:SQUMinimumFetchInterval];
    
	NSLog(@"%@", [SQUGradeParser sharedInstance]);
	
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
        SQUStudent *student = students[0];
        
        // Fetch username/pw from keychain
        NSString *username, *password;
        
        username = [Lockbox stringForKey:@"accountEmail"];
        password = [Lockbox stringForKey:@"accountPassword"];
        
#ifdef DEBUG
        NSLog(@"User: %@\nPass: %@\nSID: %@", username, password, student.student_id);
#endif
		
        [[SQUHACInterface sharedInstance] performLoginWithUser:username andPassword:password andSID:student.student_id callback:^(NSError *error, id returnData){
            if(!error) {
                NSString *sessionID = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
                
                [SVProgressHUD showProgress:-1 status:NSLocalizedString(@"Checking Session…", nil) maskType:SVProgressHUDMaskTypeGradient];
                
                // Try to get URL of grades from session key
                [[SQUHACInterface sharedInstance] getGradesURLWithBlob:sessionID callback:^(NSError *err, id data) {
                    if(data) {
						NSString *gradesURL = (NSString *) data;
						
                        [Lockbox setString:sessionID forKey:@"sessionKey"];
                        
                        [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"Logged In", nil)];
						
						// Update grades
						[[SQUHACInterface sharedInstance] parseAveragesWithURL:gradesURL callback:^(NSError *error, id returnData) {
							NSLog(@"Grades: %@", (NSDictionary *) returnData);
						}];
                    } else {
                        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Wrong Credentials", nil)];
                    }
                    
                }];
            } else {
#ifdef DEBUG
                NSLog(@"Auth error: %@", error);
#endif
                [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Error", nil)];
                
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error Authenticating", nil) message:error.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
                [alert show];
            }
        }];
    }
    
    // Put other initialisation here so this function can return faster (UI can display)
    dispatch_async(dispatch_get_main_queue(), ^{
    });
    
	NSLog(@"Fetches: %@", [[NSUserDefaults standardUserDefaults] arrayForKey:@"fetchList"]);
	
    return YES;
}

#pragma mark - Application delegate
- (void) applicationWillResignActive:(UIApplication *) application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void) applicationDidBecomeActive:(UIApplication *) application {
	NSLog(@"Application became active");
}

- (void) applicationWillTerminate:(UIApplication *) application {
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {
	NSMutableArray *array = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] arrayForKey:@"fetchList"]];
	[array addObject:[NSDate new]];
	[[NSUserDefaults standardUserDefaults] setObject:array forKey:@"fetchList"];
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

@end
