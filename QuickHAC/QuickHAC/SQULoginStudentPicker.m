//
//  SQULoginStudentPicker.m
//  QuickHAC
//
//  Created by Tristan Seifert on 1/2/14.
//  See README.MD for licensing and copyright information.
//

#import "SQUCoreData.h"
#import "SQULoginStudentPicker.h"

@interface SQULoginStudentPicker ()

@end

@implementation SQULoginStudentPicker
@synthesize delegate = _delegate, students = _students;

- (id) initWithStyle:(UITableViewStyle) style {
    self = [super initWithStyle:style];
    if (self) {
        [self.tableView registerClass:NSClassFromString(@"UITableViewCell") forCellReuseIdentifier:@"StudentSelectorCell"];
		self.title = NSLocalizedString(@"Select Student", nil);
		
		self.navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
		
		UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelPicker:)];
		self.navigationItem.leftBarButtonItem = cancel;
    }
    return self;
}

#pragma mark - Table view data source

- (NSInteger) numberOfSectionsInTableView:(UITableView *) tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return _students.count;
}

- (UITableViewCell *) tableView:(UITableView *) tableView cellForRowAtIndexPath:(NSIndexPath *) indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"StudentSelectorCell" forIndexPath:indexPath];
    
    SQUStudent *student = _students[indexPath.row];
	cell.textLabel.text = student.name;
    
	
    return cell;
}

#pragma mark - UI
- (void) cancelPicker:(id) sender {
	[_delegate studentPickerCancelled:self];
}

- (void) tableView:(UITableView *) tableView didSelectRowAtIndexPath:(NSIndexPath *) indexPath {
	[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
	[_delegate studentPickerDidSelect:self withStudent:_students[indexPath.row]];
}

@end
