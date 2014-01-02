//
//  SQUGradebookDriver.m
//  QuickHAC
//
//  Created by Tristan Seifert on 1/2/14.
//  See README.MD for licensing and copyright information.
//

#import "SQUGradebookDriver.h"

@implementation SQUGradebookDriver
@synthesize identifier = _identifier;

- (NSArray *) parseAveragesForDistrict:(SQUDistrict *) district withString:(NSString *) string {
	NSLog(@"%s(%i) %s: SQUGradebookDriver method not overridden or no subclass used", __FILE__, __LINE__, __func__);
	return nil;	
}

- (NSDictionary *) getClassGradesForDistrict:(SQUDistrict *) district withString:(NSString *) string {
	NSLog(@"%s(%i) %s: SQUGradebookDriver method not overridden or no subclass used", __FILE__, __LINE__, __func__);
	return nil;
}

- (NSString *) getStudentNameForDistrict:(SQUDistrict *) district withString:(NSString *) string {
	NSLog(@"%s(%i) %s: SQUGradebookDriver method not overridden or no subclass used", __FILE__, __LINE__, __func__);
	return nil;
}

@end
