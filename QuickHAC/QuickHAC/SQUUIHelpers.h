//
//  SQUUIHelpers.h
//  QuickHAC
//
//  Created by Tristan Seifert on 1/3/14.
//  See README.MD for licensing and copyright information.
//

#import <Foundation/Foundation.h>

/**
 * Indication of how a specific grade changed.
 *
 * @const kSQUGradeChangeNone No change occurred.
 * @const kSQUGradeChangeRaised The new grade is higher than the old one.
 * @const kSQUGradeChangeLowered The grade declined compared to the old one.
 */
typedef enum {
	kSQUGradeChangeNone = 0,
	kSQUGradeChangeRaised,
	kSQUGradeChangeLowered
} SQUGradeChangeDirection;

@interface SQUUIHelpers : NSObject {
	
}

+ (UIColor *) colourizeGrade:(float) grade withAsianness:(float) asianness andHue:(float) hue;
+ (SQUGradeChangeDirection) getGradeChange:(float) initial toNew:(float) newGrade;

@end
