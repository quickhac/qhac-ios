//
//  SQUSecurityManager.m
//  QuickHAC
//
//  Created by Tristan Seifert on 6/21/14.
//  Copyright (c) 2014 Squee! Apps. All rights reserved.
//

#import "Lockbox.h"

#import "SQUSecurityManager.h"

@interface SQUSecurityManager ()

- (void) showPasscodeEntry;

@end

static SQUSecurityManager *sharedInstance = nil;

@implementation SQUSecurityManager
@synthesize isLocked = _isLocked, lockType = _lockType;

/**
 * Initialises the security manager by loading data from storage.
 */
- (id) init {
	if(self = [super init]) {
		
	}
	
	return self;
}

/**
 * Return the shared security manager.
 */
+ (instancetype) sharedInstance {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstance = [[SQUSecurityManager alloc] init];
	});
	
	return sharedInstance;
}

#pragma mark - Querying of state
/**
 * Allows changing the mechanism the security manager uses to authenticate an
 * user.
 *
 * @param type Lock mechanism to use.
 */
- (void) setLockType:(SQUSecurityLockType) type {
	
}

#pragma mark - Validation and state change
/**
 * Attempt to validate the user is really who they say they are. This can either
 * verify a passcode stored in the keychain, or perform Touch ID authentication
 * on supported devices.
 *
 * @param passcode A user-supplied passcode
 * @param cb A callback to run once validation has completed.
 */
- (void) performUserValidation:(NSString *) passcode withCallback:(SQUSecurityCallback) cb {
	
}

/**
 * Change the passcode stored in the keychain to something else.
 *
 * @param newCode New passcode.
 */
- (void) changePasscode:(NSString *) newCode {
	
}

#pragma mark - Locking/Unlocking
/**
 * Locks the security manager.
 */
- (void) lock {
	_isLocked = YES;
}

/**
 * Attempt to unlock the security manager.
 *
 * @param cb Callback to run after verifying the user. This will signal the
 * status of the unlock.
 */
- (void) unlockWithCallback:(SQUSecurityCallback) cb {
	switch (_lockType) {
		case kSQULockTypeNone:
			cb(YES, nil);
			break;
			
		default:
			NSAssert(false, @"Invalid lock type %u", _lockType);
			break;
	}
}

#pragma mark - Interface
/**
 * Opens up the passcode entry view controller modally.
 */
- (void) showPasscodeEntry {
	
}

@end
