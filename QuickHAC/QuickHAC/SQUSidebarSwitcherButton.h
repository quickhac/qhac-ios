//
//  SQUSidebarSwitcherButton.h
//  QuickHAC
//
//  Created by Tristan Seifert on 1/11/14.
//  See README.MD for licensing and copyright information.
//

#import <UIKit/UIKit.h>

@interface SQUSidebarSwitcherButton : UIButton {
	BOOL _toggled;
	
	UIImageView *_avatar;
	CATextLayer *_titleLayer;
	CATextLayer *_subtitleLayer;
}

@property (nonatomic, readonly) BOOL toggled;
@property (nonatomic, readwrite, setter = setTitle:) NSString *title;
@property (nonatomic, readwrite, setter = setSubtitle:) NSString *subtitle;

@end
