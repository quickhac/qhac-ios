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
    _authFieldTable = [[UITableView alloc] initWithFrame:CGRectMake(0, 220, 304, 150) style:UITableViewStylePlain];

    
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
    return 3;
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
    } else if(indexPath.row == 2) {
        _textView.secureTextEntry = YES;
        _textView.returnKeyType = UIReturnKeyDone;
        
        _textView.adjustsFontSizeToFitWidth = YES;
        _textView.minimumFontSize = 12;
        
        _textView.placeholder = NSLocalizedString(@"Password", @"login view controller placeholder");
        
        _passField = _textView;
    } else if(indexPath.row == 1) {
        _textView.keyboardType = UIKeyboardTypeNumberPad;
        _textView.returnKeyType = UIReturnKeyNext;
        
        _textView.adjustsFontSizeToFitWidth = YES;
        _textView.minimumFontSize = 12;
        
        _textView.placeholder = NSLocalizedString(@"Student ID", @"login view controller placeholder");
        
        _sidField = _textView;
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
        [_sidField becomeFirstResponder];
        return YES;
    } else if(path.row == 1) {
        [_passField becomeFirstResponder];
        return YES;        
    } else if(path.row == 2) {        
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
	
	// Handle length validation of the Student ID
	if(_district.studentIDLength.length == _district.studentIDLength.location) {
		if(_sidField.text.length != _district.studentIDLength.length) {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Invalid Student ID", nil) message:[NSString stringWithFormat:NSLocalizedString(@"Please enter a valid student ID, consisting of %u consecutive digits.", nil), _district.studentIDLength.length] delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
			[alert show];
			
			return;
		}
	} else {
		// at least _district.studentIDLength.location to at most _district.studentIDLength.length
		if(!(_sidField.text.length >= _district.studentIDLength.location) || !(_sidField.text.length <= _district.studentIDLength.length)) {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Invalid Student ID", nil) message:[NSString stringWithFormat:NSLocalizedString(@"Please enter a valid student ID between %u and %u characters in length.", nil), _district.studentIDLength.location, _district.studentIDLength.length] delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
			[alert show];
			
			return;
		}
	}
    
	// See if a student with this HAC username and ID exists
	NSManagedObjectContext *context = [[SQUAppDelegate sharedDelegate] managedObjectContext];
	NSError *db_err = nil;
	
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"SQUStudent" inManagedObjectContext:context];
	[fetchRequest setEntity:entity];
	NSArray *students = [context executeFetchRequest:fetchRequest error:&db_err];
	
	if(db_err) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Database Error", nil) message:db_err.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
		[alert show];
	}
	
	for(SQUStudent *student in students) {
		if([student.hacUsername isEqualToString:_emailField.text] && [student.student_id isEqualToString:_sidField.text]) {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Student Exists", nil) message:NSLocalizedString(@"A student with the same student ID and username as you are trying to add already exists.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
			[alert show];
			
			return;
		}
	}
	
    [SVProgressHUD showProgress:-1 status:NSLocalizedString(@"Logging In…", nil) maskType:SVProgressHUDMaskTypeGradient];
    
	// Ask the current district instance to do a log in
	[[SQUDistrictManager sharedInstance] performLoginRequestWithUser:_emailField.text usingPassword:_passField.text andCallback:^(NSError *error, id returnData){
		if(!error) {
			if(!returnData) {
				[SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Wrong Credentials", nil)];
			} else {
				[SVProgressHUD showProgress:-1 status:NSLocalizedString(@"Updating Grades…", nil) maskType:SVProgressHUDMaskTypeGradient];
				
				// returnData contains student info. (user, pass, id)
				NSMutableDictionary *returnInfo = (NSMutableDictionary *) returnData;
				returnInfo[@"sid"] = _sidField.text;
				
				// Store the username's password in the keychain
				[Lockbox setString:returnInfo[@"password"] forKey:returnInfo[@"username"]];
				
				// Insert an SQUStudent object into the database
				NSManagedObjectContext *context = [[SQUAppDelegate sharedDelegate] managedObjectContext];
				SQUStudent *studentInfo = [NSEntityDescription insertNewObjectForEntityForName:@"SQUStudent" inManagedObjectContext:context];
				
				// Set up student ID and district to database
				studentInfo.student_id = returnInfo[@"sid"];
				studentInfo.district = [NSNumber numberWithInteger:_district.district_id];
				studentInfo.hacUsername = returnInfo[@"username"];
				
				// Back up the old student as we need a temporary switch to retrieve data
				SQUStudent *oldStudent = [SQUGradeManager sharedInstance].student;
				
				// Set student and district class to fetch grades
				[[SQUGradeManager sharedInstance] setStudent:studentInfo];
				[[SQUDistrictManager sharedInstance] selectDistrictWithID:_district.district_id];
				
				// Now, try to update the grades
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
						}
						
						[[NSNotificationCenter defaultCenter] postNotificationName:SQUStudentsUpdatedNotification object:nil];
						
						// Dismiss login view
						[self dismissViewControllerAnimated:YES completion:NO];
					} else {
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

@end
