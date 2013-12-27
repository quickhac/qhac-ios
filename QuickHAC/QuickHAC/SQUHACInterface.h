//
//  SQUHACInterface.h
//  QuickHAC
//
//  Created by Tristan Seifert on 06/07/2013.
//  See README.MD for licensing and copyright information.
//

#import <Foundation/Foundation.h>
#import "JSONKit.h"

typedef void (^ SQUResponseHandler)(NSError *error, id returnData);

@interface SQUHACInterface : NSObject {
}

+ (SQUHACInterface *) sharedInstance;
+ (UIColor *) colourizeGrade:(float) grade;

- (void) performLoginWithUser:(NSString *) username andPassword:(NSString *) password andSID:(NSString *) sid callback:(SQUResponseHandler) callback;
- (void) getGradesURLWithBlob:(NSString *) blob callback:(SQUResponseHandler) callback;

- (void) parseAveragesWithURL:(NSString *) url callback:(SQUResponseHandler) callback;
- (void) parseClassGradesWithURL:(NSString *) url callback:(SQUResponseHandler) callback;

- (BOOL) isServerReturnValid:(NSString *) string;

@end
