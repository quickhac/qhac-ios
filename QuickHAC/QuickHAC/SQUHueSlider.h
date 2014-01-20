//
//  SQUHueSlider.h
//  QuickHAC
//
//  Created by Tristan Seifert on 1/19/14.
//  See README.MD for licensing and copyright information.
//

#import <UIKit/UIKit.h>

@interface SQUHueSlider : UISlider {
	CALayer *_gradient;
}

- (void) redrawGradient;

@end
