//
//  SQUGradeOverviewTableViewCell.h
//  QuickHAC
//
//  Created by Tristan Seifert on 16/07/2013.
//  See README.MD for licensing and copyright information.
//

#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>

#define SQUGradeOverviewCellHeight 150.0

@class SQUCourse;
@interface SQUGradeOverviewTableViewCell : UITableViewCell {
    // public properties
    SQUCourse *_courseInfo;
    
@private
	NSMutableArray *_semesterHeads;
	NSMutableArray *_cycleHeads;
	
	CALayer *_backgroundLayer;
	
	CAGradientLayer *_semesterSeperator;
    CAGradientLayer *_sideBar;
    CATextLayer *_courseTitle;
    CATextLayer *_periodTitle;
}

@property (nonatomic) SQUCourse *courseInfo;

- (void) updateUI;

@end
