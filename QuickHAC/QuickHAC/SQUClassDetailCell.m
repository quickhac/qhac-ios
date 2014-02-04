//
//  SQUClassDetailCell.m
//  QuickHAC
//
//  Created by Tristan Seifert on 12/28/13.
//  See README.MD for licensing and copyright information.
//

#import "SQUClassDetailCell.h"
#import "UIColor+SQUColourUtilities.h"
#import "SQUCoreData.h"
#import "SQUColourScheme.h"
#import "SQUAppDelegate.h"

#import <CoreText/CoreText.h>

@interface SQUClassDetailCell (PrivateMethods)

+ (CGFloat) heightForAssignment:(SQUAssignment *) assignment;

@end

@implementation SQUClassDetailCell
@synthesize category = _category;
@synthesize index = _index;

// X position and width info for the three table columns
static NSUInteger SQUClassDetailColX[3] = {10, 235};
static NSUInteger SQUClassDetailColWidth[3] = {220, 68};
static NSUInteger SQUClassDetailSeparatorX = 8;
static NSUInteger SQUClassDetailSeparatorWidth = 287;
static NSUInteger SQUClassDetailRowHeight = 32;
static NSUInteger SQUClassDetailRowTextOffset = 4;
static NSUInteger SQUClassDetailTextZPosition = 5;
static NSUInteger SQUClassDetailTextSize = 15;

static NSUInteger SQUClassDetailAssignmentColour = 0x000000;
static NSUInteger SQUClassDetailDroppedColour = kSQUColourConcrete;
static NSUInteger SQUClassDetailMissingColour = kSQUColourAlizarin;
static NSUInteger SQUClassDetailExtraCreditColour = kSQUColourEmerald;

- (id)initWithStyle:(UITableViewCellStyle) style reuseIdentifier:(NSString *) reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
		// Card background
		_backgroundLayer = [CALayer layer];
		_backgroundLayer.frame = CGRectMake(10, 10, self.frame.size.width - 20, self.frame.size.height - 6);
        _backgroundLayer.backgroundColor = [UIColor whiteColor].CGColor;
		_backgroundLayer.borderWidth = 0.0;
		_backgroundLayer.shadowColor = [UIColor blackColor].CGColor;
		_backgroundLayer.shadowOpacity = 0.0625;
		_backgroundLayer.shadowRadius = 2.0;
		_backgroundLayer.shadowOffset = CGSizeMake(-8.0, -8.0);
		_backgroundLayer.cornerRadius = 1.0;
		_backgroundLayer.contentsScale = [UIScreen mainScreen].scale;
		_backgroundLayer.masksToBounds = NO;
		
		UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:_backgroundLayer.frame cornerRadius:_backgroundLayer.cornerRadius];
		_backgroundLayer.shadowPath = path.CGPath;
		
		// Text indicating there is no grades
		_noGradesText = [CATextLayer layer];
        _noGradesText.frame = CGRectMake(4, 32, _backgroundLayer.frame.size.width-8, 18);
        _noGradesText.contentsScale = [UIScreen mainScreen].scale;
        _noGradesText.foregroundColor = [UIColor blackColor].CGColor;
        _noGradesText.font = (__bridge CFTypeRef) [UIFont fontWithName:@"HelveticaNeue-Light" size:15.0f];
        _noGradesText.fontSize = 15.0f;
		_noGradesText.string = NSLocalizedString(@"No Assignments in This Category", @"class detail");
		_noGradesText.alignmentMode = kCAAlignmentCenter;
		
		// Prepare row headers
		_rowHeaders = [NSMutableArray new];
		_tableLabels = [NSMutableArray new];
		_rowSeparators = [NSMutableArray new];
		
		CGFloat assignmentsWidth = _backgroundLayer.frame.size.width - 130;
		CGFloat remainingWidth = (_backgroundLayer.frame.size.width - assignmentsWidth) - 13;
		
		NSArray *rowHeaderTitles = @[NSLocalizedString(@"ASSIGNMENT", @"class detail"), NSLocalizedString(@"GRADE", @"class detail")];
		_tableColumnWidths = @[@(assignmentsWidth), @(remainingWidth / 2), @(remainingWidth / 2)];
		
		for(NSUInteger i = 0; i < 2; i++) {
			CATextLayer *layer = [CATextLayer layer];
			layer.contentsScale = [UIScreen mainScreen].scale;
			layer.foregroundColor = [UIColor colorWithWhite:0.25 alpha:1.0].CGColor;
			layer.font = (__bridge CFTypeRef) [UIFont fontWithName:@"HelveticaNeue-Medium" size:14.0f];
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
        
		// Category title
        _categoryTitle = [CATextLayer layer];
        _categoryTitle.frame = CGRectMake(10, 4, _backgroundLayer.frame.size.width - 66, 24);
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
		
		// Weight
		_weightTitle = [CATextLayer layer];
        _weightTitle.frame = CGRectMake(_backgroundLayer.frame.size.width - 45, 4, 40, 24);
        _weightTitle.contentsScale = [UIScreen mainScreen].scale;
        _weightTitle.foregroundColor = [UIColor lightGrayColor].CGColor;
        _weightTitle.font = (__bridge CFTypeRef) [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:15.0f];
        _weightTitle.fontSize = 20.0f;
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
	
	_backgroundLayer.frame = CGRectMake(10, 10, self.frame.size.width - 20, self.frame.size.height - 6);
	
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
	
	CGFloat heightOfLastRow = SQUClassDetailRowHeight;
	CGFloat otherLabelOffsets = 0;
	
	// Sort assignments by date due
	NSSortDescriptor *dateSort = [NSSortDescriptor sortDescriptorWithKey:@"date_due" ascending:YES];
	NSArray *sortedAssignments = [_category.assignments sortedArrayUsingDescriptors:@[dateSort]];
	
	// Create table contents
	for(NSUInteger i = 0; i < sortedAssignments.count; i++) {
		assignment = sortedAssignments[i];
		
		// Format the assignment grade accordingly
		if(assignment.pts_earned.integerValue != -1) {
			if(_category.is100PtsBased.boolValue) {
				assignmentValueString = [NSString stringWithFormat:NSLocalizedString(@"%u", @"assignment grade in table out of 100"), assignment.pts_earned.unsignedIntegerValue];
			} else {
				assignmentValueString = [NSString stringWithFormat:NSLocalizedString(@"%u/%u", @"assignment grade in table not out of 100"), assignment.pts_earned.unsignedIntegerValue, assignment.pts_possible.unsignedIntegerValue];
			}
			
			// Append the weight so the assignment shows up as "88x0.5" or "89/90x0.8"
			if(assignment.weight.floatValue != 1) {
				assignmentValueString = [assignmentValueString stringByAppendingFormat:NSLocalizedString(@"x%.1f", nil), assignment.weight.floatValue];
			}
		} else {
			assignmentValueString = NSLocalizedString(@"-", @"shown with empty grade in category table");
		}
		
		// Text to put on labels
		NSArray *labels = @[assignment.title,
//							[_dateFormatter stringFromDate:assignment.date_due],
							assignmentValueString];
		
		// Output the columns
		for(NSUInteger c = 0; c < 2; c++) {
			CATextLayer *layer = [CATextLayer layer];
			layer.contentsScale = [UIScreen mainScreen].scale;
			layer.font = (__bridge CFTypeRef) [UIFont fontWithName:@"HelveticaNeue-Light" size:SQUClassDetailTextSize];
			layer.fontSize = (CGFloat) SQUClassDetailTextSize;
			layer.zPosition = SQUClassDetailTextZPosition;
			
			// Multi-line for assignment title
			if(c == 0) {
				layer.wrapped = YES;
			}
			
			width = [_tableColumnWidths[c] floatValue];
			layer.frame = CGRectMake(SQUClassDetailColX[c], y + SQUClassDetailRowTextOffset + otherLabelOffsets, SQUClassDetailColWidth[c], 18);
			x += width;
			
			// Grades are centered
			if(c == 2) {
				layer.alignmentMode = kCAAlignmentCenter;
			} else {
				layer.alignmentMode = kCAAlignmentLeft;
			}
			
			// Apply mask if it is the assignment title
			/*if(c == 0) {
				CAGradientLayer *textMask = [CAGradientLayer layer];
				textMask.bounds = layer.bounds;
				textMask.position = CGPointMake(layer.bounds.size.width/2.0, layer.bounds.size.height/2.0);
				textMask.locations = @[@(0.85f), @(1.0f)];
				textMask.colors = @[(id)[UIColor blackColor].CGColor, (id)[UIColor clearColor].CGColor];
				textMask.startPoint = CGPointMake(0.0, 0.5);
				textMask.endPoint = CGPointMake(1.0, 0.5);
				layer.mask = textMask;
			}*/
			
			layer.string = labels[c];
			
			// Do the line wrap shit
			if(c == 0) {
				layer.wrapped = YES;
				
				UIFont *font = [UIFont fontWithName:@"HelveticaNeue-Light" size:SQUClassDetailTextSize];
				
				// Calculate height
				NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:layer.string attributes:nil];
				[string addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, string.length)];
				CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef) string);
				CGSize textSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, 0), NULL, CGSizeMake(SQUClassDetailColWidth[0], CGFLOAT_MAX), NULL);
				
				// Resize label to fit multi-line
				if(textSize.height > (SQUClassDetailTextSize + (SQUClassDetailTextSize / 2))) {
					heightOfLastRow = SQUClassDetailRowHeight + (textSize.height - 18);
					
					CGRect frame = layer.frame;
					frame.size.height += (textSize.height - 18);
					layer.frame = frame;
					
					otherLabelOffsets = (heightOfLastRow / 4);
				} else {
					heightOfLastRow = SQUClassDetailRowHeight;
					otherLabelOffsets = 0;
				}
			}
			
			/* 
			 * If the assignment is dropped, extra credit or missing, perform
			 * special styling on the text, as well as possibly rendering an
			 * icon.
			 */
			if(assignment.extra_credit.boolValue) {
				layer.foregroundColor = UIColorFromRGB(SQUClassDetailExtraCreditColour).CGColor;
			} else if([assignment.description rangeOfString:@"Missing" options:NSCaseInsensitiveSearch].location != NSNotFound) {
				layer.foregroundColor = UIColorFromRGB(SQUClassDetailMissingColour).CGColor;
				
				/*
				 * This is kind of a nasty ugly hack and whatnot, because
				 * apparently 0 = missing.
				 */
				if(c == 1) {
					layer.string = @"0";
				}
			} else if([assignment.description rangeOfString:@"Dropped" options:NSCaseInsensitiveSearch].location != NSNotFound) {
				layer.foregroundColor = UIColorFromRGB(SQUClassDetailDroppedColour).CGColor;
				
				/*NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:layer.string];
				[str addAttribute:NSStrikethroughStyleAttributeName value:@(NSUnderlinePatternSolid | NSUnderlineStyleSingle) range:NSMakeRange(0, str.length)];
				layer.string = str;*/
			} else {
				layer.foregroundColor = UIColorFromRGB(SQUClassDetailAssignmentColour).CGColor;				
			}
			
			[_tableLabels addObject:layer];
			
			
		}
		
		// Draw separator and prepare for next row
		y += heightOfLastRow;
		otherLabelOffsets = 0;
		x = 12;
		
/*//		if(i + 1 != _category.assignments.count) {
		CAGradientLayer *layer = [CAGradientLayer layer];
		layer.frame = CGRectMake(SQUClassDetailSeparatorX, y - 3, SQUClassDetailSeparatorWidth, 1);
		layer.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0].CGColor;
		layer.zPosition = SQUClassDetailTextZPosition;
		[_rowSeparators addObject:layer];
//		}*/
	}

	// Draw average label
	CATextLayer *textLayer = [CATextLayer layer];
	textLayer.contentsScale = [UIScreen mainScreen].scale;
	textLayer.foregroundColor = [UIColor colorWithWhite:0.375 alpha:1.0].CGColor;
	textLayer.font = (__bridge CFTypeRef) [UIFont fontWithName:@"HelveticaNeue-Medium" size:14.0f];
	textLayer.fontSize = 13.0f;
	textLayer.string = NSLocalizedString(@"AVERAGE", @"category detail");
	textLayer.alignmentMode = kCAAlignmentRight;
	width = [_tableColumnWidths[0] floatValue];
	textLayer.frame = CGRectMake(SQUClassDetailColX[0], y + SQUClassDetailRowTextOffset, SQUClassDetailColWidth[0], 18);
	x += width;
	[_tableLabels addObject:textLayer];
	
	textLayer = [CATextLayer layer];
	textLayer.contentsScale = [UIScreen mainScreen].scale;
	textLayer.foregroundColor = [UIColor colorWithWhite:0.375 alpha:1.0].CGColor;
	textLayer.font = (__bridge CFTypeRef) [UIFont fontWithName:@"HelveticaNeue-Medium" size:14.0f];
	textLayer.fontSize = 13.0f;
	textLayer.string = [NSString stringWithFormat:NSLocalizedString(@"%.2f%%", @"category detail average"), _category.average.floatValue];
	textLayer.alignmentMode = kCAAlignmentLeft;
	width = [_tableColumnWidths[0] floatValue];
	textLayer.frame = CGRectMake(SQUClassDetailColX[1], y + SQUClassDetailRowTextOffset, SQUClassDetailColWidth[1], 18);
	x += width;
	[_tableLabels addObject:textLayer];
	
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

/**
 * Returns the height required to render a certain assignment label.
 */
+ (CGFloat) heightForAssignment:(SQUAssignment *) assignment {
	UIFont *font = [UIFont fontWithName:@"HelveticaNeue-Light" size:SQUClassDetailTextSize];
	
	// Calculate height
	NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:assignment.title attributes:nil];
	[string addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, string.length)];
	CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef) string);
	CGSize textSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, 0), NULL, CGSizeMake(SQUClassDetailColWidth[0], CGFLOAT_MAX), NULL);
	
	if(textSize.height > (SQUClassDetailTextSize + (SQUClassDetailTextSize/2))) {
		return (CGFloat) SQUClassDetailRowHeight + (textSize.height-18);
	} else {
		return (CGFloat) SQUClassDetailRowHeight;
	}
}

/**
 * Returns the height of the cell for a given category. Base height of the cell
 * is 50 pixels, with 32 pixels for the first assignment, then 20 for all
 * assignments thereafter
 */
+ (CGFloat) cellHeightForCategory:(SQUCategory *) category {
	if(category.assignments.count == 0) {
		return 65;
	} else if(category.assignments.count == 1) {
		return 65+SQUClassDetailRowHeight+[SQUClassDetailCell heightForAssignment:category.assignments[0]];
	} else {
		CGFloat height = 65+30;
		
		for (SQUAssignment *assignment in category.assignments) {
			height += [SQUClassDetailCell heightForAssignment:assignment];
		}
		
		// height += (category.assignments.count - 1) * SQUClassDetailRowHeight;
		// height += SQUClassDetailRowHeight;
		return height;
	}
}

/**
 * Method to handle tapping on an assignment column.
 */
- (void) touchesBegan:(NSSet *) touches withEvent:(UIEvent *) event {
	[super touchesBegan:touches withEvent:event];
	return;
	
	// Remove any selection indicators that still are existent
	if(_selectionLayer) {
		[_selectionLayer removeFromSuperlayer];
	}
	
	for (UITouch *touch in touches) {
		CGPoint point = [touch locationInView:self];
		
		// First assignment at 65 pixels
		if(point.y > 54) {
			NSUInteger selectedRow = point.y - 54;
			selectedRow /= SQUClassDetailRowHeight;
			
			// Ignore the assignment if it's the averages row
			if(_category.assignments.count > selectedRow) {
				// Show selection indicator (53 px add to account for 1st row)
				CGFloat y = (selectedRow * SQUClassDetailRowHeight) + 53;
				
				_selectionLayer = [CAGradientLayer layer];
				_selectionLayer.frame = CGRectMake(SQUClassDetailSeparatorX, y, SQUClassDetailSeparatorWidth, SQUClassDetailRowHeight);
				_selectionLayer.colors = @[(id) UIColorFromRGB(0xF0F0F0).CGColor, (id) UIColorFromRGB(0xE0E0E0).CGColor];
				_selectionLayer.zPosition = 0;
				[_backgroundLayer addSublayer:_selectionLayer];
				
				// Update selection state, display assignment info
				_selectedAssignment = _category.assignments[selectedRow];
			}
		}
	}
}

/**
 * Called when a touch event is cancelled, i.e. when the device goes to the home
 * screen or the app is pre-empted by a phone call or somesuch event.
 */
- (void) touchesCancelled:(NSSet *) touches withEvent:(UIEvent *) event {
	[super touchesCancelled:touches withEvent:event];
	[_selectionLayer removeFromSuperlayer];
}

/**
 * Called when a touch event ends, i.e. when the user lifts their finger. This
 * is used to hide the selection indicator.
 */
- (void) touchesEnded:(NSSet *) touches withEvent:(UIEvent *) event {
	[super touchesEnded:touches withEvent:event];
	[_selectionLayer removeFromSuperlayer];
}

@end
