//
//  SQUAppDelegate.h
//  QuickHAC
//
//  Created by Tristan Seifert on 05/07/2013.
//  Copyright (c) 2013 Squee! Apps. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SQUGradeOverviewController;

@interface SQUAppDelegate : UIResponder <UIApplicationDelegate> {
    UINavigationController *_navController;
    SQUGradeOverviewController *_rootViewController;
}

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

- (NSManagedObjectContext *) managedObjectContext;

+ (SQUAppDelegate *) sharedDelegate;

@end
