//
//  SQUGradeOverviewController.m
//  QuickHAC
//
//	Handles rendering a table overview of all courses of a student, using the
//	cards interface.
//
//  Created by Tristan Seifert on 16/07/2013.
//  See README.MD for licensing and copyright information.
//

#import "SQUGradeOverviewController.h"
#import "SQUGradeOverviewTableViewCell.h"
#import "SQUAppDelegate.h"
#import "SQUCoreData.h"
#import "SQUGradeManager.h"

#import "UIViewController+PKRevealController.h"
#import "PKRevealController.h"

@implementation SQUGradeOverviewController

- (id) initWithStyle:(UITableViewStyle) style {
    self = [super initWithStyle:style];
    if (self) {
        [self.tableView registerClass:[SQUGradeOverviewTableViewCell class]
               forCellReuseIdentifier:@"GradeOverviewCell"];
		self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
		self.tableView.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
        
        self.title = NSLocalizedString(@"Overview", nil);
        
        UIBarButtonItem *showSidebar = [[UIBarButtonItem alloc]
                                     initWithTitle:NSLocalizedString(@"Sidebar", nil)
                                     style:UIBarButtonItemStyleBordered target:self
                                     action:@selector(openSidebar:)];
        [self.navigationItem setLeftBarButtonItem:showSidebar];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTableNotification:) name:SQUGradesDataUpdatedNotification object:nil];
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
}

- (void) viewWillAppear:(BOOL) animated {
	[self.tableView reloadData];
}

#pragma mark - Table view data source
- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return SQUGradeOverviewCellHeight + 15;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *) tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger) tableView:(UITableView *) tableView numberOfRowsInSection:(NSInteger) section {
    // Return the number of rows in the section.
    return [[SQUGradeManager sharedInstance] getCoursesForCurrentStudent].count;
}

- (UITableViewCell *) tableView:(UITableView *) tableView cellForRowAtIndexPath:(NSIndexPath *) indexPath {
    static NSString *CellIdentifier = @"GradeOverviewCell";
    SQUGradeOverviewTableViewCell *cell = (SQUGradeOverviewTableViewCell *)
    [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
	
    cell.courseInfo = [[[SQUGradeManager sharedInstance] getCoursesForCurrentStudent] objectAtIndex:indexPath.row];
	cell.backgroundColor = [UIColor clearColor];
	
    [cell updateUI];
    
    return cell;
}

#pragma mark - UI Callbacks
- (void) openSidebar:(id) sender {
	if([self revealController].state == PKRevealControllerShowsFrontViewController) {
		[[self revealController] showViewController:[self revealController].leftViewController];
	} else {
		[[self revealController] resignPresentationModeEntirely:YES animated:YES completion:NULL];
	}
}

- (void) reloadData:(UIRefreshControl *) control {
	[[SQUGradeManager sharedInstance] fetchNewClassGradesFromServerWithDoneCallback:^(NSError *error){
		if(error) {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error Updating Grades", nil) message:error.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
            [alert show];
		} else {
			NSLog(@"Grades Refreshed");
			[self.tableView reloadData];
		}
		
		// End refreshing
		NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
		[formatter setDateFormat:@"MMM d, h:mm a"];
		NSDate *date = [NSDate date];
		NSString *lastUpdated = [NSString stringWithFormat:NSLocalizedString(@"Last Updated on %@", nil), [formatter stringFromDate:date]];
		control.attributedTitle = [[NSAttributedString alloc] initWithString:lastUpdated];
		
		[control endRefreshing];
	}];
}

- (void) updateTableNotification:(NSNotification *) notif {
	[self.tableView reloadData];
}

@end
