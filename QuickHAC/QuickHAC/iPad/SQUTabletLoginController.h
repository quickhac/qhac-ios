//
//  SQUTabletLoginController.h
//  QuickHAC
//
//  Created by Tristan Seifert on 1/1/14.
//  See README.MD for licensing and copyright information.
//

#import "SQULoginStudentPicker.h"
#import <UIKit/UIKit.h>

@class SQUDistrict;

@interface SQUTabletLoginController : UIViewController <UITextFieldDelegate, UIPickerViewDataSource, UIPickerViewDelegate, SQULoginStudentPickerDelegate> {
	UITextField *_userField;
	UITextField *_passField;
	
	UIView *_loginContainerBox;
	
	CATextLayer *_currentDistrictLabel;
	NSUInteger _selectedDistrict;
	SQUDistrict *_district;
	BOOL _shouldDoSlide;
	BOOL _isSlidUp;
	UIPopoverController *_changeDistrictPopover;
	
	NSMutableArray *_students;
	void (^_studentLoginFunction)(void);
}

@property (nonatomic, readwrite) NSMutableArray *students;

@end
