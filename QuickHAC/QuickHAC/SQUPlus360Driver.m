//
//  SQUPlus360Driver.m
//  QuickHAC
//
//  Created by Tristan Seifert on 1/6/15.
//  Copyright (c) 2015 Squee! Apps. All rights reserved.
//

#import "SQUDistrict.h"
#import "SQUGradeManager.h"
#import "SQUPlus360Driver.h"

#import "TFHpple.h"
#import "TFHppleElement.h"

#pragma mark HTML parser additions
// Category on TFHppleElement for table
@interface TFHppleElement (TableSupport)
- (NSString *) getColumnContentsWithClass:(NSString *) class;
@end

@implementation TFHppleElement (TableSupport)
- (NSString *) getColumnContentsWithClass:(NSString *) class{
	NSArray *children = [self childrenWithClassName:class];
	if(children.count == 0) return @"";
	
	return [children[0] text];
}
@end

#pragma mark - Driver init
@implementation SQUPlus360Driver
+ (void) load {
	[[SQUGradeManager sharedInstance] registerDriver:NSClassFromString(@"SQUPlus360Driver")];
}

- (id) init {
	self = [super init];
	
	if(self) {
		_identifier = @"plus360";
	}
	
	return self;
}

@end
