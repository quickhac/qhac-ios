//
//  SQULoginViewController.m
//  QuickHAC
//
//  Created by Tristan Seifert on 05/07/2013.
//  Copyright (c) 2013 Squee! Apps. All rights reserved.
//

#import "SQULoginViewController.h"
#import "SQUHACInterface.h"
#import "SVProgressHUD.h"

@interface SQULoginViewController ()

@end

@implementation SQULoginViewController

- (void) viewDidLoad {
    [super viewDidLoad];
    
    // Set up QuickHAC "q" logo
    _qLogo = [CALayer layer];
    _qLogo.frame = CGRectMake(160 - (150 / 2), 32, 150, 150);
    _qLogo.contents = (__bridge id)([UIImage imageNamed:@"QuickHACIcon"].CGImage);
    
    [self.view.layer addSublayer:_qLogo];

    _qText = [CATextLayer layer];
    _qText.font = (__bridge CFTypeRef)([UIFont boldSystemFontOfSize:50.0]);
    _qText.foregroundColor = [UIColor blackColor].CGColor;
    _qText.string = NSLocalizedString(@"QuickHAC", @"login screen");
    _qText.frame = CGRectMake(0, 190, 320, 50);
    _qText.alignmentMode = kCAAlignmentCenter;
    _qText.contentsScale = [UIScreen mainScreen].scale;
    
    [self.view.layer addSublayer:_qText];
    
    self.title = NSLocalizedString(@"Log In", nil);
    self.navigationController.navigationBarHidden = YES;
    
    // set up login fields
    if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        _authFieldTable = [[UITableView alloc] initWithFrame:CGRectMake(-16, 240, 336, 198) style:UITableViewStylePlain];
    } else {
        _authFieldTable = [[UITableView alloc] initWithFrame:CGRectMake(0, 240, 320, 198) style:UITableViewStyleGrouped];
    }
    
    _authFieldTable.delegate = self;
    _authFieldTable.dataSource = self;
    _authFieldTable.backgroundColor = [UIColor clearColor];
    _authFieldTable.backgroundView = nil;
    _authFieldTable.bounces = NO;
    
    // iOS 7 specific stuff
    if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
    //    _authFieldTable.contentOffset = CGPointMake(0, 0);
    //    _authFieldTable.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    }
    
    [_authFieldTable registerClass:[UITableViewCell class] forCellReuseIdentifier:@"LoginCell"];
    
    [self.view addSubview:_authFieldTable];
    
    _tableMovedAlready = NO;
}

- (void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table View
- (UIView *) tableView:(UITableView *) tableView viewForFooterInSection:(NSInteger) section {
    return _loginButtonContainer;
}
    
- (CGFloat) tableView:(UITableView *) tableView heightForFooterInSection:(NSInteger) section {
    return _loginButtonContainer.frame.size.height;
}

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
        tempFrame.origin.y -= 145;
        _authFieldTable.frame = tempFrame;
        
/*        _loginButton.alpha = 0.0f;
        _loginButton.userInteractionEnabled = NO;*/
        
        if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
            _qLogo.frame = CGRectMake(12, 32, 64, 64);
            _qText.frame = CGRectMake(86, 39, 234, 50);
        } else {
            _qLogo.frame = CGRectMake(12, 12, 64, 64);
        }
    } completion:^(BOOL finished) { }];
}

- (void) moveTableDown {
    _tableMovedAlready = NO;
    
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationCurveEaseInOut animations:^{
        CGRect tempFrame = _authFieldTable.frame;
        tempFrame.origin.y += 145;
        _authFieldTable.frame = tempFrame;
        
/*        _loginButton.alpha = 1.0f;
        _loginButton.userInteractionEnabled = YES;*/
        
        if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
            _qLogo.frame = CGRectMake(160 - (150 / 2), 32, 150, 150);
            _qText.frame = CGRectMake(0, 190, 320, 50);
        } else {
            _qLogo.frame = CGRectMake(160 - (150 / 2), 12, 150, 150);
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
                
                if([gradeURL rangeOfString:@"Server Error in '/HomeAccess' Application." options: NSCaseInsensitiveSearch].location == NSNotFound) {
                    NSLog(@"Grades URL: %@", gradeURL);
                } else {
                    NSLog(@"Login apparently failed");
                }
                
                // Stick session ID into keychain
                /*NSMutableDictionary *query = [NSMutableDictionary dictionary];
                [query setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
                [query setObject:@"session_key" forKey:(__bridge id)kSecAttrAccount];
                [query setObject:(__bridge id)kSecAttrAccessibleWhenUnlocked forKey:(__bridge id)kSecAttrAccessible];
                [query setObject:[sessionID dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id)kSecValueData];
                
                OSStatus error = SecItemAdd((__bridge CFDictionaryRef) query, NULL);
                
                if(error != errSecSuccess) {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error Saving Credentials", nil) message:[NSString stringWithFormat:NSLocalizedString(@"The session key could not be saved due to a Keychain Services error. (%i)", nil), error] delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
                    [alert show];
                }*/
                
                [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"Logged In", nil)];
            }];
        } else {
            NSLog(@"Auth error: %@", error);
            
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Error", nil)];
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error Authenticating", nil) message:error.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
            [alert show];
        }
    }];
}

@end
