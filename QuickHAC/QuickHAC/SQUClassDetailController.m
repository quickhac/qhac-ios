//
//  SQUClassDetailController.m
//  QuickHAC
//
//  Created by Tristan Seifert on 12/28/13.
//  See README.MD for licensing and copyright information.
//

#import "SQUClassDetailController.h"
#import "SQUCoreData.h"
#import "SQUGradeManager.h"
#import "SQUDistrictManager.h"
#import "SQUClassDetailCell.h"

#import "UIView+JMNoise.h"
#import "PKRevealController.h"
#import "WYPopoverController.h"
#import "SVProgressHUD.h"

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
										initWithImage:[UIImage imageNamed:@"RevealSidebarIcon"]
										style:UIBarButtonItemStyleBordered
										target:self
										action:@selector(openSidebar:)];
        [self.navigationItem setLeftBarButtonItem:showSidebar];
		
		UIBarButtonItem *showCycleSwitcher = [[UIBarButtonItem alloc]
											  initWithTitle:NSLocalizedString(@"Cycles", nil)
											  style:UIBarButtonItemStyleBordered
											  target:self
											  action:@selector(openCyclesSwitcher:)];
		[self.navigationItem setRightBarButtonItem:showCycleSwitcher];
		
		_refreshDateFormatter = [[NSDateFormatter alloc] init];
		[_refreshDateFormatter setDateFormat:@"MMM d, h:mm a"];
		
		if([[NSUserDefaults standardUserDefaults] objectForKey:@"selectedCycle"] == nil) {
			_displayCycle = 0;
		} else {
			// Ensure this course has data for this cycle
			_displayCycle = [[NSUserDefaults standardUserDefaults] integerForKey:@"selectedCycle"];
		}
		
		_currentCycle = _course.cycles[_displayCycle];
    }
	
    return self;
}

- (void) viewDidLoad {
    UIRefreshControl *refresher = [[UIRefreshControl alloc] init];
    [refresher addTarget:self action:@selector(reloadData:)
        forControlEvents:UIControlEventValueChanged];
	
	NSString *lastUpdated = [NSString stringWithFormat:NSLocalizedString(@"Last Updated on %@", @"class detail pull to refresh"), [_refreshDateFormatter stringFromDate:_currentCycle.last_updated]];
	refresher.attributedTitle = [[NSAttributedString alloc] initWithString:lastUpdated];
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
	
	// Set up the title view container and title text
	_navbarTitle = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
	
	_titleLayer = [CATextLayer new];
	_titleLayer.frame = CGRectMake(0, 4, 200, 28);
	_titleLayer.font = (__bridge CFTypeRef)([UIFont fontWithName:@"HelveticaNeue-Medium" size:26.0]);
	_titleLayer.fontSize = 17.0f;
	_titleLayer.contentsScale = [UIScreen mainScreen].scale;
	_titleLayer.foregroundColor = [UIColor blackColor].CGColor;
	_titleLayer.string = _course.title;
	_titleLayer.alignmentMode = kCAAlignmentCenter;
	
	[_navbarTitle.layer addSublayer:_titleLayer];
	
	_subtitleLayer = [CATextLayer new];
	_subtitleLayer.frame = CGRectMake(0, 25, 200, 28);
	_subtitleLayer.font = (__bridge CFTypeRef)([UIFont fontWithName:@"HelveticaNeue-LightItalic" size:26.0]);
	_subtitleLayer.fontSize = 12.0f;
	_subtitleLayer.contentsScale = [UIScreen mainScreen].scale;
	_subtitleLayer.foregroundColor = [UIColor lightGrayColor].CGColor;
	_subtitleLayer.string = [NSString stringWithFormat:NSLocalizedString(@"Cycle %u", @"class detail"), _displayCycle+1];
	_subtitleLayer.alignmentMode = kCAAlignmentCenter;
	
	[_navbarTitle.layer addSublayer:_subtitleLayer];
	
	// Apply to nav item
	self.navigationItem.titleView = _navbarTitle;
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
	return [SQUClassDetailCell cellHeightForCategory:_currentCycle.categories[indexPath.row]] + 8;
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

#pragma mark - Cycle switching
- (void) updateCycle {
	if(_displayCycle > _course.cycles.count) return;
	
	_currentCycle = _course.cycles[_displayCycle];
	
	NSString *lastUpdated = [NSString stringWithFormat:NSLocalizedString(@"Last Updated on %@", @"class detail pull to refresh"), [_refreshDateFormatter stringFromDate:_currentCycle.last_updated]];
	self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:lastUpdated];
	
	[self.tableView reloadData];
}

#pragma mark - UI
- (void) reloadData:(id) sender {
	// Update the title
	_subtitleLayer.string = [NSString stringWithFormat:NSLocalizedString(@"Cycle %u", @"class info"), _displayCycle+1];
	
	// If the cycle has data, update table
	if(_currentCycle.categories.count != 0) {
		// Hide the HUD if the last request showed it
		if(_iCanHazCompleteReload) {
			[SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"Grades Updated", @"class grades")];
		}
		
		[self.tableView reloadData];
		_iCanHazCompleteReload = NO;
	} else {
		_iCanHazCompleteReload = YES;
		[SVProgressHUD showProgress:-1.0 status:NSLocalizedString(@"Updating Grades…", @"class detail HUD when loading grades for first time") maskType:SVProgressHUDMaskTypeGradient];
	}
	
	// Update course grades
	[[SQUGradeManager sharedInstance] fetchNewCycleGradesFromServerForCourse:_course.courseCode withCycle:_displayCycle % 3 andSemester:_displayCycle / 3 andDoneCallback:^(NSError * error) {
		if(!error) {
			_currentCycle = _course.cycles[_displayCycle];
			[self.tableView reloadData];
			
			if(_iCanHazCompleteReload) {
				[SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"Grades Updated", @"class grades")];
			}
		} else {
			NSLog(@"Error updating course grades: %@", error);
			
			// Error 3000 indicates there's no data for this cycle
			if(error.code == kSQUDistrictManagerErrorNoDataAvailable) {
				// there is no data available for this cycle, try the previous cycle
				if(_displayCycle != 0) {
					_displayCycle--;
					_currentCycle = _course.cycles[_displayCycle];
					
					[self reloadData:self];
					return;
				} else {
					// Admit defeat, we got to cycle 1 and there's no data.
					if(_iCanHazCompleteReload) {
						[SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"Grades Updated", @"class grades")];
					}
					
					[self.tableView reloadData];
				}
			} else {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error Updating Grades", nil) message:error.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
				[alert show];
				
				if(_iCanHazCompleteReload) {
					[SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Error", @"class grades")];
				}
			}
		}
		
		[self.refreshControl endRefreshing];
		
		NSString *lastUpdated = [NSString stringWithFormat:NSLocalizedString(@"Last Updated on %@", @"class detail pull to refresh"), [_refreshDateFormatter stringFromDate:_currentCycle.last_updated]];
		self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:lastUpdated];
		
		[[NSUserDefaults standardUserDefaults] setInteger:_displayCycle forKey:@"selectedCycle"];
	}];
}

- (void) openSidebar:(id) sender {
	if([self revealController].state == PKRevealControllerShowsFrontViewController) {
		[[self revealController] showViewController:[self revealController].leftViewController];
	} else {
		[[self revealController] resignPresentationModeEntirely:YES animated:YES completion:NULL];
	}
}

#pragma mark - Cycle selection
- (void) openCyclesSwitcher:(id) sender {
	// Build a list of cycles that have data for this class
	NSMutableArray *cycles = [NSMutableArray new];
	
	for(SQUCycle *cycle in _course.cycles) {
		if(cycle.dataAvailableInGradebook.boolValue) {
			[cycles addObject:cycle.cycleIndex];
		}
	}

	SQUClassCycleChooserController *controller = [[SQUClassCycleChooserController alloc] initWithCycles:cycles];
	controller.delegate = self;
	controller.contentSizeForViewInPopover = CGSizeMake(175, 230);
	controller.selectedCycle = _displayCycle;
	
	_popover = [[WYPopoverController alloc] initWithContentViewController:[[UINavigationController alloc] initWithRootViewController:controller]];
	[_popover presentPopoverFromBarButtonItem:sender permittedArrowDirections:WYPopoverArrowDirectionAny animated:YES options:WYPopoverAnimationOptionFade];
}

- (void) cycleChooser:(SQUClassCycleChooserController *) chooser selectedCycle:(NSUInteger) cycle {
	if(_displayCycle != cycle) {
		_displayCycle = cycle;
		_currentCycle = _course.cycles[_displayCycle];
		_subtitleLayer.string = [NSString stringWithFormat:NSLocalizedString(@"Cycle %u", @"class info"), _displayCycle+1];

		[self reloadData:chooser];
		
		[[NSUserDefaults standardUserDefaults] setInteger:_displayCycle forKey:@"selectedCycle"];
	}
	
	[_popover dismissPopoverAnimated:YES];
}

@end