//
//  SQUSettingsHueElement.m
//  QuickHAC
//
//  Created by Tristan Seifert on 1/19/14.
//  See README.MD for licensing and copyright information.
//

#import "SQUHueSlider.h"
#import "SQUSettingsHueElement.h"

#import "QFloatTableViewCell.h"

#pragma mark Table cell
@interface SQUSettingsHueCell : QFloatTableViewCell
@property (nonatomic, strong, readwrite) SQUHueSlider *slider;
@end

@implementation SQUSettingsHueCell

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithReuseIdentifier:@"SQUSettingsHueCell"];
    
	if (self) {
		// Remove old slider
		if(self.slider) {
			[self.slider removeFromSuperview];
		}
		
        self.slider = [[SQUHueSlider alloc] initWithFrame:CGRectZero];
        [self.contentView addSubview:self.slider];
		
    }
    
	return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
//	[self.slider redrawGradient];
}

@end

#pragma mark - QuickDialog element
@implementation SQUSettingsHueElement

- (UITableViewCell *)getCellForTableView:(QuickDialogTableView *)tableView controller:(QuickDialogController *)controller {
    SQUSettingsHueCell *cell = [[SQUSettingsHueCell alloc] initWithFrame:CGRectZero];
	
    [cell.slider addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventValueChanged];
    cell.slider.minimumValue = 0;
    cell.slider.maximumValue = 360;
    cell.slider.value = _floatValue;
    
    cell.textLabel.text = _title;
    cell.detailTextLabel.text = [_value description];
    cell.imageView.image = _image;
    cell.accessoryType = self.accessoryType != UITableViewCellAccessoryNone ? self.accessoryType : ( self.sections!= nil || self.controllerAction!=nil ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone);
    cell.selectionStyle = self.sections!= nil || self.controllerAction!=nil ? UITableViewCellSelectionStyleBlue: UITableViewCellSelectionStyleNone;
    
    return cell;
}

@end
