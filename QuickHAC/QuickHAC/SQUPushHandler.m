//
//  SQUPushHandler.m
//  QuickHAC
//
//	This class handles essentially everything relating to push notifications,
//	including communication with the server-side API to actually perform the
//	required registration.
//
//  Created by Tristan Seifert on 1/4/14.
//  See README.MD for licensing and copyright information.
//

#import "SQUPushHandler.h"

#import "NSData+SQUAdditions.h"

#import "AFNetworking.h"
#import "Lockbox.h"

// Static variables
static SQUPushHandler *_sharedInstance = nil;

#pragma mark Private methods
@interface SQUPushHandler (PrivateMethods)
- (NSString *) createUUIDToString;
- (NSUUID *) uuidFromKeychain;
@end

// Actual class implementation
#pragma mark - Singleton
@implementation SQUPushHandler
+ (SQUPushHandler *) sharedInstance {
    @synchronized (self) {
        if (_sharedInstance == nil) {
            _sharedInstance = [[self alloc] init];
        }
    }
    
    return _sharedInstance;
}

+ (id) allocWithZone:(NSZone *) zone {
    @synchronized(self) {
        if (_sharedInstance == nil) {
            _sharedInstance = [super allocWithZone:zone];
            return _sharedInstance;
        }
    }
    
    return nil;
}

- (id) copyWithZone:(NSZone *) zone {
    return self;
}

- (id) init {
    @synchronized(self) {
        if(self = [super init]) {
			_deviceUUID = [self uuidFromKeychain];
			
			// Set up the HTTP manager
			_HTTPManager = [AFHTTPRequestOperationManager manager];
			_HTTPManager.responseSerializer = [AFJSONResponseSerializer serializer];
        }
		
        return self;
    }
}

#pragma mark - UUID management
/**
 * Generates a UUID string.
 */
- (NSString *) createUUIDToString {
	NSUUID *uuid = [NSUUID UUID];
	return [uuid UUIDString];
}

/**
 * Attempts to read the device's generated UUID from the keychain, converting it
 * to a NSUUID.
 */
- (NSUUID *) uuidFromKeychain {
	NSString *uuidString = [Lockbox stringForKey:@"device_uuid"];
	
	// If there's no UUID in the keychain, generate it.
	if(!uuidString || uuidString.length < 8) {
		uuidString = [self createUUIDToString];
		[Lockbox setString:uuidString forKey:@"device_uuid"];
	}
	
	NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:uuidString];
	return uuid;
}

#pragma mark - Miscallenous push
/**
 * Initialises various components relating to push notifications.
 */
- (void) initialisePush {
	
}

#pragma mark - Push API requests
/**
 * Registers the device with the push servers.
 *
 * @param token Device's push notification token
 */
- (void) registerWithPushToken:(NSData *) token {
	NSString *hexString = [token toHexString];
	// hexString = @"302696248015a91d0be31cf1d557d8908b366a0c8eecd7acb7c096d8c46760fb";
	
	[_HTTPManager POST:[kSQUPushEndpoint stringByAppendingString:@"register"] parameters:@{@"uuid":_deviceUUID.UUIDString, @"token":hexString} success:^(AFHTTPRequestOperation *operation, id responseObject) {
		NSDictionary *serverResponse = (NSDictionary *) responseObject;
		NSLog(@"Server response: %@", serverResponse);
		
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		NSLog(@"Push reg error: %@", error);
	}];
}

@end