//
//  SQUGradeParser.h
//  QuickHAC
//
//  Created by Tristan Seifert on 12/26/13.
//  See README.MD for licensing and copyright information.
//

#import <Foundation/Foundation.h>

@class SQUDistrict;
@interface SQUGradeParser : NSObject {
	NSDateFormatter *_gradespeedDateFormatter;
}

+ (SQUGradeParser *) sharedInstance;

- (NSArray *) parseAveragesForDistrict:(SQUDistrict *) district withString:(NSString *) string;
- (NSString *) getStudentNameForDistrict:(SQUDistrict *) district withString:(NSString *) string;
- (NSDictionary *) getClassGradesForDistrict:(SQUDistrict *) district withString:(NSString *) string;

+ (UIColor *) colourizeGrade:(float) grade;

@end
