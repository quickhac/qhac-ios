//
//  SQUClassDetailCell.m
//  QuickHAC
//
//  Created by Tristan Seifert on 12/28/13.
//  Copyright (c) 2013 Squee! Apps. All rights reserved.
//

#import "SQUClassDetailCell.h"
#import "UIColor+SQUColourUtilities.h"
#import "SQUCoreData.h"

@implementation SQUClassDetailCell
@synthesize category = _category;
@synthesize index = _index;

// X position and width info for the three table columns
static NSUInteger SQUClassDetailColX[3] = {20, 191, 245};
static NSUInteger SQUClassDetailColWidth[3] = {166, 52, 52};
static NSUInteger SQUClassDetailSeparatorX = 18;
static NSUInteger SQUClassDetailSeparatorWidth = 282;
static NSUInteger SQUClassDetailRowHeight = 32;
static NSUInteger SQUClassDetailRowTextOffset = 4;

- (id)initWithStyle:(UITableViewCellStyle) style reuseIdentifier:(NSString *) reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
		// Card background
		_backgroundLayer = [CALayer layer];
		_backgroundLayer.frame = CGRectMake(5, 5, self.frame.size.width - 10, self.frame.size.height - 10);
        _backgroundLayer.backgroundColor = [UIColor whiteColor].CGColor;
		_backgroundLayer.cornerRadius = 3.0;
		
		// Card shadow
		_backgroundLayer.borderWidth = 0.0;
		_backgroundLayer.shadowColor = [UIColor blackColor].CGColor;
		_backgroundLayer.shadowOpacity = 0.15;
		_backgroundLayer.shadowRadius = 4.0;
		_backgroundLayer.shadowOffset = CGSizeMake(-4.0, -1.0);
		_backgroundLayer.masksToBounds = NO;
		
		UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:_backgroundLayer.frame cornerRadius:_backgroundLayer.cornerRadius];
		_backgroundLayer.shadowPath = path.CGPath;
		
		// Left bar on card
        _sideBar = [CAGradientLayer layer];
        _sideBar.frame = CGRectMake(0, 0, 8, _backgroundLayer.frame.size.height);
		[_backgroundLayer addSublayer:_sideBar];
		
		// Prepare and apply a mask to apply rounded corners.
		UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:_sideBar.frame
													   byRoundingCorners:UIRectCornerTopLeft | UIRectCornerBottomLeft
															 cornerRadii:CGSizeMake(3.0, 3.0)];
		
		CAShapeLayer *maskLayer = [CAShapeLayer layer];
		maskLayer.frame = _sideBar.bounds;
		maskLayer.path = maskPath.CGPath;
		_sideBar.mask = maskLayer;
        
		// Category title
        _categoryTitle = [CATextLayer layer];
        _categoryTitle.frame = CGRectMake(20, 4, _backgroundLayer.frame.size.width - 66, 24);
        _categoryTitle.contentsScale = [UIScreen mainScreen].scale;
        _categoryTitle.foregroundColor = [UIColor blackColor].CGColor;
        _categoryTitle.font = (__bridge CFTypeRef) [UIFont fontWithName:@"HelveticaNeue-Light" size:15.0f];
        _categoryTitle.fontSize = 20.0f;
		[_backgroundLayer addSublayer:_categoryTitle];
		
		// Apply a mask so overly long category titles "fade out"
		CAGradientLayer *categoryTitleMask = [CAGradientLayer layer];
		categoryTitleMask.bounds = CGRectMake(0, 0, _backgroundLayer.frame.size.width - 50, 24);
		categoryTitleMask.position = CGPointMake(_categoryTitle.bounds.size.width/2.0, _categoryTitle.bounds.size.height/2.0);
		categoryTitleMask.locations = @[@(0.85f), @(1.0f)];
		categoryTitleMask.colors = @[(id)[UIColor blackColor].CGColor, (id)[UIColor clearColor].CGColor];
		categoryTitleMask.startPoint = CGPointMake(0.0, 0.5);
		categoryTitleMask.endPoint = CGPointMake(1.0, 0.5);
		_categoryTitle.mask = categoryTitleMask;
		
		// Text indicating there is no grades
		_noGradesText = [CATextLayer layer];
        _noGradesText.frame = CGRectMake(4, 30, _backgroundLayer.frame.size.width-8, 18);
        _noGradesText.contentsScale = [UIScreen mainScreen].scale;
        _noGradesText.foregroundColor = [UIColor blackColor].CGColor;
        _noGradesText.font = (__bridge CFTypeRef) [UIFont fontWithName:@"HelveticaNeue-Light" size:15.0f];
        _noGradesText.fontSize = 15.0f;
		_noGradesText.string = NSLocalizedString(@"No Grades in Category", @"class detail");
		_noGradesText.alignmentMode = kCAAlignmentCenter;
		
		// Prepare row headers
		_rowHeaders = [NSMutableArray new];
		_tableLabels = [NSMutableArray new];
		_rowSeparators = [NSMutableArray new];
		
		CGFloat assignmentsWidth = _backgroundLayer.frame.size.width - 130;
		CGFloat remainingWidth = (_backgroundLayer.frame.size.width - assignmentsWidth) - 13;
		
		NSArray *rowHeaderTitles = @[NSLocalizedString(@"ASSIGNMENT", @"class detail"), NSLocalizedString(@"DUE", @"class detail"), NSLocalizedString(@"GRADE", @"class detail")];
		_tableColumnWidths = @[@(assignmentsWidth), @(remainingWidth / 2), @(remainingWidth / 2)];
		
		for(NSUInteger i = 0; i < 3; i++) {
			CATextLayer *layer = [CATextLayer layer];
			layer.contentsScale = [UIScreen mainScreen].scale;
			layer.foregroundColor = [UIColor colorWithWhite:0.25 alpha:1.0].CGColor;
			layer.font = (__bridge CFTypeRef) [UIFont fontWithName:@"HelveticaNeue-Bold" size:14.0f];
			layer.fontSize = 13.0f;
			layer.string = rowHeaderTitles[i];
			
			if(i == 2) {
				layer.alignmentMode = kCAAlignmentCenter;
			} else {
				layer.alignmentMode = kCAAlignmentLeft;
			}
			
			layer.frame = CGRectMake(SQUClassDetailColX[i], 34, SQUClassDetailColWidth[i], 18);
			
			[_rowHeaders addObject:layer];
		}
		
		// Weight
		_weightTitle = [CATextLayer layer];
        _weightTitle.frame = CGRectMake(_backgroundLayer.frame.size.width - 45, 7, 40, 18);
        _weightTitle.contentsScale = [UIScreen mainScreen].scale;
        _weightTitle.foregroundColor = [UIColor lightGrayColor].CGColor;
        _weightTitle.font = (__bridge CFTypeRef) [UIFont systemFontOfSize:15.0f];
        _weightTitle.fontSize = 15.0f;
		_weightTitle.alignmentMode = kCAAlignmentRight;
		[_backgroundLayer addSublayer:_weightTitle];
		
		// Add sublayers
		[self.layer addSublayer:_backgroundLayer];
		
		// Prepare background layer
		self.layer.backgroundColor = [UIColor clearColor].CGColor;

		_dateFormatter = [NSDateFormatter new];
		[_dateFormatter setDateFormat:@"MMM-dd"];
    }
    return self;
}

- (void) updateUI {
	CGRect rect = self.frame;
	rect.size.height = [SQUClassDetailCell cellHeightForCategory:_category];
	self.frame = rect;
	
	_backgroundLayer.frame = CGRectMake(5, 5, self.frame.size.width - 10, self.frame.size.height);
	
	// We also need to update the mask on the sidebar when changing the frame
	_sideBar.frame = CGRectMake(0, 0, 8, _backgroundLayer.frame.size.height);
	UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:_sideBar.frame
												   byRoundingCorners:UIRectCornerTopLeft | UIRectCornerBottomLeft
														 cornerRadii:CGSizeMake(3.0, 3.0)];
	
	CAShapeLayer *maskLayer = [CAShapeLayer layer];
	maskLayer.frame = _sideBar.bounds;
	maskLayer.path = maskPath.CGPath;
	_sideBar.mask = maskLayer;
	
	// Update the sidebar colour
	NSArray *sbcolours = @[
						   [UIColor colorWithRed:0 green:0.608 blue:0.808 alpha:1] /*#009bce*/,
						   [UIColor colorWithRed:0.612 green:0.204 blue:0.816 alpha:1], /*#9c34d0*/
						   [UIColor colorWithRed:0.373 green:0.561 blue:0 alpha:1], /*#5f8f00*/
						   [UIColor colorWithRed:0.992 green:0.529 blue:0 alpha:1], /*#fd8700*/
						   [UIColor colorWithRed:0.824 green:0 blue:0 alpha:1], /*#d20000*/
						   [UIColor colorWithRed:0.2 green:0.71 blue:0.898 alpha:1], /*#33b5e5*/
						   [UIColor colorWithRed:0.667 green:0.435 blue:0.78 alpha:1], /*#aa6fc7*/
						   [UIColor colorWithRed:0.624 green:0.831 blue:0 alpha:1], /*#9fd400*/
						   [UIColor colorWithRed:1 green:0.741 blue:0.22 alpha:1], /*#ffbd38*/
						   [UIColor colorWithRed:1 green:0.322 blue:0.322 alpha:1] /*#ff5252*/
						   ];
	
	NSUInteger index = _index;
	
	if(index > sbcolours.count) {
		_sideBar.colors = @[(id) [UIColor colorWithWhite:0.08 alpha:1.0].CGColor, (id) [[UIColor colorWithWhite:0.08 alpha:1.0] darkerColor].CGColor];
	} else {
		_sideBar.colors = @[(id) [sbcolours[index] CGColor], (id) [[sbcolours[index] darkerColor] CGColor]];
	}
	
	// Update titles
	_categoryTitle.string = _category.title;
	_weightTitle.string = [NSString stringWithFormat:NSLocalizedString(@"%.0f%%", @"class detail weight"), _category.weight.floatValue];
	
	// Clean up the layer
	_backgroundLayer.sublayers = nil;
	
	[_backgroundLayer addSublayer:_noGradesText];
	[_backgroundLayer addSublayer:_weightTitle];
	[_backgroundLayer addSublayer:_sideBar];
	[_backgroundLayer addSublayer:_categoryTitle];
	
	// Build the table
	if(_category.assignments.count != 0) {
		[_noGradesText removeFromSuperlayer];
		[self buildTable];
	}
	
	// Update shadow
	UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:_backgroundLayer.frame cornerRadius:_backgroundLayer.cornerRadius];
	_backgroundLayer.shadowPath = path.CGPath;
}

- (void) buildTable {
	[_tableLabels removeAllObjects];
	[_rowSeparators removeAllObjects];
	
	CGFloat x, y, width;
	SQUAssignment *assignment;
	NSString *assignmentValueString;
	
	x = 16;
	y = 52;
	
	// Draw the header separator
	CAGradientLayer *layer = [CAGradientLayer layer];
	layer.frame = CGRectMake(SQUClassDetailSeparatorX, y, SQUClassDetailSeparatorWidth, 1);
	layer.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0].CGColor;
	[_rowSeparators addObject:layer];
	
	y += 4;
	
	// Create table contents
	for(NSUInteger i = 0; i < _category.assignments.count; i++) {
		assignment = _category.assignments[i];
		
		// Format the assignment grade accordingly
		if(assignment.pts_possible.floatValue == 100 && !assignment.extra_credit.boolValue) {
			assignmentValueString = [NSString stringWithFormat:NSLocalizedString(@"%u", @"assignment grade in table out of 100"), assignment.pts_earned.unsignedIntegerValue];
		} else if(assignment.extra_credit.boolValue) {
			assignmentValueString = [NSString stringWithFormat:NSLocalizedString(@"%u", @"assignment grade extra credit"), assignment.pts_earned.unsignedIntegerValue];
		} else {
			assignmentValueString = [NSString stringWithFormat:NSLocalizedString(@"%u/%u", @"assignment grade in table not out of 100"), assignment.pts_earned.unsignedIntegerValue, assignment.pts_possible.unsignedIntegerValue];
		}
		
		// Text to put on labels
		NSArray *labels = @[assignment.title,
							[_dateFormatter stringFromDate:assignment.date_due],
							assignmentValueString];
		
		// Output "Assignment", "Due Date" and "Grade" columns
		for(NSUInteger c = 0; c < 3; c++) {
			CATextLayer *layer = [CATextLayer layer];
			layer.contentsScale = [UIScreen mainScreen].scale;
			layer.foregroundColor = [UIColor blackColor].CGColor;
			layer.font = (__bridge CFTypeRef) [UIFont systemFontOfSize:15.0f];
			layer.fontSize = 15.0f;
			
			width = [_tableColumnWidths[c] floatValue];
			layer.frame = CGRectMake(SQUClassDetailColX[c], y + SQUClassDetailRowTextOffset, SQUClassDetailColWidth[c], 18);
			x += width;
			
			// Grades are centered
			if(c == 2) {
				layer.alignmentMode = kCAAlignmentCenter;
			} else {
				layer.alignmentMode = kCAAlignmentLeft;
			}
			
			// Apply mask if it is the assignment title
			if(c == 0) {
				CAGradientLayer *textMask = [CAGradientLayer layer];
				textMask.bounds = layer.bounds;
				textMask.position = CGPointMake(layer.bounds.size.width/2.0, layer.bounds.size.height/2.0);
				textMask.locations = @[@(0.85f), @(1.0f)];
				textMask.colors = @[(id)[UIColor blackColor].CGColor, (id)[UIColor clearColor].CGColor];
				textMask.startPoint = CGPointMake(0.0, 0.5);
				textMask.endPoint = CGPointMake(1.0, 0.5);
				layer.mask = textMask;
			}
			
			layer.string = labels[c];
			
			[_tableLabels addObject:layer];
		}
		
		// Draw separator and prepare for next row
		y += SQUClassDetailRowHeight;
		x = 12;
		
		if(i + 1 != _category.assignments.count) {
			CAGradientLayer *layer = [CAGradientLayer layer];
			layer.frame = CGRectMake(SQUClassDetailSeparatorX, y - 3, SQUClassDetailSeparatorWidth, 1);
			layer.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0].CGColor;
			[_rowSeparators addObject:layer];
		}
	}
	
	// Add headers
	for(CALayer *layer in _rowHeaders) {
		[_backgroundLayer addSublayer:layer];
	}
	
	// Add labels
	for(CALayer *layer in _tableLabels) {
		[_backgroundLayer addSublayer:layer];
	}
	
	// Add separators
	for(CALayer *layer in _rowSeparators) {
		[_backgroundLayer addSublayer:layer];
	}
}

/*
 * Returns the height of the cell for a given category. Base height of the cell
 * is 50 pixels, with 32 pixels for the first assignment, then 20 for all
 * assignments thereafter
 */
+ (CGFloat) cellHeightForCategory:(SQUCategory *) category {
	if(category.assignments.count == 0) {
		return 55;
	} else if(category.assignments.count == 1) {
		return 55+30+SQUClassDetailRowHeight;
	} else {
		CGFloat height = 55+30;
		height += (category.assignments.count - 1) * SQUClassDetailRowHeight;
		return height;
	}
}

@end
