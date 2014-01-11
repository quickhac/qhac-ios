//
//  SQUSidebarCell.m
//  QuickHAC
//
//  Created by Tristan Seifert on 1/11/14.
//  See README.MD for licensing and copyright information.
//

#import "SQUSidebarCell.h"

@implementation SQUSidebarCell
@synthesize titleText = _text;

- (id) initWithStyle:(UITableViewCellStyle) style reuseIdentifier:(NSString *) reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
	if (self) {
		// Suppress default selection
        self.selectionStyle = UITableViewCellSelectionStyleNone;
		self.backgroundColor = UIColorFromRGB(0x363636);
		
		// Set up our own text rendering
		CGRect frame = self.frame;
		frame.origin = CGPointMake(15, 11);
		frame.size.height -= 10;
		
		_titleLayer = [CATextLayer layer];
        _titleLayer.contentsScale = [UIScreen mainScreen].scale;
        _titleLayer.foregroundColor = UIColorFromRGB(0xd6d6d6).CGColor;
        _titleLayer.font = (__bridge CFTypeRef) [UIFont fontWithName:@"HelveticaNeue-Medium" size:17.0];
        _titleLayer.fontSize = self.textLabel.font.pointSize;
		_titleLayer.zPosition = 10;
		_titleLayer.frame = frame;
		_titleLayer.alignmentMode = kCAAlignmentLeft;
		[self.layer addSublayer:_titleLayer];
		
		[self.textLabel removeFromSuperview];
    }
	
    return self;
}

- (void) setSelected:(BOOL) selected animated:(BOOL) animated {
    [super setSelected:selected animated:animated];

    if(selected) {
		_titleLayer.foregroundColor = UIColorFromRGB(0xd6d6d6).CGColor;
		
		// Create selection view
		if(!_bgLayer) {
			_bgLayer = [CALayer layer];
			_bgLayer.cornerRadius = 4.0;
			_bgLayer.backgroundColor = UIColorFromRGB(0x1e1e1e).CGColor;
			_bgLayer.zPosition = 0;
			_bgLayer.borderWidth = 1.0;
			_bgLayer.borderColor = UIColorFromRGB(0x282828).CGColor;
		}
		
		// Set up frame for the layer (6px from L/R, 4px top/bottom)
		CGRect frame = self.frame;
		frame.origin = CGPointMake(6, 4);
		frame.size.width = 246;
		frame.size.height -= 8;
		_bgLayer.frame = frame;
		
		[self.layer addSublayer:_bgLayer];
	} else {
		_titleLayer.foregroundColor = UIColorFromRGB(0xd6d6d6).CGColor;
		
		// Hide the selection indicator, if it is shown
		if(_bgLayer) {
			[_bgLayer removeFromSuperlayer];
		}
	}
}

/**
 * Sets the string displayed on the title layer.
 */
- (void) setTitleText:(NSString *) text {
	_titleLayer.string = (id) text;
}

@end
