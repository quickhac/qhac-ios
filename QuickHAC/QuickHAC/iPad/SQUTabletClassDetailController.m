//
//  SQUTabletClassDetailController.m
//  QuickHAC
//
//  Created by Tristan Seifert on 2/22/14.
//  See README.MD for licensing and copyright information.
//

#import "SQUCoreData.h"

#import "SQUTabletClassDetailController.h"

@interface SQUTabletClassDetailController ()

@end

@implementation SQUTabletClassDetailController

- (id) init {
    self = [super initWithStyle:UITableViewStylePlain];
	
    if (self) {
        // Custom initialization
    }
	
    return self;
}

- (void) viewDidLoad {
    [super viewDidLoad];
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger) numberOfSectionsInTableView:(UITableView *) tableView {
    // Return the number of sections.
    return 0;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger) section {
    // Return the number of rows in the section.
    return 0;
}

- (UITableViewCell *) tableView:(UITableView *) tableView cellForRowAtIndexPath:(NSIndexPath *) indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}

@end
