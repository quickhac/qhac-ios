//
//  SQULoginViewController.m
//  QuickHAC
//
//  Created by Tristan Seifert on 05/07/2013.
//  Copyright (c) 2013 Squee! Apps. All rights reserved.
//  See README file for license information.
//

#import "SQULoginViewController.h"
#import "SVProgressHUD.h"

@interface SQULoginViewController ()

@end

@implementation SQULoginViewController
@synthesize district = _district;

- (void) viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    // Set up QuickHAC "q" logo
    _qLogo = [CALayer layer];
    _qLogo.frame = CGRectMake(160 - (140 / 2), 32, 140, 140);
    _qLogo.contents = (__bridge id)([UIImage imageNamed:@"QuickHACIcon"].CGImage);
    
    [self.view.layer addSublayer:_qLogo];

    _qText = [CATextLayer layer];
    _qText.font = (__bridge CFTypeRef)([UIFont boldSystemFontOfSize:50.0]);
    _qText.foregroundColor = [UIColor blackColor].CGColor;
    _qText.string = NSLocalizedString(@"QuickHAC", @"login screen");
    _qText.frame = CGRectMake(0, 170, 320, 50);
    _qText.alignmentMode = kCAAlignmentCenter;
    _qText.contentsScale = [UIScreen mainScreen].scale;
    
    [self.view.layer addSublayer:_qText];
    
    // Set up the selected district and changing link
    _districtSelected = [CATextLayer layer];
    _districtSelected.fontSize = 14;
    _districtSelected.contentsScale = [UIScreen mainScreen].scale;
    _districtSelected.alignmentMode = kCAAlignmentCenter;
    _districtSelected.frame = CGRectMake(16, 420, (320 - 32), 18);
    _districtSelected.string = [NSString stringWithFormat:NSLocalizedString(@"You selected %@.", nil), [SQUHACInterface schoolEnumToName:_district]];
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
    
    self.title = NSLocalizedString(@"Log In", nil);
    
    // set up login fields
    if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        _authFieldTable = [[UITableView alloc] initWithFrame:CGRectMake(-16, 210, 336, 150) style:UITableViewStylePlain];
    } else {
        _authFieldTable = [[UITableView alloc] initWithFrame:CGRectMake(0, 230, 320, 150) style:UITableViewStyleGrouped];
    }
    
    _authFieldTable.delegate = self;
    _authFieldTable.dataSource = self;
    _authFieldTable.backgroundColor = [UIColor clearColor];
    _authFieldTable.backgroundView = nil;
    _authFieldTable.bounces = NO;
    
    [_authFieldTable registerClass:[UITableViewCell class] forCellReuseIdentifier:@"LoginCell"];
    
    [self.view addSubview:_authFieldTable];
    
    _tableMovedAlready = NO;
}

- (void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Miscellaneous UI actions
- (void) changeDistrictSelection:(id) sender {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void) viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void) viewWillDisappear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:YES];
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
        NSLog(@"Second text field pressed done");
        
        [textField resignFirstResponder];
        [self moveTableDown];
        [self performAuthentication:textField];
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
        tempFrame.origin.y -= 100;
        _authFieldTable.frame = tempFrame;
        
/*        _loginButton.alpha = 0.0f;
        _loginButton.userInteractionEnabled = NO;*/
        
        if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
            _qLogo.frame = CGRectMake(12, 32, 74, 74);
            _qText.frame = CGRectMake(96, 44 , 224, 50);
        } else {
            _qLogo.frame = CGRectMake(12, 12, 74, 74);
            _qText.frame = CGRectMake(96, 19, 224, 50);
        }
    } completion:^(BOOL finished) { }];
}

- (void) moveTableDown {
    _tableMovedAlready = NO;
    
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationCurveEaseInOut animations:^{
        CGRect tempFrame = _authFieldTable.frame;
        tempFrame.origin.y += 100;
        _authFieldTable.frame = tempFrame;
        
/*        _loginButton.alpha = 1.0f;
        _loginButton.userInteractionEnabled = YES;*/
        
        if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
            _qLogo.frame = CGRectMake(160 - (140 / 2), 32, 140, 140);
            _qText.frame = CGRectMake(0, 170, 320, 50);
        } else {
            _qLogo.frame = CGRectMake(160 - (140 / 2), 22, 140, 140);
            _qText.frame = CGRectMake(0, 150, 320, 50);
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
    
    [[SQUHACInterface sharedInstance] performLoginWithUser:_emailField.text andPassword:_passField.text andSID:_sidField.text callback:^(NSError *error, id returnData){
        if(!error) {
            NSString *sessionID = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
            
            NSLog(@"Session key: %@", sessionID);
            
            [SVProgressHUD showProgress:-1 status:NSLocalizedString(@"Checking Session…", nil) maskType:SVProgressHUDMaskTypeGradient];
            
            [[SQUHACInterface sharedInstance] getGradesURLWithBlob:sessionID callback:^(NSError *err, id data) {
                NSString *gradeURL = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                
                NSLog(@"Grades URL value: %@", gradeURL);
                
                // TODO: Eval regex to check for the link: /id=([\w\d%]*)/.
                if([gradeURL rangeOfString:@"Server Error in '/HomeAccess' Application." options: NSCaseInsensitiveSearch].location == NSNotFound) {
                    NSLog(@"Grades URL value: %@", gradeURL);
                    
                    // Delete session ID if it exists
                    NSMutableDictionary *query = [NSMutableDictionary dictionary];
                    [query setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
                    [query setObject:@"session_key" forKey:(__bridge id)kSecAttrAccount];
                    
                    OSStatus error = SecItemDelete((__bridge CFDictionaryRef) query);
                    
                    query = [NSMutableDictionary dictionary];
                    [query setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
                    [query setObject:[@"co.squee.quickhac.account" dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id)kSecAttrGeneric];
                    
                    error = SecItemDelete((__bridge CFDictionaryRef) query);
                    
                    NSLog(@"Session key deletion error: %i", (int)error);
                    
                    // Stick session ID into keychain
                    query = [NSMutableDictionary dictionary];
                    [query setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
                     // Make the item be only accessible when the device is unlocked
                    [query setObject:(__bridge id)kSecAttrAccessibleWhenUnlocked forKey:(__bridge id)kSecAttrAccessible];
                    
                    [query setObject:@"session_key" forKey:(__bridge id)kSecAttrAccount];
                    // Store the session key as an UTF8-encoded string
                    [query setObject:[sessionID dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id)kSecValueData];
                    
                    error = SecItemAdd((__bridge CFDictionaryRef) query, NULL);
                    
                    if(error != errSecSuccess) {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error Saving Credentials", nil) message:[NSString stringWithFormat:NSLocalizedString(@"The session key could not be saved due to a Keychain Services error. (%i)", nil), error] delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
                        [alert show];
                        
                        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Error", nil)];
                        return;
                    }
                    
                    // Stick user/password combo into keychain
                    query = [NSMutableDictionary dictionary];
                    [query setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
                    [query setObject:(__bridge id)kSecAttrAccessibleWhenUnlocked forKey:(__bridge id)kSecAttrAccessible];
                    
                    [query setObject:_emailField.text forKey:(__bridge id)kSecAttrAccount];
                    [query setObject:[_passField.text dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id)kSecValueData];
                    [query setObject:[@"co.squee.quickhac.account" dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id)kSecAttrGeneric];
                    
                    error = SecItemAdd((__bridge CFDictionaryRef) query, NULL);
                    
                    if(error != errSecSuccess) {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error Saving Credentials", nil) message:[NSString stringWithFormat:NSLocalizedString(@"The username and password could not be saved due to a Keychain Services error. (%i)", nil), error] delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
                        [alert show];
                        
                        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Error", nil)];
                        return;
                    }
                    
                    // Shove the student ID in as well (not as sensitive, can live in user defaults)
                    [[NSUserDefaults standardUserDefaults] setObject:_sidField.text forKey:@"studentid"];
                    
                    [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"Logged In", nil)];
                    
                    [self dismissViewControllerAnimated:YES completion:NO];
                    
                    // Set authenticated flag and sync user defaults
                    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:@"authenticated"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                } else {
                    NSLog(@"Login failed");
                    [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Wrong Credentials", nil)];
                }
                
            }];
        } else {
            NSLog(@"Auth error: %@", error);
            
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
