//
//  SQUGradeOverviewTableViewCell.h
//  QuickHAC
//
//  Created by Tristan Seifert on 16/07/2013.
//  See README.MD for licensing and copyright information.
//

#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>

#define SQUGradeOverviewCellHeight 212.0
#define SQUGradeOverviewCellCollapsedHeight 70

@class SQUCourse, SQUCycle;
@interface SQUGradeOverviewTableViewCell : UITableViewCell {
    // public properties
    SQUCourse *_courseInfo;
    
@private	
	CALayer *_backgroundLayer;
	
    CATextLayer *_courseTitle;
	CATextLayer *_currentAverageLabel;
	
    CATextLayer *_periodTitle;
	CALayer *_periodCircle;
	
	CATextLayer *_noGradesAvailable;
	
	NSMutableArray *_headers;
	NSMutableArray *_cells;
	NSMutableArray *_shades;
	
	BOOL _isCollapsed;
}

@property (nonatomic) SQUCourse *courseInfo;
@property (nonatomic) BOOL isCollapsed;

- (void) updateUI;

+ (UIColor *) colourForLetterGrade:(NSString *) grade;
+ (CGFloat) cellHeightForCourse:(SQUCourse *) course;
+ (UIColor *) gradeChangeColour:(SQUCycle *) cycle;

@end
