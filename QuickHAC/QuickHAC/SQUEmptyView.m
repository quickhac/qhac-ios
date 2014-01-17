//
//  SQUEmptyView.m
//  QuickHAC
//
//  Created by Tristan Seifert on 1/5/14.
//  See README.MD for licensing and copyright information.
//

#import "SQUEmptyView.h"

@implementation SQUEmptyView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
	if (self) {
        _header = [[UILabel alloc] init];
		_header.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:26.0];
		_header.text = @"No Data Available";
		_header.textAlignment = NSTextAlignmentCenter;
		
		_subtitle = [[UILabel alloc] init];
		_subtitle.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16.0];
		_subtitle.text = @"Either the teacher has not entered any data yet, or your Internet connection is offline.";
		_subtitle.textAlignment = NSTextAlignmentCenter;
		_subtitle.lineBreakMode = NSLineBreakByWordWrapping;
		_subtitle.numberOfLines = 0;
		
		_imageView = [[UIImageView alloc] init];
		_imageView.layer.borderColor = UIColorFromRGB(0x00ff00).CGColor;
		_imageView.layer.borderWidth = 1.0;
		
		[self addSubview:_header];
		[self addSubview:_subtitle];
		[self addSubview:_imageView];
		
		self.backgroundColor = UIColorFromRGB(0xf8f8f8);
    }
	
    return self;
}

/**
 * Re-arranges the views to fit the resized dimensions.
 */
- (void) layoutSubviews {
	[super layoutSubviews];

	CGFloat startYPos = self.frame.size.height / 2;
	startYPos += 32;
	
	CGFloat imageY = (startYPos / 2) - 100;
	
	_imageView.frame = CGRectMake((self.frame.size.width / 2) - 100, imageY, 200, 200);
	
	_header.frame = CGRectMake(8, startYPos, self.frame.size.width-16, 34);
	_subtitle.frame = CGRectMake(8, startYPos + 42, self.frame.size.width-16, 72);
}


@end
