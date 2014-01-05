//
//  NSData+SQUAdditions.m
//  QuickHAC
//
//  Created by Tristan Seifert on 1/4/14.
//  See README.MD for licensing and copyright information.
//

#import "NSData+SQUAdditions.h"

@implementation NSData (SQUAdditions)

/**
 * Converts the data bytes to a hexadeciml string.
 * @return A string with each byte represented as two characters.
 */
- (NSString *) toHexString {
	const unsigned char *dataBuffer = (const unsigned char *) self.bytes;
	
	// If this data object is empty, return an empty string
    if (!dataBuffer) {
        return [NSString string];
	}
	
	NSUInteger dataLength  = self.length;
    NSMutableString *hexString = [NSMutableString stringWithCapacity:(dataLength * 2)];
	
	// Convert each byte to a hex representation
    for (NSUInteger i = 0; i < dataLength; i++) {
        [hexString appendFormat:@"%02hhx", dataBuffer[i]];
	}
	
    return [NSString stringWithString:hexString];
}

@end
