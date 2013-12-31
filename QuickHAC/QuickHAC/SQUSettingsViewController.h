//
//  SQUSettingsViewController.h
//  QuickHAC
//
//  Created by Tristan Seifert on 12/29/13.
//  See README.MD for licensing and copyright information.
//

#import "LTHPasscodeViewController.h"

#import <Foundation/Foundation.h>
#import <QuickDialogController.h>

@interface SQUSettingsViewController : UITableViewController <UIAlertViewDelegate, LTHPasscodeViewControllerDelegate> {
	UITextView *_feedbackView;
}

@end
