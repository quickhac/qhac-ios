//
//  SQUPersistence.h
//  QuickHAC
//
//  Created by Tristan Seifert on 6/21/14.
//  See README.MD for licensing and copyright information.
//

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

@interface SQUPersistence : NSObject {
	
}

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

+ (instancetype) sharedInstance;

- (void) saveContext;
- (NSURL *)applicationDocumentsDirectory;
- (NSManagedObjectContext *) managedObjectContext;

@end
