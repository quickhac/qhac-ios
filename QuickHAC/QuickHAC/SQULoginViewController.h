//
//  SQULoginViewController.h
//  QuickHAC
//
//  Created by Tristan Seifert on 05/07/2013.
//  See README.MD for licensing and copyright information.
//

#import "SQULoginStudentPicker.h"

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreText/CoreText.h>

@class SQUDistrict;

@interface SQULoginViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, SQULoginStudentPickerDelegate> {
    UITableView *_authFieldTable;
    
    BOOL _tableMovedAlready;
    
    CALayer *_qLogo;
    CATextLayer *_qText;
    
    UITextField *_usernameField;
    UITextField *_passField;
    
    UIButton *_loginButton;
    UIView *_loginButtonContainer;
    
    UIButton *_changeDistrictLink;
    CATextLayer *_districtSelected;
    
    SQUDistrict *_district;
    
    UIView *_selectedTableTextField;
	
	NSMutableArray *_students;
	void (^_studentLoginFunction)(void);
}

@property (nonatomic) SQUDistrict *district;
@property (nonatomic, readwrite) NSMutableArray *students;

@end
