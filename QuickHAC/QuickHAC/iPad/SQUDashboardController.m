//
//  SQUDashboardController.m
//  QuickHAC
//
//  Created by Tristan Seifert on 2/22/14.
//  See README.MD for licensing and copyright information.
//

#import "SQUColourScheme.h"
#import "SQUGradeManager.h"

#import "SQUDashboardCell.h"
#import "SQUDashboardController.h"

@interface SQUDashboardController ()

@end

@implementation SQUDashboardController

- (instancetype) init {
    self = [super initWithCollectionViewLayout:[[UICollectionViewFlowLayout alloc] init]];
   
	if (self) {
		self.title = NSLocalizedString(@"Dashboard", nil);
		
		self.collectionView.backgroundColor = UIColorFromRGB(kSQUColourTableBackground);
        [self.collectionView registerClass:[SQUDashboardCell class] forCellWithReuseIdentifier:@"DashCell"];
    }
	
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Collection View Data Source
- (NSInteger) collectionView:(UICollectionView *) view numberOfItemsInSection:(NSInteger) section {
    return [[SQUGradeManager sharedInstance] getCoursesForCurrentStudent].count;
}

- (NSInteger) numberOfSectionsInCollectionView:(UICollectionView *) collectionView {
    return 1;
}

- (UICollectionViewCell *) collectionView:(UICollectionView *) cv cellForItemAtIndexPath:(NSIndexPath *) indexPath {
	SQUDashboardCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"DashCell" forIndexPath:indexPath];
	cell.course = [[SQUGradeManager sharedInstance] getCoursesForCurrentStudent][indexPath.row];
	cell.clipsToBounds = NO;
	
    return cell;
}

#pragma mark - Collection View Delegate
- (void) collectionView:(UICollectionView *) collectionView didSelectItemAtIndexPath:(NSIndexPath *) indexPath {

}

- (void) collectionView:(UICollectionView *) collectionView didDeselectItemAtIndexPath:(NSIndexPath *) indexPath {

}

#pragma mark - Collection View Flow Layout Delegate
- (CGSize) collectionView:(UICollectionView *) collectionView layout:(UICollectionViewLayout*) collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *) indexPath {
	CGFloat width = collectionView.frame.size.width - 40 - 16;
	return CGSizeMake(width / 2, 184);
}

- (UIEdgeInsets) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*) collectionViewLayout insetForSectionAtIndex:(NSInteger) section {
	return UIEdgeInsetsMake(16, 20, 32, 20);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
	return 16;
}

@end
