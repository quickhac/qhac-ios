//
//  SQUClassDetailController.h
//  QuickHAC
//
//  Created by Tristan Seifert on 12/28/13.
//  See README.MD for licensing and copyright information.
//

#import <UIKit/UIKit.h>
#import "SQUClassCycleChooserController.h"

@class SQUCourse;
@class SQUCycle;
@class WYPopoverController;

@interface SQUClassDetailController : UITableViewController <SQUClassCycleChooserControllerDelegate> {
	NSDateFormatter *_refreshDateFormatter;
	SQUCourse *_course;
	
	NSUInteger _displayCycle;
	SQUCycle *_currentCycle;
	
	BOOL _iCanHazCompleteReload;
	
	// Navbar title view
	UIView *_navbarTitle;
	CATextLayer *_titleLayer;
	CATextLayer *_subtitleLayer;
	
	WYPopoverController *_popover;
}

- (id) initWithCourse:(SQUCourse *) course;


@end
