//
//  NSMutableURLRequest+POSTGenerator.m
//  QuickHAC
//
//  Created by Tristan Seifert on 1/4/14.
//  See README.MD for licensing and copyright information.
//

#import "NSMutableURLRequest+POSTGenerator.h"

@implementation NSMutableURLRequest (POSTGenerator)

/**
 * Takes the supplied dictionary, and encodes it as a POST body.
 *
 * @param parameters The dictionary to encode.
 * @return Encoded string.
 */
+ (NSString *) encodeFormPostParameters: (NSDictionary *) parameters {
	NSMutableString *formPostParams = [[NSMutableString alloc] init];
	
	NSEnumerator *keys = [parameters keyEnumerator];
	
	NSString *name = [keys nextObject];
	while (nil != name) {
		NSString *encodedValue = CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef) [parameters objectForKey: name], NULL, CFSTR("!*'\"();:@&=+$,/?%#[]%"), kCFStringEncodingUTF8));
		
		[formPostParams appendString: name];
		[formPostParams appendString: @"="];
		[formPostParams appendString: encodedValue];
		
		name = [keys nextObject];
		
		if (nil != name) {
			[formPostParams appendString: @"&"];
		}
	}
	
	return formPostParams;
}

- (void) setFormPostParameters: (NSDictionary *) parameters {
	NSString *formPostParams = [NSMutableURLRequest encodeFormPostParameters: parameters];
	
	[self setHTTPBody:[formPostParams dataUsingEncoding: NSUTF8StringEncoding]];
	[self setValue: @"application/x-www-form-urlencoded; charset=utf-8" forHTTPHeaderField: @"Content-Type"];
}

@end
