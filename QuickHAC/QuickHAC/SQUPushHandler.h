//
//  SQUPushHandler.h
//  QuickHAC
//
//  Created by Tristan Seifert on 1/4/14.
//  See README.MD for licensing and copyright information.
//

#import <Foundation/Foundation.h>

#define kSQUPushEndpoint @"https://api.quickhac.com/ios/"

@class AFHTTPRequestOperationManager;
@interface SQUPushHandler : NSObject {
	AFHTTPRequestOperationManager *_HTTPManager;
	NSUUID *_deviceUUID;
}

+ (SQUPushHandler *) sharedInstance;

- (void) initialisePush;
- (void) registerWithPushToken:(NSData *) token;

@end
