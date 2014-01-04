//
//  SQUTabletSidebarController.m
//  QuickHAC
//
//  Created by Tristan Seifert on 1/1/14.
//  See README.MD for licensing and copyright information.
//

#import "SQUCoreData.h"
#import "SQUSidebarCell.h"
#import "SQUGradeManager.h"
#import "SQUTabletSidebarController.h"

@interface SQUTabletSidebarController ()

@end

@implementation SQUTabletSidebarController

- (id) initWithStyle:(UITableViewStyle) style {
    self = [super initWithStyle:style];
    if (self) {
        [self.tableView registerClass:NSClassFromString(@"SQUSidebarCell") forCellReuseIdentifier:@"SidebarCell"];
		
		self.title = NSLocalizedString(@"QuickHAC", nil);
		self.tableView.backgroundColor = UIColorFromRGB(0x4E5758);
		self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
		self.automaticallyAdjustsScrollViewInsets = NO;
		
		// 28 = no margin
		self.tableView.contentInset = UIEdgeInsetsMake(28+8, 0, 0, 0);
		
		[self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTableNotification:) name:SQUGradesDataUpdatedNotification object:nil];
    }
    return self;
}

- (void) viewDidLoad {
    [super viewDidLoad];

    self.clearsSelectionOnViewWillAppear = NO;
}

#pragma mark - Table view data source

- (NSInteger) numberOfSectionsInTableView:(UITableView *) tableView {
    // Return the number of sections.
    return 3;
}

- (NSInteger) tableView:(UITableView *) tableView numberOfRowsInSection:(NSInteger) section {
	switch(section) {
		case 0:
			return 1;
			break;
			
		case 1:
			return [[SQUGradeManager sharedInstance] getCoursesForCurrentStudent].count;
			break;
			
		case 2:
			return 4;
			break;
			
		default:
			return 0;
			break;
	}
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if(indexPath.section == 0) {
		return 50;
	} else {
		return 36;
	}
}

- (UITableViewCell *) tableView:(UITableView *) tableView cellForRowAtIndexPath:(NSIndexPath *) indexPath {
    SQUSidebarCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SidebarCell" forIndexPath:indexPath];
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	
	[cell setGrade:-1];
	cell.icon = nil;
	cell.iconSelected = nil;
	cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:17.0];
	
	switch(indexPath.section) {
		case 0: {
			cell.icon = [UIImage imageNamed:@"icon_chart_bars"];
			cell.iconSelected = [UIImage imageNamed:@"icon_chart_bars_selected"];
			cell.textLabel.text = NSLocalizedString(@"Dashboard", nil);
			break;
		}
			
		case 1: {
			SQUCourse *course = [[SQUGradeManager sharedInstance] getCoursesForCurrentStudent][indexPath.row];
			cell.textLabel.text = course.title;
			
			// Try to find the latest cycle with data now
			NSInteger latestCycle = -1;
			for(SQUCycle *cycle in course.cycles) {
				if(cycle.dataAvailableInGradebook.boolValue) {
					latestCycle++;
				}
			}
			
			if(latestCycle != -1) {
				SQUCycle *semester = course.cycles[latestCycle];
				[cell setGrade:semester.average.floatValue];
			} else {
				[cell setGrade:-1];
			}
			
			break;
		}

		case 2: {
			NSArray *strings = @[NSLocalizedString(@"Preferences", nil), NSLocalizedString(@"Help", nil), NSLocalizedString(@"Report Issue", nil), NSLocalizedString(@"Sign Out", nil)];
			cell.textLabel.text = strings[indexPath.row];
			
			break;
		}
	}
    
    return cell;
}

- (UIView *) tableView:(UITableView *) tableView viewForHeaderInSection:(NSInteger) section {
	if(section == 1 || section == 2) {
		UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, self.tableView.frame.size.width-32, 17)];
		headerLabel.textColor = UIColorFromRGB(0xBDC3C7);
		headerLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:16.0];
		
		// Set strings
		NSArray *titles = @[NSLocalizedString(@"COURSES", nil), NSLocalizedString(@"MORE", nil)];
		headerLabel.text = titles[section-1];
		
		// Container
		UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 22)];
		[container addSubview:headerLabel];
		
		// Add the underline
		CAGradientLayer *layer = [CAGradientLayer layer];
		layer.backgroundColor = UIColorFromRGB(0x7F8C8D).CGColor;
		layer.frame = CGRectMake(16, 18, self.tableView.frame.size.width-32, 1);
		
		[container.layer addSublayer:layer];
		container.clipsToBounds = NO;
		
		return container;
	}
	
	return nil;
}

- (CGFloat) tableView:(UITableView *) tableView heightForHeaderInSection:(NSInteger) section {
	return (section == 0) ? 0 : 22;
}

- (CGFloat) tableView:(UITableView *) tableView heightForFooterInSection:(NSInteger) section {
	return 0;
}

/*
 * Table selection callback
 */
- (void) tableView:(UITableView *) tableView didSelectRowAtIndexPath:(NSIndexPath *) indexPath {
	
}


- (void) updateTableNotification:(NSNotification *) notif {
	NSIndexPath *path = self.tableView.indexPathForSelectedRow;
	[self.tableView reloadData];
	[self.tableView selectRowAtIndexPath:path animated:NO scrollPosition:UITableViewScrollPositionNone];
}

@end
