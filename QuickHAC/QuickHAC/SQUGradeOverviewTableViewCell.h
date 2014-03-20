//
//  SQUGradeOverviewTableViewCell.h
//  QuickHAC
//
//  Created by Tristan Seifert on 16/07/2013.
//  See README.MD for licensing and copyright information.
//

#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>

#define SQUGradeOverviewCellHeight 216.0
#define SQUGradeOverviewCellCollapsedHeight 76

@class SQUCourse, SQUCycle;
@interface SQUGradeOverviewTableViewCell : UITableViewCell {
    // public properties
    __strong SQUCourse *_courseInfo;
    
@private	
	CAGradientLayer *_backgroundLayer;
	
    CATextLayer *_courseTitle;
	CATextLayer *_currentAverageLabel;
	
    CATextLayer *_periodTitle;
	CALayer *_periodCircle;
	
	CATextLayer *_noGradesAvailable;
	
	NSMutableArray *_headers;
	NSMutableArray *_cells;
	NSMutableArray *_shades;
	
	CAGradientLayer *_topBar;
	
	BOOL _isCollapsed;
}

@property (nonatomic, strong) SQUCourse *courseInfo;
@property (nonatomic) BOOL isCollapsed;

- (void) updateUI;

+ (UIColor *) colourForLetterGrade:(NSString *) grade;
+ (CGFloat) cellHeightForCourse:(SQUCourse *) course;
+ (UIColor *) gradeChangeColour:(SQUCycle *) cycle;

@end
