//
//  TodayViewController.m
//  NotificationWidget
//
//  Created by Tristan Seifert on 6/20/14.
//  See README.MD for licensing and copyright information.
//

#import "SQUNotifWidgetController.h"
#import <NotificationCenter/NotificationCenter.h>

@interface SQUNotifWidgetController () <NCWidgetProviding>

@end

@implementation SQUNotifWidgetController

- (instancetype) initWithNibName:(NSString *) nibNameOrNil
						  bundle:(NSBundle *) nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/**
 * Called by iOS when it wants new data. This means we connect to GradeSpeed and
 * pull down new grades.
 */
- (void) widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult)) completionHandler {
    // Perform any setup necessary in order to update the view.
    
    // If an error is encoutered, use NCUpdateResultFailed
    // If there's no update required, use NCUpdateResultNoData
    // If there's an update, use NCUpdateResultNewData

    completionHandler(NCUpdateResultNewData);
}

@end
