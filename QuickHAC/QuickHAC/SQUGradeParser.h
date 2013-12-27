//
//  SQUGradeParser.h
//  QuickHAC
//
//  Created by Tristan Seifert on 12/26/13.
//  Copyright (c) 2013 Squee! Apps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

typedef struct {
	NSUInteger semesters;
	NSUInteger cyclesPerSemester;
} semester_params_t;

@interface SQUGradeParser : NSObject {
	JSVirtualMachine *_jsVirtualMachine;
	JSContext *_jsContext;
}

+ (SQUGradeParser *) sharedInstance;

- (NSArray *) parseAveragesForDistrict:(void *) district withString:(NSString *) string;
- (NSString *) getStudentNameForDistrict:(void *) district withString:(NSString *) string;
- (NSDictionary *) getClassGradesForDistrict:(void *) district withString:(NSString *) string;
@end
