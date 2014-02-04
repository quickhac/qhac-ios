//
//  SQUSettingsViewController.m
//  QuickHAC
//
//  Created by Tristan Seifert on 12/29/13.
//  See README.MD for licensing and copyright information.
//

#import "SQUSettingsStudents.h"
#import "LTHPasscodeViewController.h"
#import "Testflight.h"
#import "SQUCoreData.h"
#import "SQUGradeManager.h"
#import "SQUDistrictManager.h"
#import "SQUSettingsGeneralController.h"
#import "SQUSettingsViewController.h"

#import <QuickDialog.h>
#import <PKRevealController.h>

#define kSQUSettingsPasscode 4211

@interface SQUSettingsViewController ()

@end

@implementation SQUSettingsViewController

- (id) initWithStyle:(UITableViewStyle)style {
	self = [super initWithStyle:UITableViewStyleGrouped];
	
	if(self) {
		[self.tableView registerClass:NSClassFromString(@"UITableViewCell") forCellReuseIdentifier:@"SettingsCell"];
		self.title = NSLocalizedString(@"Settings", nil);
	}
	
	return self;
}

- (void) viewDidLoad {
	// Add the sidebar button.
	UIBarButtonItem *doneButton = [[UIBarButtonItem alloc]
									initWithBarButtonSystemItem:UIBarButtonSystemItemDone
									target:self
									action:@selector(closeModal:)];
	self.navigationItem.leftBarButtonItem = doneButton;
}

#pragma mark - Table view data source

- (NSInteger) numberOfSectionsInTableView:(UITableView *) tableView {
    // Return the number of sections.
    return 2; // 3 if beta
}

- (NSInteger) tableView:(UITableView *) tableView numberOfRowsInSection:(NSInteger) section {
    // Return the number of rows in the section.
	switch(section) {
		case 0:
			return 2; 
			break;
			
		case 1:
			return 2; // about, acknowledgements
			break;
			
		case 2:
			return 1; // beta
			break;
			
		default:
			return 0;
			break;
	}
}

- (UITableViewCell *) tableView:(UITableView *) tableView cellForRowAtIndexPath:(NSIndexPath *) indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SettingsCell" forIndexPath:indexPath];
	
	if(indexPath.section == 0) {
		NSArray *titles = @[NSLocalizedString(@"General", @"settings"), NSLocalizedString(@"Students", @"settings"), NSLocalizedString(@"Security", @"settings"), NSLocalizedString(@"Import & Export", @"settings")];
		cell.textLabel.text = titles[indexPath.row];
		
		NSArray *iconImage = @[@"settings_icon_general", @"settings_icon_students", @"settings_icon_security", @"settings_icon_import"];
		
		cell.imageView.image = [UIImage imageNamed:iconImage[indexPath.row]];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	} else if(indexPath.section == 1) {
		NSArray *titles = @[NSLocalizedString(@"About QuickHAC…", @"settings"), NSLocalizedString(@"Acknowledgements", @"settings")];
		cell.textLabel.text = titles[indexPath.row];
		
		cell.imageView.image = nil;
		cell.accessoryType = UITableViewCellAccessoryNone;
	} else {
		cell.textLabel.text = @"BetaTest feedback";
	}
	
    return cell;
}

#pragma mark - Navigation
- (void) tableView:(UITableView *) tableView didSelectRowAtIndexPath:(NSIndexPath *) indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	switch(indexPath.section) {
		case 0:
			switch(indexPath.row) {
				case 0: {
					SQUSettingsGeneralController *generalSettings = [[SQUSettingsGeneralController alloc] init];
					[self.navigationController pushViewController:generalSettings animated:YES];
					
					break;
				}
					
				// Students
				case 1: {
					SQUSettingsStudents *setting = [[SQUSettingsStudents alloc] initWithStyle:UITableViewStyleGrouped];
					if(setting) {
						[self.navigationController pushViewController:setting animated:YES];
					}
					break;
				}
					
				// Security
			/*	case 2: {
					if([[NSUserDefaults standardUserDefaults] boolForKey:@"passcodeEnabled"]) {
						UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Passcode", nil) message:NSLocalizedString(@"You currently have a passcode set up for QuickHAC on this device.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"Change", nil), NSLocalizedString(@"Disable", nil), nil];
						alert.tag = kSQUSettingsPasscode;
						[alert show];
					} else {
						UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Passcode", nil) message:NSLocalizedString(@"You do not have a passcode set up.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"Set Up", nil), nil];
						alert.tag = kSQUSettingsPasscode;
						[alert show];
					}
					
					break;
				}*/
					
				default: {
					UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"Settings have not yet been implemented." delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
					[alert show];
					
					NSLog(@"Selected unhandled settings: (%u, %u)", indexPath.row, indexPath.section);
					break;
				}
			}
			break;
			
		case 1: {
			if(indexPath.row == 0) {
				UIViewController *controller = [[UIViewController alloc] init];
				controller.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeModal:)];
				controller.title = NSLocalizedString(@"About QuickHAC", @"settings");
				
				UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
				textView.editable = NO;
				controller.view = textView;
				
				NSURL *urlOfRTF = [[NSBundle mainBundle] URLForResource:@"about" withExtension:@"rtfd"];
				NSAttributedString *attrString = [[NSAttributedString alloc] initWithFileURL:urlOfRTF options:@{NSDocumentTypeDocumentAttribute:NSRTFDTextDocumentType} documentAttributes:nil error:nil];
				textView.attributedText = attrString;
				
				[self presentViewController:[[UINavigationController alloc] initWithRootViewController:controller] animated:YES completion:NULL];
			} else if(indexPath.row == 1) {
				UIViewController *controller = [[UIViewController alloc] init];
				controller.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeModal:)];
				controller.title = NSLocalizedString(@"Acknowledgements", @"settings");
				
				UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
				textView.editable = NO;
				controller.view = textView;
				
				NSURL *urlOfRTF = [[NSBundle mainBundle] URLForResource:@"acknowledgements" withExtension:@"rtf"];
				NSAttributedString *attrString = [[NSAttributedString alloc] initWithFileURL:urlOfRTF options:@{NSDocumentTypeDocumentAttribute:NSRTFTextDocumentType} documentAttributes:nil error:nil];
				textView.attributedText = attrString;
				
				[self presentViewController:[[UINavigationController alloc] initWithRootViewController:controller] animated:YES completion:NULL];
			}
			
			break;
		}
			
		case 2: {
			// Show testflight
			UIViewController *controller = [[UIViewController alloc] init];
			controller.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(submitFeedback:)];
			controller.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(closeModal:)];
			controller.title = NSLocalizedString(@"Feedback", @"settings");
			
			_feedbackView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
			controller.view = _feedbackView;
			
			[self presentViewController:[[UINavigationController alloc] initWithRootViewController:controller] animated:YES completion:NULL];
			
			break;
		}
			
		default:
			NSLog(@"Selected unhandled settings: (%u, %u)", indexPath.row, indexPath.section);
			break;
	}
}

/**
 * This method is overridden to allow us to have a custom footer in the table.
 */
- (NSString *) tableView:(UITableView *) tableView titleForFooterInSection:(NSInteger) section {
	if(section == 1) {
		NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
		NSString *build = info[@"CFBundleVersion"];
		NSString *version = info[@"CFBundleShortVersionString"];
		
		return [NSString stringWithFormat:NSLocalizedString(@"QuickHAC Version %@ (build %@)", @"settings footer"), version, build];
	}
	
	return nil;
}

#pragma mark - UI callbacks
- (void) closeModal:(id) sender {
	[self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - Passcode alert
- (void)alertView:(UIAlertView *) alertView clickedButtonAtIndex:(NSInteger) buttonIndex {
	if(alertView.tag == kSQUSettingsPasscode) {
		if([[NSUserDefaults standardUserDefaults] boolForKey:@"passcodeEnabled"]) {
			
		} else {
			// Enable passcode
			NSLog(@"Button: %u", buttonIndex);
			
			if(buttonIndex == 1) {
				[[LTHPasscodeViewController sharedUser] setDelegate:self];
				[[LTHPasscodeViewController sharedUser] showForEnablingPasscodeInViewController:self];
			}
		}
	}
}

- (void) passcodeViewControllerWasDismissed {
	NSLog(@"Dismissed passcode view");
}

- (void)passcodeWasEnteredSuccessfully {
	NSLog(@"Passcode entered successful !!!");
}

#ifdef DEBUG
- (void) submitFeedback:(id) sender {
	[TestFlight submitFeedback:_feedbackView.text];
	[self dismissViewControllerAnimated:YES completion:NULL];
}
#endif

@end
