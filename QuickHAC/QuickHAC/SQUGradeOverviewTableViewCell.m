//
//  SQUGradeOverviewTableViewCell.m
//  QuickHAC
//
//  Created by Tristan Seifert on 16/07/2013.
//  Copyright (c) 2013 Squee! Apps. All rights reserved.
//

#import "SQUGradeOverviewTableViewCell.h"
#import "SQUHACInterface.h"

@implementation SQUGradeOverviewTableViewCell
@synthesize classTitle = _classTitle, grade = _grade, period = _period;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        CGRect rect = self.frame;
        rect.size.height = SQUGradeOverviewCellHeight;
        self.frame = rect;
        
        _gradeBadge = [CAGradientLayer layer];
        _gradeBadge.cornerRadius = 5.0f;
        _gradeBadge.frame = CGRectMake(self.frame.size.width - 80,
                                       (self.frame.size.height / 2) - 16, 70, 32);
        _gradeBadge.backgroundColor = [UIColor greenColor].CGColor;
        
        _gradeText = [CATextLayer layer];
        _gradeText.contentsScale = [UIScreen mainScreen].scale;
        _gradeText.foregroundColor = [UIColor whiteColor].CGColor;
        _gradeText.fontSize = 24.0f;
        _gradeText.font = (__bridge CFTypeRef) [UIFont boldSystemFontOfSize:24.0f];
        _gradeText.alignmentMode = kCAAlignmentCenter;
        _gradeText.frame = CGRectMake(0, 2, 70, 24);
        [_gradeBadge addSublayer:_gradeText];
        
        _courseTitle = [CATextLayer layer];
        _courseTitle.frame = CGRectMake(12, 4, self.frame.size.width - 95, 24);
        _courseTitle.contentsScale = [UIScreen mainScreen].scale;
        _courseTitle.foregroundColor = [UIColor blackColor].CGColor;
        _courseTitle.font = (__bridge CFTypeRef) [UIFont boldSystemFontOfSize:18.0f];
        _courseTitle.fontSize = 18.0f;
        
        _periodTitle = [CATextLayer layer];
        _periodTitle.frame = CGRectMake(12, 30, self.frame.size.width - 95, 24);
        _periodTitle.contentsScale = [UIScreen mainScreen].scale;
        _periodTitle.foregroundColor = [UIColor grayColor].CGColor;
        _periodTitle.font = (__bridge CFTypeRef) [UIFont systemFontOfSize:18.0f];
        _periodTitle.fontSize = 16.0f;
        
        [self.layer addSublayer:_courseTitle];
        [self.layer addSublayer:_periodTitle];
        [self.layer addSublayer:_gradeBadge];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) updateUI {
    _gradeText.string = [NSString stringWithFormat:@"%.0f", _grade];
    _periodTitle.string = [NSString stringWithFormat:NSLocalizedString(@"Period %i", nil), _period];
    
    _courseTitle.string = _classTitle;
    
    UIColor *gradeColor = [SQUHACInterface colourizeGrade:_grade];
    _gradeBadge.backgroundColor = gradeColor.CGColor;
    
    // "in my experience white on white is hard to read"
    if(_grade > 80) {
        _gradeText.foregroundColor = [UIColor darkGrayColor].CGColor;
    } else {
        _gradeText.foregroundColor = [UIColor whiteColor].CGColor;
    }
}

@end
