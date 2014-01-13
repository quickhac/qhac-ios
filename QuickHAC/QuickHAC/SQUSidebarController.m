//
//  SQUSidebarController.m
//  QuickHAC
//
//  Created by Tristan Seifert on 12/27/13.
//  See README.MD for licensing and copyright information.
//

#import "SQUGradeOverviewController.h"
#import "SQUClassDetailController.h"
#import "SQUSidebarController.h"
#import "SQUGradeManager.h"
#import "SQUCoreData.h"
#import "SQUSidebarCell.h"
#import "SQUSidebarSwitcherButton.h"
#import "UIColor+SQUColourUtilities.h"
#import "SQUUserSwitcherView.h"
#import "SQUAppDelegate.h"
#import "SQUSettingsViewController.h"

#import "PKRevealController.h"

@interface SQUSidebarController ()

@end

@implementation SQUSidebarController
@synthesize overviewController = _overview;

- (id) init {
    self = [super init];
    if (self) {
		selectedItem =[NSIndexPath indexPathForRow:0 inSection:0];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gradesUpdatedNotification:) name:SQUGradesDataUpdatedNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showCourseOverviewNotification:) name:SQUSidebarControllerShowSidebarMessage object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(goToOverview:) name:SQUSidebarControllerShowOverview object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifToggleSwitcher:) name:SQUSidebarControllerToggleUserSwitcher object:nil];
		
		_lastSelection = [NSIndexPath indexPathForRow:0 inSection:0];
    }
    return self;
}

- (void) viewDidLoad {
    [super viewDidLoad];

	self.navigationController.navigationBarHidden = YES;
	self.edgesForExtendedLayout = UIRectEdgeNone;

	// Set up new content view
	self.view.backgroundColor = UIColorFromRGB(0x363636);
	
	// Set up table view
	CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
	_tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 65, 260, screenHeight-65) style:UITableViewStylePlain];
	[_tableView registerClass:NSClassFromString(@"SQUSidebarCell") forCellReuseIdentifier:@"SidebarCell"];
	
	_tableView.delegate = self;
	_tableView.dataSource = self;
	
	_tableView.backgroundColor = UIColorFromRGB(0x363636);
	_tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
	_tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	_tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, _tableView.bounds.size.width, 0.01f)];

	[_tableView selectRowAtIndexPath:selectedItem animated:NO scrollPosition:UITableViewScrollPositionTop];
	[self.view addSubview:_tableView];
	
	// Set up top view
	_topView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 260, 64)];
	_topView.backgroundColor = UIColorFromRGB(0x363636);
	[self.view addSubview:_topView];
	
	// settings button: 60px
	_settingsButton = [[UIButton alloc] initWithFrame:CGRectMake(200, 0, 60, 64)];
	[_settingsButton setBackgroundImage:[UIColorFromRGB(0x363636) imageFromColor] forState:UIControlStateNormal];
	[_settingsButton setBackgroundImage:[UIColorFromRGB(0x2b2b2b) imageFromColor] forState:UIControlStateSelected];
	[_settingsButton setImage:[UIImage imageNamed:@"sidebar_gear"] forState:UIControlStateNormal];
	[_settingsButton addTarget:self action:@selector(showSettings:) forControlEvents:UIControlEventTouchUpInside];
	[_topView addSubview:_settingsButton];
	
	// account switcher button: 200px
	_switcherButton = [[SQUSidebarSwitcherButton alloc] initWithFrame:CGRectMake(0, 0, 200, 64)];
	[_switcherButton addTarget:self action:@selector(toggleSwitcher:) forControlEvents:UIControlEventTouchUpInside];
	[_topView addSubview:_switcherButton];
	
	// Separator
	UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(0, 64, 260, 1)];
	separator.backgroundColor = UIColorFromRGB(0x262626);
	[self.view addSubview:separator];
	
	separator = [[UIView alloc] initWithFrame:CGRectMake(_tableView.frame.size.width, 0, 1, self.view.frame.size.height)];
	separator.backgroundColor = UIColorFromRGB(0x262626);
	[self.view addSubview:separator];
}

- (void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source
- (NSInteger) numberOfSectionsInTableView:(UITableView *) tableView {
    // Return the number of sections.
    return 2;
}

- (NSInteger) tableView:(UITableView *) tableView numberOfRowsInSection:(NSInteger) section {
    // Return the number of rows in the section.
    switch(section) {
		case 0:
			return 1;
			break;
			
		case 1:
			return [SQUGradeManager sharedInstance].student.courses.count;
			break;
			
		default:
			return 0;
			break;
	}
}

- (UITableViewCell *) tableView:(UITableView *) tableView cellForRowAtIndexPath:(NSIndexPath *) indexPath {
    static NSString *CellIdentifier = @"SidebarCell";
    SQUSidebarCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
   
	switch(indexPath.section) {
		case 0:
			cell.titleText = NSLocalizedString(@"Overview", @"sidebar item");
			break;
			
		case 1: {
			SQUCourse *course = [SQUGradeManager sharedInstance].student.courses[indexPath.row];
			cell.titleText = course.title;
			
			break;
		}
			
		default:
			return 0;
			break;
	}
    
    return cell;
}

- (NSString *) tableView:(UITableView *) tableView titleForHeaderInSection:(NSInteger) section {
	switch(section) {	
		case 1:
			return NSLocalizedString(@"Courses", @"sidebar section header");
			break;
			
		default:
			return 0;
			break;
	}
}

#pragma mark - Navigation
- (void) tableView:(UITableView *) tableView didSelectRowAtIndexPath:(NSIndexPath *) indexPath {
	selectedItem = indexPath;
	
	switch(indexPath.section) {
		case 0:
			_lastSelection = indexPath;
			
			[[self revealController] setFrontViewController:_overview.navigationController];
			[[self revealController] resignPresentationModeEntirely:YES animated:YES completion:NULL];
			break;
			
		case 1: {
			SQUCourse *course = [SQUGradeManager sharedInstance].student.courses[indexPath.row];
			
			NSUInteger numCyclesAvailable = 0;
			
			for(SQUCycle *cycle in course.cycles) {
				if(cycle.dataAvailableInGradebook.boolValue) {
					numCyclesAvailable++;
				}
			}
			
			// Display a message if this cycle has no information
			if(!numCyclesAvailable) {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No Grades Available", nil) message:[NSString stringWithFormat:NSLocalizedString(@"There is no data available in the gradebook for the course %@.\nPlease check again later, or consult %@.", @"no cycles with data alert"), course.title, course.teacher_name] delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
				[alert show];
				
				[tableView selectRowAtIndexPath:_lastSelection animated:NO scrollPosition:UITableViewScrollPositionNone];
				return;
			}
			
			[self showCourseOverviewForCourse:course];
			_lastSelection = indexPath;
			break;
		}
			
		default:
			break;
	}
}

#pragma mark - Button callbacks
- (void) showSettings:(id) sender {
	SQUSettingsViewController *settings = [[SQUSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
	UINavigationController *navCtrlr = [[UINavigationController alloc] initWithRootViewController:settings];
	[self presentViewController:navCtrlr animated:YES completion:NULL];
}

- (void) toggleSwitcher:(id) sender {
	if(!_switcher) {
		CGRect switcherFrame = _tableView.frame;
		switcherFrame.size.height += 32;
		switcherFrame.origin.y = -switcherFrame.size.height + _topView.frame.size.height - 32;
		
		_switcher = [[SQUUserSwitcherView alloc] initWithFrame:switcherFrame];
		[self.view insertSubview:_switcher belowSubview:_topView];
	}
	
	// Update switcher's data
	[_switcher updateStudents:nil];
	
	// Set up bounce animation
	CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"position.y"];
	animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
	animation.duration = 0.2;
	
	CGRect switcherFrame = _tableView.frame;
	
	// Show switcher
	if(_switcherButton.toggled) {
		CGFloat finalPoint = 32+(switcherFrame.size.height/2);
		
		// Add keyframes
		int steps = 100;
		NSMutableArray *values = [NSMutableArray arrayWithCapacity:steps];
		double value = 0;
		float e = 2.71;
		for (int t = 0; t < steps; t++) {
			// 32 is the bouncyness coefficient, in pixels
			value = 32 * pow(e, -0.055*t) * cos(0.08*t) + finalPoint;
			[values addObject:@(value)];
		}
		
		animation.values = values;
		
		// UIView animation slides down, CAAnimation does bounce
		[UIView animateWithDuration:0.2 animations:^{
			CGRect newFrame = switcherFrame;
			newFrame.origin.y = _tableView.frame.origin.y-32;
			_switcher.frame = newFrame;
		} completion:^(BOOL finished) {
			// do bounce
			[_switcher.layer addAnimation:animation forKey:nil];
		}];
	} else {
		[UIView animateWithDuration:0.4 animations:^{
			CGRect newFrame = switcherFrame;
			newFrame.origin.y = -switcherFrame.size.height + _topView.frame.size.height - 32;
			_switcher.frame = newFrame;
		}];
	}
}

#pragma mark - Notifications
- (void) gradesUpdatedNotification:(NSNotification *) notif {
	[_tableView reloadData];
	
	if(selectedItem) {
		[_tableView selectRowAtIndexPath:selectedItem animated:YES scrollPosition:UITableViewScrollPositionNone];
	}
}

- (void) goToOverview:(NSNotification *) notif {
	selectedItem = [NSIndexPath indexPathForRow:0 inSection:0];
	
	[[self revealController] setFrontViewController:_overview.navigationController];
	[[self revealController] resignPresentationModeEntirely:YES animated:YES completion:NULL];
}

- (void) notifToggleSwitcher:(NSNotification *) notif {
	[_switcherButton buttonActuated:nil];
	[self toggleSwitcher:nil];
}

/*
 * Notification fired when the main view wants to show the information for a
 * specific course.
 */
- (void) showCourseOverviewNotification:(NSNotification *) notif {
	SQUCourse *course = (SQUCourse *) notif.userInfo[@"course"];
	
	if(course) {
		NSUInteger numCyclesAvailable = 0;
		
		for(SQUCycle *cycle in course.cycles) {
			if(cycle.dataAvailableInGradebook.boolValue) {
				numCyclesAvailable++;
			}
		}
		
		// Display a message if this cycle has no information
		if(!numCyclesAvailable) {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No Grades Available", nil) message:[NSString stringWithFormat:NSLocalizedString(@"There is no data available in the gradebook for the course %@.\nPlease check again later, or consult %@.", @"no cycles with data alert"), course.title, course.teacher_name] delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
			[alert show];
			return;
		}
		
		NSUInteger index = [[[SQUGradeManager sharedInstance] getCoursesForCurrentStudent] indexOfObject:course];
		
		selectedItem = [NSIndexPath indexPathForRow:index inSection:1];
		[_tableView selectRowAtIndexPath:selectedItem animated:YES scrollPosition:UITableViewScrollPositionNone];
		
		SQUClassDetailController *controller = [[SQUClassDetailController alloc] initWithCourse:course];
		UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
		
		// !!! this is real kind of a hack
		PKRevealController *drawerController = [PKRevealController revealControllerWithFrontViewController:navController
																	 leftViewController:self.navigationController
																	rightViewController:nil];
		drawerController.animationDuration = 0.25;
		
		[[SQUAppDelegate sharedDelegate].window setRootViewController:drawerController];
	}
}

- (void) showCourseOverviewForCourse:(SQUCourse *) course {
	NSUInteger index = [[[SQUGradeManager sharedInstance] getCoursesForCurrentStudent] indexOfObject:course];
	
	selectedItem = [NSIndexPath indexPathForRow:index inSection:1];
	[_tableView selectRowAtIndexPath:selectedItem animated:YES scrollPosition:UITableViewScrollPositionNone];
	
	SQUClassDetailController *controller = [[SQUClassDetailController alloc] initWithCourse:course];
	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
	
	if([self revealController].state == PKRevealControllerShowsFrontViewController) {
		[[self revealController] showViewController:[self revealController].leftViewController animated:NO completion:NULL];
		[[self revealController] setFrontViewController:navController];
		[[self revealController] resignPresentationModeEntirely:YES animated:YES completion:NULL];
	} else {
		[[self revealController] setFrontViewController:navController];
		[[self revealController] resignPresentationModeEntirely:YES animated:YES completion:NULL];
	}
}

@end
