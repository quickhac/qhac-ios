//
//  SQUSidebarCell.h
//  QuickHAC
//
//  Created by Tristan Seifert on 1/11/14.
//  See README.MD for licensing and copyright information.
//



#import <UIKit/UIKit.h>

@interface SQUSidebarCell : UITableViewCell {
	CALayer *_bgLayer;
	CATextLayer *_titleLayer;
	
	NSString *_text;
}

@property (nonatomic, readwrite, setter = setTitleText:) NSString *titleText;

@end
