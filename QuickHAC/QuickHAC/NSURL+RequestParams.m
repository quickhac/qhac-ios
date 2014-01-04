//
//  NSURL+RequestParams.m
//  QuickHAC
//
//  Created by Tristan Seifert on 1/4/14.
//  See README.MD for licensing and copyright information.
//

#import "NSURL+RequestParams.h"

@implementation NSURL (RequestParams)

+ (NSString *) urlEscape:(NSString *) unencodedString {
	NSString *s = CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,
																	  (CFStringRef)unencodedString,
																	  NULL,
																	  (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",
																	  kCFStringEncodingUTF8));
	return s; // Due to the 'create rule' we own the above and must autorelease it
}

/**
 * Convers a dictionary to paremeters, and appends them to the end of the URL.
 *
 * @param params Parameters to append.
 * @return The current URL with the query string appended.
 */
- (NSURL *) URLByAppendingQuery:(NSDictionary *) params {
	NSMutableString *urlWithQuerystring = [[NSMutableString alloc] initWithString:[self absoluteString]];
	
	// Convert the params into a query string
	if (params) {
		for(id key in params) {
			NSString *sKey = [key description];
			NSString *sVal = [[params objectForKey:key] description];
			// Do we need to add ?k=v or &k=v ?
			if ([urlWithQuerystring rangeOfString:@"?"].location == NSNotFound) {
				[urlWithQuerystring appendFormat:@"?%@=%@", [NSURL urlEscape:sKey], [NSURL urlEscape:sVal]];
			} else {
				[urlWithQuerystring appendFormat:@"&%@=%@", [NSURL urlEscape:sKey], [NSURL urlEscape:sVal]];
			}
		}
	}
	
	return [NSURL URLWithString:urlWithQuerystring];
}

@end
