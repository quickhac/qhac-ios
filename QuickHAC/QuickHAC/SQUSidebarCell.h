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
}

- (void) setGrade:(float) grade;

@end
