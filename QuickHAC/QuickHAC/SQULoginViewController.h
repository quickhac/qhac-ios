//
//  SQULoginViewController.h
//  QuickHAC
//
//  Created by Tristan Seifert on 05/07/2013.
//  See README.MD for licensing and copyright information.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreText/CoreText.h>

#import "SQUHACInterface.h"

@interface SQULoginViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate> {
    UITableView *_authFieldTable;
    
    BOOL _tableMovedAlready;
    
    CALayer *_qLogo;
    CATextLayer *_qText;
    
    UITextField *_emailField;
    UITextField *_passField;
    UITextField *_sidField;
    
    UIButton *_loginButton;
    UIView *_loginButtonContainer;
    
    UIButton *_changeDistrictLink;
    CATextLayer *_districtSelected;
    
    SQUSchoolDistrict _district;
    
    UIView *_selectedTableTextField;
}

@property (nonatomic) SQUSchoolDistrict district;

@end
