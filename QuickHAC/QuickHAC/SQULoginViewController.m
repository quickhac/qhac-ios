//
//  SQULoginViewController.m
//  QuickHAC
//
//  Created by Tristan Seifert on 05/07/2013.
//  See README.MD for licensing and copyright information.
//

#import "SQUPersistence.h"
#import "SQULoginViewController.h"
#import <KVNProgress.h>
#import "SQUAppDelegate.h"
#import "SQUDistrict.h"
#import "SQUGradeManager.h"
#import "SQUColourScheme.h"
#import "SQUDistrictManager.h"
#import "SQUCoreData.h"

// seriously, I thought I could handle the Keychain APIs but nope.avi
#import "Lockbox.h"

@interface SQULoginViewController ()

- (BOOL) studentExistsWithID:(NSString *) dasID;
- (BOOL) studentExistsWithUser:(NSString *) user;

@end

@implementation SQULoginViewController
@synthesize district = _district, students = _students;

- (void) viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor darkGrayColor];
    
    // Set up QuickHAC "q" logo
    _qLogo = [CALayer layer];
    _qLogo.frame = CGRectMake(160 - (180 / 2), 34, 180, 180);
    _qLogo.contents = (__bridge id)([UIImage imageNamed:@"LoginIcon"].CGImage);
	_qLogo.cornerRadius = 25.263;
	_qLogo.masksToBounds = YES;
	_qLogo.contentsScale = [UIScreen mainScreen].scale;
    
    [self.view.layer addSublayer:_qLogo];
    
    // Set up the selected district and changing link
    _districtSelected = [CATextLayer layer];
    _districtSelected.fontSize = 14;
    _districtSelected.contentsScale = [UIScreen mainScreen].scale;
    _districtSelected.alignmentMode = kCAAlignmentCenter;
    _districtSelected.frame = CGRectMake(16, 370, (320 - 32), 18);
    _districtSelected.string = [NSString stringWithFormat:NSLocalizedString(@"You selected %@.", nil), _district.name];
    _districtSelected.foregroundColor = UIColorFromRGB(kSQUColourTitle).CGColor;
    
    [self.view.layer addSublayer:_districtSelected];
    
    _changeDistrictLink = [UIButton buttonWithType:UIButtonTypeCustom];
    
    NSMutableAttributedString *changeDistrictTitle = [[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@"Change District", nil) attributes:nil];
    [changeDistrictTitle addAttribute:(__bridge NSString *) kCTUnderlineStyleAttributeName value:[NSNumber numberWithInteger:kCTUnderlineStyleSingle] range:NSMakeRange(0, changeDistrictTitle.length)];
    [changeDistrictTitle addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:14.0f] range:NSMakeRange(0, changeDistrictTitle.length)];
    [changeDistrictTitle addAttribute:NSForegroundColorAttributeName value:UIColorFromRGB(kSQUColourTitle) range:NSMakeRange(0, changeDistrictTitle.length)];
    [_changeDistrictLink setAttributedTitle:changeDistrictTitle forState:UIControlStateNormal];
    
    [_changeDistrictLink addTarget:self action:@selector(changeDistrictSelection:) forControlEvents:UIControlEventTouchUpInside];
    _changeDistrictLink.frame = CGRectMake((160 - 50), _districtSelected.frame.origin.y + 24, 100, 18);
    
    [self.view addSubview:_changeDistrictLink];
    
    // set up login fields
    _authFieldTable = [[UITableView alloc] initWithFrame:CGRectMake(0, 238, 304, 100) style:UITableViewStylePlain];
	
    _authFieldTable.delegate = self;
    _authFieldTable.dataSource = self;
    _authFieldTable.backgroundColor = [UIColor clearColor];
    _authFieldTable.backgroundView = nil;
    _authFieldTable.bounces = NO;
    
    [_authFieldTable registerClass:[UITableViewCell class] forCellReuseIdentifier:@"LoginCell"];
    
    [self.view addSubview:_authFieldTable];
    
    _tableMovedAlready = NO;
	
	// Background
/*	_background = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"blurry_bg.jpg"]];
	_background.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
	_background.alpha =  0.75;
	_background.opaque = YES;
	_background.contentMode = UIViewContentModeCenter;
	[self.view insertSubview:_background atIndex:0];
	
	// Set vertical effect
	UIInterpolatingMotionEffect *verticalMotionEffect =
	[[UIInterpolatingMotionEffect alloc]
	 initWithKeyPath:@"center.y"
	 type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
	verticalMotionEffect.minimumRelativeValue = @(-10);
	verticalMotionEffect.maximumRelativeValue = @(10);
	
	// Set horizontal effect
	UIInterpolatingMotionEffect *horizontalMotionEffect =
	[[UIInterpolatingMotionEffect alloc]
	 initWithKeyPath:@"center.x"
	 type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
	horizontalMotionEffect.minimumRelativeValue = @(-10);
	horizontalMotionEffect.maximumRelativeValue = @(10);
	
	// Create group to combine both
	UIMotionEffectGroup *group = [UIMotionEffectGroup new];
	group.motionEffects = @[horizontalMotionEffect, verticalMotionEffect];
	
	// Add both effects to your view
	[_background addMotionEffect:group];*/
	
	self.view.backgroundColor = UIColorFromRGB(kSQUColourConcrete);
	
    // set up navbar state
    self.title = NSLocalizedString(@"QuickHAC", @"login screen");
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                              initWithTitle:NSLocalizedString(@"Log In", @"login screen")
                                              style:UIBarButtonItemStyleDone
                                              target:self action:@selector(loginBarButtonItemPressed:)];
}

- (void) viewWillAppear:(BOOL) animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void) viewWillDisappear:(BOOL) animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

#pragma mark - Miscellaneous UI actions
- (void) changeDistrictSelection:(id) sender {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void) loginBarButtonItemPressed:(id) sender {
    if(_tableMovedAlready) {
        [self moveTableDown];
        [_selectedTableTextField resignFirstResponder];
    }
    
    [self performAuthentication:sender];
}

#pragma mark - Table View
- (NSInteger) tableView:(UITableView *) tableView numberOfRowsInSection:(NSInteger) section {
    return 2;
}

- (UITableViewCell *) tableView:(UITableView *) tableView cellForRowAtIndexPath:(NSIndexPath *) indexPath {
    static NSString *CellIdentifier = @"LoginCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
	cell.backgroundColor = [UIColor clearColor];
	cell.opaque = NO;
	
    UITextField *_textView = [[UITextField alloc] initWithFrame:CGRectMake(12+16, 9, cell.frame.size.width - 24 - 14 - 16, cell.frame.size.height - 17)];
    _textView.delegate = self;
	_textView.textColor = UIColorFromRGB(kSQUColourTitle);
    [cell.contentView addSubview:_textView];
    
    if(indexPath.row == 0) {
        _textView.autocorrectionType = UITextAutocorrectionTypeNo;
        _textView.autocapitalizationType = UITextAutocapitalizationTypeNone;
        
        _textView.keyboardType = UIKeyboardTypeEmailAddress;
        _textView.returnKeyType = UIReturnKeyNext;
        
        _textView.adjustsFontSizeToFitWidth = YES;
        _textView.minimumFontSize = 12;
        
		_textView.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Username", @"login view controller placeholder") attributes:@{NSForegroundColorAttributeName: UIColorFromRGB(kSQUColourSilver)}];
        
        _usernameField = _textView;
    } else if(indexPath.row == 1) {
        _textView.secureTextEntry = YES;
        _textView.returnKeyType = UIReturnKeyDone;
        
        _textView.adjustsFontSizeToFitWidth = YES;
        _textView.minimumFontSize = 12;
        
		_textView.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Password", @"login view controller placeholder") attributes:@{NSForegroundColorAttributeName: UIColorFromRGB(kSQUColourSilver)}];
        
        _passField = _textView;
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

#pragma mark - Table view text cell
- (void) textFieldDidBeginEditing:(UITextField *) textField {
    _selectedTableTextField = textField;
    [self moveTableUp];
}

/**
 * Called when the return key is pressed on the software keyboard.
 */
- (BOOL) textFieldShouldReturn:(UITextField *) textField {
    if(textField == _usernameField) {
        [_passField becomeFirstResponder];
    } else if(textField == _passField) { // perform login
        [textField resignFirstResponder];
		
        [self moveTableDown];
        [self performAuthentication:textField];
        _selectedTableTextField = nil;
    }
	
	return YES;
}

- (void) moveTableUp {
    if(_tableMovedAlready) return;
    
    _tableMovedAlready = YES;
    
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationCurveEaseInOut animations:^{
        CGRect tempFrame = _authFieldTable.frame;
        tempFrame.origin.y -= 95;
        _authFieldTable.frame = tempFrame;
        
        _qLogo.frame = CGRectMake(160 - (104 / 2), 30, 104, 104);
    } completion:^(BOOL finished) { }];
}

- (void) moveTableDown {
    _tableMovedAlready = NO;
    
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationCurveEaseInOut animations:^{
        CGRect tempFrame = _authFieldTable.frame;
        tempFrame.origin.y += 95;
        _authFieldTable.frame = tempFrame;
        
        _qLogo.frame = CGRectMake(160 - (180 / 2), 34, 180, 180);
    } completion:^(BOOL finished) { }];
}

#pragma mark - Authentication
- (void) performAuthentication:(id) sender {
    if(_usernameField.text.length == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Invalid Username", nil) message:NSLocalizedString(@"Please enter a valid username.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
        [alert show];
        
        return;
    } else if(_passField.text.length == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Invalid Password", nil) message:NSLocalizedString(@"Please enter a valid password.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
        [alert show];
        
        return;
    }
	
	// Set up district interfacing
	[SQUDistrictManager sharedInstance].currentDistrict = _district;
	
	// Set up some things
	[KVNProgress showWithStatus:NSLocalizedString(@"Logging In…", nil)];
	_students = [NSMutableArray new];
	
	// This block is called for every student that we must add.
	void (^addStudent)(NSDictionary *student) = ^(NSDictionary *student) {
		if(student) {
			NSString *studentID = student[@"id"];
			NSString *studentName = student[@"name"];
			
			if(![self studentExistsWithID:studentID]) {
				NSManagedObjectContext *context = [[SQUPersistence sharedInstance] managedObjectContext];
				SQUStudent *studentInfo = [NSEntityDescription insertNewObjectForEntityForName:@"SQUStudent" inManagedObjectContext:context];
				
				// Set up student ID and district to database
				studentInfo.district = [NSNumber numberWithInteger:_district.district_id];
				studentInfo.hacUsername = _usernameField.text;
				
				// Set name to `nil` if it's a single student account
				if(student) {
					studentInfo.name = studentName;
					studentInfo.student_id = studentID;
				} else {
					studentInfo.name = nil;
					studentInfo.student_id = nil;
				}
				
				// Convert to display name
				NSArray *components = [studentName componentsSeparatedByString:@", "];
				if(components.count == 2) {
					NSString *firstName = components[1];
					components = [firstName componentsSeparatedByString:@" "];
					
					if(components.count == 0) {
						studentInfo.display_name = firstName;
					} else {
						studentInfo.display_name = components[0];
					}
				} else {
					studentInfo.display_name = studentName;
				}
				
				[_students addObject:studentInfo];
				
				[[SQUGradeManager sharedInstance] setStudent:studentInfo];
			}
		} else {
			// Single student account
			if(![self studentExistsWithUser:_usernameField.text]) {
				NSManagedObjectContext *context = [[SQUPersistence sharedInstance] managedObjectContext];
				SQUStudent *studentInfo = [NSEntityDescription insertNewObjectForEntityForName:@"SQUStudent" inManagedObjectContext:context];
				
				// Set up student ID and district to database
				studentInfo.student_id = nil;
				studentInfo.district = [NSNumber numberWithInteger:_district.district_id];
				studentInfo.hacUsername = _usernameField.text;
				
				[_students addObject:studentInfo];
				
				[[SQUGradeManager sharedInstance] setStudent:studentInfo];
			}
		}
	};
	
	// Set district so login may occurr
	[[SQUDistrictManager sharedInstance] selectDistrictWithID:_district.district_id];
	
	__block SQUStudent *oldStudent = [SQUGradeManager sharedInstance].student;
	
	// Ask the current district instance to do a log in
	[[SQUDistrictManager sharedInstance] performLoginRequestWithUser:_usernameField.text usingPassword:_passField.text andCallback:^(NSError *error, id returnData){
		if(!error) {
			if(!returnData) {
				[KVNProgress showErrorWithStatus:NSLocalizedString(@"Wrong Credentials", nil)];

				// Restore old student state
				if(oldStudent) {
					[[SQUDistrictManager sharedInstance] selectDistrictWithID:oldStudent.district.integerValue];
					[[SQUGradeManager sharedInstance] setStudent:oldStudent];
				}
			} else {
				[KVNProgress showWithStatus:NSLocalizedString(@"Adding students…", nil)];
				// Store the username's password in the keychain
				[Lockbox setString:_passField.text forKey:_usernameField.text];

				// Back up the old student as we need a temporary switch to retrieve data
				__unsafe_unretained __block SQULoginViewController *self_unsafe = self;

				// Set up login function
				_studentLoginFunction = ^{
					// Update grades
					[KVNProgress showWithStatus:NSLocalizedString(@"Updating Grades…", nil)];
					
					NSLog(@"fetching grades for: %@", [SQUGradeManager sharedInstance].student.name);
					
					// Fetch grades
					[[SQUGradeManager sharedInstance] fetchNewClassGradesFromServerWithDoneCallback:^(NSError *error) {
						if(!error) {
							[KVNProgress showSuccessWithStatus:NSLocalizedString(@"Done", nil)];
							
							// Restore old student state
							if(oldStudent) {
								[[SQUGradeManager sharedInstance] setStudent:oldStudent];
								[[SQUDistrictManager sharedInstance] selectDistrictWithID:oldStudent.district.integerValue];
							}
							
							[[NSNotificationCenter defaultCenter] postNotificationName:SQUGradesDataUpdatedNotification object:nil userInfo:@{}];
							[[NSNotificationCenter defaultCenter] postNotificationName:SQUStudentsUpdatedNotification object:nil];
							
							// Dismiss login view
							[self_unsafe dismissViewControllerAnimated:YES completion:NO];
						} else {
							[KVNProgress showErrorWithStatus:NSLocalizedString(@"Error", nil)];
							
							// Delete students added to the DB
							for(SQUStudent *studentToDelete in self_unsafe.students) {
								[[SQUPersistence sharedInstance].managedObjectContext deleteObject:studentToDelete];
							}
							[[SQUPersistence sharedInstance] saveContext];
							
							UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error Fetching Grades", nil) message:error.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
							[alert show];
						}
					}];
				};
				
				// If the account is single-student, add the student.
				if(![SQUDistrictManager sharedInstance].currentDistrict.hasMultipleStudents) {
					addStudent(nil);
				} else {
					for(NSDictionary *student in [SQUDistrictManager sharedInstance].currentDistrict.studentsOnAccount) {
						addStudent(student);
					}
				}
				
				if(_students.count == 0) {
					UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No Students", nil) message:[NSString stringWithFormat:NSLocalizedString(@"All students on the account '%@' have already been added to QuickHAC.\nUse the sidebar to switch between them.", nil), _usernameField.text] delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
					[alert show];
					[KVNProgress dismiss];
					
					// Restore old student state
					if(oldStudent) {
						[[SQUDistrictManager sharedInstance] selectDistrictWithID:oldStudent.district.integerValue];
						[[SQUGradeManager sharedInstance] setStudent:oldStudent];
					}
					
					[self dismissViewControllerAnimated:YES completion:NULL];
					return;
				}
				
				// Save the database.
				[[SQUPersistence sharedInstance] saveContext];
				
				// Bring up a student selector if multistudent account and no students yet
				if([SQUDistrictManager sharedInstance].currentDistrict.hasMultipleStudents && !oldStudent) {
					[KVNProgress dismiss];
					
					SQULoginStudentPicker *picker = [[SQULoginStudentPicker alloc] initWithStyle:UITableViewStyleGrouped];
					picker.students = _students;
					picker.delegate = self;
					[self.navigationController pushViewController:picker animated:YES];
				} else if(![SQUDistrictManager sharedInstance].currentDistrict.hasMultipleStudents && !oldStudent) {
					// No previous students and not multistudent account
					[[SQUGradeManager sharedInstance] changeSelectedStudent:_students[0]];
					[[SQUGradeManager sharedInstance] setStudent:_students[0]];
					
					_studentLoginFunction();
				} else {
					// There exists a previous student(s), and this account does not have multistudent
					
					// Perform fetch for this student to gather some info about them
					if(![SQUDistrictManager sharedInstance].currentDistrict.hasMultipleStudents) {
						// this is so the student data goes to the right student
						SQUStudent *theStudent = _students[0];
						theStudent.name = nil;
						theStudent.display_name = nil;
						[[SQUGradeManager sharedInstance] setStudent:theStudent];
						
						[KVNProgress showWithStatus:NSLocalizedString(@"Updating Grades…", nil)];
						
						// Fetch grades
						[[SQUGradeManager sharedInstance] fetchNewClassGradesFromServerWithDoneCallback:^(NSError *error) {
							if(!error) {
								[KVNProgress showSuccessWithStatus:NSLocalizedString(@"Done", nil)];
								
								// Restore old student state
								if(oldStudent) {
									[[SQUDistrictManager sharedInstance] selectDistrictWithID:oldStudent.district.integerValue];
									[[SQUGradeManager sharedInstance] setStudent:oldStudent];
								}
								
								[[NSNotificationCenter defaultCenter] postNotificationName:SQUGradesDataUpdatedNotification object:nil userInfo:@{}];
								[[NSNotificationCenter defaultCenter] postNotificationName:SQUStudentsUpdatedNotification object:nil];
								
								// Dismiss login view
								[self_unsafe dismissViewControllerAnimated:YES completion:NO];
							} else {
								// Delete students added to the DB
								for(SQUStudent *studentToDelete in self_unsafe.students) {
									[[SQUPersistence sharedInstance].managedObjectContext deleteObject:studentToDelete];
								}
								
								[[SQUPersistence sharedInstance] saveContext];
								
								[KVNProgress showErrorWithStatus:NSLocalizedString(@"Error", nil)];
								
								UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error Fetching Grades", nil) message:error.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
								[alert show];
							}
						}];
					} else {
						// Restore student
						[[SQUGradeManager sharedInstance] setStudent:oldStudent];
						[[SQUDistrictManager sharedInstance] selectDistrictWithID:oldStudent.district.unsignedIntegerValue];
						
						// Dismiss the login controller
						[KVNProgress dismiss];
						[self dismissViewControllerAnimated:YES completion:NULL];
					}
					
					[[NSNotificationCenter defaultCenter] postNotificationName:SQUStudentsUpdatedNotification object:nil];
				}
			}
		} else {
            [KVNProgress showErrorWithStatus:NSLocalizedString(@"Error", nil)];
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error Authenticating", nil) message:error.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
            [alert show];
			
			// Restore old student state
			if(oldStudent) {
				// NSLog(@"Restoring student: %@", oldStudent);
				
				[[SQUDistrictManager sharedInstance] selectDistrictWithID:oldStudent.district.integerValue];
				[[SQUGradeManager sharedInstance] setStudent:oldStudent];
			}
		}
	}];
}

#pragma mark - View Controller Shenanigans
- (NSUInteger) supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationPortraitUpsideDown;
}

- (BOOL) shouldAutorotate {
    return YES;
}

#pragma mark - Database helpers
- (BOOL) studentExistsWithID:(NSString *) dasID {
	NSError *error = nil;
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"SQUStudent" inManagedObjectContext:[SQUPersistence sharedInstance].managedObjectContext];
	[request setEntity:entity];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(student_id == %@)", dasID];
	[request setPredicate:predicate];
	
	return ([[SQUPersistence sharedInstance].managedObjectContext countForFetchRequest:request error:&error] != 0);
}

- (BOOL) studentExistsWithUser:(NSString *) user {
	NSError *error = nil;
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"SQUStudent" inManagedObjectContext:[SQUPersistence sharedInstance].managedObjectContext];
	[request setEntity:entity];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(hacUsername == %@)", user];
	[request setPredicate:predicate];
	
	return ([[SQUPersistence sharedInstance].managedObjectContext countForFetchRequest:request error:&error] != 0);
}

#pragma mark - Student selector
- (void) studentPickerCancelled:(SQULoginStudentPicker *) picker {
	// Delete students added to the DB
	for(SQUStudent *studentToDelete in _students) {
		[[SQUPersistence sharedInstance].managedObjectContext deleteObject:studentToDelete];
	}
	[[SQUPersistence sharedInstance] saveContext];
	
	[self.navigationController popViewControllerAnimated:YES];
}

- (void) studentPickerDidSelect:(SQULoginStudentPicker *) picker withStudent:(SQUStudent *) student {
	// Check which index this student is in the database.
	NSUInteger selectedStudent;
	
	NSError *error = nil;
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"SQUStudent" inManagedObjectContext:[SQUPersistence sharedInstance].managedObjectContext];
	[request setEntity:entity];
	
	NSArray *students = [[SQUPersistence sharedInstance].managedObjectContext executeFetchRequest:request error:&error];
	if(error) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Database Error", nil) message:error.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
		[alert show];
		return;
	}
	
	selectedStudent = [students indexOfObject:student];
	
	// Make sure the student is in the DB
	if(selectedStudent != NSNotFound) {
		// Only update selection if there's no other students in the database
		if(students.count == _students.count) {
			[[SQUGradeManager sharedInstance] changeSelectedStudent:student];
			[[SQUGradeManager sharedInstance] setStudent:student];
			
			// Fire off notifications
			[[NSNotificationCenter defaultCenter] postNotificationName:SQUGradesDataUpdatedNotification object:nil userInfo:@{}];
			[[NSNotificationCenter defaultCenter] postNotificationName:SQUStudentsUpdatedNotification object:nil];
		}
	} else {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Database Error", nil) message:NSLocalizedString(@"Something happened.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
		[alert show];
		
		// something broke so delete students added earlier from DB and plsagaintry
		for(SQUStudent *studentToDelete in _students) {
			[[SQUPersistence sharedInstance].managedObjectContext deleteObject:studentToDelete];
		}
		
		[[SQUPersistence sharedInstance] saveContext];
		[self.navigationController popViewControllerAnimated:YES];
		
		return;
	}
	
	// Log in with this student.
	_studentLoginFunction();
}

@end
