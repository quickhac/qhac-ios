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

@class SQUCourse;
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
}

@property (nonatomic) SQUCourse *courseInfo;

- (void) updateUI;

+ (UIColor *) colourizeGrade:(float) grade;
+ (UIColor *) colourForLetterGrade:(NSString *) grade;
+ (CGFloat) cellHeightForCourse:(SQUCourse *) course;

@end
