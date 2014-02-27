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
#import "SQUSettingsHueElement.h"
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
	
	section.footer =NSLocalizedString(@"Calculated GPA may not be accurate. We are not responsible for any problems arising from inaccurate calculations.", @"general settings");
	
	[root addSection:section];
	
	// Build "Appearance" section
	section = [[QSection alloc] initWithTitle:NSLocalizedString(@"Grade Colourisation", @"general settings")];
	
	QFloatElement *asianness = [[QFloatElement alloc] initWithTitle:NSLocalizedString(@"Power Level", @"general settings") value:[[NSUserDefaults standardUserDefaults] floatForKey:@"asianness"]];
	__unsafe_unretained QFloatElement *tempAsianness = asianness;
	asianness.minimumValue = 1.0;
	asianness.maximumValue = 12.2;
	asianness.onValueChanged = ^(QRootElement *element) {
		[[NSUserDefaults standardUserDefaults] setFloat:tempAsianness.floatValue forKey:@"asianness"];
	};
	[section addElement:asianness];
	
	SQUSettingsHueElement *hue = [[SQUSettingsHueElement alloc] initWithTitle:NSLocalizedString(@"Hue", @"general settings") value:[[NSUserDefaults standardUserDefaults] floatForKey:@"gradesHue"]];
	__unsafe_unretained SQUSettingsHueElement *tempHue = hue;
	hue.onValueChanged = ^(QRootElement *element) {
		[[NSUserDefaults standardUserDefaults] setFloat:tempHue.floatValue forKey:@"gradesHue"];
	};
	[section addElement:hue];
	
	[root addSection:section];
	
	// Misc section
	section = [[QSection alloc] initWithTitle:NSLocalizedString(@"Miscellaneous", nil)];
	
	QBooleanElement *secureSwitcher = [[QBooleanElement alloc] initWithTitle:NSLocalizedString(@"Connection Validation", @"general settings") BoolValue:[[NSUserDefaults standardUserDefaults] boolForKey:@"certPinning"]];
	__unsafe_unretained QBooleanElement *secureSwitcherTmp = secureSwitcher;
	secureSwitcher.onValueChanged = ^(QRootElement *element) {
		[[NSUserDefaults standardUserDefaults] setBool:secureSwitcherTmp.boolValue
												forKey:@"certPinning"];
	};
	[section addElement:secureSwitcher];
	section.footer = NSLocalizedString(@"If you have difficulty getting grades, try disabling this option.", @"general settings");
	
	[root addSection:section];
	
	self.root = root;
	
	return self;
}

@end
