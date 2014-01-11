//
//  UIColor+SQUColourUtilities.m
//  QuickHAC
//
//  Created by Tristan Seifert on 12/28/13.
//  See README.MD for licensing and copyright information.
//

#import "UIColor+SQUColourUtilities.h"

@implementation UIColor (SQUColourUtilities)

/**
 * Lightens the current colour.
 */
- (UIColor *) lighterColor {
    CGFloat h, s, b, a;
    if ([self getHue:&h saturation:&s brightness:&b alpha:&a])
        return [UIColor colorWithHue:h
                          saturation:s
                          brightness:MIN(b * 1.3, 1.0)
                               alpha:a];
    return nil;
}

/**
 * Creates a darker version of the current colour.
 */
- (UIColor *) darkerColor {
    CGFloat h, s, b, a;
    if ([self getHue:&h saturation:&s brightness:&b alpha:&a])
        return [UIColor colorWithHue:h
                          saturation:s
                          brightness:b * 0.75
                               alpha:a];
    return nil;
}

/**
 * Returns a 1x1 image filled with this colour.
 */
- (UIImage *) imageFromColor {
	CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
	UIGraphicsBeginImageContext(rect.size);
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	CGContextSetFillColorWithColor(context, self.CGColor);
	CGContextFillRect(context, rect);
	
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return image;
}

@end
