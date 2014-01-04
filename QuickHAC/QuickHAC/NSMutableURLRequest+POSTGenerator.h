//
//  NSMutableURLRequest+POSTGenerator.h
//  QuickHAC
//
//  Created by Tristan Seifert on 1/4/14.
//  See README.MD for licensing and copyright information.
//

#import <Foundation/Foundation.h>

@interface NSMutableURLRequest (POSTGenerator)

+ (NSString *) encodeFormPostParameters: (NSDictionary *) parameters;
- (void) setFormPostParameters: (NSDictionary *) parameters;

@end
