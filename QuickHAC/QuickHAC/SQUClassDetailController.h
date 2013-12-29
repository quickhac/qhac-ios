//
//  SQUClassDetailController.h
//  QuickHAC
//
//  Created by Tristan Seifert on 12/28/13.
//  Copyright (c) 2013 Squee! Apps. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SQUCourse;
@class SQUCycle;

@interface SQUClassDetailController : UITableViewController {
	NSDateFormatter *_refreshDateFormatter;
	SQUCourse *_course;
	
	NSUInteger _displayCycle;
	SQUCycle *_currentCycle;
	
	// Navbar title view
	UIView *_navbarTitle;
	CATextLayer *_titleLayer;
	CATextLayer *_subtitleLayer;
}

- (id) initWithCourse:(SQUCourse *) course;


@end
