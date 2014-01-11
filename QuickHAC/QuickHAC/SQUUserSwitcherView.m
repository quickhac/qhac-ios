//
//  SQUUserSwitcherView.m
//  QuickHAC
//
//  Created by Tristan Seifert on 1/11/14.
//  See README.MD for licensing and copyright information.
//

#import "UIColor+SQUColourUtilities.h"
#import "SQUCoreData.h"
#import "SQUAppDelegate.h"
#import "SQUUserSwitcherCell.h"
#import "SQUGradeManager.h"
#import "SQUUserSwitcherView.h"

@implementation SQUUserSwitcherView

- (id) initWithFrame:(CGRect) frame {
    self = [super initWithFrame:frame];
    
	if (self) {
		[self updateStudents:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateStudents:) name:SQUStudentsUpdatedNotification object:nil];
		
		self.backgroundColor = UIColorFromRGB(0x262626);
		
		// Grid layout
		_gridLayout = [[UICollectionViewFlowLayout alloc] init];
		_gridLayout.minimumInteritemSpacing = 0;
		_gridLayout.minimumLineSpacing = 10;
		_gridLayout.itemSize = CGSizeMake(kSQUUserSwitcherCellWidth, kSQUUserSwitcherCellHeight);
		
		CGRect gridFrame = frame;
		gridFrame.origin.y = 0;
		gridFrame.size.height -= 45;
		NSLog(@"Grid frame: %@", NSStringFromCGRect(gridFrame));
		
		// Grid
		_grid = [[UICollectionView alloc] initWithFrame:gridFrame collectionViewLayout:_gridLayout];
		[_grid registerClass:NSClassFromString(@"SQUUserSwitcherCell") forCellWithReuseIdentifier:@"UserSwitcherCell"];
		_grid.backgroundColor = UIColorFromRGB(0x363636);
		_grid.delegate = self;
		_grid.dataSource = self;
		_grid.contentInset = UIEdgeInsetsMake(37, 5, 5, 5); // top left bottom right
		_grid.scrollIndicatorInsets = UIEdgeInsetsMake(32, 0, 0, 0);
		[self addSubview:_grid];
		
		// Logout button
		CGRect buttonRect = CGRectMake(0, gridFrame.size.height + 1, gridFrame.size.width, 44);
		_logoutButton = [[UIButton alloc] initWithFrame:buttonRect];
		[_logoutButton setBackgroundImage:[UIColorFromRGB(0x363636) imageFromColor] forState:UIControlStateNormal];
		[_logoutButton setBackgroundImage:[UIColorFromRGB(0x2b2b2b) imageFromColor] forState:UIControlStateSelected];
		[_logoutButton setTitle:NSLocalizedString(@"Log Out", nil) forState:UIControlStateNormal];
		[self addSubview:_logoutButton];
    }
	
    return self;
}

#pragma mark - Data handling
- (void) updateStudents:(id) ignored {
	// Fetch students objects from DB
	NSManagedObjectContext *context = [[SQUAppDelegate sharedDelegate] managedObjectContext];
	NSError *db_err = nil;
	
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"SQUStudent" inManagedObjectContext:context];
	[fetchRequest setEntity:entity];
	_students = [NSMutableArray arrayWithArray:[context executeFetchRequest:fetchRequest error:&db_err]];
	
	if(db_err) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Database Error", nil) message:db_err.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
		[alert show];
		return;
	}
	
	[_grid reloadData];
}

#pragma mark - Grid view
- (NSInteger) collectionView:(UICollectionView *) collectionView numberOfItemsInSection:(NSInteger) section {
	return _students.count + 1;
}

- (UICollectionViewCell *) collectionView:(UICollectionView *) collectionView cellForItemAtIndexPath:(NSIndexPath *) indexPath {
	SQUUserSwitcherCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"UserSwitcherCell" forIndexPath:indexPath];
	
	// "Add Student…" button
	if(indexPath.row == _students.count) {
		cell.showsSelection = NO;
		
		[cell setTitle:NSLocalizedString(@"Add Account", nil)];
		[cell setSubTitle:nil];
		[cell setImage:[UIImage imageNamed:@"switcher_add"]];
	} else {
		cell.showsSelection = YES;
		
		SQUStudent *student = _students[indexPath.row];
		
		[cell setTitle:student.name];
		[cell setSubTitle:@"student ID or district"];
		[cell setImage:[UIImage imageNamed:@"default_avatar.jpg"]];
	}
	
	return cell;
}

- (BOOL) collectionView:(UICollectionView *) collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *) indexPath {
	// Prevent selection of the "add students" button
	if(indexPath.row == _students.count) {
		return NO;
	}
	
	return YES;
}

- (void) collectionView:(UICollectionView *) collectionView didHighlightItemAtIndexPath:(NSIndexPath *) indexPath {
	NSLog(@"Selected row %u", indexPath.row);
}

@end
