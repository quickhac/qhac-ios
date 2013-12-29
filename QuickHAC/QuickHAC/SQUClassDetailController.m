//
//  SQUClassDetailController.m
//  QuickHAC
//
//  Created by Tristan Seifert on 12/28/13.
//  Copyright (c) 2013 Squee! Apps. All rights reserved.
//

#import "SQUClassDetailController.h"
#import "SQUCoreData.h"
#import "SQUGradeManager.h"
#import "SQUDistrictManager.h"
#import "SQUClassDetailCell.h"

#import "UIView+JMNoise.h"
#import "PKRevealController.h"

@interface SQUClassDetailController ()

@end

@implementation SQUClassDetailController

- (id) initWithCourse:(SQUCourse *) course {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        [self.tableView registerClass:[SQUClassDetailCell class]
               forCellReuseIdentifier:@"CourseOverviewCell"];
		self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        
		self.tableView.backgroundView = [[UIView alloc] initWithFrame:self.tableView.frame];
		self.tableView.backgroundView.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
		[self.tableView.backgroundView applyNoiseWithOpacity:0.15f];
		
        _course = course;
		self.title = course.title;
        
        UIBarButtonItem *showSidebar = [[UIBarButtonItem alloc]
										initWithTitle:NSLocalizedString(@"Sidebar", nil)
										style:UIBarButtonItemStyleBordered target:self
										action:@selector(openSidebar:)];
        [self.navigationItem setLeftBarButtonItem:showSidebar];
		
		_refreshDateFormatter = [[NSDateFormatter alloc] init];
		[_refreshDateFormatter setDateFormat:@"MMM d, h:mm a"];
		
		_displayCycle = 2;
		_currentCycle = _course.cycles[_displayCycle];
    }
	
    return self;
}

- (void) viewDidLoad {
	
    UIRefreshControl *refresher = [[UIRefreshControl alloc] init];
    [refresher addTarget:self action:@selector(reloadData:)
        forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refresher;
	
	// iOS 7 is stupid and draws the referesh control behind the table's BG view
	self.refreshControl.layer.zPosition = self.tableView.backgroundView.layer.zPosition + 1;
	
	// Blurry navbar
	self.navigationController.navigationBar.translucent = YES;
}

- (void) viewWillAppear:(BOOL) animated {
    [super viewWillAppear:animated];
	
	[self reloadData:self.refreshControl];
	[self.tableView reloadData];
	
	NSLog(@"Course categories: %u", _currentCycle.categories.count);
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return _currentCycle.categories.count;
}

- (CGFloat) tableView:(UITableView *) tableView heightForRowAtIndexPath:(NSIndexPath *) indexPath {
	return [SQUClassDetailCell cellHeightForCategory:_currentCycle.categories[indexPath.row]] + 20;
}

- (UITableViewCell *) tableView:(UITableView *) tableView cellForRowAtIndexPath:(NSIndexPath *) indexPath {
    static NSString *CellIdentifier = @"CourseOverviewCell";
    SQUClassDetailCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
	cell.category = _currentCycle.categories[indexPath.row];
	cell.index = indexPath.row;
	cell.backgroundColor = [UIColor clearColor];
	cell.clipsToBounds = NO;
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	
    [cell updateUI];
    
    return cell;
}

#pragma mark - UI
- (void) reloadData:(id) sender {
	NSLog(@"Refreshing course grades for %@...", _course.courseCode);
	
	// Update course grades
	[[SQUGradeManager sharedInstance] fetchNewCycleGradesFromServerForCourse:_course.courseCode withCycle:_displayCycle % 3 andSemester:_displayCycle / 3 andDoneCallback:^(NSError * error) {
		if(!error) {
			_currentCycle = _course.cycles[_displayCycle];
			[self.tableView reloadData];
		} else {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error Updating Grades", nil) message:error.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
            [alert show];
			
			NSLog(@"Error updating course grades: %@", error);
		}
		
		[self.refreshControl endRefreshing];
	}];
}

- (void) openSidebar:(id) sender {
	if([self revealController].state == PKRevealControllerShowsFrontViewController) {
		[[self revealController] showViewController:[self revealController].leftViewController];
	} else {
		[[self revealController] resignPresentationModeEntirely:YES animated:YES completion:NULL];
	}
}

@end