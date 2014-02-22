//
//  SQUSplitViewController.m
//  QuickHAC
//
//  Created by Tristan Seifert on 2/22/14.
//  See README.MD for licensing and copyright information.
//

#import "SQUSplitViewController.h"

@implementation SQUSplitViewController

- (void) viewDidLayoutSubviews {
	if(UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
		// Get view controllers
		UIViewController *controller1 = self.viewControllers[0];
		UIViewController *controller2 = self.viewControllers[1];
		
		CGFloat detailWidth = 768;
		
		// Adjust master
		CGRect frame1 = controller1.view.frame;
		frame1.size.width = self.view.bounds.size.width - detailWidth;
		frame1.origin.x = 0;
		controller1.view.frame = frame1;
		
		// Adjust detail
		CGRect frame2 = controller2.view.frame;
		frame2.origin.x = CGRectGetMaxX(frame1);
		frame2.size.width = detailWidth;
		controller2.view.frame = frame2;
	}
}

- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation) toInterfaceOrientation duration:(NSTimeInterval) duration {
	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	[self viewDidLayoutSubviews];
}

@end
