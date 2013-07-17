//
//  SQUHACInterface.h
//  QuickHAC
//
//  Created by Tristan Seifert on 06/07/2013.
//  Copyright (c) 2013 Squee! Apps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFHTTPClient.h"
#import "JSONKit.h"

#define SQUNumSupportedSchools 2

typedef void (^ SQUResponseHandler)(NSError *error, id returnData);

typedef enum {
    kSQUSchoolDistrictRRISD = 0,
    kSQUSchoolDistrictAISD
} SQUSchoolDistrict;

@interface SQUHACInterface : NSObject {
    AFHTTPClient *_HTTPClient;
}

+ (SQUHACInterface *) sharedInstance;
+ (NSString *) schoolEnumToName:(SQUSchoolDistrict) district;
+ (UIColor *) colourizeGrade:(float) grade;

- (void) performLoginWithUser:(NSString *) username andPassword:(NSString *) password andSID:(NSString *) sid callback:(SQUResponseHandler) callback;
- (void) getGradesURLWithBlob:(NSString *) blob callback:(SQUResponseHandler) callback;

@end
