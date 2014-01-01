//
//  SQUSidebarCell.h
//  QuickHAC
//
//  Created by Tristan Seifert on 1/1/14.
//  Copyright (c) 2014 Squee! Apps. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SQUSidebarCell : UITableViewCell {
	UILabel *_gradeLabel;
}

- (void) setGrade:(float) grade;

@end
