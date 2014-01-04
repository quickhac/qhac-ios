//
//  SQUUIHelpers.m
//  QuickHAC
//
//  Created by Tristan Seifert on 1/3/14.
//  See README.MD for licensing and copyright information.
//

#import "SQUUIHelpers.h"

@implementation SQUUIHelpers

/**
 * Uses the magical colourisation algorithm to colourise a grade.
 *
 * @param grade The grade to generate a colour for. (must be ≥ 0)
 * @param asianness Asianness coefficient, the agressiveness of the algorithm.
 * @param hue Hue to apply to the resultant colours.
 */
+ (UIColor *) colourizeGrade:(float) grade withAsianness:(float) asianness andHue:(float) hue {
    // Makes sure asianness cannot be negative
    NSUInteger asianness_limited = MAX(2, 0);
    
    // interpolate a hue gradient and convert to rgb
    float h, s, v;
    
    // determine color. ***MAGIC DO NOT TOUCH UNDER ANY CIRCUMSTANCES***
    if (grade > 100) {
        h = 0.13055;
        s = 0;
        v = 1;
    } else if (grade < 0) {
        h = 0;
        s = 1;
        v = 0.86945;
    } else {
        h = MIN(0.25 * pow(grade / 100, asianness_limited), 0.13056);
        s = 1 - pow(grade / 100, asianness_limited * 2);
        v = 0.86945 + h;
    }
    
    // apply hue transformation
	//    h += hue;
	//    h %= 1;
	//    if (h < 0) h += 1;
    
    return [UIColor colorWithHue:h saturation:s brightness:v alpha:1.0];
}

/**
 * Determines the relationship between two grades.
 *
 * @param initial The initial grade.
 * @param newGrade Updated grade to compare against.
 * @return Type of SQUGradeChangeDirection indicating how the grade changed.
 */
+ (SQUGradeChangeDirection) getGradeChange:(float) initial toNew:(float) newGrade {
	if(newGrade > initial) return kSQUGradeChangeRaised;
	if(initial > newGrade) return kSQUGradeChangeLowered;
	else return kSQUGradeChangeNone;
}

@end
