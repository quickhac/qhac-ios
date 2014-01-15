//
//  SQUUserSwitcherView.m
//  QuickHAC
//
//  Created by Tristan Seifert on 1/11/14.
//  See README.MD for licensing and copyright information.
//

#import "UIColor+SQUColourUtilities.h"
#import "SQUCoreData.h"
#import "SQUAppDelegate.h"
#import "SQUUserSwitcherCell.h"
#import "SQUGradeManager.h"
#import "SQUDistrictManager.h"
#import "SQULoginSchoolSelector.h"
#import "SQUSidebarController.h"
#import "SQUUserSwitcherView.h"

#import "SVProgressHUD.h"
#import "Lockbox.h"

@implementation SQUUserSwitcherView

- (id) initWithFrame:(CGRect) frame {
    self = [super initWithFrame:frame];
    
	if (self) {
		self.backgroundColor = UIColorFromRGB(0x262626);
		
		// Grid layout
		_gridLayout = [[UICollectionViewFlowLayout alloc] init];
		_gridLayout.minimumInteritemSpacing = 0;
		_gridLayout.minimumLineSpacing = 10;
		_gridLayout.itemSize = CGSizeMake(kSQUUserSwitcherCellWidth, kSQUUserSwitcherCellHeight);
		
		CGRect gridFrame = frame;
		gridFrame.origin.y = 0;
		gridFrame.size.height -= 45;
		
		// Grid
		_grid = [[UICollectionView alloc] initWithFrame:gridFrame collectionViewLayout:_gridLayout];
		[_grid registerClass:NSClassFromString(@"SQUUserSwitcherCell") forCellWithReuseIdentifier:@"UserSwitcherCell"];
		_grid.backgroundColor = UIColorFromRGB(0x363636);
		_grid.delegate = self;
		_grid.dataSource = self;
		_grid.allowsSelection = YES;
		_grid.contentInset = UIEdgeInsetsMake(37, 5, 5, 5); // top left bottom right
		_grid.scrollIndicatorInsets = UIEdgeInsetsMake(32, 0, 0, 0);
		[self addSubview:_grid];
		
		// Logout button
		CGRect buttonRect = CGRectMake(0, gridFrame.size.height + 1, gridFrame.size.width, 44);
		_logoutButton = [[UIButton alloc] initWithFrame:buttonRect];
		[_logoutButton setBackgroundImage:[UIColorFromRGB(0x363636) imageFromColor] forState:UIControlStateNormal];
		[_logoutButton setBackgroundImage:[UIColorFromRGB(0x2b2b2b) imageFromColor] forState:UIControlStateSelected];
		[_logoutButton setTitle:NSLocalizedString(@"Log Out", nil) forState:UIControlStateNormal];
		[self addSubview:_logoutButton];
		
		// Subscribe to notifications
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateNotification:) name:SQUStudentsUpdatedNotification object:nil];
		[self updateStudents:nil];
    }
	
    return self;
}

#pragma mark - Data handling
- (void) updateNotification:(NSNotification *) notif {
	[self updateStudents:nil];
}

- (void) updateStudents:(id) ignored {
	// Update students data only if "ignored" is nil
	if(!ignored) {
		// Fetch students objects from DB
		NSManagedObjectContext *context = [[SQUAppDelegate sharedDelegate] managedObjectContext];
		NSError *db_err = nil;
		
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"SQUStudent" inManagedObjectContext:context];
		[fetchRequest setEntity:entity];
		_students = [NSMutableArray arrayWithArray:[context executeFetchRequest:fetchRequest error:&db_err]];
		
		if(db_err) {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Database Error", nil) message:db_err.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
			[alert show];
			return;
		}
		
		[_grid reloadData];
	}
	
	// Update selection
	NSInteger selectedStudent = [[NSUserDefaults standardUserDefaults] integerForKey:@"selectedStudent"];
	[_grid selectItemAtIndexPath:[NSIndexPath indexPathForItem:selectedStudent inSection:0] animated:NO scrollPosition:UICollectionViewScrollPositionTop];
}

- (void) showStudentAdder {
	SQULoginSchoolSelector *loginController = [[SQULoginSchoolSelector alloc] initWithStyle:UITableViewStyleGrouped];
	loginController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismissModal:)];
	[[SQUAppDelegate sharedDelegate].window.rootViewController presentViewController:[[UINavigationController alloc] initWithRootViewController:loginController] animated:YES completion:NULL];
}

- (void) dismissModal:(id) sender {
	[[SQUAppDelegate sharedDelegate].window.rootViewController dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - Grid view
- (NSInteger) collectionView:(UICollectionView *) collectionView numberOfItemsInSection:(NSInteger) section {
	return _students.count + 1;
}

- (UICollectionViewCell *) collectionView:(UICollectionView *) collectionView cellForItemAtIndexPath:(NSIndexPath *) indexPath {
	SQUUserSwitcherCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"UserSwitcherCell" forIndexPath:indexPath];
	
	// "Add Student…" button
	if(indexPath.row == _students.count) {
		cell.showsSelection = NO;
		
		[cell setTitle:NSLocalizedString(@"Add Student", nil)];
		[cell setSubTitle:nil];
		[cell setImage:[UIImage imageNamed:@"switcher_add"]];
	} else {
		cell.showsSelection = YES;
		
		SQUStudent *student = _students[indexPath.row];
		
		if(student.student_id) {
			[cell setSubTitle:[NSString stringWithFormat:NSLocalizedString(@"ID: %@", @"student selector"), student.student_id]];
		} else {
			[cell setSubTitle:student.school];
		}
		
		[cell setTitle:student.display_name];
		[cell setImage:[UIImage imageNamed:@"default_avatar.jpg"]];
	}
	
	return cell;
}

- (void) collectionView:(UICollectionView *) collectionView didSelectItemAtIndexPath:(NSIndexPath *) indexPath {	
	if(indexPath.row == _students.count) {
		[self showStudentAdder];
		[self performSelectorOnMainThread:@selector(updateStudents:) withObject:collectionView waitUntilDone:NO];
		
		// Hide switcher view
		[[NSNotificationCenter defaultCenter] postNotificationName:SQUSidebarControllerToggleUserSwitcher object:nil];
	} else {
		NSInteger selectedStudent = indexPath.row;
		
		[[NSUserDefaults standardUserDefaults] setInteger:selectedStudent forKey:@"selectedStudent"];
		[[NSUserDefaults standardUserDefaults] synchronize];
		
		SQUStudent *student = _students[selectedStudent];
		[[SQUGradeManager sharedInstance] setStudent:student];
		
		[[SQUDistrictManager sharedInstance] selectDistrictWithID:student.district.integerValue];
		
		// Load grades, if required
		if(!student.lastAveragesUpdate) {
			[SVProgressHUD showProgress:-1 status:NSLocalizedString(@"Changing Student", nil) maskType:SVProgressHUDMaskTypeGradient];
			
			// We also have to log in again and disambiguate
			NSString *username, *password, *studentID;
			
			username = student.hacUsername;
			password = [Lockbox stringForKey:username];
			studentID = student.student_id;
			
			// Log in
			[[SQUDistrictManager sharedInstance] performLoginRequestWithUser:username usingPassword:password andCallback:^(NSError *error, id returnData){
				if(!error) {
					if(!returnData) {
						[SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Wrong Credentials", nil)];
						
						// Tell the user what happened
						UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error Authenticating", nil) message:NSLocalizedString(@"Your username or password were rejected by HAC. Please update your password, if it was changed, and try again.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:NSLocalizedString(@"Settings", nil), nil];
						alert.tag = kSQUAlertChangePassword;
						[alert show];
					} else {
						// Login succeeded, so we can do a fetch of grades.
						[SVProgressHUD showProgress:-1 status:NSLocalizedString(@"Updating Grades", nil) maskType:SVProgressHUDMaskTypeGradient];
						
						[[SQUGradeManager sharedInstance] fetchNewClassGradesFromServerWithDoneCallback:^(NSError *err) {
							[SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"Done", nil)];
							[[NSNotificationCenter defaultCenter] postNotificationName:SQUGradesDataUpdatedNotification object:nil];
							
							// Display error
							if(err) {
								UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error Updating Grades", nil) message:err.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
								[alert show];
								
								[_grid selectItemAtIndexPath:_lastSelection animated:NO scrollPosition:UICollectionViewScrollPositionTop];
							} else {
								_lastSelection = indexPath;
								
								// Hide switcher
								[[NSNotificationCenter defaultCenter] postNotificationName:SQUSidebarControllerToggleUserSwitcher object:nil];
								// Show overview
								[[NSNotificationCenter defaultCenter] postNotificationName:SQUSidebarControllerShowOverview object:nil];
								// Update overview
								[[NSNotificationCenter defaultCenter] postNotificationName:SQUGradesDataUpdatedNotification object:nil];
								
								// Update student array
								NSManagedObjectContext *context = [[SQUAppDelegate sharedDelegate] managedObjectContext];
								NSError *db_err = nil;
								
								NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
								NSEntityDescription *entity = [NSEntityDescription entityForName:@"SQUStudent" inManagedObjectContext:context];
								[fetchRequest setEntity:entity];
								_students = [NSMutableArray arrayWithArray:[context executeFetchRequest:fetchRequest error:&db_err]];
								
								// Update selection
								NSInteger index = [_students indexOfObject:student];
								if(index != NSNotFound) {
									[[NSUserDefaults standardUserDefaults] setInteger:index forKey:@"selectedStudent"];
									[[NSUserDefaults standardUserDefaults] synchronize];
									
									_lastSelection = [NSIndexPath indexPathForItem:index inSection:0];
								}
								
								[_grid selectItemAtIndexPath:_lastSelection animated:NO scrollPosition:UICollectionViewScrollPositionNone];
							}
						}];
					}
				} else {
					[SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Error", nil)];
					
					UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error Authenticating", nil) message:error.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
					[alert show];
				}
			}];
		} else { // We needn't update grades
			_lastSelection = indexPath;
			
			// Hide switcher
			[[NSNotificationCenter defaultCenter] postNotificationName:SQUSidebarControllerToggleUserSwitcher object:nil];
			// Show overview
			[[NSNotificationCenter defaultCenter] postNotificationName:SQUSidebarControllerShowOverview object:nil];
			// Update overview
			[[NSNotificationCenter defaultCenter] postNotificationName:SQUGradesDataUpdatedNotification object:nil];
		}
	}
}

@end
