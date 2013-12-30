//
//  SQUClassDetailCell.h
//  QuickHAC
//
//  Created by Tristan Seifert on 12/28/13.
//  See README.MD for licensing and copyright information.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>


@class SQUCategory;
@interface SQUClassDetailCell : UITableViewCell {
	CALayer *_backgroundLayer;
    CAGradientLayer *_sideBar;
	
    CATextLayer *_categoryTitle;
	CATextLayer *_weightTitle;
	
	CATextLayer *_noGradesText;
	
	NSDateFormatter *_dateFormatter;
	
	// Widths of each table column
	NSArray *_tableColumnWidths;
	
	NSMutableArray *_rowSeparators;
	
	/*
	 * Three columns: Name, due, grade
	 *
	 * If pointsPossible is not 100, grade is displayed as earned/possible, not
	 * possible%
	 */
	NSMutableArray *_rowHeaders;
	NSMutableArray *_tableLabels;
	
	SQUCategory *_category;
	NSUInteger _index;
}

@property (nonatomic, readwrite, strong) SQUCategory *category;
@property (nonatomic, readwrite) NSUInteger index;

- (void) updateUI;

+ (CGFloat) cellHeightForCategory:(SQUCategory *) category;

@end
