//
//  SQUHueSlider.m
//  QuickHAC
//
//  Created by Tristan Seifert on 1/19/14.
//  See README.MD for licensing and copyright information.
//

#import "SQUHueSlider.h"

@interface SQUHueSlider (PrivateMethods)
- (UIImage *) generateHueGradientWithSize:(CGSize) size andStart:(CGFloat) currentHue andStep:(CGFloat) hueStep;
@end

@implementation SQUHueSlider

- (id) initWithFrame:(CGRect) frame {
    self = [super initWithFrame:frame];
    
	if (self) {
		self.clipsToBounds = NO;
		_gradient = [CALayer layer];
		_gradient.backgroundColor = UIColorFromRGB(0xff00ff).CGColor;
		[self.layer insertSublayer:_gradient atIndex:2];
		[self redrawGradient];
    }
	
    return self;
}

/**
 * Draws the hue gradient.
 */
- (UIImage *) generateHueGradientWithSize:(CGSize) size andStart:(CGFloat) currentHue andStep:(CGFloat) hueStep {
	UIGraphicsBeginImageContextWithOptions(size, YES, [UIScreen mainScreen].scale);
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	
	CGColorRef colour;
	
	// Iterate through each cycle
	for(NSUInteger x = 0; x < size.width; x++) {
		colour = [UIColor colorWithHue:currentHue saturation:1.0 brightness:1.0 alpha:1.0].CGColor;
		CGContextSetFillColorWithColor(ctx, colour);
		CGContextFillRect(ctx, CGRectMake(x, 0, 1, size.height));
		currentHue += hueStep;
	}
	
	// Render context to image and delete it
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return image;
}

- (void) layoutSubviews {
	[super layoutSubviews];
	
	_gradient.frame = CGRectMake(2, 21, self.frame.size.width - 4, 2);
	
	[self redrawGradient];
}

/**
 * Re-draws the gradient on the slider in response to a frame change.
 */
- (void) redrawGradient {
	/*CGFloat currentHue = self.value;
	CGFloat minimum = (self.frame.size.width) * (currentHue / 360.0);
	CGFloat maximum = self.frame.size.width - minimum;

	CGFloat minStep = (currentHue / minimum);
	CGFloat maxStep = (360 - currentHue) / maximum;
	
	NSLog(@"Hue: %f, minStep = %f, minWidth = %f, maxStep = %f, maxWidth = %f", currentHue, minStep, minimum, maxStep, maximum);
	
	self.minimumValueImage = [self generateHueGradientWithSize:CGSizeMake(minimum, 2) andStart:0 andStep:(minStep / 360.0)];
	self.maximumValueImage = [self generateHueGradientWithSize:CGSizeMake(maximum, 2) andStart:(currentHue / 360.0) andStep:(maxStep / 360.0)];*/
	
	UIImage *gradient = [self generateHueGradientWithSize:CGSizeMake(_gradient.frame.size.width, 2) andStart:0 andStep:(1.0 / self.frame.size.width)];
	_gradient.contents = (__bridge id) gradient.CGImage;
}

@end