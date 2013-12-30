//
//  SQUClassCycleChooserController.h
//  QuickHAC
//
//  Created by Tristan Seifert on 12/29/13.
//  Copyright (c) 2013 Squee! Apps. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SQUClassCycleChooserController;
@protocol SQUClassCycleChooserControllerDelegate
@optional

- (void) cycleChooser:(SQUClassCycleChooserController *) chooser selectedCycle:(NSUInteger) cycle;

@end

@interface SQUClassCycleChooserController : UITableViewController {
	NSArray *_cycles;
	NSUInteger _selectedCycle;
	id <SQUClassCycleChooserControllerDelegate> _delegate;
}

@property (nonatomic, readwrite) NSUInteger selectedCycle;
@property (nonatomic, readwrite) id <SQUClassCycleChooserControllerDelegate> delegate;

- (id) initWithCycles:(NSArray *) cycles;

@end
