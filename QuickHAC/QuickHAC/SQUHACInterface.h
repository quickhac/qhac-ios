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

typedef void (^ SQUResponseHandler)(NSError *error, id returnData);

@interface SQUHACInterface : NSObject {
    AFHTTPClient *_HTTPClient;
}

+ (SQUHACInterface *) sharedInstance;

- (void) performLoginWithUser:(NSString *) username andPassword:(NSString *) password andSID:(NSString *) sid callback:(SQUResponseHandler) callback;
- (void) getGradesURLWithBlob:(NSString *) blob callback:(SQUResponseHandler) callback;

@end
