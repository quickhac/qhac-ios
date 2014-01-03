//
//  SQULoginViewController.m
//  QuickHAC
//
//  Created by Tristan Seifert on 05/07/2013.
//  See README.MD for licensing and copyright information.
//

#import "SQULoginViewController.h"
#import "SVProgressHUD.h"
#import "SQUAppDelegate.h"
#import "SQUDistrict.h"
#import "SQUGradeManager.h"
#import "SQUDistrictManager.h"
#import "SQUCoreData.h"

// seriously, I thought I could handle the Keychain APIs but nope.avi
#import "Lockbox.h"

@interface SQULoginViewController ()

- (BOOL) studentExistsWithID:(NSString *) dasID;
- (BOOL) studentExistsWithUser:(NSString *) user;

@end

@implementation SQULoginViewController
@synthesize district = _district;

- (void) viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    // Set up QuickHAC "q" logo
    _qLogo = [CALayer layer];
    _qLogo.frame = CGRectMake(160 - (140 / 2), 70, 140, 140);
    _qLogo.contents = (__bridge id)([UIImage imageNamed:@"QuickHACIcon"].CGImage);
    
    [self.view.layer addSublayer:_qLogo];
    
    // Set up the selected district and changing link
    _districtSelected = [CATextLayer layer];
    _districtSelected.fontSize = 14;
    _districtSelected.contentsScale = [UIScreen mainScreen].scale;
    _districtSelected.alignmentMode = kCAAlignmentCenter;
    _districtSelected.frame = CGRectMake(16, 370, (320 - 32), 18);
    _districtSelected.string = [NSString stringWithFormat:NSLocalizedString(@"You selected %@.", nil), _district.name];
    _districtSelected.foregroundColor = [UIColor grayColor].CGColor;
    
    [self.view.layer addSublayer:_districtSelected];
    
    _changeDistrictLink = [UIButton buttonWithType:UIButtonTypeCustom];
    
    NSMutableAttributedString *changeDistrictTitle = [[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@"Change District", nil) attributes:nil];
    [changeDistrictTitle addAttribute:(__bridge NSString *) kCTUnderlineStyleAttributeName value:[NSNumber numberWithInteger:kCTUnderlineStyleSingle] range:NSMakeRange(0, changeDistrictTitle.length)];
    [changeDistrictTitle addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:14.0f] range:NSMakeRange(0, changeDistrictTitle.length)];
    [changeDistrictTitle addAttribute:NSForegroundColorAttributeName value:[UIColor grayColor] range:NSMakeRange(0, changeDistrictTitle.length)];
    [_changeDistrictLink setAttributedTitle:changeDistrictTitle forState:UIControlStateNormal];
    
    [_changeDistrictLink addTarget:self action:@selector(changeDistrictSelection:) forControlEvents:UIControlEventTouchUpInside];
    _changeDistrictLink.frame = CGRectMake((160 - 50), _districtSelected.frame.origin.y + 24, 100, 18);
    
    [self.view addSubview:_changeDistrictLink];
    
    // set up login fields
    _authFieldTable = [[UITableView alloc] initWithFrame:CGRectMake(0, 220, 304, 100) style:UITableViewStylePlain];
	
    _authFieldTable.delegate = self;
    _authFieldTable.dataSource = self;
    _authFieldTable.backgroundColor = [UIColor clearColor];
    _authFieldTable.backgroundView = nil;
    _authFieldTable.bounces = NO;
    
    [_authFieldTable registerClass:[UITableViewCell class] forCellReuseIdentifier:@"LoginCell"];
    
    [self.view addSubview:_authFieldTable];
    
    _tableMovedAlready = NO;
    
    // set up navbar state
    self.title = NSLocalizedString(@"QuickHAC", @"login screen");
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                              initWithTitle:NSLocalizedString(@"Log In", @"login screen")
                                              style:UIBarButtonItemStyleDone
                                              target:self action:@selector(loginBarButtonItemPressed:)];
	
	// Set up district interfacing
	[SQUDistrictManager sharedInstance].currentDistrict = _district;
}

- (void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    
    UITextField *_textView = [[UITextField alloc] initWithFrame:CGRectMake(12+16, 9, cell.frame.size.width - 24 - 14 - 16, cell.frame.size.height - 17)];
    _textView.delegate = self;
    [cell.contentView addSubview:_textView];
    
    if(indexPath.row == 0) {
        _textView.autocorrectionType = UITextAutocorrectionTypeNo;
        _textView.autocapitalizationType = UITextAutocapitalizationTypeNone;
        
        _textView.keyboardType = UIKeyboardTypeEmailAddress;
        _textView.returnKeyType = UIReturnKeyNext;
        
        _textView.adjustsFontSizeToFitWidth = YES;
        _textView.minimumFontSize = 12;
        
        _textView.placeholder = NSLocalizedString(@"Username", @"login view controller placeholder");
        
        _emailField = _textView;
    } else if(indexPath.row == 1) {
        _textView.secureTextEntry = YES;
        _textView.returnKeyType = UIReturnKeyDone;
        
        _textView.adjustsFontSizeToFitWidth = YES;
        _textView.minimumFontSize = 12;
        
        _textView.placeholder = NSLocalizedString(@"Password", @"login view controller placeholder");
        
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

- (BOOL) textFieldShouldReturn:(UITextField *) textField {
    NSIndexPath *path;
    
    if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        //        NSLog(@"%@", textField.superview.superview.superview);
        path = [_authFieldTable indexPathForCell:(UITableViewCell*)textField.superview.superview.superview];
    } else {
        path = [_authFieldTable indexPathForCell:(UITableViewCell*)textField.superview.superview];
    }
    
    if(path.row == 0) {
        [_passField becomeFirstResponder];
        return YES;
    } else if(path.row == 1) {
        [textField resignFirstResponder];
        [self moveTableDown];
        [self performAuthentication:textField];
        _selectedTableTextField = nil;
        return YES;
    } else {
        return YES;
    }
}

- (void) moveTableUp {
    if(_tableMovedAlready) return;
    
    _tableMovedAlready = YES;
    
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationCurveEaseInOut animations:^{
        CGRect tempFrame = _authFieldTable.frame;
        tempFrame.origin.y -= 88;
        _authFieldTable.frame = tempFrame;
        
        _qLogo.frame = CGRectMake(12, 68, 64, 64);
    } completion:^(BOOL finished) { }];
}

- (void) moveTableDown {
    _tableMovedAlready = NO;
    
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationCurveEaseInOut animations:^{
        CGRect tempFrame = _authFieldTable.frame;
        tempFrame.origin.y += 88;
        _authFieldTable.frame = tempFrame;
        
        _qLogo.frame = CGRectMake(160 - (140 / 2), 70, 140, 140);
    } completion:^(BOOL finished) { }];
}

#pragma mark - Authentication
- (void) performAuthentication:(id) sender {
    if(_emailField.text.length == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Invalid Username", nil) message:NSLocalizedString(@"Please enter a valid username.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
        [alert show];
        
        return;
    } else if(_passField.text.length == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Invalid Password", nil) message:NSLocalizedString(@"Please enter a valid password.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
        [alert show];
        
        return;
    }
	
	// Do a login
    [SVProgressHUD showProgress:-1 status:NSLocalizedString(@"Logging In…", nil) maskType:SVProgressHUDMaskTypeGradient];
    
	NSMutableArray *students = [NSMutableArray new];
	
	// This block is called for every student that we must add.
	void (^addStudent)(NSDictionary *student) = ^(NSDictionary *student) {
		if(student) {
			NSString *studentID = student[@"id"];
			NSString *studentName = student[@"name"];
			
			if([self studentExistsWithID:studentID]) {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Student Exists", nil) message:NSLocalizedString(@"The student already exists.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
				[alert show];
			} else {
				NSManagedObjectContext *context = [[SQUAppDelegate sharedDelegate] managedObjectContext];
				SQUStudent *studentInfo = [NSEntityDescription insertNewObjectForEntityForName:@"SQUStudent" inManagedObjectContext:context];
				
				// Set up student ID and district to database
				studentInfo.student_id = studentID;
				studentInfo.district = [NSNumber numberWithInteger:_district.district_id];
				studentInfo.hacUsername = _emailField.text;
				studentInfo.name = studentName;
				
				[students addObject:studentInfo];
				
				[[SQUGradeManager sharedInstance] setStudent:studentInfo];
			}
		} else {
			// Single student account
			if([self studentExistsWithUser:_emailField.text]) {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Student Exists", nil) message:NSLocalizedString(@"The student already exists.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
				[alert show];
			} else {
				NSManagedObjectContext *context = [[SQUAppDelegate sharedDelegate] managedObjectContext];
				SQUStudent *studentInfo = [NSEntityDescription insertNewObjectForEntityForName:@"SQUStudent" inManagedObjectContext:context];
				
				// Set up student ID and district to database
				studentInfo.student_id = nil;
				studentInfo.district = [NSNumber numberWithInteger:_district.district_id];
				studentInfo.hacUsername = _emailField.text;
				
				[students addObject:studentInfo];
				
				[[SQUGradeManager sharedInstance] setStudent:studentInfo];
			}
		}
	};
	
	// Ask the current district instance to do a log in
	[[SQUDistrictManager sharedInstance] performLoginRequestWithUser:_emailField.text usingPassword:_passField.text andCallback:^(NSError *error, id returnData){
		if(!error) {
			if(!returnData) {
				[SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Wrong Credentials", nil)];
			} else {
				[SVProgressHUD showProgress:-1 status:NSLocalizedString(@"Adding students", nil) maskType:SVProgressHUDMaskTypeGradient];
				// Store the username's password in the keychain
				[Lockbox setString:_passField.text forKey:_emailField.text];

				// Back up the old student as we need a temporary switch to retrieve data
				SQUStudent *oldStudent = [SQUGradeManager sharedInstance].student;
				NSUInteger selectedStudent = [[NSUserDefaults standardUserDefaults] integerForKey:@"selectedStudent"];
				
				// If the account is single-student, add the student.
				if(![SQUDistrictManager sharedInstance].currentDistrict.hasMultipleStudents) {
					addStudent(nil);
				} else {
					for(NSDictionary *student in [SQUDistrictManager sharedInstance].currentDistrict.studentsOnAccount) {
						addStudent(student);
					}
				}
				
				// Set student and district class to fetch grades
				[[SQUDistrictManager sharedInstance] selectDistrictWithID:_district.district_id];
				
				// Save the database.
				[[SQUAppDelegate sharedDelegate] saveContext];
				
				// Update grades
				[SVProgressHUD showProgress:-1 status:NSLocalizedString(@"Updating Grades", nil) maskType:SVProgressHUDMaskTypeGradient];
				
				[[SQUGradeManager sharedInstance] fetchNewClassGradesFromServerWithDoneCallback:^(NSError *error) {
					if(!error) {
						[SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"Done", nil)];
						
						// Restore old student state
						if(oldStudent) {
							[[SQUGradeManager sharedInstance] setStudent:oldStudent];
							[[SQUDistrictManager sharedInstance] selectDistrictWithID:oldStudent.district.integerValue];
						} else {
							// If this is the first student logged in, update grades UI
							[[NSNotificationCenter defaultCenter] postNotificationName:SQUGradesDataUpdatedNotification object:nil];
							
							// Set the default student
							NSError *error = nil;
							NSFetchRequest *request = [[NSFetchRequest alloc] init];
							NSEntityDescription *entity = [NSEntityDescription entityForName:@"SQUStudent" inManagedObjectContext:[SQUAppDelegate sharedDelegate].managedObjectContext];
							[request setEntity:entity];
							NSUInteger numberOfStudents = [[SQUAppDelegate sharedDelegate].managedObjectContext countForFetchRequest:request error:&error];
							
							[[NSUserDefaults standardUserDefaults] setInteger:numberOfStudents-1 forKey:@"selectedStudent"];
							[[NSUserDefaults standardUserDefaults] synchronize];
						}
						
						[[NSNotificationCenter defaultCenter] postNotificationName:SQUStudentsUpdatedNotification object:nil];
						
						// Dismiss login view
						[self dismissViewControllerAnimated:YES completion:NO];
					} else {
						// Delete students added to the DB
						for(SQUStudent *studentToDelete in students) {
							[[SQUAppDelegate sharedDelegate].managedObjectContext delete:studentToDelete];
						}
						[[SQUAppDelegate sharedDelegate] saveContext];
						
						[SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Error", nil)];
						
						UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error Fetching Grades", nil) message:error.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
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
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"SQUStudent" inManagedObjectContext:[SQUAppDelegate sharedDelegate].managedObjectContext];
	[request setEntity:entity];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(student_id == %@)", dasID];
	[request setPredicate:predicate];
	
	return ([[SQUAppDelegate sharedDelegate].managedObjectContext countForFetchRequest:request error:&error] != 0);
}

- (BOOL) studentExistsWithUser:(NSString *) user {
	NSError *error = nil;
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"SQUStudent" inManagedObjectContext:[SQUAppDelegate sharedDelegate].managedObjectContext];
	[request setEntity:entity];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(hacUsername == %@)", user];
	[request setPredicate:predicate];
	
	return ([[SQUAppDelegate sharedDelegate].managedObjectContext countForFetchRequest:request error:&error] != 0);
}


@end
