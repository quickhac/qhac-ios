//
//  SQUUserSwitcherCell.h
//  QuickHAC
//
//  Created by Tristan Seifert on 1/11/14.
//  See README.MD for licensing and copyright information.
//

#import <UIKit/UIKit.h>

#define kSQUUserSwitcherCellWidth 120
#define kSQUUserSwitcherCellHeight 150
#define kSQUUserSwitcherCellSelectionThickness 5

@interface SQUUserSwitcherCell : UICollectionViewCell {
	CALayer *_image;
	CATextLayer *_title;
	CATextLayer *_subtitle;
	
	CALayer *_badge;
	CATextLayer *_badgeText;
	
	BOOL _showsSelection;
	NSUInteger _badgeCount;
}

@property (nonatomic, setter = setShowsSelection:) BOOL showsSelection;

- (void) setTitle:(NSString *) title;
- (void) setSubTitle:(NSString *) title;
- (void) setImage:(UIImage *) image;
- (void) setBadgeCount:(NSUInteger) count;

@end
