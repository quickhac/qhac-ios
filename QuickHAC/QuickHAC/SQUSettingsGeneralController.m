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
		[[NSUserDefaults standardUserDefaults] synchronize];
	};
	
	[section addElement:precision];
	
	QButtonElement *button = [[QButtonElement alloc] initWithTitle:NSLocalizedString(@"Manage Courses…", nil)];
	button.onSelected = ^{
		SQUSettingsGPAOptionsController *controller = [[SQUSettingsGPAOptionsController alloc] init];
		[self.navigationController pushViewController:controller animated:YES];
	};
	[section addElement:button];
	
	section.footer =NSLocalizedString(@"Calculated GPA may not be accurate. We are not responsible for any problems arising from inaccurate calculations.", nil);
	
	[root addSection:section];
	
	self.root = root;
	
	return self;
}

@end
