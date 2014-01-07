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
#import "SQUAppDelegate.h"
#import "SQUSettingsViewController.h"

#import "PKRevealController.h"

@interface SQUSidebarController ()

@end

@implementation SQUSidebarController
@synthesize overviewController = _overview;

- (id) initWithStyle:(UITableViewStyle) style {
    self = [super initWithStyle:style];
    if (self) {
		[self.tableView registerClass:NSClassFromString(@"UITableViewCell") forCellReuseIdentifier:@"SidebarCell"];
		
		UIImageView *backgroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"menu-background"]];
		self.tableView.backgroundView = backgroundImageView;
		
		selectedItem =[NSIndexPath indexPathForRow:0 inSection:0];
		[self.tableView selectRowAtIndexPath:selectedItem animated:NO scrollPosition:UITableViewScrollPositionTop];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gradesUpdatedNotification:) name:SQUGradesDataUpdatedNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showCourseOverviewNotification:) name:SQUSidebarControllerShowSidebarMessage object:nil];
		
		_lastSelection = [NSIndexPath indexPathForRow:0 inSection:0];
    }
    return self;
}

- (void) viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = NO;
}

- (void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source
- (NSInteger) numberOfSectionsInTableView:(UITableView *) tableView {
    // Return the number of sections.
    return 3;
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
			
		case 2:
			return 1;
			break;
			
		default:
			return 0;
			break;
	}
}

- (UITableViewCell *) tableView:(UITableView *) tableView cellForRowAtIndexPath:(NSIndexPath *) indexPath {
    static NSString *CellIdentifier = @"SidebarCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    cell.backgroundColor  = nil;
	cell.backgroundView = nil;
	
	cell.textLabel.textColor = [UIColor whiteColor];
   
	switch(indexPath.section) {
		case 0:
			cell.textLabel.text = NSLocalizedString(@"Overview", @"sidebar item");
			break;
			
		case 1: {
			SQUCourse *course = [SQUGradeManager sharedInstance].student.courses[indexPath.row];
			cell.textLabel.text = course.title;
			
			break;
		}
			
		case 2:
			cell.textLabel.text = NSLocalizedString(@"Settings", @"sidebar item");
			break;
			
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
			
		case 2:
			return NSLocalizedString(@"Miscellaneous", @"sidebar section header");
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
			
		case 2: {
			_lastSelection = indexPath;
			
			SQUSettingsViewController *settings = [[SQUSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
			UINavigationController *navCtrlr = [[UINavigationController alloc] initWithRootViewController:settings];
				
			[[self revealController] setFrontViewController:navCtrlr];
			[[self revealController] resignPresentationModeEntirely:YES animated:YES completion:NULL];
			
			break;
		}
			
		default:
			break;
	}
}

#pragma mark - UI Integration
- (void) gradesUpdatedNotification:(NSNotification *) notif {
	[self.tableView reloadData];
	
	if(selectedItem) {
		[self.tableView selectRowAtIndexPath:selectedItem animated:YES scrollPosition:UITableViewScrollPositionNone];
	}
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
		[self.tableView selectRowAtIndexPath:selectedItem animated:YES scrollPosition:UITableViewScrollPositionNone];
		
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
	[self.tableView selectRowAtIndexPath:selectedItem animated:YES scrollPosition:UITableViewScrollPositionNone];
	
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
