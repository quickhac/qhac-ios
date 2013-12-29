//
//  SQUGradeOverviewTableViewCell.m
//  QuickHAC
//
//  Created by Tristan Seifert on 16/07/2013.
//  See README.MD for licensing and copyright information.
//

#import <QuartzCore/QuartzCore.h>

#import "SQUGradeOverviewTableViewCell.h"
#import "SQUGradeParser.h"
#import "SQUCoreData.h"
#import "UIColor+SQUColourUtilities.h"

@implementation SQUGradeOverviewTableViewCell
@synthesize courseInfo = _courseInfo;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        CGRect rect = self.frame;
        rect.size.height = SQUGradeOverviewCellHeight;
        self.frame = rect;
		
		// Card background
		_backgroundLayer = [CALayer layer];
		_backgroundLayer.frame = CGRectMake(5, 5, self.frame.size.width - 10, self.frame.size.height - 10);
        _backgroundLayer.backgroundColor = [UIColor whiteColor].CGColor;
		_backgroundLayer.cornerRadius = 3.0;
		
		// Card shadow
		_backgroundLayer.borderWidth = 0.0;
		_backgroundLayer.shadowColor = [UIColor blackColor].CGColor;
		_backgroundLayer.shadowOpacity = 0.25;
		_backgroundLayer.shadowRadius = 4.0;
		_backgroundLayer.shadowOffset = CGSizeMake(0, 2);
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
        _courseTitle.frame = CGRectMake(20, 4, _backgroundLayer.frame.size.width - 106, 32);
        _courseTitle.contentsScale = [UIScreen mainScreen].scale;
        _courseTitle.foregroundColor = [UIColor blackColor].CGColor;
        _courseTitle.font = (__bridge CFTypeRef) [UIFont fontWithName:@"HelveticaNeue-Light" size:15.0f];
        _courseTitle.fontSize = 23.5f;
        
		// Period label
        _periodTitle = [CATextLayer layer];
        _periodTitle.frame = CGRectMake(_backgroundLayer.frame.size.width - 80, 8, 70, 24);
        _periodTitle.contentsScale = [UIScreen mainScreen].scale;
        _periodTitle.foregroundColor = [UIColor grayColor].CGColor;
        _periodTitle.font = (__bridge CFTypeRef) [UIFont systemFontOfSize:18.0f];
        _periodTitle.fontSize = 17.5f;
		_periodTitle.alignmentMode = kCAAlignmentRight;
		
		// Create Semester Average heads
		_semesterHeads = [NSMutableArray new];
		_cycleHeads = [NSMutableArray new];
		
		for(NSUInteger i = 0; i < 2; i++) {
			CGFloat currentX = 16 + ((_backgroundLayer.frame.size.width / 2) * i);
			
			CATextLayer *semesterHead = [CATextLayer layer];
			semesterHead.frame = CGRectMake(currentX, 34, (_backgroundLayer.frame.size.width / 2) - 24, 16);
			semesterHead.contentsScale = [UIScreen mainScreen].scale;
			semesterHead.foregroundColor = [UIColor blackColor].CGColor;
			semesterHead.font = (__bridge CFTypeRef) [UIFont boldSystemFontOfSize:14.0f];
			semesterHead.fontSize = 14.0f;
			semesterHead.string = @"Semester 1: 100";
			semesterHead.alignmentMode = kCAAlignmentCenter;
			
			// Create cycle subheads
			for(NSUInteger j = 0; j < 4; j++) {
				CGFloat currentX = 16 + ((_backgroundLayer.frame.size.width / 2) * i);
				
				CATextLayer *cycleHead = [CATextLayer layer];
				cycleHead.frame = CGRectMake(currentX, 56 + (j * 20), (_backgroundLayer.frame.size.width / 2) - 24, 16);
				cycleHead.contentsScale = [UIScreen mainScreen].scale;
				cycleHead.foregroundColor = [UIColor blackColor].CGColor;
				cycleHead.font = (__bridge CFTypeRef) [UIFont systemFontOfSize:14.0f];
				cycleHead.fontSize = 14.0f;
				cycleHead.string = @"Cycle 1: 100";
				//cycleHead.alignmentMode = (i == 0) ? kCAAlignmentLeft : kCAAlignmentRight;
				cycleHead.alignmentMode = kCAAlignmentLeft;
				
				[_cycleHeads addObject:cycleHead];
				[_backgroundLayer addSublayer:cycleHead];
			}
			
			[_semesterHeads addObject:semesterHead];
			[_backgroundLayer addSublayer:semesterHead];
		}
		
		// Add semester seperator
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
		_sideBar.colors = @[(id) [sbcolours[period-1] CGColor], (id) [[sbcolours[period-1] darkerColor] CGColor]];
	}
	
    _periodTitle.string = [NSString stringWithFormat:NSLocalizedString(@"Period %u", nil), period];
    _courseTitle.string = _courseInfo.title;
	
	for(NSUInteger i = 0; i < 2; i++) {
		SQUSemester *semester = _courseInfo.semesters[i];
		
		CATextLayer *semesterHead = _semesterHeads[i];
		
		if(semester.average.integerValue == -1) {
			semesterHead.string = [NSString stringWithFormat:NSLocalizedString(@"Semester %u: N/A", nil), i + 1];
		} else {
			semesterHead.string = [NSString stringWithFormat:NSLocalizedString(@"Semester %u: %u", nil), i + 1, semester.average.unsignedIntegerValue];
		}
		
		for(NSUInteger j = 0; j < 4; j++) {
			CATextLayer *cycleHead = _cycleHeads[j + (i * 4)];
			
			// Exam grade
			if(j == 3) {
				if(semester.examGrade.integerValue == -1) {
					cycleHead.string = [NSString stringWithFormat:NSLocalizedString(@"Exam %u: N/A", nil), i + 1];
				} else if(!semester.examIsExempt.boolValue) {
					cycleHead.string = [NSString stringWithFormat:NSLocalizedString(@"Exam %u: %u", nil), i + 1, semester.examGrade.unsignedIntegerValue];
				} else {
					cycleHead.string = [NSString stringWithFormat:NSLocalizedString(@"Exam %u: Exc", nil), i + 1];
				}
			} else {
				SQUCycle *cycle = _courseInfo.cycles[j + (i * 3)];
				
				if(cycle.average.unsignedIntegerValue == 0) {
					cycleHead.string = [NSString stringWithFormat:NSLocalizedString(@"Cycle %u: N/A", nil), j + 1];
				} else {
					cycleHead.string = [NSString stringWithFormat:NSLocalizedString(@"Cycle %u: %u", nil), j + 1, cycle.average.unsignedIntegerValue];
				}
			}
		}
	}
}

@end
