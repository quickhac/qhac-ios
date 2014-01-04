//
//  NSURL+RequestParams.h
//  QuickHAC
//
//  Created by Tristan Seifert on 1/4/14.
//  See README.MD for licensing and copyright information.
//

#import <Foundation/Foundation.h>

@interface NSURL (RequestParams)

+ (NSString *) urlEscape:(NSString *) unencodedString;
- (NSURL *) URLByAppendingQuery:(NSDictionary *) params;

@end
