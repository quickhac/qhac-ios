//
//  SQUTabletSidebarController.m
//  QuickHAC
//
//  Created by Tristan Seifert on 1/1/14.
//  See README.MD for licensing and copyright information.
//

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
		return 66;
	} else {
		return 44;
	}
}

- (UITableViewCell *) tableView:(UITableView *) tableView cellForRowAtIndexPath:(NSIndexPath *) indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SidebarCell" forIndexPath:indexPath];
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	cell.textLabel.text = @"OBAMAOBAMAOBAMA";
    
    return cell;
}

/*
 * Table selection callback
 */
- (void) tableView:(UITableView *) tableView didSelectRowAtIndexPath:(NSIndexPath *) indexPath {
	
}

@end
