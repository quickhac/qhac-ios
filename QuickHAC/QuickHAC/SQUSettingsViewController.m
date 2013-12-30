//
//  SQUSettingsViewController.m
//  QuickHAC
//
//  Created by Tristan Seifert on 12/29/13.
//  See README.MD for licensing and copyright information.
//

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
	} else {
		NSArray *titles = @[NSLocalizedString(@"About QuickHAC…", @"settings"), NSLocalizedString(@"Acknowledgements", @"settings")];
		cell.textLabel.text = titles[indexPath.row];
		
		cell.imageView.image = nil;
	}
	
    return cell;
}

#pragma mark - Navigation
- (void) tableView:(UITableView *) tableView didSelectRowAtIndexPath:(NSIndexPath *) indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	NSLog(@"Selected %u, %u", indexPath.section, indexPath.row);
}

#pragma mark - UI callbacks
- (void) openSidebar:(id) sender {
	if([self revealController].state == PKRevealControllerShowsFrontViewController) {
		[[self revealController] showViewController:[self revealController].leftViewController];
	} else {
		[[self revealController] resignPresentationModeEntirely:YES animated:YES completion:NULL];
	}
}

@end
