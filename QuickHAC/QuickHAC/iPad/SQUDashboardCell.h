//
//  SQUDashboardCell.h
//  QuickHAC
//
//  Created by Tristan Seifert on 2/22/14.
//  See README.MD for licensing and copyright information.
//

#import <UIKit/UIKit.h>

@class SQUCourse;
@interface SQUDashboardCell : UICollectionViewCell {
	SQUCourse *_courseInfo;
	
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
}

@property (nonatomic, readwrite, setter = setCourse:) SQUCourse *course;

@end
