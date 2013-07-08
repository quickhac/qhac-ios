//
//  SQUHACInterface.m
//  QuickHAC
//
//  Handles interfacing with the qHAC servers and generation of URLs, as well
//  as storage of user metadata.
//
//  Just a friendly FYI, Home Access is the shittiest pile of "software" on the
//  face of the damn Earth.
//
//  Created by Tristan Seifert on 06/07/2013.
//  Copyright (c) 2013 Squee! Apps. All rights reserved.
//

#import "SQUHACInterface.h"

#import <objc/runtime.h>
#import <objc/message.h>

#define SQUHACAPIRoot @"https://hacaccess.herokuapp.com/api/"
#define SQURRISDHACRoot @"https://gradebook.roundrockisd.org/pc/displaygrades.aspx"

@interface SQUHACInterface (PrivateMethods)

- (NSString *) rot13:(NSString *) theText;
- (NSString *) base64Encode:(NSString *) data;

- (NSString *) rot13AndBase64AreNotEncryptionDammit:(NSString *) godDamnWhenWillTheyLearn;
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
    MethodSwizzle([self class], @selector(encrypt:), @selector(rot13AndBase64AreNotEncryptionDammit:));
    MethodSwizzle([self class], @selector(decrypt:), @selector(doTheInverseOfWhateverTheHellThatDoes:));
}

#pragma mark - HAC "encryption" crap
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

// String.prototype.encrypt = function() {
//  return this.b64enc().rot13();
// };

- (NSString *) rot13AndBase64AreNotEncryptionDammit:(NSString *) godDamnWhenWillTheyLearn {
    NSString *notReallyEncryptedString = [self rot13:[self base64Encode:godDamnWhenWillTheyLearn]];
    
    NSLog(@"Raw: %@\nEnc: %@", godDamnWhenWillTheyLearn, notReallyEncryptedString);
    
    return notReallyEncryptedString;
}

//String.prototype.rot13 = function(){
//	return this.replace(/[a-zA-Z]/g, function(c){
//		return String.fromCharCode((c <= "Z" ? 90 : 122) >= (c = c.charCodeAt(0) + 13) ? c : c - 26);
//	});
//};

- (NSString *) rot13:(NSString *)theText {
    NSData *data = [theText dataUsingEncoding:NSASCIIStringEncoding];
    NSMutableData *resultantData = [[NSMutableData alloc] initWithCapacity:data.length];
    
    unsigned char *byteArray = (unsigned char *) [data bytes];
    unsigned char *newData = (unsigned char *) [resultantData bytes];
    
    for (NSUInteger i = 0; i < data.length; i++) {
        unsigned char character = byteArray[i];
        
        unsigned char newChar = (character <= 'Z' ? 90 : 122) >= (character + 13) ? character : character - 26;
        newData[i] = newChar;
    }
    
    return [NSString stringWithUTF8String:(const char *) [resultantData bytes]];
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
    
    NSLog(@" Blob: %@\nRot13: %@", blob, [self rot13:blob]);
    
    [requestParams setValue:[self rot13:blob] forKey:@"sessionid"];
    
    [_HTTPClient postPath:@"gradesURL" parameters:requestParams success:^(AFHTTPRequestOperation *operation, id responseObject) {
        callback(nil, responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        callback(error, nil);
    }];
    
}

@end
