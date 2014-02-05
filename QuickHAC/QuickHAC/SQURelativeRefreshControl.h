//
//  SQURelativeRefreshControl.h
//  QuickHAC
//
//  Created by Tristan Seifert on 2/5/14.
//  Copyright (c) 2014 Squee! Apps. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SQURelativeRefreshControl : UIRefreshControl {
	NSDate *_date;
	NSTimer *_timer;
	
	BOOL _timerIsUsingOneMinuteTicks;
}

@property (nonatomic, readwrite, setter = setDate:) NSDate *date;

@end
