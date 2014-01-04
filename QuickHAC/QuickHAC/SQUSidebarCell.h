//
//  SQUSidebarCell.h
//  QuickHAC
//
//  Created by Tristan Seifert on 1/1/14.
//  See README.MD for licensing and copyright information.
//

#import <UIKit/UIKit.h>

@interface SQUSidebarCell : UITableViewCell {
	UILabel *_gradeLabel;
	
	UIImage *_icon;
	UIImage *_iconSelected;
}

/// Icon displayed on left of cell.
@property (nonatomic) UIImage *icon;
/// Selected icon
@property (nonatomic) UIImage *iconSelected;

- (void) setGrade:(float) grade;

@end
