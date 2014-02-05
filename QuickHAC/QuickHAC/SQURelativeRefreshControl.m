//
//  SQURelativeRefreshControl.m
//  QuickHAC
//
//  Created by Tristan Seifert on 2/5/14.
//  Copyright (c) 2014 Squee! Apps. All rights reserved.
//

#import "NSDate+RelativeDate.h"
#import "SQURelativeRefreshControl.h"

@implementation SQURelativeRefreshControl
@synthesize date = _date;

/**
 * Sets the date displayed on the refresh control, as well as updating the timer
 * used to update it.
 */
- (void) setDate:(NSDate *) date {
	_date = date;
	_timerIsUsingOneMinuteTicks = NO;
	
	[self timerTick:_timer];
	[self updateTimer];
}

/**
 * Updates the timer
 */
- (void) updateTimer {
	NSTimeInterval tick;
	
	// Remove old timer
	if(_timer) {
		[_timer invalidate];
	}
	
	// Calculate difference between current time and date
	NSTimeInterval diff = [[NSDate new] timeIntervalSinceDate:_date];
	
	// Is the date more than one minute in the past?
	if(diff > 60) {
		_timerIsUsingOneMinuteTicks = YES;
		tick = 60.0;
	} else {
		_timerIsUsingOneMinuteTicks = NO;
		tick = 1.0;
	}
	
	// Create the timer
	_timer = [NSTimer timerWithTimeInterval:tick target:self
								   selector:@selector(timerTick:)
								   userInfo:nil repeats:YES];
	
	// Manually add to run loop (as to not stop it when scrolling)
	[[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
}

/**
 * Called by the timer to update the label.
 */
- (void) timerTick:(NSTimer *) sender {
	self.attributedTitle = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@"Updated %@", @"relative refresh control"), [_date relativeDate]]];
	
	// Check if the timer needs to be set to 1 minute tick intervals
	if(!_timerIsUsingOneMinuteTicks) {
		// Calculate difference between current time and date
		NSTimeInterval diff = [[NSDate new] timeIntervalSinceDate:_date];
		
		// If the difference is more than 60 seconds, update timer
		if(diff > 60) {
			[self updateTimer];
		}
	}
}

@end
