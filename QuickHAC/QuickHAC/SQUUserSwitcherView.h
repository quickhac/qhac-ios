//
//  SQUUserSwitcherView.h
//  QuickHAC
//
//  Created by Tristan Seifert on 1/11/14.
//  See README.MD for licensing and copyright information.
//

#import <UIKit/UIKit.h>

@interface SQUUserSwitcherView : UIView <UICollectionViewDelegate, UICollectionViewDataSource> {
	UICollectionView *_grid;
	UICollectionViewFlowLayout *_gridLayout;
	UIButton *_logoutButton;
	
	NSMutableArray *_students;
	
	NSIndexPath *_lastSelection;
}

- (void) updateStudents:(id) ignored;

@end
