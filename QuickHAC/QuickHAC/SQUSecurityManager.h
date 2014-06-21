//
//  SQUSecurityManager.h
//  QuickHAC
//
//  Created by Tristan Seifert on 6/21/14.
//  Copyright (c) 2014 Squee! Apps. All rights reserved.
//

#import "LTHPasscodeViewController.h"

#import <Foundation/Foundation.h>

typedef void (^ SQUSecurityCallback)(BOOL unlocked, NSError *error);

typedef NS_ENUM(NSUInteger, SQUSecurityLockType) {
	kSQULockTypeNone,
	kSQULockTypePasscode,
	kSQULockTypeTouchID,
};

@interface SQUSecurityManager : NSObject {
	
}

@property (nonatomic, readonly) BOOL isLocked;
@property (nonatomic, readwrite, setter=setLockType:) SQUSecurityLockType lockType;

+ (instancetype) sharedInstance;

- (void) performUserValidation:(NSString *) passcode withCallback:(SQUSecurityCallback) cb;
- (void) changePasscode:(NSString *) newCode;

- (void) lock;
- (void) unlockWithCallback:(SQUSecurityCallback) cb;

@end
