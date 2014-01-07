//
//  SQUGradeOverviewTableViewCell.m
//  QuickHAC
//
//  Created by Tristan Seifert on 16/07/2013.
//  See README.MD for licensing and copyright information.
//

#import <QuartzCore/QuartzCore.h>

#import "SQUGradeOverviewTableViewCell.h"
#import "SQUCoreData.h"
#import "SQUDistrictManager.h"
#import "SQUGradeManager.h"
#import "UIColor+SQUColourUtilities.h"

@implementation SQUGradeOverviewTableViewCell
@synthesize courseInfo = _courseInfo;

static NSUInteger SQUGradeOverviewTableViewCellXPos[2] = {24, 162};
static NSUInteger SQUGradeOverviewTableViewCellWidth[2] = {115, 112};

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        CGRect rect = self.frame;
        rect.size.height = SQUGradeOverviewCellHeight;
        self.frame = rect;
		
		// Card background
		_backgroundLayer = [CALayer layer];
		_backgroundLayer.frame = CGRectMake(15, 15, self.frame.size.width - 30, self.frame.size.height - 10);
        _backgroundLayer.backgroundColor = [UIColor whiteColor].CGColor;
		_backgroundLayer.cornerRadius = 3.0;
		
		// Card shadow
		_backgroundLayer.borderWidth = 0.0;
		_backgroundLayer.shadowColor = [UIColor blackColor].CGColor;
		_backgroundLayer.shadowOpacity = 0.0625;
		_backgroundLayer.shadowRadius = 4.0;
		_backgroundLayer.shadowOffset = CGSizeMake(-8.0, -8.0);
		_backgroundLayer.masksToBounds = NO;
		
		UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:_backgroundLayer.frame cornerRadius:_backgroundLayer.cornerRadius];
		_backgroundLayer.shadowPath = path.CGPath;
		
		// Left bar on card
        _sideBar = [CAGradientLayer layer];
        _sideBar.frame = CGRectMake(0, 0, 8, _backgroundLayer.frame.size.height);
		
		// Prepare and apply a mask to apply rounded corners.
		UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:_sideBar.frame
													   byRoundingCorners:UIRectCornerTopLeft | UIRectCornerBottomLeft
															 cornerRadii:CGSizeMake(3.0, 3.0)];
		
		CAShapeLayer *maskLayer = [CAShapeLayer layer];
		maskLayer.frame = _sideBar.bounds;
		maskLayer.path = maskPath.CGPath;
		_sideBar.mask = maskLayer;
        
		// Course title
        _courseTitle = [CATextLayer layer];
        _courseTitle.frame = CGRectMake(SQUGradeOverviewTableViewCellXPos[0], 5, _backgroundLayer.frame.size.width - 106, 32);
        _courseTitle.contentsScale = [UIScreen mainScreen].scale;
        _courseTitle.foregroundColor = [UIColor blackColor].CGColor;
        _courseTitle.font = (__bridge CFTypeRef) [UIFont fontWithName:@"HelveticaNeue-Light" size:15.0f];
        _courseTitle.fontSize = 23.0f;
		
		// Apply a mask so overly long course titles "fade out"
		CAGradientLayer *courseTitleMask = [CAGradientLayer layer];
		courseTitleMask.bounds = CGRectMake(0, 0, _courseTitle.frame.size.width, _courseTitle.frame.size.height);
		courseTitleMask.position = CGPointMake(_courseTitle.bounds.size.width/2.0, _courseTitle.bounds.size.height/2.0);
		courseTitleMask.locations = @[@(0.85f), @(1.0f)];
		courseTitleMask.colors = @[(id)[UIColor blackColor].CGColor, (id)[UIColor clearColor].CGColor];
		courseTitleMask.startPoint = CGPointMake(0.0, 0.5);
		courseTitleMask.endPoint = CGPointMake(1.0, 0.5);
		_courseTitle.mask = courseTitleMask;
        
		// Period label
        _periodTitle = [CATextLayer layer];
        _periodTitle.frame = CGRectMake(_backgroundLayer.frame.size.width - 80, 8, 65, 24);
        _periodTitle.contentsScale = [UIScreen mainScreen].scale;
        _periodTitle.foregroundColor = [UIColor grayColor].CGColor;
        _periodTitle.font = (__bridge CFTypeRef) [UIFont fontWithName:@"HelveticaNeue-Light" size:15.0f];
        _periodTitle.fontSize = 17.5f;
		_periodTitle.alignmentMode = kCAAlignmentRight;
		
		// Create Semester Average heads
		_semesterHeads = [NSMutableArray new];
		_cycleHeads = [NSMutableArray new];

		for(NSUInteger i = 0; i < 2; i++) {
			NSString *alignment = (i == 0) ? kCAAlignmentLeft : kCAAlignmentRight;
			
			CGFloat currentX = SQUGradeOverviewTableViewCellXPos[i];
			
			CATextLayer *semesterHead = [CATextLayer layer];
			semesterHead.frame = CGRectMake(currentX, 34, SQUGradeOverviewTableViewCellWidth[i], 16);
			semesterHead.contentsScale = [UIScreen mainScreen].scale;
			semesterHead.foregroundColor = [UIColor blackColor].CGColor;
			semesterHead.font = (__bridge CFTypeRef) [UIFont fontWithName:@"HelveticaNeue-Medium" size:15.0f];
			semesterHead.fontSize = 14.0f;
			semesterHead.string = @"Semester 1: 100";
			semesterHead.alignmentMode = alignment;
			
			// Create cycle subheads
			for(NSUInteger j = 0; j < 4; j++) {
				CATextLayer *cycleHead = [CATextLayer layer];
				cycleHead.frame = CGRectMake(currentX, 56 + (j * 20), SQUGradeOverviewTableViewCellWidth[i], 16);
				cycleHead.contentsScale = [UIScreen mainScreen].scale;
				cycleHead.foregroundColor = [UIColor blackColor].CGColor;
				cycleHead.font = (__bridge CFTypeRef) [UIFont fontWithName:@"HelveticaNeue-Light" size:15.0f];
				cycleHead.fontSize = 14.0f;
				cycleHead.string = @"Cycle 1: 100";
				//cycleHead.alignmentMode = (i == 0) ? kCAAlignmentLeft : kCAAlignmentRight;
				cycleHead.alignmentMode = alignment;
				
				[_cycleHeads addObject:cycleHead];
				[_backgroundLayer addSublayer:cycleHead];
			}
			
			[_semesterHeads addObject:semesterHead];
			[_backgroundLayer addSublayer:semesterHead];
		}
		
		_semesterSeperator = [CAGradientLayer layer];
		_semesterSeperator.frame = CGRectMake((_backgroundLayer.frame.size.width / 2) + 6, 32, 1, _backgroundLayer.frame.size.height - 40);
		_semesterSeperator.backgroundColor = [UIColor colorWithWhite:0.85 alpha:1.0].CGColor;
				
		// Add sublayers
		[_backgroundLayer addSublayer:_semesterSeperator];
        [_backgroundLayer addSublayer:_courseTitle];
        [_backgroundLayer addSublayer:_periodTitle];
        [_backgroundLayer addSublayer:_sideBar];
		
		[self.layer addSublayer:_backgroundLayer];
    
		// Prepare background layer
		self.layer.backgroundColor = [UIColor clearColor].CGColor;
	}
    
	return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) updateUI {
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
	
	// Periods start counting at 1, not 0, so offset by -1 for the array
	NSUInteger period = _courseInfo.period.unsignedIntegerValue;
	
	if(period > sbcolours.count) {
		_sideBar.colors = @[(id) [UIColor colorWithWhite:0.08 alpha:1.0].CGColor, (id) [[UIColor colorWithWhite:0.08 alpha:1.0] darkerColor].CGColor];
	} else {
		NSUInteger index = [[SQUGradeManager sharedInstance].student.courses indexOfObject:_courseInfo];
		
		_sideBar.colors = @[(id) [sbcolours[index] CGColor], (id) [[sbcolours[index] darkerColor] CGColor]];
	}
	
    _periodTitle.string = [NSString stringWithFormat:NSLocalizedString(@"Period %u", nil), period];
    _courseTitle.string = _courseInfo.title;
	
	// Add only the cycle heads we need
	if(_courseInfo.semesters.count != 1) {
		for(CATextLayer *layer in _semesterHeads) {
			[_backgroundLayer addSublayer:layer];
		}
		
		for(CATextLayer *layer in _cycleHeads) {
			[_backgroundLayer addSublayer:layer];
		}
	} else { // We need cycles 1-4
		// Remove semester heads
		for(CATextLayer *layer in _semesterHeads) {
			[layer removeFromSuperlayer];
		}
		
		// Remove other cycle's labels
		for(CATextLayer *layer in _cycleHeads) {
			[layer removeFromSuperlayer];
		}
		
		// Add cycles 1-4 labels
		for(NSUInteger i = 0; i < 4; i++) {
			[_backgroundLayer addSublayer:_cycleHeads[i]];
		}
	}
	
	// Generate something for each semester
	for(NSUInteger i = 0; i < _courseInfo.semesters.count; i++) {
		SQUSemester *semester = _courseInfo.semesters[i];
		
		CATextLayer *semesterHead = _semesterHeads[i];
		
		if(semester.average.integerValue == -1) {
			semesterHead.string = [NSString stringWithFormat:NSLocalizedString(@"Semester %u: -", nil), i + 1];
			semesterHead.foregroundColor = [UIColor lightGrayColor].CGColor;
		} else {
			semesterHead.string = [NSString stringWithFormat:NSLocalizedString(@"Semester %u: %u", nil), i + 1, semester.average.unsignedIntegerValue];
			semesterHead.foregroundColor = [UIColor blackColor].CGColor;
		}
		
		if(_courseInfo.semesters.count != 1) {
			for(NSUInteger j = 0; j < 4; j++) {
				CATextLayer *cycleHead = _cycleHeads[j + (i * 4)];
				
				// Exam grade
				if(j == 3) {
					if(semester.examIsExempt.boolValue) {
						cycleHead.string = [NSString stringWithFormat:NSLocalizedString(@"Exam %u: Exc", nil), i + 1];
						cycleHead.foregroundColor = [UIColor blackColor].CGColor;
					} else if(semester.examGrade.integerValue == -1) {
						cycleHead.string = [NSString stringWithFormat:NSLocalizedString(@"Exam %u: -", nil), i + 1];
						cycleHead.foregroundColor = [UIColor lightGrayColor].CGColor;
					} else if(!semester.examIsExempt.boolValue) {
						cycleHead.string = [NSString stringWithFormat:NSLocalizedString(@"Exam %u: %u", nil), i + 1, semester.examGrade.unsignedIntegerValue];
						cycleHead.foregroundColor = [UIColor blackColor].CGColor;
					}
				} else {
					SQUCycle *cycle = _courseInfo.cycles[j + (i * 3)];
					
					if(cycle.average.unsignedIntegerValue == 0) {
						cycleHead.string = [NSString stringWithFormat:NSLocalizedString(@"Cycle %u: -", nil), j + 1];
						cycleHead.foregroundColor = [UIColor lightGrayColor].CGColor;
					} else {
						cycleHead.string = [NSString stringWithFormat:NSLocalizedString(@"Cycle %u: %u", nil), j + 1, cycle.average.unsignedIntegerValue];
						cycleHead.foregroundColor = [UIColor blackColor].CGColor;
					}
				}
			}
		} else {
			// Elementary students
			for(NSUInteger j = 0; j < 4; j++) {
				CATextLayer *cycleHead = _cycleHeads[j];
				SQUCycle *cycle = _courseInfo.cycles[j];
				
				if(cycle.average.unsignedIntegerValue != 0 && !cycle.usesLetterGrades.boolValue) {
					// Does NOT use letter grade, has a grade inputted
					cycleHead.string = [NSString stringWithFormat:NSLocalizedString(@"Cycle %u: %u", nil), j + 1, cycle.average.unsignedIntegerValue];
					cycleHead.foregroundColor = [UIColor blackColor].CGColor;
				}  else if(cycle.letterGrade.length != 0 && cycle.usesLetterGrades.boolValue) {
					// Uses letter grade, has grade inputted
					cycleHead.string = [NSString stringWithFormat:NSLocalizedString(@"Cycle %u: %@", @"letter grades"), j + 1, cycle.letterGrade];
					cycleHead.foregroundColor = [UIColor blackColor].CGColor;
				} else {
					// Either letter grade or numerical grade but not entered
					cycleHead.string = [NSString stringWithFormat:NSLocalizedString(@"Cycle %u: -", nil), j + 1];
					cycleHead.foregroundColor = [UIColor lightGrayColor].CGColor;
				}
			}
		}
	}
	
	// Remove the seperator as needed (if there's only one semester)
	if(_courseInfo.semesters.count == 1) {
		[_semesterSeperator removeFromSuperlayer];
	} else {
		[_backgroundLayer addSublayer:_semesterSeperator];
	}
}

@end
