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

#import "NSDate+RelativeDate.h"

#import "SQUGradeOverviewTableViewCell.h"
#import "SQUAppDelegate.h"
#import "SQUCoreData.h"
#import "SQUDistrictManager.h"
#import "SQUPushHandler.h"
#import "SQUGradeManager.h"
#import "SQUDistrictManager.h"
#import "SQUSidebarController.h"
#import "SQUColourScheme.h"
#import "SQUGradeOverviewController.h"

#import "UIViewController+PKRevealController.h"
#import "PKRevealController.h"
#import "UIView+JMNoise.h"
#import "AFNetworking.h"

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
		
		// Set up the title view container and title text
		_navbarTitle = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
		
		_titleLayer = [CATextLayer new];
		_titleLayer.frame = CGRectMake(0, 4, 200, 28);
		_titleLayer.font = (__bridge CFTypeRef)([UIFont fontWithName:@"HelveticaNeue-Light" size:26.0]);
		_titleLayer.fontSize = 17.0f;
		_titleLayer.contentsScale = [UIScreen mainScreen].scale;
		_titleLayer.foregroundColor = UIColorFromRGB(kSQUColourTitle).CGColor;
		_titleLayer.string = NSLocalizedString(@"Overview", nil);
		_titleLayer.alignmentMode = kCAAlignmentCenter;
		
		[_navbarTitle.layer addSublayer:_titleLayer];
		
		_subtitleLayer = [CATextLayer new];
		_subtitleLayer.frame = CGRectMake(0, 25, 200, 28);
		_subtitleLayer.font = (__bridge CFTypeRef)([UIFont fontWithName:@"HelveticaNeue-LightItalic" size:26.0]);
		_subtitleLayer.fontSize = 12.0f;
		_subtitleLayer.contentsScale = [UIScreen mainScreen].scale;
		_subtitleLayer.foregroundColor = UIColorFromRGB(kSQUColourSubtitle).CGColor;
		_subtitleLayer.alignmentMode = kCAAlignmentCenter;
		
		[_navbarTitle.layer addSublayer:_subtitleLayer];
		
		// Apply to nav item
		self.navigationItem.titleView = _navbarTitle;
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTableNotification:) name:SQUGradesDataUpdatedNotification object:nil];
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

	refresher.attributedTitle = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@"Updated %@", @"relative date grades refresh control"), [[SQUGradeManager sharedInstance].student.lastAveragesUpdate relativeDate]]];
	
	// iOS 7 is stupid and draws the referesh control behind the table's BG view
	refresher.layer.zPosition = self.tableView.backgroundView.layer.zPosition + 1;
    self.refreshControl = refresher;
	
	// Blurry navbar
	self.navigationController.navigationBar.translucent = YES;
}

- (void) viewWillAppear:(BOOL) animated {
	// Show relative date
	self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@"Updated %@", @"relative date grades refresh control"), [[SQUGradeManager sharedInstance].student.lastAveragesUpdate relativeDate]]];
	
	// Reload table data
	[self.tableView reloadData];
}

- (void) viewDidAppear:(BOOL) animated {
	[super viewDidAppear:animated];
	[self updateGPA];
}

#pragma mark - Table view data source
- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	SQUCourse *course = [[[SQUGradeManager sharedInstance] getCoursesForCurrentStudent] objectAtIndex:indexPath.row];
	CGFloat cellHeight = [SQUGradeOverviewTableViewCell cellHeightForCourse:course];
	
	if((indexPath.row + 1) != [[SQUGradeManager sharedInstance] getCoursesForCurrentStudent].count) {
		return cellHeight + 8;
	} else {
		return cellHeight + 24;
	}
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *) tableView {
    return 1;
}

- (NSInteger) tableView:(UITableView *) tableView numberOfRowsInSection:(NSInteger) section {
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
	if([SQUDistrictManager sharedInstance].reachabilityManager.isReachable) {
		[[SQUGradeManager sharedInstance] fetchNewClassGradesFromServerWithDoneCallback:^(NSError *error){
			[[NSNotificationCenter defaultCenter] postNotificationName:SQUGradesDataUpdatedNotification object:nil];
			
			if(error) {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error Updating Grades", nil) message:error.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
				[alert show];
			} else {
				[self.tableView reloadData];
			}
			
			// End refreshing
			control.attributedTitle = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@"Updated %@", @"relative date grades refresh control"), [[NSDate date] relativeDate]]];
			
			[control endRefreshing];
		}];
	} else {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Not Connected", nil) message:NSLocalizedString(@"To refresh the overview, please connect to the Internet, and then ensure that you have unrestricted access to the district's gradebook.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
		[alert show];
		
		// Update the UI that normally would be updated by the post-request block
		[control endRefreshing];
	}
}

#pragma mark - Update handlers
- (void) updateTableNotification:(NSNotification *) notif {
	[self.tableView reloadData];
	
	self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@"Updated %@", @"relative date grades refresh control"), [[SQUGradeManager sharedInstance].student.lastAveragesUpdate relativeDate]]];
	
	// Update GPA display
	[self updateGPA];
}

/**
 * Updates the GPA display.
 */
- (void) updateGPA {
	// Hide GPA for elementary students
	if([[SQUGradeManager sharedInstance].student.school rangeOfString:@"Elementary"].location != NSNotFound) {
		self.navigationItem.titleView = nil;
	} else {
		self.navigationItem.titleView = _navbarTitle;
	}
	
	// Take GPA precision preference into account
	NSInteger precision = [[NSUserDefaults standardUserDefaults] integerForKey:@"gpa_precision"];
	NSString *gpaFormatString = [NSString stringWithFormat:NSLocalizedString(@"GPA: %%.%1$uf/%%.%1$uf", @"The first %%.%1$uf is unweighted, the second is weighted GPA."), precision];
	
	// Calculate GPA
	NSNumber *gpaUnweighted = [[SQUDistrictManager sharedInstance].currentDistrict unweightedGPAWithCourses:[SQUGradeManager sharedInstance].student.courses.array];
	NSNumber *gpaWeighted = [[SQUDistrictManager sharedInstance].currentDistrict weightedGPAWithCourses:[SQUGradeManager sharedInstance].student.courses.array];
	
	_subtitleLayer.string = [NSString stringWithFormat:gpaFormatString, gpaUnweighted.floatValue, gpaWeighted.floatValue];
}

@end
