//
//  SQUSettingsStudents.h
//  QuickHAC
//
//  Created by Tristan Seifert on 12/30/13.
//  See README.MD for licensing and copyright information.
//

#import <UIKit/UIKit.h>

#define kSQUActionSheetDeleteStudent 1337

@interface SQUSettingsStudents : UITableViewController <UIActionSheetDelegate> {
	NSMutableArray *_students;
}

@end
