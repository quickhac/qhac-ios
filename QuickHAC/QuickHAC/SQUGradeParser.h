//
//  SQUGradeParser.h
//  QuickHAC
//
//  Created by Tristan Seifert on 12/26/13.
//  Copyright (c) 2013 Squee! Apps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

@class SQUDistrict;
@interface SQUGradeParser : NSObject {
	JSVirtualMachine *_jsVirtualMachine;
	JSContext *_jsContext;
}

+ (SQUGradeParser *) sharedInstance;

- (NSArray *) parseAveragesForDistrict:(SQUDistrict *) district withString:(NSString *) string;
- (NSString *) getStudentNameForDistrict:(SQUDistrict *) district withString:(NSString *) string;
- (NSDictionary *) getClassGradesForDistrict:(SQUDistrict *) district withString:(NSString *) string;

+ (UIColor *) colourizeGrade:(float) grade;

@end
