//
//  SQUSettingsSecurity.m
//  QuickHAC
//
//  Created by Tristan Seifert on 6/21/14.
//  Copyright (c) 2014 Squee! Apps. All rights reserved.
//

#import "LTHPasscodeViewController.h"
#import "SQUSettingsSecurity.h"

#import <QuickDialog.h>

static __strong UINavigationController *rootNav = nil;

@interface SQUSettingsSecurity ()

@end

@implementation SQUSettingsSecurity

- (id) init {
	self = [super initWithRoot:nil];
	__weak SQUSettingsSecurity *self_weak = self;
	
	// Create general settings
	QRootElement *root = [[QRootElement alloc] init];
	root.title = NSLocalizedString(@"General", nil);
	root.grouped = YES;
	
	
	QSection *section;
	
	// Build enable/disable section
	section = [[QSection alloc] initWithTitle:nil];
	
	QBooleanElement *enabled = [[QBooleanElement alloc] initWithTitle:NSLocalizedString(@"Passcode Lock", nil)
															BoolValue:[LTHPasscodeViewController doesPasscodeExist]];
	enabled.onValueChanged = ^(QRootElement *element) {
		// Enable passcode
		if(![LTHPasscodeViewController doesPasscodeExist]) {
			[[LTHPasscodeViewController sharedUser] showForEnablingPasscodeInViewController:self
																					asModal:YES];
		} else { // disable
			[[LTHPasscodeViewController sharedUser] showForDisablingPasscodeInViewController:self
																					 asModal:YES];
		}
	};
	[section addElement:enabled];
	
	_changeButton = [[QButtonElement alloc] initWithTitle:NSLocalizedString(@"Change Passcode…", nil)];
	[_changeButton setEnabled:[LTHPasscodeViewController doesPasscodeExist]];
	_changeButton.onSelected = ^{
		if([LTHPasscodeViewController doesPasscodeExist]) {
			[[LTHPasscodeViewController sharedUser] showForChangingPasscodeInViewController:self_weak
																					asModal:YES];
		}
	};
	[section addElement:_changeButton];
	
	[root addSection:section];
	
	// Passcode complexity
	section = [[QSection alloc] initWithTitle:nil];
	
/*	QBooleanElement *complexPasscode = [[QBooleanElement alloc] initWithTitle:NSLocalizedString(@"Simple Passcode", nil)
																	BoolValue:[[LTHPasscodeViewController sharedUser] isSimple]];
	[complexPasscode setEnabled:[LTHPasscodeViewController doesPasscodeExist]];
	complexPasscode.onValueChanged = ^(QRootElement *element) {
		BOOL simplicity = [[LTHPasscodeViewController sharedUser] isSimple];
		
		[[LTHPasscodeViewController sharedUser] setIsSimple:!simplicity inViewController:self asModal:YES];
	};
	[section addElement:complexPasscode];
	
	[root addSection:section];*/
	
	[LTHPasscodeViewController sharedUser].delegate = (id<LTHPasscodeViewControllerDelegate>) self;
	
	self.root = root;
	return self;
}

#pragma mark - Security Validationmajig
/**
 * Called when the passcode view controller is about to be closed. This pops a
 * new one of us to rebuild the UI.
 */
- (void) passcodeViewControllerWillClose {
	NSLog(@"closieren");
	
	rootNav = self.navigationController;
	[self.navigationController popViewControllerAnimated:NO];
	
	dispatch_async(dispatch_get_main_queue(), ^{
		SQUSettingsSecurity *setting = [[SQUSettingsSecurity alloc] init];
		[rootNav pushViewController:setting animated:NO];
	});
}

@end
