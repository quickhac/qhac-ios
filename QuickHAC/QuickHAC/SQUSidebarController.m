//
//  SQUSidebarController.m
//  QuickHAC
//
//  Created by Tristan Seifert on 12/27/13.
//  Copyright (c) 2013 Squee! Apps. All rights reserved.
//

#import "SQUSidebarController.h"

@interface SQUSidebarController ()

@end

@implementation SQUSidebarController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
		[self.tableView registerClass:NSClassFromString(@"UITableViewCell") forCellReuseIdentifier:@"SidebarCell"];
		
		UIImageView *backgroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"menu-background"]];
		self.tableView.backgroundView = backgroundImageView;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"SidebarCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    cell.backgroundColor  = nil;
	cell.backgroundView = nil;
	
	cell.textLabel.textColor = [UIColor whiteColor];
    cell.textLabel.text = @"Text.";
    
    return cell;
}

#pragma mark - Navigation
- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSLog(@"Selected cell: (%i, %i)", indexPath.section, indexPath.row);
}

@end
