//
//  SQUClassDetailHeaderCell.m
//  QuickHAC
//
//  Created by Tristan Seifert on 2/12/14.
//  See README.MD for licensing and copyright information.
//

#import "SQUColourScheme.h"
#import "SQUCoreData.h"
#import "SQUAppDelegate.h"
#import "SQUGradeOverviewTableViewCell.h"
#import "SQUClassDetailHeaderCell.h"

#import <CoreText/CoreText.h>

#define SQUClassDetailHeaderCellAvgLabelWidth 73

@implementation SQUClassDetailHeaderCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
	if (self) {
		// Card background
		_backgroundLayer = [CALayer layer];
		_backgroundLayer.frame = CGRectMake(10, 0, self.frame.size.width - 20, SQUClassDetailHeaderCellHeight - 6);
        _backgroundLayer.backgroundColor = [UIColor clearColor].CGColor;
		_backgroundLayer.borderWidth = 0.0;
		_backgroundLayer.contentsScale = [UIScreen mainScreen].scale;
		_backgroundLayer.masksToBounds = YES;
		[self.layer addSublayer:_backgroundLayer];
		
		// Average label
		_average = [CATextLayer layer];
        _average.frame = CGRectMake(_backgroundLayer.frame.size.width - SQUClassDetailHeaderCellAvgLabelWidth, 2, SQUClassDetailHeaderCellAvgLabelWidth, 44);
        _average.contentsScale = [UIScreen mainScreen].scale;
        _average.font = (__bridge CFTypeRef) [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:15.0f];
        _average.fontSize = 42.0f;
		_average.alignmentMode = kCAAlignmentRight;
        _average.foregroundColor = [UIColor blackColor].CGColor;
		[_backgroundLayer addSublayer:_average];
		
		// Course title label
		_courseTitle = [CATextLayer layer];
        _courseTitle.frame = CGRectMake(0, 6, _backgroundLayer.frame.size.width - SQUClassDetailHeaderCellAvgLabelWidth - 4, 32);
        _courseTitle.contentsScale = [UIScreen mainScreen].scale;
        _courseTitle.font = (__bridge CFTypeRef) [UIFont fontWithName:@"HelveticaNeue-Light" size:15.0f];
        _courseTitle.fontSize = 25.0f;
        _courseTitle.foregroundColor = [UIColor blackColor].CGColor;
		[_backgroundLayer addSublayer:_courseTitle];
		[self applyMaskToTextLayer:_courseTitle];
		
		// Teacher name
		_teacher = [CATextLayer layer];
        _teacher.frame = CGRectMake(0, 36, _backgroundLayer.frame.size.width - SQUClassDetailHeaderCellAvgLabelWidth - 4, 32);
        _teacher.contentsScale = [UIScreen mainScreen].scale;
        _teacher.font = (__bridge CFTypeRef) [UIFont fontWithName:@"HelveticaNeue" size:15.0f];
        _teacher.fontSize = 15.0f;
        _teacher.foregroundColor = UIColorFromRGB(kSQUColourAsbestos).CGColor;
		[_backgroundLayer addSublayer:_teacher];
		[self applyMaskToTextLayer:_teacher];
    }
	
    return self;
}

- (void) setCourse:(SQUCourse *) course {
	// Clear old course
	_course = nil;
	
	if(course) {
		_course = course;
		_courseTitle.string = _course.title;
		_teacher.string = [_course.teacher_name uppercaseStringWithLocale:
						   [NSLocale currentLocale]];
		
		// If the cycle has a letter grade, use that instead
		if(_cycle.letterGrade.length != 0) {
			_average.string = _cycle.letterGrade;
		} else {
			_average.string = [_cycle.average stringValue];
		}
		
		_average.foregroundColor = [SQUGradeOverviewTableViewCell gradeChangeColour:_cycle].CGColor;
		
		if(_cycle.changedSinceLastFetch.boolValue) {
			// Reset fetch status
			_cycle.changedSinceLastFetch = @(NO);
			// Save to DB
			NSError *err = nil;
			if(![[SQUAppDelegate sharedDelegate].managedObjectContext save:&err]) {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Database Error", nil) message:err.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
				[alert show];
			}
		}
	}
}

- (void) applyMaskToTextLayer:(CATextLayer *) layer {
	CAGradientLayer *mask = [CAGradientLayer layer];
	mask.bounds = CGRectMake(0, 0, layer.frame.size.width, layer.frame.size.height);
	mask.position = CGPointMake(layer.bounds.size.width/2.0, layer.bounds.size.height/2.0);
	mask.locations = @[@(0.85f), @(1.0f)];
	mask.colors = @[(id)[UIColor blackColor].CGColor, (id)[UIColor clearColor].CGColor];
	mask.startPoint = CGPointMake(0.0, 0.5);
	mask.endPoint = CGPointMake(1.0, 0.5);
	layer.mask = mask;
}

@end
