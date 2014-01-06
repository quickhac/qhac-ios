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

#import <CoreImage/CoreImage.h>
#import <QuartzCore/QuartzCore.h>

#import "SQUGradeOverviewTableViewCell.h"
#import "SQUAppDelegate.h"
#import "SQUCoreData.h"
#import "SQUPushHandler.h"
#import "SQUGradeManager.h"
#import "SQUSidebarController.h"
#import "SQUGradeOverviewController.h"

#import "UIViewController+PKRevealController.h"
#import "PKRevealController.h"
#import "UIView+JMNoise.h"

@implementation SQUGradeOverviewController

- (id) initWithStyle:(UITableViewStyle) style {
    self = [super initWithStyle:style];
    if (self) {
        [self.tableView registerClass:[SQUGradeOverviewTableViewCell class]
               forCellReuseIdentifier:@"GradeOverviewCell"];
		self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        
		self.tableView.backgroundView = [[UIView alloc] initWithFrame:self.tableView.frame];
		self.tableView.backgroundView.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
		[self.tableView.backgroundView applyNoiseWithOpacity:0.15f];
		
        self.title = NSLocalizedString(@"Overview", nil);
        
        UIBarButtonItem *showSidebar = [[UIBarButtonItem alloc]
										initWithImage:[UIImage imageNamed:@"RevealSidebarIcon"]
										style:UIBarButtonItemStyleBordered
										target:self
										action:@selector(openSidebar:)];
		self.navigationItem.leftBarButtonItem = showSidebar;
		
		/*UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"Push" style:UIBarButtonItemStyleDone target:self action:@selector(testPush:)];
		self.navigationItem.rightBarButtonItem = item;*/
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTableNotification:) name:SQUGradesDataUpdatedNotification object:nil];
		
		_refreshDateFormatter = [[NSDateFormatter alloc] init];
		[_refreshDateFormatter setDateFormat:@"MMM d, h:mm a"];
    }
	
    return self;
}

// Test action for push notifications
- (void) testPush:(id) sender {
	[[SQUPushHandler sharedInstance] registerWithPushToken:nil];
}

- (void) viewDidLoad {
    [super viewDidLoad];
    
    // set up refresh control
    UIRefreshControl *refresher = [[UIRefreshControl alloc] init];
    [refresher addTarget:self action:@selector(reloadData:)
        forControlEvents:UIControlEventValueChanged];
	
	NSString *lastUpdated = [NSString stringWithFormat:NSLocalizedString(@"Last Updated on %@", nil), [_refreshDateFormatter stringFromDate:[SQUGradeManager sharedInstance].student.lastAveragesUpdate]];
	refresher.attributedTitle = [[NSAttributedString alloc] initWithString:lastUpdated];

    self.refreshControl = refresher;
	
	// iOS 7 is stupid and draws the referesh control behind the table's BG view
	self.refreshControl.layer.zPosition = self.tableView.backgroundView.layer.zPosition + 1;
	
	// Blurry navbar
	self.navigationController.navigationBar.translucent = YES;
}

- (void) viewWillAppear:(BOOL) animated {
	// Set up the title view container and title text
	_navbarTitle = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
	
	_titleLayer = [CATextLayer new];
	_titleLayer.frame = CGRectMake(0, 4, 200, 28);
	_titleLayer.font = (__bridge CFTypeRef)([UIFont fontWithName:@"HelveticaNeue-Medium" size:26.0]);
	_titleLayer.fontSize = 17.0f;
	_titleLayer.contentsScale = [UIScreen mainScreen].scale;
	_titleLayer.foregroundColor = [UIColor blackColor].CGColor;
	_titleLayer.string = NSLocalizedString(@"Overview", nil);
	_titleLayer.alignmentMode = kCAAlignmentCenter;
	
	[_navbarTitle.layer addSublayer:_titleLayer];
	
	_subtitleLayer = [CATextLayer new];
	_subtitleLayer.frame = CGRectMake(0, 25, 200, 28);
	_subtitleLayer.font = (__bridge CFTypeRef)([UIFont fontWithName:@"HelveticaNeue-LightItalic" size:26.0]);
	_subtitleLayer.fontSize = 12.0f;
	_subtitleLayer.contentsScale = [UIScreen mainScreen].scale;
	_subtitleLayer.foregroundColor = [UIColor lightGrayColor].CGColor;
	_subtitleLayer.alignmentMode = kCAAlignmentCenter;
	
	[_navbarTitle.layer addSublayer:_subtitleLayer];
	
	// Apply to nav item
	self.navigationItem.titleView = _navbarTitle;
	
	// Reload table data
	[self.tableView reloadData];
}

- (void) viewDidAppear:(BOOL) animated {
	[super viewDidAppear:animated];
	[self updateGPA];
}

#pragma mark - Table view data source
- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return SQUGradeOverviewCellHeight + 8;
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
	cell.clipsToBounds = NO;
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	
    [cell updateUI];
    
    return cell;
}

- (void) tableView:(UITableView *) tableView didSelectRowAtIndexPath:(NSIndexPath *) indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
	
	SQUCourse *course = [SQUGradeManager sharedInstance].courses[indexPath.row];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:SQUSidebarControllerShowSidebarMessage object:nil userInfo:@{@"course": course}];
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
		[[NSNotificationCenter defaultCenter] postNotificationName:SQUGradesDataUpdatedNotification object:nil];
		
		if(error) {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error Updating Grades", nil) message:error.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
            [alert show];
		} else {
			NSLog(@"Grades Refreshed");
			[self.tableView reloadData];
		}
		
		// End refreshing
		NSDate *date = [NSDate date];
		NSString *lastUpdated = [NSString stringWithFormat:NSLocalizedString(@"Last Updated on %@", nil), [_refreshDateFormatter stringFromDate:date]];
		control.attributedTitle = [[NSAttributedString alloc] initWithString:lastUpdated];
		
		[control endRefreshing];
	}];
}

#pragma mark - Update handlers
- (void) updateTableNotification:(NSNotification *) notif {
	[self.tableView reloadData];
	
	NSString *lastUpdated = [NSString stringWithFormat:NSLocalizedString(@"Last Updated on %@", nil), [_refreshDateFormatter stringFromDate:[SQUGradeManager sharedInstance].student.lastAveragesUpdate]];
	self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:lastUpdated];
	
	// Update GPA display
	[self updateGPA];
}

/**
 * Updates the GPA display.
 */
- (void) updateGPA {
	// Take GPA precision preference into account
	NSInteger precision = [[NSUserDefaults standardUserDefaults] integerForKey:@"gpa_precision"];
	NSString *gpaFormatString = [NSString stringWithFormat:NSLocalizedString(@"GPA: %%.%1$uf/%%.%1$uf", nil), precision];
	
	// Calculate GPA
	NSNumber *gpaUnweighted = [[SQUGradeManager sharedInstance] calculateGPAWeighted:NO forCourses:[SQUGradeManager sharedInstance].courses.array];
	NSNumber *gpaWeighted = [[SQUGradeManager sharedInstance] calculateGPAWeighted:YES forCourses:[SQUGradeManager sharedInstance].courses.array];
	
	_subtitleLayer.string = [NSString stringWithFormat:gpaFormatString, gpaUnweighted.floatValue, gpaWeighted.floatValue];
}

@end
