//
//  SQUDashboardController.h
//  QuickHAC
//
//  Created by Tristan Seifert on 2/22/14.
//  See README.MD for licensing and copyright information.
//

#import <UIKit/UIKit.h>

@class SQURelativeRefreshControl;
@interface SQUDashboardController : UICollectionViewController <UICollectionViewDelegateFlowLayout> {
	SQURelativeRefreshControl *_refresher;
}

- (instancetype) init;

@end
