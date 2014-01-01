//
//  SQUSettingsGeneralController.m
//  QuickHAC
//
//  Created by Tristan Seifert on 12/31/13.
//  See README.MD for licensing and copyright information.
//

#import "SQUGradeManager.h"
#import "SQUCoreData.h"
#import "SQUSettingsGPAOptionsController.h"

#import "SQUSettingsGeneralController.h"

#import <QuickDialog.h>

@interface SQUSettingsGeneralController ()

@end

@implementation SQUSettingsGeneralController

- (id) init {
	self = [super initWithRoot:nil];
	
	// Create general settings
	QRootElement *root = [[QRootElement alloc] init];
	root.title = NSLocalizedString(@"General", nil);
	root.grouped = YES;
	
	
	QSection *section;
	
	// Build "GPA Options" section
	section = [[QSection alloc] initWithTitle:NSLocalizedString(@"GPA", nil)];
	
	__block QDecimalElement *precision = [[QDecimalElement alloc] initWithTitle:NSLocalizedString(@"GPA Precision", nil) value:@([[NSUserDefaults standardUserDefaults] integerForKey:@"gpa_precision"])];
	
	__unsafe_unretained QDecimalElement *tempPrecision = precision;
	precision.onValueChanged = ^(QRootElement *root) {
		[[NSUserDefaults standardUserDefaults] setInteger:tempPrecision.numberValue.integerValue forKey:@"gpa_precision"];
	};
	
	[section addElement:precision];
	
	__block QBooleanElement *weighted = [[QBooleanElement alloc] initWithTitle:NSLocalizedString(@"Weighted", nil) BoolValue:[[NSUserDefaults standardUserDefaults] boolForKey:@"gpa_weighted"]];
	
	__unsafe_unretained QBooleanElement *tempWeighted = weighted;
	weighted.onValueChanged = ^(QRootElement *root) {
		[[NSUserDefaults standardUserDefaults] setBool:tempWeighted.boolValue forKey:@"gpa_weighted"];
	};
	
	[section addElement:weighted];
	
	QButtonElement *button = [[QButtonElement alloc] initWithTitle:NSLocalizedString(@"Manage Courses…", nil)];
	button.onSelected = ^{
		SQUSettingsGPAOptionsController *controller = [[SQUSettingsGPAOptionsController alloc] init];
		[self.navigationController pushViewController:controller animated:YES];
	};
	[section addElement:button];
	
	[root addSection:section];
	
	self.root = root;
	
	return self;
}

@end
