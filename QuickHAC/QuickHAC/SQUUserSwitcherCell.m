//
//  SQUUserSwitcherCell.m
//  QuickHAC
//
//  Created by Tristan Seifert on 1/11/14.
//  See README.MD for licensing and copyright information.
//

#import "SQUUserSwitcherCell.h"

@implementation SQUUserSwitcherCell
@synthesize showsSelection = _showsSelection;

- (id) initWithFrame:(CGRect) frame {
    self = [super initWithFrame:frame];
    
	if (self) {
		// Avatar
		CGFloat imageWidth = kSQUUserSwitcherCellWidth - (kSQUUserSwitcherCellSelectionThickness * 2);
		
		_image = [CALayer layer];
		_image.frame = CGRectMake(kSQUUserSwitcherCellSelectionThickness, kSQUUserSwitcherCellSelectionThickness, imageWidth, imageWidth);
		_image.cornerRadius = 5;
		_image.masksToBounds = YES;
		[self.contentView.layer addSublayer:_image];
		
		// Title and subtitle
		_title = [CATextLayer layer];
		_title.contentsScale = [UIScreen mainScreen].scale;
		_title.string = @"Title.";
		_title.foregroundColor = UIColorFromRGB(0xd6d6d6).CGColor;
		_title.frame = CGRectMake(0, 122, kSQUUserSwitcherCellWidth, 20);
        _title.font = (__bridge CFTypeRef) [UIFont fontWithName:@"HelveticaNeue-Medium" size:17.0];
        _title.fontSize = 14;
		_title.alignmentMode = kCAAlignmentCenter;
		
		[self.contentView.layer addSublayer:_title];
		
		// Subtitle
		_subtitle = [CATextLayer layer];
		_subtitle.contentsScale = [UIScreen mainScreen].scale;
		_subtitle.string = @"Subtitle!";
		_subtitle.foregroundColor = [UIColor lightGrayColor].CGColor;
		_subtitle.frame = CGRectMake(0, 138, kSQUUserSwitcherCellWidth, 16);
        _subtitle.font = (__bridge CFTypeRef) [UIFont fontWithName:@"HelveticaNeue-Light" size:17.0];
        _subtitle.fontSize = 11;
		_subtitle.alignmentMode = kCAAlignmentCenter;
		
		[self.contentView.layer addSublayer:_subtitle];
		
		// Prepare selection background
		_showsSelection = YES;
		self.selectedBackgroundView = [[UIView alloc] initWithFrame:self.contentView.frame];
		self.selectedBackgroundView.layer.frame = CGRectMake(0, 0, kSQUUserSwitcherCellWidth, kSQUUserSwitcherCellWidth);
		self.selectedBackgroundView.layer.backgroundColor = UIColorFromRGB(0x0d63d6).CGColor;
		self.selectedBackgroundView.layer.cornerRadius = _image.cornerRadius*2;
		self.selectedBackgroundView.layer.masksToBounds = YES;
    }
	
    return self;
}

#pragma mark - Setters
/**
 * Sets the title label's text.
 */
- (void) setTitle:(NSString *) title {
	_title.string = title;
}

/**
 * Sets the subtitle label's text.
 */
- (void) setSubTitle:(NSString *) title {
	_subtitle.string = title;
}

/**
 * Sets the image displayed.
 */
- (void) setImage:(UIImage *) image {
	_image.contents = (__bridge id) image.CGImage;
}

/**
 * Sets the badge count, hiding/showing the badge as neccesary.
 */
- (void) setBadgeCount:(NSUInteger) count {
	_badgeCount = count;
}

- (void) setShowsSelection:(BOOL) showsSelection {
	_showsSelection = showsSelection;
	
	if(!_showsSelection) {
		self.selectedBackgroundView = nil;
	} else {
		self.selectedBackgroundView = [[UIView alloc] initWithFrame:self.contentView.frame];
		self.selectedBackgroundView.layer.frame = CGRectMake(0, 0, kSQUUserSwitcherCellWidth, kSQUUserSwitcherCellWidth);
		self.selectedBackgroundView.layer.backgroundColor = UIColorFromRGB(0x0d63d6).CGColor;
		self.selectedBackgroundView.layer.cornerRadius = _image.cornerRadius*2;
		self.selectedBackgroundView.layer.masksToBounds = YES;
	}
}

@end
