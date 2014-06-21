//
//  SQUSettingsStudents.m
//  QuickHAC
//
//  Created by Tristan Seifert on 12/30/13.
//  See README.MD for licensing and copyright information.
//

#import "SQUPersistence.h"
#import "SQUGradeManager.h"
#import "SQUDistrict.h"
#import "SQUDistrictManager.h"
#import "SQUCoreData.h"
#import "SQULoginSchoolSelector.h"
#import "SQUSettingsStudents.h"

#import "PKRevealController.h"
#import "SVProgressHUD.h"
#import "Lockbox.h"

@interface SQUSettingsStudents ()

@end

@implementation SQUSettingsStudents

- (id)initWithStyle:(UITableViewStyle) style {
    self = [super initWithStyle:style];
    if (self) {
        [self.tableView registerClass:NSClassFromString(@"UITableViewCell") forCellReuseIdentifier:@"SettingsButtonCell"];
		
		// Fetch students objects from DB
		NSManagedObjectContext *context = [[SQUPersistence sharedInstance] managedObjectContext];
		NSError *db_err = nil;
		
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"SQUStudent" inManagedObjectContext:context];
		[fetchRequest setEntity:entity];
		_students = [NSMutableArray arrayWithArray:[context executeFetchRequest:fetchRequest error:&db_err]];
		
		if(db_err) {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Database Error", nil) message:db_err.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
			[alert show];
			return nil;
		}
		
		// Display edit button regardless
		if(true) {
			self.navigationItem.rightBarButtonItem = self.editButtonItem;
		}
		
		self.title = NSLocalizedString(@"Students", nil);
		
		// Register notification for when a student is added
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(studentsUpdated:) name:SQUStudentsUpdatedNotification object:nil];
    }
	
    return self;
}

- (void) viewDidLoad {
	if(_students.count > 1) {
		self.navigationItem.rightBarButtonItem = self.editButtonItem;
	}
}

#pragma mark - Table view data source
- (NSInteger) numberOfSectionsInTableView:(UITableView *) tableView {
	return 2;
}

- (NSInteger) tableView:(UITableView *) tableView numberOfRowsInSection:(NSInteger) section {
	switch(section) {
		case 0:
			return _students.count;
			break;
			
		case 1:
			return 1;
			break;
			
		default:
			return 0;
			break;
	}
}

- (UITableViewCell *)tableView:(UITableView *) tableView cellForRowAtIndexPath:(NSIndexPath *) indexPath {
    UITableViewCell *cell;
	
	// Configure it as a student cell
    if(indexPath.section == 0) {
		cell = [tableView dequeueReusableCellWithIdentifier:@"SettingsStudentCell"];
		
		if(!cell) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"SettingsStudentCell"];
		}
		
		SQUStudent *student = _students[indexPath.row];
		SQUDistrict *district = [[SQUDistrictManager sharedInstance] districtWithID:student.district.integerValue];
		
		cell.textLabel.text = student.name;
		
		if(student.student_id) {
			cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Student ID: %@ — %@", nil), student.student_id, district.name];
		} else {
			cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"District: %@", nil), district.name];			
		}
		
		NSInteger selectedStudent = [_students indexOfObject:[[SQUGradeManager sharedInstance] getSelectedStudent]];
		
		// Always show the check if there's only a single student
		if(indexPath.row == selectedStudent || _students.count == 1) {
			cell.accessoryType = UITableViewCellAccessoryCheckmark;
		} else {
			cell.accessoryType = UITableViewCellAccessoryNone;
		}
		
		// Disable selection
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
	} else if(indexPath.section == 1) {
		// "Add New…" button
		cell = [tableView dequeueReusableCellWithIdentifier:@"SettingsButtonCell" forIndexPath:indexPath];
		cell.textLabel.text = NSLocalizedString(@"Add Student…", nil);
	}
    
    return cell;
}

- (NSString *) tableView:(UITableView *) tableView titleForHeaderInSection:(NSInteger) section {
	switch(section) {
		case 0:
			return NSLocalizedString(@"Students", nil);
			break;
	}
	
	return nil;
}

#pragma mark - Table editng for student items
- (BOOL) tableView:(UITableView *) tableView canEditRowAtIndexPath:(NSIndexPath *) indexPath {
    return (indexPath.section == 0) /*&& !(_students.count == 1)*/;
}

- (void) tableView:(UITableView *) tableView commitEditingStyle:(UITableViewCellEditingStyle) editingStyle forRowAtIndexPath:(NSIndexPath *) indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
		// if there's only one student left and we delete it ask for more confirmation
		if(_students.count == 1) {
			UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Once you remove this student, QuickHAC will require you to add an account before you can use it.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:NSLocalizedString(@"Remove Student", nil) otherButtonTitles:nil];
			sheet.tag = kSQUActionSheetDeleteStudent;
			[sheet showInView:self.view];
			return;
		}
		
		NSInteger selectedStudent = [_students indexOfObject:[[SQUGradeManager sharedInstance] getSelectedStudent]];
		
		// Delete object from DB
		[[SQUPersistence sharedInstance].managedObjectContext deleteObject:_students[indexPath.row]];
		[_students removeObject:_students[indexPath.row]];
		
		// Do animate-y thing
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
		
		// Update selection, if we are deleting the selected student
		if(indexPath.row == selectedStudent) {
			[[SQUGradeManager sharedInstance] changeSelectedStudent:_students[0]];
			
			// Set default student
			SQUStudent *student = _students[0];
			[[SQUDistrictManager sharedInstance] selectDistrictWithID:student.district.integerValue];
			[[SQUGradeManager sharedInstance] setStudent:student];
			
			// Update UI
			[[NSNotificationCenter defaultCenter] postNotificationName:SQUGradesDataUpdatedNotification object:nil];
			[[NSNotificationCenter defaultCenter] postNotificationName:SQUStudentsUpdatedNotification object:nil];
		}
		
		// If we deleted all students, we must show the login dialogue
		if(_students.count == 0) {
			SQULoginSchoolSelector *loginController = [[SQULoginSchoolSelector alloc] initWithStyle:UITableViewStyleGrouped];
			[self.navigationController popToRootViewControllerAnimated:YES];
			[self.navigationController dismissViewControllerAnimated:YES completion:NULL];
			[self.navigationController presentViewController:[[UINavigationController alloc] initWithRootViewController:loginController] animated:NO completion:NULL];
		}
		
		// Save to DB
		NSError *err = nil;
		if(![[SQUPersistence sharedInstance].managedObjectContext save:&err]) {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Database Error", nil) message:err.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
			[alert show];
		}
    }
}

#pragma mark - Action sheet
- (void) actionSheet:(UIActionSheet *) actionSheet clickedButtonAtIndex:(NSInteger) buttonIndex {
	switch (actionSheet.tag) {
		case kSQUActionSheetDeleteStudent: {
			if (buttonIndex == 1) {
				[self.tableView endEditing:YES];
			} else if(buttonIndex == 0) {
				// Delete object from DB
				[self.tableView beginUpdates];
				[[SQUPersistence sharedInstance].managedObjectContext deleteObject:_students[0]];
				[_students removeObject:_students[0]];
				
				// Do animate-y thing
				[self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
				[self.tableView endUpdates];
				
				// Reset default student
				[[SQUGradeManager sharedInstance] changeSelectedStudent:nil];
				
				/*
				 * This is ESSENTIAL to avoid a crash in the login code when all
				 * students are deleted and a multi-student account is added, as
				 * the student picker will NOT be shown and the app is left in
				 * an inconsistent state.
				 */
				[SQUGradeManager sharedInstance].student = nil;
				
				// Save to DB
				NSError *err = nil;
				if(![[SQUPersistence sharedInstance].managedObjectContext save:&err]) {
					UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Database Error", nil) message:err.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
					[alert show];
					return;
				}
				
				// If we deleted all students, we must show the login dialogue
				[self.navigationController dismissViewControllerAnimated:NO completion:^{
					SQULoginSchoolSelector *loginController = [[SQULoginSchoolSelector alloc] initWithStyle:UITableViewStyleGrouped];
					[[[UIApplication sharedApplication].windows[0] rootViewController] presentViewController:[[UINavigationController alloc] initWithRootViewController:loginController] animated:NO completion:NULL];
					
					// Hide sidebar
					[((PKRevealController *) [[UIApplication sharedApplication].windows[0] rootViewController]) resignPresentationModeEntirely:YES animated:NO completion:NULL];
				}];
			}
			
			break;
		}
			
		default:
			break;
	}
}

#pragma mark - Student adding
- (void) tableView:(UITableView *) tableView didSelectRowAtIndexPath:(NSIndexPath *) indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	if(indexPath.section == 0) {
		return;
		
		NSInteger selectedStudent = [_students indexOfObject:[[SQUGradeManager sharedInstance] getSelectedStudent]];
		
		// Update selection if we're not tapping the same cell as selected
		if(indexPath.row != selectedStudent) {
			// Update UI and user defaults
			[[SQUGradeManager sharedInstance] changeSelectedStudent:_students[indexPath.row]];
		
			[self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:selectedStudent inSection:0], indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
			
			selectedStudent = indexPath.row;
			
			[SVProgressHUD showProgress:-1 status:NSLocalizedString(@"Changing Student…", nil) maskType:SVProgressHUDMaskTypeGradient];
			
			// Update internal state to reflect new student
			SQUStudent *student = _students[selectedStudent];
			[[SQUGradeManager sharedInstance] setStudent:student];
			
			// Change to correct district
			[[SQUDistrictManager sharedInstance] selectDistrictWithID:student.district.integerValue];
			
			// We also have to log in again and disambiguate
			NSString *username, *password, *studentID;
			
			username = student.hacUsername;
			password = [Lockbox stringForKey:username];
			studentID = student.student_id;
			
			// Display at least cached grades if available
			[[NSNotificationCenter defaultCenter] postNotificationName:SQUGradesDataUpdatedNotification object:nil];
			
			// Log in
			[[SQUDistrictManager sharedInstance] performLoginRequestWithUser:username usingPassword:password andCallback:^(NSError *error, id returnData){
				if(!error) {
					if(!returnData) {
						[SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Wrong Credentials", nil)];
						
						// Tell the user what happened
						UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error Authenticating", nil) message:NSLocalizedString(@"Your username or password were rejected by HAC. Please update your password, if it was changed, and try again.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
						[alert show];
					} else {
						// Login succeeded, so we can do a fetch of grades.
						[SVProgressHUD showProgress:-1 status:NSLocalizedString(@"Updating Grades…", nil) maskType:SVProgressHUDMaskTypeGradient];
						[[SQUGradeManager sharedInstance] fetchNewClassGradesFromServerWithDoneCallback:^(NSError *err) {
							[SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"Done", nil)];
							[[NSNotificationCenter defaultCenter] postNotificationName:SQUGradesDataUpdatedNotification object:nil];
							
							// Display error
							if(err) {
								UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error Updating Grades", nil) message:err.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
								[alert show];
							}
						}];
					}
				} else {
					[SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Error", nil)];
					
					UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error Authenticating", nil) message:error.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
					[alert show];
				}
			}];
			
			NSLog(@"Changed student to %@ (index %ld)",
				  [SQUGradeManager sharedInstance].student.name,
				  (long) selectedStudent);
		}
	} else if(indexPath.section == 1) {
		// Show login controller
		if(indexPath.row == 0) {
			SQULoginSchoolSelector *loginController = [[SQULoginSchoolSelector alloc] initWithStyle:UITableViewStyleGrouped];
			loginController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismissModal:)];
			[self presentViewController:[[UINavigationController alloc] initWithRootViewController:loginController] animated:YES completion:NULL];
		}
	}
}

- (void) dismissModal:(id) sender {
	[self dismissViewControllerAnimated:YES completion:NULL];
}

/*
 * This notification is fired when the students in the database are updated.
 */
- (void) studentsUpdated:(NSNotification *) notif {
	NSManagedObjectContext *context = [[SQUPersistence sharedInstance] managedObjectContext];
	NSError *db_err = nil;
	
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"SQUStudent" inManagedObjectContext:context];
	[fetchRequest setEntity:entity];
	_students = [NSMutableArray arrayWithArray:[context executeFetchRequest:fetchRequest error:&db_err]];
	
	if(db_err) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Database Error", nil) message:db_err.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
		[alert show];
	}
	
	if(_students.count > 1) {
		self.navigationItem.rightBarButtonItem = self.editButtonItem;
	}
	
	[self.tableView reloadData];
}

@end
