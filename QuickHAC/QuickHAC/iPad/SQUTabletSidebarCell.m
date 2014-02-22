//
//  SQUTabletSidebarCell.m
//  QuickHAC
//
//  Created by Tristan Seifert on 1/1/14.
//  See README.MD for licensing and copyright information.
//

#import "SQUColourScheme.h"
#import "SQUTabletSidebarCell.h"

@implementation SQUTabletSidebarCell

@synthesize icon = _icon, iconSelected = _iconSelected;

- (id) initWithStyle:(UITableViewCellStyle) style reuseIdentifier:(NSString *) reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _gradeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 48, 36)];
		_gradeLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:17.0];
		_gradeLabel.textAlignment = NSTextAlignmentRight;
    }
    return self;
}

- (void) setSelected:(BOOL) selected animated:(BOOL) animated {
    [super setSelected:selected animated:animated];
	
    if(selected) {
		self.backgroundColor = UIColorFromRGB(kSQUColourClouds);
		self.textLabel.textColor = UIColorFromRGB(kSQUColourPetermannRiver);
		_gradeLabel.textColor = UIColorFromRGB(kSQUColourPetermannRiver);
		
		self.imageView.image = _iconSelected;
	} else {
		self.backgroundColor = UIColorFromRGB(kSQUColourWetAsphalt);
		self.textLabel.textColor = UIColorFromRGB(kSQUColourClouds);
		_gradeLabel.textColor = UIColorFromRGB(kSQUColourClouds);
		
		self.imageView.image = _icon;
	}
}

/**
 * Updates the grade displayed in a badge on the right side of the cell.
 *
 * @param grade A floating-point number to show. Set to -1 to hide grades.
 */
- (void) setGrade:(float) grade {
	if(grade == -1) {
		[self setAccessoryView:nil];
	} else {
		_gradeLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%.0f", @"grade average badge ipad"), grade];
		[self setAccessoryView:_gradeLabel];
	}
}


@end
