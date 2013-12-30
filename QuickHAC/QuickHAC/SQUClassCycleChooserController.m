//
//  SQUClassCycleChooserController.m
//  QuickHAC
//
//  Created by Tristan Seifert on 12/29/13.
//  Copyright (c) 2013 Squee! Apps. All rights reserved.
//

#import "SQUClassCycleChooserController.h"

@implementation SQUClassCycleChooserController
@synthesize delegate = _delegate, selectedCycle = _selectedCycle;

- (id) initWithCycles:(NSArray *) cycles {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        _cycles = cycles;
		self.title = NSLocalizedString(@"Cycles", nil);
		[self.tableView registerClass:NSClassFromString(@"UITableViewCell") forCellReuseIdentifier:@"CycleCell"];
    }
	
    return self;
}

- (void) viewWillAppear:(BOOL) animated {
	[super viewWillAppear:animated];
	[self.tableView reloadData];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return _cycles.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"CycleCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
	NSNumber *cycle = _cycles[indexPath.row];
	cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Cycle %u", @"cycle selector"), cycle.unsignedIntegerValue+1];
    
	if(cycle.unsignedIntegerValue == _selectedCycle) {
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	} else {
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
	
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSUInteger cycle = [_cycles[indexPath.row] unsignedIntegerValue];
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	[_delegate cycleChooser:self selectedCycle:cycle];
}

@end
