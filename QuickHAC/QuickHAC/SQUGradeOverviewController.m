//
//  SQUGradeOverviewController.m
//  QuickHAC
//
//  Created by Tristan Seifert on 16/07/2013.
//  Copyright (c) 2013 Squee! Apps. All rights reserved.
//

#import "SQUGradeOverviewController.h"
#import "SQUGradeOverviewTableViewCell.h"

#import "SQUAppDelegate.h"
#import "SQUCoreData.h"

@interface SQUGradeOverviewController ()
- (NSString *) getTitleForGradingCycle:(NSUInteger) cycle;
@end

@implementation SQUGradeOverviewController

- (id) initWithStyle:(UITableViewStyle) style {
    self = [super initWithStyle:style];
    if (self) {
        [self.tableView registerClass:[SQUGradeOverviewTableViewCell class]
               forCellReuseIdentifier:@"GradeOverviewCell"];
        
        _gradingCycle = 0;
        self.title = [self getTitleForGradingCycle:_gradingCycle];
        
        UIBarButtonItem *settings = [[UIBarButtonItem alloc]
                                     initWithTitle:NSLocalizedString(@"Settings", nil)
                                     style:UIBarButtonItemStyleBordered target:self
                                     action:@selector(openSettings:)];
        
        [self.navigationItem setLeftBarButtonItem:settings];
    }
    return self;
}

- (void) viewDidLoad {
    [super viewDidLoad];
    
    // set up refresh control
    UIRefreshControl *refresher = [[UIRefreshControl alloc] init];
    [refresher addTarget:self action:@selector(reloadData:)
        forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refresher;
    
    [self updateDatabase];
}

- (void) viewWillAppear:(BOOL) animated {
    [self updateDatabase];
}

- (void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source
- (NSInteger) numberOfSectionsInTableView:(UITableView *) tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger) tableView:(UITableView *) tableView numberOfRowsInSection:(NSInteger) section {
    // Return the number of rows in the section.
    return _classes.count;
}

- (UITableViewCell *) tableView:(UITableView *) tableView cellForRowAtIndexPath:(NSIndexPath *) indexPath {
    static NSString *CellIdentifier = @"GradeOverviewCell";
    SQUGradeOverviewTableViewCell *cell = (SQUGradeOverviewTableViewCell *)
    [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Get class info
    SQUClassInfo *classInfo = (SQUClassInfo *) _classes[indexPath.row];
    
    cell.period = indexPath.row + 1;
    cell.classTitle = classInfo.title;
    cell.grade = classInfo.currentGrade.floatValue;
    
    [cell updateUI];
    
    return cell;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return SQUGradeOverviewCellHeight;
}

#pragma mark - UI Callbacks
- (void) openSettings:(id) sender {
    // lolsettings
}

- (void) reloadData:(UIRefreshControl *) control {
    control.attributedTitle = [[NSAttributedString alloc]
                               initWithString:NSLocalizedString(@"Refreshing Data…", nil)];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MMM d, h:mm a"];
    NSDate *date = [NSDate date];
    NSString *lastUpdated = [NSString stringWithFormat:NSLocalizedString(@"Last Updated on %@", nil),
                             [formatter stringFromDate:date]];
    control.attributedTitle = [[NSAttributedString alloc] initWithString:lastUpdated];
    
    [control endRefreshing];
}

- (void) updateDatabase {
    // Load classes from CoreData
    NSManagedObjectContext *context = [[SQUAppDelegate sharedDelegate] managedObjectContext];
    NSError *db_err = nil;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"SQUStudent" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    // If we have students, try and display grades
    NSArray *students = [context executeFetchRequest:fetchRequest error:&db_err];
    if(students.count > 0) {
        if(_classes) {
            [_classes removeAllObjects];
        } else {
            _classes = [[NSMutableArray alloc] init];
        }
        
        SQUStudent *activeStudent = students[0];
        
        for (SQUClassInfo *class in activeStudent.classes) {
            // Insert the classes into an array used for display
            [_classes addObject:class];
        }
    
        [self.tableView reloadData];
    }
}

#pragma mark - Miscellaneous helper methods
- (NSString *) getTitleForGradingCycle:(NSUInteger) cycle {
    static NSArray *items = nil;
    
    if(!items) {
        items = @[@"Cycle 1", @"Cycle 2", @"Cycle 3", @"Exam 1", @"Semester 1",
                  @"Cycle 4", @"Cycle 5", @"Cycle 6", @"Exam 2", @"Semester 2"];
    }
    
    return NSLocalizedString(items[cycle], nil);
}

@end
