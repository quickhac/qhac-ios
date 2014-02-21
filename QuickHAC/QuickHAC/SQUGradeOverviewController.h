//
//  SQUGradeOverviewController.h
//  QuickHAC
//
//  Created by Tristan Seifert on 16/07/2013.
//  See README.MD for licensing and copyright information.
//

#import <UIKit/UIKit.h>

@interface SQUGradeOverviewController : UITableViewController {	
	// Navbar title view
	UIView *_navbarTitle;
	CATextLayer *_titleLayer;
	CATextLayer *_subtitleLayer;
	
	BOOL _cellsCollapsed;
}

@end
