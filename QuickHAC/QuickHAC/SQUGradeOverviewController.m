//
//  SQUGradeOverviewController.m
//  QuickHAC
//
//  Created by Tristan Seifert on 16/07/2013.
//  Copyright (c) 2013 Squee! Apps. All rights reserved.
//

#import "SQUGradeOverviewController.h"
#import "SQUGradeOverviewTableViewCell.h"

@interface SQUGradeOverviewController ()

@end

@implementation SQUGradeOverviewController

- (id) initWithStyle:(UITableViewStyle) style {
    self = [super initWithStyle:style];
    if (self) {
        [self.tableView registerClass:[SQUGradeOverviewTableViewCell class]
               forCellReuseIdentifier:@"GradeOverviewCell"];
        
        self.title = NSLocalizedString(@"Grades", nil);
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

#warning lolplaceholderdata
- (NSInteger) numberOfSectionsInTableView:(UITableView *) tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger) tableView:(UITableView *) tableView numberOfRowsInSection:(NSInteger) section {
    // Return the number of rows in the section.
    return 8;
}

- (UITableViewCell *) tableView:(UITableView *) tableView cellForRowAtIndexPath:(NSIndexPath *) indexPath {
    static NSString *CellIdentifier = @"GradeOverviewCell";
    SQUGradeOverviewTableViewCell *cell = (SQUGradeOverviewTableViewCell *)
    [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    
    cell.period = indexPath.row + 1;
    cell.classTitle = @[@"Test class 1", @"Something boring", @"NO",
                        @"Here, this is a really long and boring one", @"beep boop",
                        @"I'm a computer or something", @"STOP LOOKING AT ME",
                        @"=V"][indexPath.row];
    cell.grade = ((indexPath.row + 1) * 12);
    
    [cell updateUI];
    
    return cell;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return SQUGradeOverviewCellHeight;
}

@end
