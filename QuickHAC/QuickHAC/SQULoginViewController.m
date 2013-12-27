//
//  SQULoginViewController.m
//  QuickHAC
//
//  Created by Tristan Seifert on 05/07/2013.
//  See README.MD for licensing and copyright information.
//  See README file for license information.
//

#import "SQULoginViewController.h"
#import "SVProgressHUD.h"
#import "SQUAppDelegate.h"
#import "SQUDistrict.h"
#import "SQUDistrictManager.h"
#import "SQUHACInterface.h"
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
    if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        _authFieldTable = [[UITableView alloc] initWithFrame:CGRectMake(-16, 220, 336, 150) style:UITableViewStylePlain];
    } else {
        _authFieldTable = [[UITableView alloc] initWithFrame:CGRectMake(0, 216, 320, 150) style:UITableViewStyleGrouped];
    }
    
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
        
        if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
            _qLogo.frame = CGRectMake(12, 68, 64, 64);
        } else {
            _qLogo.frame = CGRectMake(12, 12, 74, 74);
        }
    } completion:^(BOOL finished) { }];
}

- (void) moveTableDown {
    _tableMovedAlready = NO;
    
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationCurveEaseInOut animations:^{
        CGRect tempFrame = _authFieldTable.frame;
        tempFrame.origin.y += 88;
        _authFieldTable.frame = tempFrame;
        
        if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
            _qLogo.frame = CGRectMake(160 - (140 / 2), 70, 140, 140);
        } else {
            _qLogo.frame = CGRectMake(160 - (140 / 2), 60, 140, 140);
        }
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
    } else if(_sidField.text.length != 6) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Invalid Student ID", nil) message:NSLocalizedString(@"Please enter a valid student ID, consisting of six consecutive digits.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
        [alert show];
        
        return;
    }
    
    [SVProgressHUD showProgress:-1 status:NSLocalizedString(@"Logging In…", nil) maskType:SVProgressHUDMaskTypeGradient];
    
	// Ask the current district instance to do a log in
	[[SQUDistrictManager sharedInstance] performLoginRequestWithUser:_emailField.text usingPassword:_passField.text andCallback:^(NSError *error, id returnData){
		if(!error) {
			if(!returnData) {
				[SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Wrong Credentials", nil)];
			} else {
				[SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"Logged In", nil)];
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
				
				// Save info to database
				NSError *db_err = nil;
				if (![context save:&db_err]) {
					UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error Storing Information", nil) message:db_err.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
					[alert show];
					
					NSLog(@"Couldn't save database: %@", [db_err localizedDescription]);
					return;
				}
				
				[[NSUserDefaults standardUserDefaults] synchronize];

				
				// Dismiss this view and go to the grade overview
				[self dismissViewControllerAnimated:YES completion:NO];
			}
		} else {
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Error", nil)];
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error Authenticating", nil) message:error.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
            [alert show];
		}
	}];
	
    /*[[SQUHACInterface sharedInstance] performLoginWithUser:_emailField.text andPassword:_passField.text andSID:_sidField.text callback:^(NSError *error, id returnData){
        if(!error) {
            NSString *sessionID = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
            
            NSLog(@"Session key: %@", sessionID);
            
            [SVProgressHUD showProgress:-1 status:NSLocalizedString(@"Checking Session…", nil) maskType:SVProgressHUDMaskTypeGradient];
            
            [[SQUHACInterface sharedInstance] getGradesURLWithBlob:sessionID callback:^(NSError *err, id data) {
                NSString *gradeURL = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                
                // TODO: Eval regex to check for the link: /id=([\w\d%]*)/.
                if([gradeURL rangeOfString:@"Server Error in '/HomeAccess' Application." options: NSCaseInsensitiveSearch].location == NSNotFound) {
                    NSLog(@"Grades URL value: %@", gradeURL);
                    
                    if(![Lockbox setString:sessionID forKey:@"sessionKey"]) {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error Saving Credentials", nil) message:[NSString stringWithFormat:NSLocalizedString(@"The session key could not be saved due to a Keychain Services error. (%i)", nil), error] delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
                        [alert show];
                        
                        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Error", nil)];
                        return;
                    }
                    
                    if(![Lockbox setString:_passField.text forKey:@"accountPassword"] || ![Lockbox setString:_emailField.text forKey:@"accountEmail"]) {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error Saving Credentials", nil) message:[NSString stringWithFormat:NSLocalizedString(@"The username and password could not be saved due to a Keychain Services error. (%i)", nil), error] delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
                        [alert show];
                        
                        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Error", nil)];
                        return;
                    }
                    
                    [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"Logged In", nil)];
                    
                    [self dismissViewControllerAnimated:YES completion:NO];
                    
                    // Save some information about the user in the database
                    NSManagedObjectContext *context = [[SQUAppDelegate sharedDelegate] managedObjectContext];
                    SQUStudent *studentInfo = [NSEntityDescription insertNewObjectForEntityForName:@"SQUStudent" inManagedObjectContext:context];
                    studentInfo.student_id = _sidField.text;
                    studentInfo.district = [NSNumber numberWithInt:_district];
                    
                    // Save info to database
                    NSError *db_err = nil;
                    if (![context save:&db_err]) {
                        NSLog(@"Couldn't save database: %@", [db_err localizedDescription]);
                    }
                    
                    [[NSUserDefaults standardUserDefaults] synchronize];
                } else {
                    NSLog(@"Login failed");
                    [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Wrong Credentials", nil)];
                    
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error Authenticating", nil) message:NSLocalizedString(@"Please check your username, password and student ID and try again.", @"login controller") delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
                    [alert show];
                }
                
            }];
        } else {
            NSLog(@"Auth error: %@", error);
            
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Error", nil)];
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error Authenticating", nil) message:error.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
            [alert show];
        }
    }];*/
}

#pragma mark - View Controller Shenanigans
- (NSUInteger) supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationPortraitUpsideDown;
}

- (BOOL) shouldAutorotate {
    return YES;
}

@end
