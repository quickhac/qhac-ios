//
//  SQUCrashHandler.m
//  QuickHAC
//
//  Created by Tristan Seifert on 3/18/14.
//  Copyright (c) 2014 Squee! Apps. All rights reserved.
//

#import "SQUAppDelegate.h"
#import "SQUCrashHandler.h"

#import "PLCrashReporter.h"
#import "PLCrashReport.h"
#import "PLCrashReportTextFormatter.h"

#import "AFNetworking.h"

static SQUCrashHandler *_sharedInstance = nil;

@implementation SQUCrashHandler

/*
 * Returns the shared crash handler.
 */
+ (instancetype) sharedInstance {
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

#pragma mark - Crash handling
- (void) handleCrashReport {
	PLCrashReporter *crashReporter = [PLCrashReporter sharedReporter];
	NSData *crashData;
	NSError *error;

	// Try loading the crash report
	crashData = [crashReporter loadPendingCrashReportDataAndReturnError: &error];
	if (crashData == nil) {
		NSLog(@"Could not load crash report: %@", error);
		[crashReporter purgePendingCrashReport];
		return;
	}
	
	// Ask the user what to do
	UIAlertView *alert = [[UIAlertView alloc]
						  initWithTitle:NSLocalizedString(@"Crash Reporting", @"crash reporter")
						  message:NSLocalizedString(@"We’re sorry about the inconvenience, but QuickHAC crashed the last time you used it. Would you like to submit a crash report to help us solve the cause of the crash?", @"crash reporter")
						  delegate:self
						  cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
						  otherButtonTitles:NSLocalizedString(@"Submit", nil), nil];
	[alert show];
}


/*
 * Installs the global crash handler, and returns whether there is a pending
 * crash report.
 */
- (BOOL) installCrashHandlerWithRootView:(UIViewController *) rootView {
	_rootView = rootView;
	
	PLCrashReporter *crashReporter = [PLCrashReporter sharedReporter];
	NSError *error;
	BOOL state = NO;

	// Check if we previously crashed
	if ([crashReporter hasPendingCrashReport]) {
		[self handleCrashReport];
		state = YES;
	}

	// Enable the Crash Reporter
	if (![crashReporter enableCrashReporterAndReturnError: &error]) {
		NSLog(@"Warning: Could not enable crash reporter: %@", error);
	} else {
		NSLog(@"Crash reporter installed.");
	}

	return state;
}

/*
 * Called in response to our alert asking if the user wants to submit a crash
 * report.
 */
- (void) alertView:(UIAlertView *) alertView clickedButtonAtIndex:(NSInteger) buttonIndex {
	if(buttonIndex == 1) {
		NSLog("Submit report");
	} else {
		return;
	}
	
	// Drop down here to submit the report
	PLCrashReporter *crashReporter = [PLCrashReporter sharedReporter];
	NSData *crashData;
	NSError *error;
	
	// Read report
	crashData = [crashReporter loadPendingCrashReportDataAndReturnError:&error];
	
	if(error) {
		NSLog("Couldn't get crash report: %@", error);
		return;
	}
	
	// Parse report
	PLCrashReport *report = [[PLCrashReport alloc] initWithData:crashData error:&error];
	if (report == nil) {
		NSLog(@"Could not parse crash report: %@", error);
		return;
	}
	
	// Get app versioning info
	NSString *appVersion = [[[NSBundle mainBundle] infoDictionary]
							objectForKey:@"CFBundleShortVersionString"];
	NSString *appBuild = [[[NSBundle mainBundle] infoDictionary]
							objectForKey:@"CFBundleVersion"];
	
	// Convert report to string
	NSString *reportStr = [PLCrashReportTextFormatter
						   stringValueForCrashReport:report
						   withTextFormat:PLCrashReportTextFormatiOS];

	// Build request data
	NSDictionary *postData = @{@"appVersion": appVersion,
							   @"build": appBuild,
							   @"report": reportStr,
							   @"hi": @"deadbeef"};
	
	AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
	manager.responseSerializer = [AFHTTPResponseSerializer serializer];
	manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/plain"];
	
	[manager POST:CRASH_HANDLER_URL parameters:postData success:^(AFHTTPRequestOperation *operation, id responseObject) {
		PLCrashReporter *crashReporter = [PLCrashReporter sharedReporter];
		[crashReporter purgePendingCrashReport];
		
		[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Crash Reporting", nil)
									message:NSLocalizedString(@"Thank you for submitting a crash report. Your help is much appreciated in improving QuickHAC.", nil)
								   delegate:nil
						  cancelButtonTitle:NSLocalizedString(@"Dismiss", nil)
						  otherButtonTitles:nil] show];
		
		
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		NSLog(@"Error: %@", error);
	}];
}

@end
