//
//  SQULoginSchoolSelector.m
//  QuickHAC
//
//  Created by Tristan Seifert on 09/07/2013.
//  See README.MD for licensing and copyright information.
//

#import "SQULoginSchoolSelector.h"

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
    return 1;
}

- (NSInteger) tableView:(UITableView *) tableView numberOfRowsInSection:(NSInteger) section {
    // Return the number of rows in the section.
    return SQUNumSupportedSchools;
}

- (UITableViewCell *) tableView:(UITableView *) tableView cellForRowAtIndexPath:(NSIndexPath *) indexPath {
    static NSString *CellIdentifier = @"SchoolCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    cell.textLabel.text = [SQUHACInterface schoolEnumToName:indexPath.row];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

#pragma mark - Moving to actual login controller
- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    SQULoginViewController *loginController = [[SQULoginViewController alloc] init];
    loginController.district = indexPath.row;
    
    [self.navigationController pushViewController:loginController animated:YES];
}

@end
