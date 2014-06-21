//
//  SQUSettingsGPAOptionsController.m
//  QuickHAC
//
//  Created by Tristan Seifert on 12/31/13.
//  See README.MD for licensing and copyright information.
//

#import "SQUPersistence.h"
#import "SQUCoreData.h"
#import "SQUGradeManager.h"
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
			tempCourse.isHonours = @(tempToggle.boolValue);
			_shouldSaveDB = YES;
			// [[SQUPersistence sharedInstance] saveContext];
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
			_shouldSaveDB = YES;
			// [[SQUPersistence sharedInstance] saveContext];
		};
		
		[section addElement:toggle];
	}
	
	section.footer = NSLocalizedString(@"These courses will not be counted towards weighted GPA.", nil);
	
	[root addSection:section];
	self.root = root;
	
	_shouldSaveDB = NO;
	
	return self;
}

// When the view disappears, we should try to save the DB
- (void) viewWillDisappear:(BOOL) animated {
	// Only save if needed
	if(!_shouldSaveDB) return;
	
	// Save to DB
	NSError *err = nil;
	if(![[SQUPersistence sharedInstance].managedObjectContext save:&err]) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Database Error", nil) message:err.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
		[alert show];
	} else {
		_shouldSaveDB = NO;
	}
}

@end
