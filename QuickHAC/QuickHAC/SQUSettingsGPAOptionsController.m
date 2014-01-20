//
//  SQUSettingsGPAOptionsController.m
//  QuickHAC
//
//  Created by Tristan Seifert on 12/31/13.
//  See README.MD for licensing and copyright information.
//

#import "SQUCoreData.h"
#import "SQUGradeManager.h"
#import "SQUAppDelegate.h"
#import "SQUSettingsGPAOptionsController.h"

#import <QuickDialog.h>

@interface SQUSettingsGPAOptionsController ()

@end

@implementation SQUSettingsGPAOptionsController

- (id) init {
	self = [super initWithRoot:nil];
	
	QRootElement *root = [[QRootElement alloc] init];
	root.title = NSLocalizedString(@"GPA Settings", nil);
	root.grouped = YES;
	
	QSection *section;
	QBooleanElement *toggle;
	
	// Build Honours Courses list
	section = [[QSection alloc] initWithTitle:NSLocalizedString(@"Honours Courses", nil)];
	
	for(SQUCourse *course in [SQUGradeManager sharedInstance].student.courses) {
		toggle = [[QBooleanElement alloc] initWithTitle:course.title BoolValue:course.isHonours.boolValue];
		
		__unsafe_unretained QBooleanElement *tempToggle = toggle;
		__unsafe_unretained SQUCourse *tempCourse = course;
		
		toggle.onValueChanged = ^(QRootElement *root) {
			tempCourse.isExcludedFromGPA = @(tempToggle.boolValue);
			[[SQUAppDelegate sharedDelegate] saveContext];
		};
		
		[section addElement:toggle];
	}
	
	[root addSection:section];
	
	// Build Excluded Courses list
	section = [[QSection alloc] initWithTitle:NSLocalizedString(@"Excluded Courses", nil)];
	
	for(SQUCourse *course in [SQUGradeManager sharedInstance].student.courses) {
		toggle = [[QBooleanElement alloc] initWithTitle:course.title BoolValue:course.isExcludedFromGPA.boolValue];
		
		__unsafe_unretained QBooleanElement *tempToggle = toggle;
		__unsafe_unretained SQUCourse *tempCourse = course;
		
		toggle.onValueChanged = ^(QRootElement *root) {
			tempCourse.isExcludedFromGPA = @(tempToggle.boolValue);
			[[SQUAppDelegate sharedDelegate] saveContext];
		};
		
		[section addElement:toggle];
	}
	
	[root addSection:section];
	self.root = root;
	
	return self;
}

@end
