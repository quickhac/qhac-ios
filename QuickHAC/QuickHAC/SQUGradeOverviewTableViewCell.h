//
//  SQUGradeOverviewTableViewCell.h
//  QuickHAC
//
//  Created by Tristan Seifert on 16/07/2013.
//  See README.MD for licensing and copyright information.
//

#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>

#define SQUGradeOverviewCellHeight 54

@interface SQUGradeOverviewTableViewCell : UITableViewCell {
    // public properties
    NSString *_classTitle;
    NSUInteger _period;
    float _grade;
    
    // private properties
    CAGradientLayer *_gradeBadge;
    CATextLayer *_gradeText;
    
    CATextLayer *_courseTitle;
    CATextLayer *_periodTitle;
}

@property (nonatomic) NSString *classTitle;
@property (nonatomic) NSUInteger period;
@property (nonatomic) float grade;

- (void) updateUI;

@end
