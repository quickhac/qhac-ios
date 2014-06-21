//
//  SQULoginSchoolSelector.m
//  QuickHAC
//
//  Created by Tristan Seifert on 09/07/2013.
//  See README.MD for licensing and copyright information.
//

#import "SQULoginSchoolSelector.h"
#import "SQUDistrictManager.h"
#import "SQUDistrict.h"

@interface SQULoginSchoolSelector ()

@end

@implementation SQULoginSchoolSelector

- (id) initWithStyle:(UITableViewStyle) style {
    self = [super initWithStyle:style];
    if (self) {
        [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"SchoolCell"];
        self.title = NSLocalizedString(@"Select School District", nil);
    }
    return self;
}

- (void) viewDidLoad {
    [super viewDidLoad];
}

- (void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source
- (NSInteger) numberOfSectionsInTableView:(UITableView *) tableView {
    return 2;
}

- (NSInteger) tableView:(UITableView *) tableView numberOfRowsInSection:(NSInteger) section {
    // Return the number of rows in the section.
	switch (section) {
		case 0:
			return [[SQUDistrictManager sharedInstance] loadedDistricts].count;
			break;
		
		case 1:
			return 1;
			break;
			
		default:
			return 0;
			break;
	}
}

- (UITableViewCell *) tableView:(UITableView *) tableView cellForRowAtIndexPath:(NSIndexPath *) indexPath {
    static NSString *CellIdentifier = @"SchoolCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
	
	// district
	if(indexPath.section == 0) {
		SQUDistrict *district = [[SQUDistrictManager sharedInstance] loadedDistricts][indexPath.row];
		cell.textLabel.text = district.name;
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	} else if(indexPath.section == 1) {
		cell.textLabel.text = NSLocalizedString(@"Don't see your district?", nil);
	}
	
    return cell;
}

#pragma mark - Moving to actual login controller
- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if(indexPath.section == 0) {
		SQULoginViewController *loginController = [[SQULoginViewController alloc] init];
		loginController.district = [[SQUDistrictManager sharedInstance] loadedDistricts][indexPath.row];
		
		[self.navigationController pushViewController:loginController animated:YES];
	} else if(indexPath.section == 1) {
		UIViewController *controller = [[UIViewController alloc] init];
		controller.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeModal:)];
		controller.title = NSLocalizedString(@"District Not Listed", @"settings");
		
		UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
		textView.editable = NO;
		controller.view = textView;
		
		NSURL *urlOfRTF = [[NSBundle mainBundle] URLForResource:@"districtNotListed" withExtension:@"rtf"];
		NSAttributedString *attrString = [[NSAttributedString alloc] initWithFileURL:urlOfRTF options:@{NSDocumentTypeDocumentAttribute:NSRTFTextDocumentType} documentAttributes:nil error:nil];
		textView.attributedText = attrString;
		
		[self presentViewController:[[UINavigationController alloc] initWithRootViewController:controller] animated:YES completion:NULL];
	}
}

/**
 * Dismiss any open view controllers.
 */
- (void) closeModal:(id) sender {
	[self dismissViewControllerAnimated:YES completion:NULL];
}

@end
