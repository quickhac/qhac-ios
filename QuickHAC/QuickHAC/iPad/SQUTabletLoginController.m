//
//  SQUTabletLoginController.m
//  QuickHAC
//
//  Created by Tristan Seifert on 1/1/14.
//  See README.MD for licensing and copyright information.
//

#import "SQUPersistence.h"
#import "SQUDistrictManager.h"
#import "SQUCoreData.h"
#import "SQUAppDelegate.h"
#import "SQUGradeManager.h"
#import "SQUColourScheme.h"
#import "SQUTabletLoginController.h"

#import "SVProgressHUD.h"
#import "Lockbox.h"

#import <CoreText/CoreText.h>
#import <QuartzCore/QuartzCore.h>

@interface SQUTabletLoginController ()

- (void) doLogin;
- (BOOL) studentExistsWithID:(NSString *) dasID;
- (BOOL) studentExistsWithUser:(NSString *) user;

@end

@implementation SQUTabletLoginController
@synthesize students = _students;

- (void) viewDidLoad {
    [super viewDidLoad];
	
	// Draw background view
	UIImageView *backgroundView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 768, 1024)];
	backgroundView.image = [UIImage imageNamed:@"blurry_bg.jpg"];
	backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[self.view addSubview:backgroundView];
	
	self.navigationController.navigationBarHidden = YES;
	
	// Login container box
	_loginContainerBox = [[UIView alloc] initWithFrame:CGRectMake(171, 393, 425, 238)];
	_loginContainerBox.autoresizingMask = UIViewAutoresizingFlexibleRightMargin |
										 UIViewAutoresizingFlexibleTopMargin |
										 UIViewAutoresizingFlexibleBottomMargin |
										 UIViewAutoresizingFlexibleLeftMargin;
	
	// QuickHAC icon
	UIImageView *icon = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 128, 128)];
	icon.image = [UIImage imageNamed:@"LoginIcon"];
	[_loginContainerBox addSubview:icon];
	
	// "Welcome to QuickHAC" text
	UILabel *welcomeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 144, 132, 60)];
	welcomeLabel.lineBreakMode = NSLineBreakByWordWrapping;
	welcomeLabel.numberOfLines = 0;
	welcomeLabel.textAlignment = NSTextAlignmentCenter;
	
	NSMutableAttributedString *welcomeText = [[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@"Welcome to\nQuickHAC", nil) attributes:@{NSKernAttributeName:[NSNull null], NSForegroundColorAttributeName:UIColorFromRGB(kSQUColourClouds)}];
	
	/*
	 * "Welcome to" is in HelveticaNeue-Medium, "Quick" in HelveticaNeue-UltraLight,
	 * and "HAC" in HelveticaNeue-Bold.
	 */
	[welcomeText addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"HelveticaNeue-Medium" size:23.5] range:NSMakeRange(0, 10)];
	[welcomeText addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"HelveticaNeue-Light" size:23.5] range:NSMakeRange(11, 5)];
	[welcomeText addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"HelveticaNeue-Bold" size:23.5] range:NSMakeRange(16, 3)];
	
	welcomeLabel.attributedText = welcomeText;
	
	[_loginContainerBox addSubview:welcomeLabel];
	
	// Build the form container.
	UIView *formContainer = [[UIView alloc] initWithFrame:CGRectMake(154, 48, 271, 147)];
	formContainer.backgroundColor = UIColorFromRGB(kSQUColourClouds);
	
	// Set up the shadow for the form container.
	formContainer.layer.shadowColor = [UIColor blackColor].CGColor;
	formContainer.layer.shadowOpacity = 0.0625;
	formContainer.layer.shadowRadius = 4.0;
	formContainer.layer.shadowOffset = CGSizeMake(4.0, 4.0);
	formContainer.layer.shadowPath = [UIBezierPath bezierPathWithRect:CGRectMake(0, -48, 271, 195)].CGPath;
	
	// Do NOT clip to bounds so the triangle and shadow will show up.
	formContainer.clipsToBounds = NO;
	[_loginContainerBox addSubview:formContainer];
	
	// Draw the little triangle
	CGFloat triangleWidth = 16;
	CGFloat triangleHeight = 32;
	
	CAShapeLayer *triangle = [CAShapeLayer layer];
	triangle.frame = CGRectMake(-triangleWidth, 57, triangleWidth, triangleHeight);
	triangle.fillColor = UIColorFromRGB(kSQUColourClouds).CGColor;
	
	CGMutablePathRef path = CGPathCreateMutable();
	CGPathMoveToPoint(path, NULL, triangleWidth, 0);
	CGPathAddLineToPoint(path, NULL, triangleWidth, triangleHeight);
	CGPathAddLineToPoint(path, NULL, 0, triangleHeight/2);
	CGPathAddLineToPoint(path, NULL, triangleWidth, 0);
	CGPathCloseSubpath(path);
	
	triangle.path = path;
	CGPathRelease(path);
	
	[formContainer.layer addSublayer:triangle];
	
	// District selector BG
	UIView *districtSelectorContainer = [[UIView alloc] initWithFrame:CGRectMake(154, 0, 271, 48)];
	CAGradientLayer *districtSelectorBG = [CAGradientLayer layer];
	districtSelectorBG.frame = CGRectMake(0, 0, 271, 48);
	districtSelectorBG.backgroundColor = [UIColor whiteColor].CGColor;
	districtSelectorBG.opacity = 0.247059;
	[districtSelectorContainer.layer addSublayer:districtSelectorBG];
	[_loginContainerBox addSubview:districtSelectorContainer];
	
	// Chevron
	UIButton *districtDownButton = [[UIButton alloc] initWithFrame:CGRectMake(223, 0, 48, 48)];
	[districtDownButton setImage:[UIImage imageNamed:@"icon_chevron_down"] forState:UIControlStateNormal];
	[districtDownButton addTarget:self action:@selector(showDistrictSelector:) forControlEvents:UIControlEventTouchUpInside];
	[districtSelectorContainer addSubview:districtDownButton];
	
	// Label
	_selectedDistrict = 0;
	
	_currentDistrictLabel = [CATextLayer layer];
	_currentDistrictLabel.frame = CGRectMake(8, 15, 200, 32);
	_currentDistrictLabel.alignmentMode = kCAAlignmentCenter;
	_currentDistrictLabel.string = NSLocalizedString(@"Select District…", nil);
	_currentDistrictLabel.font = (__bridge CFTypeRef)([UIFont fontWithName:@"HelveticaNeue-Medium" size:16.0]);
	_currentDistrictLabel.fontSize = 17.0;
	[districtSelectorContainer.layer addSublayer:_currentDistrictLabel];
	
	// Add username/password fields
	_userField = [[UITextField alloc] initWithFrame:CGRectMake(16, 16, 239, 48)];
	_userField.borderStyle = UITextBorderStyleNone;
	_userField.placeholder = NSLocalizedString(@"HAC Username", nil);
	_userField.rightViewMode = UITextFieldViewModeAlways;
	_userField.delegate = self;
	_userField.returnKeyType = UIReturnKeyNext;
	_userField.autocorrectionType = UITextAutocorrectionTypeNo;
	_userField.autocapitalizationType = UITextAutocapitalizationTypeNone;
	[formContainer addSubview:_userField];
	
	// Add user icon to username field.
	UIImageView *userIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_person"]];
	userIcon.frame = CGRectMake(0, 0, 24, 24);
	_userField.rightView = userIcon;
	
	// Create password field
	_passField = [[UITextField alloc] initWithFrame:CGRectMake(16, 74, 239, 48)];
	_passField.secureTextEntry = YES;
	_passField.borderStyle = UITextBorderStyleNone;
	_passField.placeholder = NSLocalizedString(@"HAC Password", nil);
	_passField.rightViewMode = UITextFieldViewModeAlways;
	_passField.delegate = self;
	_passField.returnKeyType = UIReturnKeyDone;
	[formContainer addSubview:_passField];
	
	// Add key icon to username field.
	UIImageView *keyIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_key"]];
	keyIcon.frame = CGRectMake(0, 0, 24, 24);
	_passField.rightView = keyIcon;
	
	// Add "Forgot Password?" button.
	UIButton *lostPasswordButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    NSMutableAttributedString *lostPasswordTitle = [[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@"Lost your password?", nil) attributes:nil];
    [lostPasswordTitle addAttribute:(__bridge NSString *) kCTUnderlineStyleAttributeName value:[NSNumber numberWithInteger:kCTUnderlineStyleSingle] range:NSMakeRange(0, lostPasswordTitle.length)];
    [lostPasswordTitle addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"HelveticaNeue-Light" size:13.0] range:NSMakeRange(0, lostPasswordTitle.length)];
    [lostPasswordTitle addAttribute:NSForegroundColorAttributeName value:UIColorFromRGB(0x95A5A6) range:NSMakeRange(0, lostPasswordTitle.length)];
    [lostPasswordButton setAttributedTitle:lostPasswordTitle forState:UIControlStateNormal];
    lostPasswordButton.frame = CGRectMake(16, 124, 239, 18);
    lostPasswordButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    [formContainer addSubview:lostPasswordButton];
	
	// Add login container to root.
	[self.view addSubview:_loginContainerBox];
	
	_shouldDoSlide = YES;
}

#pragma mark - Text field delegate
- (void) textFieldDidBeginEditing:(UITextField *) textField {
	if(!_shouldDoSlide || _isSlidUp) return;
	
    // Move login form upwards
	[UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationCurveEaseInOut animations:^{
		CGRect frame = _loginContainerBox.frame;
		frame.origin.y -= 140;
		_loginContainerBox.frame = frame;
		_isSlidUp = YES;
    } completion:^(BOOL finished) { }];
}

- (void) textFieldDidEndEditing:(UITextField *) textField {
	if(!_shouldDoSlide || !_isSlidUp) return;
	
    // Move login form downwards
	[UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationCurveEaseInOut animations:^{
		CGRect frame = _loginContainerBox.frame;
		frame.origin.y += 140;
		_loginContainerBox.frame = frame;
		_isSlidUp = NO;
    } completion:^(BOOL finished) { }];
}

- (BOOL) textFieldShouldReturn:(UITextField *) textField {
	if(textField == _userField) {
		_shouldDoSlide = NO;
		[_passField becomeFirstResponder];
		_shouldDoSlide = YES;
	} else if(textField == _passField) {
		_shouldDoSlide = YES;
		[_passField resignFirstResponder];

		[self doLogin];
	}
	return YES;
}

#pragma mark - Login
- (void) doLogin {
	if(!_district) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No District Selected", nil) message:NSLocalizedString(@"You need to select a district before you can log in.\n\nTap the arrow at the top of the form to bring up a list of supported districts.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
		[alert show];
		return;
	}
	
    if(_userField.text.length == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Invalid Username", nil) message:NSLocalizedString(@"Please enter a valid username.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
        [alert show];
        
        return;
    } else if(_passField.text.length == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Invalid Password", nil) message:NSLocalizedString(@"Please enter a valid password.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
        [alert show];
        
        return;
    }
	
	BOOL couldSelectDistrict = [[SQUDistrictManager sharedInstance] selectDistrictWithID:_district.district_id];
	
	if(!couldSelectDistrict) {
		NSLog(@"District somehow vanished");
		return;
	}
	
	[SVProgressHUD showProgress:-1 status:NSLocalizedString(@"Logging In…", nil) maskType:SVProgressHUDMaskTypeGradient];
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
				studentInfo.student_id = studentID;
				studentInfo.district = [NSNumber numberWithInteger:_district.district_id];
				studentInfo.hacUsername = _userField.text;
				studentInfo.name = studentName;
				
				[_students addObject:studentInfo];
				
				[[SQUGradeManager sharedInstance] setStudent:studentInfo];
			}
		} else {
			// Single student account
			if(![self studentExistsWithUser:_userField.text]) {
				NSManagedObjectContext *context = [[SQUPersistence sharedInstance] managedObjectContext];
				SQUStudent *studentInfo = [NSEntityDescription insertNewObjectForEntityForName:@"SQUStudent" inManagedObjectContext:context];
				
				// Set up student ID and district to database
				studentInfo.student_id = nil;
				studentInfo.district = [NSNumber numberWithInteger:_district.district_id];
				studentInfo.hacUsername = _userField.text;
				
				[_students addObject:studentInfo];
				
				[[SQUGradeManager sharedInstance] setStudent:studentInfo];
			}
		}
	};
	
	// Do a login request for the user
	[[SQUDistrictManager sharedInstance] performLoginRequestWithUser:_userField.text usingPassword:_passField.text andCallback:^(NSError *error, id returnData) {
		if(!error) {
			if(!returnData) {
				[SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Invalid Credentials", nil)];
			} else {
				// Store username/password in keychain
				[Lockbox setString:_passField.text forKey:_userField.text];
				
				// Back up the old student as we need a temporary switch to retrieve data
				SQUStudent *oldStudent = [SQUGradeManager sharedInstance].student;
				
				// Add to database
				if([SQUDistrictManager sharedInstance].currentDistrict.hasMultipleStudents) {
					for(NSDictionary *student in [SQUDistrictManager sharedInstance].currentDistrict.studentsOnAccount) {
						addStudent(student);
					}
				} else {
					addStudent(nil);
				}
				
				__unsafe_unretained __block SQUTabletLoginController *self_unsafe = self;
				
				// If the account is single-student, add the student.
				if(![SQUDistrictManager sharedInstance].currentDistrict.hasMultipleStudents) {
					addStudent(nil);
				} else {
					for(NSDictionary *student in [SQUDistrictManager sharedInstance].currentDistrict.studentsOnAccount) {
						addStudent(student);
					}
				}
				
				if(_students.count == 0) {
					UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No Students", nil) message:[NSString stringWithFormat:NSLocalizedString(@"All students on the account '%@' have already been added to QuickHAC.\nUse the sidebar to switch between them.", nil), _userField.text] delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
					[alert show];
					[SVProgressHUD dismiss];
					
					[self dismissViewControllerAnimated:YES completion:NULL];
					return;
				}
				
				// Save the database.
				[[SQUPersistence sharedInstance] saveContext];
				
				_studentLoginFunction = ^{
					// Update grades
					[SVProgressHUD showProgress:-1 status:NSLocalizedString(@"Updating Grades", nil) maskType:SVProgressHUDMaskTypeGradient];
					
					// Fetch grades
					[[SQUGradeManager sharedInstance] fetchNewClassGradesFromServerWithDoneCallback:^(NSError *error) {
						if(!error) {
							[SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"Done", nil)];
							
							// Restore old student state
							if(oldStudent) {
								[[SQUGradeManager sharedInstance] setStudent:oldStudent];
								[[SQUDistrictManager sharedInstance] selectDistrictWithID:oldStudent.district.integerValue];
							}
							
							[[NSNotificationCenter defaultCenter] postNotificationName:SQUGradesDataUpdatedNotification object:nil];
							[[NSNotificationCenter defaultCenter] postNotificationName:SQUStudentsUpdatedNotification object:nil];
							
							// Dismiss login view
							[self_unsafe dismissViewControllerAnimated:YES completion:NO];
						} else {
							// Delete students added to the DB
							for(SQUStudent *studentToDelete in self_unsafe.students) {
								[[SQUPersistence sharedInstance].managedObjectContext deleteObject:studentToDelete];
							}
							
							[[SQUPersistence sharedInstance] saveContext];
							
							[SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Error", nil)];
							
							UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error Fetching Grades", nil) message:error.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
							[alert show];
						}
					}];
				};
				
				// Bring up a student selector if multistudent account and no students yet
				if([SQUDistrictManager sharedInstance].currentDistrict.hasMultipleStudents && !oldStudent) {
					[SVProgressHUD dismiss];
					
					SQULoginStudentPicker *picker = [[SQULoginStudentPicker alloc] initWithStyle:UITableViewStyleGrouped];
					picker.students = _students;
					picker.delegate = self;
					UINavigationController *navCtrlr = [[UINavigationController alloc] initWithRootViewController:picker];
					navCtrlr.modalPresentationStyle = UIModalPresentationFormSheet;
					
					[self.navigationController presentViewController:navCtrlr animated:YES completion:NULL];
				} else if(![SQUDistrictManager sharedInstance].currentDistrict.hasMultipleStudents && !oldStudent) {
					_studentLoginFunction();
				} else {
					// If students already exist, don't show a picker
					[SVProgressHUD dismiss];
					[self dismissViewControllerAnimated:YES completion:NULL];
				}				
			}
		} else {
			// Login error
			[SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Error", nil)];
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error Logging In", nil) message:error.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
			[alert show];
		}
	}];
}

#pragma mark - Student selector
- (void) studentPickerCancelled:(SQULoginStudentPicker *) picker {
	// Delete students added to the DB
	for(SQUStudent *studentToDelete in _students) {
		[[SQUPersistence sharedInstance].managedObjectContext deleteObject:studentToDelete];
	}
	[[SQUPersistence sharedInstance] saveContext];
	
	[self.navigationController dismissViewControllerAnimated:YES completion:NULL];
}

- (void) studentPickerDidSelect:(SQULoginStudentPicker *) picker withStudent:(SQUStudent *) student {
	[[SQUGradeManager sharedInstance] setStudent:student];
	
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
	
	if(selectedStudent != NSNotFound) {
		// Only update selection if there's no other students in the database
		if(students.count == _students.count) {
			[[SQUGradeManager sharedInstance] changeSelectedStudent:student];
		}
	} else {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Database Error", nil) message:NSLocalizedString(@"Something happened.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
		[alert show];
		return;
	}
	
	[self.navigationController dismissViewControllerAnimated:YES completion:NULL];
	
	// Log in with this student.
	_studentLoginFunction();
}

#pragma mark - DB Interfacing
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

#pragma mark - District selection
- (void) showDistrictSelector:(id) sender {
	UIPickerView *picker = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 0, 320, 216)];
	picker.dataSource = self;
	picker.delegate = self;
	[picker selectRow:_selectedDistrict inComponent:0 animated:NO];
	
	UIViewController *controller = [[UIViewController alloc] init];
	controller.view = picker;
	controller.preferredContentSize = CGSizeMake(320, 216);
	
	_changeDistrictPopover = [[UIPopoverController alloc] initWithContentViewController:controller];
	[_changeDistrictPopover presentPopoverFromRect:CGRectMake(0, - 8, 48, 48) inView:sender permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

- (NSInteger) numberOfComponentsInPickerView:(UIPickerView *) pickerView {
	return 1;
}

- (NSInteger) pickerView:(UIPickerView *) pickerView numberOfRowsInComponent:(NSInteger) component {
	NSUInteger count = [[SQUDistrictManager sharedInstance] loadedDistricts].count;
	return (!_district) ? count+1 : count;
}

- (NSString *) pickerView:(UIPickerView *) pickerView titleForRow:(NSInteger) row forComponent:(NSInteger) component {
	if(!_district) {
		if(row == 0) {
			return NSLocalizedString(@"Select District…", nil);
		} else {
			return [(SQUDistrict *) [[SQUDistrictManager sharedInstance] loadedDistricts][row-1] name];
		}
	} else {
		return [(SQUDistrict *) [[SQUDistrictManager sharedInstance] loadedDistricts][row] name];
	}
}

- (void) pickerView:(UIPickerView *) pickerView didSelectRow:(NSInteger) row inComponent:(NSInteger) component {
	NSUInteger index = row;
	
	if(!_district) {
		if(row == 0) {
			return;
		}
		
		index--;
	}
	
	_selectedDistrict = index;
	_district = [[SQUDistrictManager sharedInstance] loadedDistricts][_selectedDistrict];
	_currentDistrictLabel.string = [(SQUDistrict *) [[SQUDistrictManager sharedInstance] loadedDistricts][_selectedDistrict] name];
	
	[pickerView reloadAllComponents];
	[pickerView selectRow:[[[SQUDistrictManager sharedInstance] loadedDistricts] indexOfObject:_district] inComponent:0 animated:NO];
}

#pragma mark - Miscellaneous UI
- (UIStatusBarStyle) preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

@end
