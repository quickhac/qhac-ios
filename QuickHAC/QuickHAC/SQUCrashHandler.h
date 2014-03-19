//
//  SQUCrashHandler.h
//  QuickHAC
//
//  Created by Tristan Seifert on 3/18/14.
//  Copyright (c) 2014 Squee! Apps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MessageUI/MessageUI.h>

#define CRASH_HANDLER_URL @"https://api.quickhac.com/ios/crash_report"

@class PLCrashReporter;

@interface SQUCrashHandler : NSObject <UIAlertViewDelegate, MFMailComposeViewControllerDelegate> {
	UIViewController *_rootView;
}

+ (instancetype) sharedInstance;

- (BOOL) installCrashHandlerWithRootView:(UIViewController *) rootView;

@end
