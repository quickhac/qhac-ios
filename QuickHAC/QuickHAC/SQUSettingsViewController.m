//
//  SQUSettingsViewController.m
//  QuickHAC
//
//  Created by Tristan Seifert on 12/29/13.
//  See README.MD for licensing and copyright information.
//

#import "SQUSettingsStudents.h"

#import "SQUSettingsViewController.h"

#import <QuickDialog.h>
#import <PKRevealController.h>

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
	UIBarButtonItem *showSidebar = [[UIBarButtonItem alloc]
									initWithImage:[UIImage imageNamed:@"RevealSidebarIcon"]
									style:UIBarButtonItemStyleBordered
									target:self
									action:@selector(openSidebar:)];
	[self.navigationItem setLeftBarButtonItem:showSidebar];
}

#pragma mark - Table view data source

- (NSInteger) numberOfSectionsInTableView:(UITableView *) tableView {
    // Return the number of sections.
    return 2;
}

- (NSInteger) tableView:(UITableView *) tableView numberOfRowsInSection:(NSInteger) section {
    // Return the number of rows in the section.
	return (section == 0) ? 4 : 2;
}

- (UITableViewCell *) tableView:(UITableView *) tableView cellForRowAtIndexPath:(NSIndexPath *) indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SettingsCell" forIndexPath:indexPath];
	
	if(indexPath.section == 0) {
		NSArray *titles = @[NSLocalizedString(@"General", @"settings"), NSLocalizedString(@"Students", @"settings"), NSLocalizedString(@"Security", @"settings"), NSLocalizedString(@"Import & Export", @"settings")];
		cell.textLabel.text = titles[indexPath.row];
		
		NSArray *iconImage = @[@"settings_icon_general", @"settings_icon_students", @"settings_icon_security", @"settings_icon_import"];
		
		cell.imageView.image = [UIImage imageNamed:iconImage[indexPath.row]];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	} else {
		NSArray *titles = @[NSLocalizedString(@"About QuickHAC…", @"settings"), NSLocalizedString(@"Acknowledgements", @"settings")];
		cell.textLabel.text = titles[indexPath.row];
		
		cell.imageView.image = nil;
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
	
    return cell;
}

#pragma mark - Navigation
- (void) tableView:(UITableView *) tableView didSelectRowAtIndexPath:(NSIndexPath *) indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	switch(indexPath.section) {
		case 0:
			switch(indexPath.row) {
				case 1: {
					SQUSettingsStudents *setting = [[SQUSettingsStudents alloc] initWithStyle:UITableViewStyleGrouped];
					if(setting) {
						[self.navigationController pushViewController:setting animated:YES];
					}
					break;
				}
					
				default:
					NSLog(@"Selected unhandled settings: (%u, %u)", indexPath.row, indexPath.section);
					break;
			}
			break;
			
		case 1: {
			if(indexPath.row == 0) {
				
			} else if(indexPath.row == 1) {
				UIViewController *controller = [[UIViewController alloc] init];
				controller.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeModal:)];
				controller.title = NSLocalizedString(@"Acknowledgements", @"settings");
				
				UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
				textView.editable = NO;
				controller.view = textView;
				
				NSURL *urlOfAckText = [[NSBundle mainBundle] URLForResource:@"acknowledgements" withExtension:@"rtf"];
				NSAttributedString *attrString = [[NSAttributedString alloc] initWithFileURL:urlOfAckText options:@{NSDocumentTypeDocumentAttribute:NSRTFTextDocumentType} documentAttributes:nil error:nil];
				textView.attributedText = attrString;
				
				[self presentViewController:[[UINavigationController alloc] initWithRootViewController:controller] animated:YES completion:NULL];
			}
			
			break;
		}
			
		default:
			NSLog(@"Selected unhandled settings: (%u, %u)", indexPath.row, indexPath.section);
			break;
	}
}

#pragma mark - UI callbacks
- (void) closeModal:(id) sender {
	[self dismissViewControllerAnimated:YES completion:NULL];
}

- (void) openSidebar:(id) sender {
	if([self revealController].state == PKRevealControllerShowsFrontViewController) {
		[[self revealController] showViewController:[self revealController].leftViewController];
	} else {
		[[self revealController] resignPresentationModeEntirely:YES animated:YES completion:NULL];
	}
}

- (void) showAcknowledgements {
	
}

@end
