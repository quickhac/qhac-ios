//
//  SQUGradeOverviewController.h
//  QuickHAC
//
//  Created by Tristan Seifert on 16/07/2013.
//  See README.MD for licensing and copyright information.
//

#import <UIKit/UIKit.h>

@interface SQUGradeOverviewController : UITableViewController {
	NSDateFormatter *_refreshDateFormatter;
	
	// Navbar title view
	UIView *_navbarTitle;
	CATextLayer *_titleLayer;
	CATextLayer *_subtitleLayer;
}

@end
