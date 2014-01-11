//
//  SQUSidebarSwitcherButton.m
//  QuickHAC
//
//	Sidebar user switching toggle button
//
//	User icon: 27x27pt, left offset 10pt, 19pt top, 18pt bottom
//	Text: offset left 48pt
//	Title: offset top 20pt
//	Subtitle: offset top 36 pt
//
//  Created by Tristan Seifert on 1/11/14.
//  See README.MD for licensing and copyright information.
//

#import "UIColor+SQUColourUtilities.h"
#import "SQUSidebarSwitcherButton.h"

@implementation SQUSidebarSwitcherButton

- (id) initWithFrame:(CGRect) frame {
    self = [super initWithFrame:frame];
    
	if (self) {
        [self setImage:[UIImage imageNamed:@"switcher_arrow"] forState:UIControlStateNormal];
		[self setBackgroundImage:[UIColorFromRGB(0x363636) imageFromColor] forState:UIControlStateNormal];
		[self setBackgroundImage:[UIColorFromRGB(0x2b2b2b) imageFromColor] forState:UIControlStateSelected];
		[self addTarget:self action:@selector(buttonActuated:) forControlEvents:UIControlEventTouchUpInside];
		
		// Add avatar view
		_avatar = [[UIImageView alloc] initWithFrame:CGRectMake(10, 19, 27, 27)];
		_avatar.image = [UIImage imageNamed:@"default_avatar.jpg"];
		_avatar.layer.masksToBounds = YES;
		_avatar.layer.cornerRadius = 2.0;
		[self addSubview:_avatar];
		
		// Title and subtitle
		_titleLayer = [CATextLayer layer];
		_titleLayer.contentsScale = [UIScreen mainScreen].scale;
		_titleLayer.string = @"Title.";
		_titleLayer.foregroundColor = UIColorFromRGB(0xd6d6d6).CGColor;
		_titleLayer.frame = CGRectMake(48, 17, self.frame.size.width - 58, 22);
        _titleLayer.font = (__bridge CFTypeRef) [UIFont fontWithName:@"HelveticaNeue-Medium" size:17.0];
        _titleLayer.fontSize = 16;
		
		[self.layer addSublayer:_titleLayer];
		
		// Subtitle
		_subtitleLayer = [CATextLayer layer];
		_subtitleLayer.contentsScale = [UIScreen mainScreen].scale;
		_subtitleLayer.string = @"Subtitle!";
		_subtitleLayer.foregroundColor = [UIColor lightGrayColor].CGColor;
		_subtitleLayer.frame = CGRectMake(48, 35, self.frame.size.width - 58, 22);
        _subtitleLayer.font = (__bridge CFTypeRef) [UIFont fontWithName:@"HelveticaNeue-Light" size:17.0];
        _subtitleLayer.fontSize = 12;
		
		[self.layer addSublayer:_subtitleLayer];
    }
	
    return self;
}

- (void) layoutSubviews {
	[super layoutSubviews];
	
	// Fix image view (16 pt away from right side of button)
	CGRect frame = self.imageView.frame;
	frame.origin.x = self.frame.size.width - frame.size.width - 16;
	self.imageView.frame = frame;
}

#pragma mark - Setters
- (void) setTitle:(NSString *) title {
	_titleLayer.string = title;
}

- (void) setSubtitle:(NSString *) subtitle {
	_titleLayer.string = subtitle;
}

#pragma mark - Button action
- (void) buttonActuated:(id) sender {
	if(_toggled) {
		[UIView animateWithDuration:0.4 animations:^{
			self.imageView.transform = CGAffineTransformMakeRotation(0);
		}];
	} else {
		[UIView animateWithDuration:0.4 animations:^{
			self.imageView.transform = CGAffineTransformMakeRotation(M_PI);
		}];
	}
	
	_toggled = !_toggled;
}

@end
