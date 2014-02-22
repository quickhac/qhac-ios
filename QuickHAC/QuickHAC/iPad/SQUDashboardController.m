//
//  SQUDashboardController.m
//  QuickHAC
//
//  Created by Tristan Seifert on 2/22/14.
//  See README.MD for licensing and copyright information.
//

#import "SQUColourScheme.h"
#import "SQUGradeManager.h"
#import "SQUDistrictManager.h"
#import "SQUCoreData.h"
#import "SQURelativeRefreshControl.h"

#import "SQUDashboardCell.h"
#import "SQUDashboardController.h"

#import "AFNetworking.h"

@interface SQUDashboardController ()

@end

@implementation SQUDashboardController

- (instancetype) init {
    self = [super initWithCollectionViewLayout:[[UICollectionViewFlowLayout alloc] init]];
   
	if (self) {
		// Set up nav item
		self.title = NSLocalizedString(@"Dashboard", nil);
		
        UIBarButtonItem *showNotifications = [[UIBarButtonItem alloc]
											  initWithImage:[UIImage imageNamed:@"notificationsIcon"]
											  style:UIBarButtonItemStyleBordered
											  target:self
											  action:@selector(showNotifications:)];
		self.navigationItem.rightBarButtonItem = showNotifications;
		
		// Set up collection view
		self.collectionView.backgroundColor = UIColorFromRGB(kSQUColourTableBackground);
		self.collectionView.alwaysBounceVertical = YES;
        [self.collectionView registerClass:[SQUDashboardCell class] forCellWithReuseIdentifier:@"DashCell"];
		
		// Register for notifications
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTableNotification:) name:SQUGradesDataUpdatedNotification object:nil];
    }
	
    return self;
}

#pragma mark - UI actions
- (void) showNotifications:(id) sender {
	
}

#pragma mark - View controller management
- (void) viewDidLoad {
    [super viewDidLoad];
    
    // set up refresh control
    _refresher = [[SQURelativeRefreshControl alloc] init];
    [_refresher addTarget:self action:@selector(reloadData:)
        forControlEvents:UIControlEventValueChanged];
    [self.collectionView addSubview:_refresher];
	
	// Blurry navbar
	self.navigationController.navigationBar.translucent = YES;
}

- (void) viewWillAppear:(BOOL) animated {
	// Show relative date
	_refresher.date = [SQUGradeManager sharedInstance].student.lastAveragesUpdate;
	
	// Reload table data
	[self.collectionView reloadData];
}

#pragma mark - Collection View Data Source
- (NSInteger) collectionView:(UICollectionView *) view numberOfItemsInSection:(NSInteger) section {
    return [[SQUGradeManager sharedInstance] getCoursesForCurrentStudent].count;
}

- (NSInteger) numberOfSectionsInCollectionView:(UICollectionView *) collectionView {
    return 1;
}

- (UICollectionViewCell *) collectionView:(UICollectionView *) cv cellForItemAtIndexPath:(NSIndexPath *) indexPath {
	SQUDashboardCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"DashCell" forIndexPath:indexPath];
	cell.course = [[SQUGradeManager sharedInstance] getCoursesForCurrentStudent][indexPath.row];
	cell.clipsToBounds = NO;
	
    return cell;
}

#pragma mark - Collection View Delegate
- (void) collectionView:(UICollectionView *) collectionView didSelectItemAtIndexPath:(NSIndexPath *) indexPath {

}

- (void) collectionView:(UICollectionView *) collectionView didDeselectItemAtIndexPath:(NSIndexPath *) indexPath {

}

#pragma mark - Collection View Flow Layout Delegate
- (CGSize) collectionView:(UICollectionView *) collectionView layout:(UICollectionViewLayout*) collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *) indexPath {
	CGFloat width = collectionView.frame.size.width - 40 - 16;
	return CGSizeMake(width / 2, 184);
}

- (UIEdgeInsets) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*) collectionViewLayout insetForSectionAtIndex:(NSInteger) section {
	return UIEdgeInsetsMake(16, 20, 32, 20);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
	return 16;
}

#pragma mark - Data reloading
- (void) reloadData:(SQURelativeRefreshControl *) control {
	if([SQUDistrictManager sharedInstance].reachabilityManager.isReachable) {
		[[SQUGradeManager sharedInstance] fetchNewClassGradesFromServerWithDoneCallback:^(NSError *error){
			[[NSNotificationCenter defaultCenter] postNotificationName:SQUGradesDataUpdatedNotification object:nil];
			
			if(error) {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error Updating Grades", nil) message:error.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
				[alert show];
			} else {
				[self.collectionView reloadData];
			}
			
			// End refreshing
			control.date = [NSDate date];
			[control endRefreshing];
		}];
	} else {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Not Connected", nil) message:NSLocalizedString(@"To refresh the overview, please connect to the Internet, and then ensure that you have unrestricted access to the district's gradebook.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
		[alert show];
		
		// Update the UI that normally would be updated by the post-request block
		[control endRefreshing];
	}
}

- (void) updateTableNotification:(NSNotification *) notif {
	[self.collectionView reloadData];
	
	_refresher.date = [SQUGradeManager sharedInstance].student.lastAveragesUpdate;
	
	// Update GPA display
	[self updateGPA];
}

/**
 * Updates the GPA display.
 */
- (void) updateGPA {
	// Hide GPA for elementary students
/*	if([[SQUGradeManager sharedInstance].student.school rangeOfString:@"Elementary"].location != NSNotFound) {
		self.navigationItem.titleView = nil;
	} else {
		self.navigationItem.titleView = _navbarTitle;
	}
	
	// Take GPA precision preference into account
	NSInteger precision = [[NSUserDefaults standardUserDefaults] integerForKey:@"gpa_precision"];
	NSString *gpaFormatString = [NSString stringWithFormat:NSLocalizedString(@"GPA: %%.%1$uf/%%.%1$uf", @"The first %%.%1$uf is unweighted, the second is weighted GPA."), precision];
	
	// Calculate GPA
	NSNumber *gpaUnweighted = [[SQUDistrictManager sharedInstance].currentDistrict unweightedGPAWithCourses:[SQUGradeManager sharedInstance].student.courses.array];
	NSNumber *gpaWeighted = [[SQUDistrictManager sharedInstance].currentDistrict weightedGPAWithCourses:[SQUGradeManager sharedInstance].student.courses.array];*/
}


@end
