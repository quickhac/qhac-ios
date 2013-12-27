//
//  SQUHACInterface.m
//  QuickHAC
//
//  Handles interfacing with the qHAC servers and generation of URLs, as well
//  as storage of user metadata.
//
//  Created by Tristan Seifert on 06/07/2013.
//  See README.MD for licensing and copyright information.
//

#import "SQUHACInterface.h"
#import "SQUGradeParser.h"

#import <objc/runtime.h>
#import <objc/message.h>

#define SQUHACAPIRoot @"https://hacaccess.herokuapp.com/api/"
#define SQURRISDHACRoot @"https://gradebook.roundrockisd.org/pc/displaygrades.aspx?"

@interface SQUHACInterface (PrivateMethods)

- (NSString *) rot13:(NSString *) theText;
- (NSString *) base64Encode:(NSString *) data;

- (NSString *) weirdEncryption:(NSString *) input;
- (NSString *) doTheInverseOfWhateverTheHellThatDoes:(NSString *) string;

@end

@interface SQUHACInterface (Base64AndRot16AreNotEncryption)

- (NSString *) encrypt:(NSString *) stuff;
- (NSString *) decrypt:(NSString *) stuff;

@end

// Holds singleton instance of this class that all calls will be made using
static SQUHACInterface *_sharedInstance = nil;

@implementation SQUHACInterface
#pragma mark - Singleton

+ (SQUHACInterface *) sharedInstance {
    @synchronized (self) {
        if (_sharedInstance == nil) {
            _sharedInstance = [[self alloc] init];
        }
    }
    
    return _sharedInstance;
}

+ (id) allocWithZone:(NSZone *) zone {
    @synchronized(self) {
        if (_sharedInstance == nil) {
            _sharedInstance = [super allocWithZone:zone];
            return _sharedInstance;
        }
    }
    
    return nil;
}

- (id) copyWithZone:(NSZone *) zone {
    return self;
}

- (id) init {
    @synchronized(self) {
        if(self = [super init]) {
            _HTTPClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:SQUHACAPIRoot]];
        }

        
        return self;
    }
}

+ (void) load {
    MethodSwizzle([self class], @selector(encrypt:), @selector(weirdEncryption:));
    MethodSwizzle([self class], @selector(decrypt:), @selector(doTheInverseOfWhateverTheHellThatDoes:));
}

#pragma mark - HAC "encryption"
- (NSString *) base64Encode:(NSString *) data {
    char *base64Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    const char *input = [data cStringUsingEncoding:NSUTF8StringEncoding];
    unsigned long inputLength = [data length];
    unsigned long modulo = inputLength % 3;
    unsigned long outputLength = (inputLength / 3) * 4 + (modulo ? 4 : 0);
    unsigned long j = 0;
    
    unsigned char *output = malloc(outputLength + 1);
    output[outputLength] = 0;
    
    // Here are no checks inside the loop, so it works much faster than other implementations
    for (unsigned long i = 0; i < inputLength; i += 3) {
        output[j++] = base64Chars[ (input[i] & 0xFC) >> 2 ];
        output[j++] = base64Chars[ ((input[i] & 0x03) << 4) | ((input[i + 1] & 0xF0) >> 4) ];
        output[j++] = base64Chars[ ((input[i + 1] & 0x0F)) << 2 | ((input[i + 2] & 0xC0) >> 6) ];
        output[j++] = base64Chars[ (input[i + 2] & 0x3F) ];
    }
    // Padding in the end of encoded string directly depends of modulo
    if (modulo > 0) {
        output[outputLength - 1] = '=';
        if (modulo == 1)
            output[outputLength - 2] = '=';
    }
    NSString *s = [NSString stringWithUTF8String:(const char *)output];
    free(output);
    return s;
}   
- (NSString *) weirdEncryption:(NSString *) input {
    return [self rot13:[self base64Encode:input]];
}

// This is an objc wrapper around do_rot13(char)
- (NSString *) rot13:(NSString *)theText {
    char* outData = do_rot13((char *) [theText cStringUsingEncoding:NSASCIIStringEncoding]);
    
    return [NSString stringWithUTF8String:(const char *) outData];
}

/*
 * ACHTUNG BABY: This code relies on the input chars being plain 8-bit ASCII, and
 * will output in the same format. Just an FYI in case your cat dies from
 * using this code on non-ASCII text or something.
 *
 * It *may* be possible to modify it for other character encodings by altering
 * the table, but that was not required in the original design.
 */

// This maps a regular ASCII character to a rot13'd char
// The table covers ASCII chars 0x30 to 0x7A
static unsigned char rot13map[0x80] = "0123456789:;<=>?@NOPQRSTUVWZYZABCDEFGHIJKLM[\\]^_`nopqrstuvwxyzabcdefghijklm";
static unsigned int rot13map_ASCIIOffset = 0x30;

char* do_rot13(char *inBuffer) {
	char *tempInPtr = inBuffer;
	
	int bytesRequired = 0;
	// Calculate how many bytes to allocate for output buffer.
	while(1) {
		bytesRequired++; // Increase byte counter
        
		if(*tempInPtr == 0x00) { // Check if char is 0x00 (0-terminated)
			break;
		}
		
		tempInPtr++; // Advance read pointer
	}
    
	// Allocate output memory (plus a small extra amount)
	char *outBuffer = malloc(sizeof(char) * bytesRequired + 8);
	char *tempOutPtr = outBuffer;
	tempInPtr = inBuffer; // Reset input read pointer
	
	// Loop through all chars
	while(1) {
		if(*tempInPtr >= rot13map_ASCIIOffset && *tempInPtr <= 0x7A) { // Is char in bounds?
			// Fetch the appropriate char from the array
			*tempOutPtr = rot13map[(*tempInPtr) - rot13map_ASCIIOffset];
		} else if(*tempInPtr == 0x00) { // Is char 0x00?
			*tempOutPtr = 0x00;
			break;
		} else { // Other chars that we can't translate nor are 0x00
			// If the char is out of bounds, just copy it as-is
			*tempOutPtr = *tempInPtr;
		}
		
		// Increase pointers
		tempOutPtr++;
		tempInPtr++;
	}
	
	return outBuffer;
}

#pragma mark - API calls
#pragma mark Login and user management
- (void) performLoginWithUser:(NSString *) username andPassword:(NSString *) password andSID:(NSString *) sid callback:(SQUResponseHandler) callback {
    NSMutableDictionary *requestParams = [[NSMutableDictionary alloc] initWithCapacity:4];
    
    [requestParams setValue:[self encrypt:username] forKey:@"login"];
    [requestParams setValue:[self encrypt:password] forKey:@"password"];
    [requestParams setValue:sid forKey:@"studentid"];
    
    [_HTTPClient postPath:@"login" parameters:requestParams success:^(AFHTTPRequestOperation *operation, id responseObject) {        
        callback(nil, responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {            
        callback(error, nil);
    }];
}

- (void) getGradesURLWithBlob:(NSString *) blob callback:(SQUResponseHandler) callback {
    NSMutableDictionary *requestParams = [[NSMutableDictionary alloc] initWithCapacity:2];
    
    blob = [blob substringWithRange:NSMakeRange(0, 24)]; // Ensure blob is 24 chars max
    
    [requestParams setValue:[self rot13:blob] forKey:@"sessionid"];
    
    [_HTTPClient postPath:@"gradesURL" parameters:requestParams success:^(AFHTTPRequestOperation *operation, id responseObject) {
		NSString *returnString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
		
		if([self isServerReturnValid:returnString]) {
			NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"<a\\shref.*(h.*)\">" options:NSRegularExpressionCaseInsensitive error:nil];
			NSRange URLLocInString = [[regex firstMatchInString:returnString options:0 range:NSMakeRange(0, [returnString length])] rangeAtIndex:1];
			
			// Check if we got a good URL
			if (!NSEqualRanges(URLLocInString, NSMakeRange(NSNotFound, 0))) {
				// we get the entire link, so we need to grab just the text between the first quotes.
				NSString *gradesURL = [NSString stringWithFormat:@"%@%@%@", SQURRISDHACRoot, @"studentid=", [returnString substringWithRange:URLLocInString]];
				callback(nil, gradesURL);
			} else {
				callback(nil, nil);
			}
		} else {
			callback(nil, nil);
		}
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        callback(error, nil);
    }];
}

/*
 * Loads the document at url and interprets it as the overall grades, extracting
 * the class averages from it.
 */
- (void) parseAveragesWithURL:(NSString *) url callback:(SQUResponseHandler) callback {
	[_HTTPClient getPath:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
		NSString *returnString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
		
		[[SQUGradeParser sharedInstance] parseAveragesForDistrict:nil withString:returnString];
	} failure:^(AFHTTPRequestOperation *operation, NSError* failure) {
				 
	}];
}

/*
 * Loads the document at url and parses it as a class' grades, extracting the
 * individual assignments from it.
 */
- (void) parseClassGradesWithURL:(NSString *) url callback:(SQUResponseHandler) callback {
	
}

#pragma mark - Helper methods
- (BOOL) isServerReturnValid:(NSString *) string {
	NSError *regexError = nil;
	NSRegularExpression *regex = [NSRegularExpression
								  regularExpressionWithPattern:@"/id=([\\w\\d%]*)/"
								  options:NSRegularExpressionCaseInsensitive
								  error:&regexError];
	
	return ([regex numberOfMatchesInString:string options:0 range:NSMakeRange(0, string.length)] == 0);
}

#pragma mark - User-interface support
static NSArray *enumToSchoolArray = nil;

+ (NSString *) schoolEnumToName:(SQUSchoolDistrict) district {
    if(!enumToSchoolArray) {
        enumToSchoolArray = [[NSArray alloc] initWithObjects:@"Round Rock ISD", @"Austin ISD", nil];   
    }

    return enumToSchoolArray[district];
}

// warning: contains magical numbers and some kind of black magic
+ (UIColor *) colourizeGrade:(float) grade {    
    // Makes sure asianness cannot be negative
    NSUInteger asianness_limited = MAX(2, 0);
    
    // interpolate a hue gradient and convert to rgb
    float h, s, v;
    
    // determine color. ***MAGIC DO NOT TOUCH UNDER ANY CIRCUMSTANCES***
    if (grade > 100) {
        h = 0.13055;
        s = 0;
        v = 1;
    } else if (grade < 0) {
        h = 0;
        s = 1;
        v = 0.86945;
    } else {
        h = MIN(0.25 * pow(grade / 100, asianness_limited), 0.13056);
        s = 1 - pow(grade / 100, asianness_limited * 2);
        v = 0.86945 + h;
    }
    
    // apply hue transformation
//    h += hue;
//    h %= 1;
//    if (h < 0) h += 1;
    
    return [UIColor colorWithHue:h saturation:s brightness:v alpha:1.0];
}

@end
