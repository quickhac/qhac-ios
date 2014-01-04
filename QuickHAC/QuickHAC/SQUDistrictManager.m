//
//  SQUDistrictManager.m
//  QuickHAC
//
//	Management of districts loaded into the app and interfacing with them.
//
//  Created by Tristan Seifert on 12/27/13.
//  See README.MD for licensing and copyright information.
//

#import "SQUDistrict.h"
#import "SQUGradeManager.h"
#import "SQUCoreData.h"
#import "NSURL+RequestParams.h"
#import "NSMutableURLRequest+POSTGenerator.h"
#import "SQUDistrictManager.h"

#import "AFNetworking.h"

static SQUDistrictManager *_sharedInstance = nil;

@implementation SQUDistrictManager
@synthesize currentDistrict = _currentDistrict;

#pragma mark - Singleton

+ (SQUDistrictManager *) sharedInstance {
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
			_loadedDistricts = [NSMutableArray new];
			_initialisedDistricts = [NSMutableArray new];
        }
		
        
        return self;
    }
}

#pragma mark - District management
/**
 * Registers the specified district with the manager.
 *
 * @param district: Class to register.
 */
- (void) registerDistrict:(Class) district {
	if([district conformsToProtocol:@protocol(SQUDistrictProtocol)]) {
		[_loadedDistricts addObject:district];
		NSUInteger index = [_loadedDistricts indexOfObject:district];
		
		SQUDistrict *districtInitialised = [[district alloc] init];
		[districtInitialised districtWasSelected:districtInitialised];
		[_initialisedDistricts insertObject:districtInitialised atIndex:index];
		
		NSLog(@"Loaded district %@ (%@, using driver %@)",  district, districtInitialised.name, districtInitialised.driver);
	} else {
		NSLog(@"Tried to load %@, but %@ does not conform to SQUDistrictProtocol.", district, NSStringFromClass(district));
	}
}

/**
 * Returns an array of SQUDistrict subclasses that have been registered.
 *
 * @return All districts currently registered.
 */
- (NSArray *) loadedDistricts {
	return [NSArray arrayWithArray:_initialisedDistricts];
}

/**
 * Searches through all loaded districts for one that matches the ID, then sets
 * it as the active district.
 *
 * @param districtID: Numerical identifier of the district.
 * @return YES on success, NO if not found.
 */
- (BOOL) selectDistrictWithID:(NSInteger) districtID {
	for(SQUDistrict *district in _initialisedDistricts) {
		if(district.district_id == districtID) {
			// we found the district, activate it
			_currentDistrict = district;
			return YES;
		}
	}
	
	return NO;
}

/**
 * Returns a district for a specific ID.
 *
 * @param districtID: Numerical identifier of the district.
 * @return A SQUDistrict object matching the identifier, or nil if not found.
 */
- (SQUDistrict *) districtWithID:(NSInteger) districtID {
	for(SQUDistrict *district in _initialisedDistricts) {
		if(district.district_id == districtID) {
			return district;
		}
	}
	
	return nil;
}

#pragma mark - Request helper methods
/**
 * This does nothing more than shoving data in a temporary file since iOS is a
 * cockmunch with background upload requests.
 */
- (NSURL *) createRequestTempFileForIOSToBeHappy:(NSData *) data {
	// Create a temporary file name
	NSString *tempFileTemplate =  [NSTemporaryDirectory() stringByAppendingPathComponent:@"qhac_request.XXXXXX"];
	const char *tempFileTemplateCString = [tempFileTemplate fileSystemRepresentation];
	char *tempFileNameCString = (char *) malloc(strlen(tempFileTemplateCString) + 1);
	strcpy(tempFileNameCString, tempFileTemplateCString);
	
	// Open file descriptor and add random
	int fileDescriptor = mkstemp(tempFileNameCString);

	// Handle error
	if (fileDescriptor == -1) {
		return nil;
	}

	NSString *tempFilePath =[[NSFileManager defaultManager] stringWithFileSystemRepresentation:tempFileNameCString length:strlen(tempFileNameCString)];
	
	// Clean up
	free(tempFileNameCString);
	close(fileDescriptor);
	
	// Write to the file
	[data writeToFile:tempFilePath atomically:YES];
	
	return [NSURL fileURLWithPath:tempFilePath];
}

/**
 * Creates a GET request with the specified URL, parameters, and success and
 * failure callback blocks.
 */
- (void) sendGETRequestToURL:(NSURL *) url withParameters:(NSDictionary *) params andSuccessBlock:(void (^)(NSURLResponse *operation, id responseObject)) success andFailureBlock:(void (^)(NSURLResponse *operation, NSError *error)) failure {
	BOOL isInbackground = ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground);
	NSError *error = nil;
	
	// Create the session manager
	AFHTTPSessionManager *manager;
	if(isInbackground) {
		manager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration backgroundSessionConfiguration:@"co.squee.quickhac.background_request"]];
	} else {
		manager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
	}
	
	manager.responseSerializer = [AFHTTPResponseSerializer serializer];
	
	// Load the district's SSL certs, if it has one.
	NSArray *certs = [_currentDistrict districtSSLCertData];
	
	if(certs.count == 1 && [certs[0] integerValue] == 0) {
		manager.securityPolicy.allowInvalidCertificates = YES;
	} else if(certs.count != 0) {
		manager.securityPolicy.SSLPinningMode = AFSSLPinningModeCertificate;
		[manager.securityPolicy setPinnedCertificates:certs];
	}
	
	// Prepare the request.
	NSURL *paramURL = [url URLByAppendingQuery:params];
    NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] requestWithMethod:@"GET" URLString:[paramURL absoluteString] parameters:nil error:&error];
	
	if(error) {
		NSLog(@"GET create error: %@", error);
		return;
	}
	
	// Shove data into a temp file
	NSURL *tempFile = [self createRequestTempFileForIOSToBeHappy:[NSData new]];
	
	// Send off a request.
	NSURLSessionUploadTask *task = [manager uploadTaskWithRequest:request fromFile:tempFile progress:nil completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
		NSLog(@"GET complete");
		
		if(error) {
			failure(response, error);
		} else {
			success(response, responseObject);
		}
		
		[[NSFileManager defaultManager] removeItemAtURL:tempFile error:nil];
	}];
	
	[task resume];
}

/**
 * Creates a POST request with the specified URL, parameters, and success and
 * failure callback blocks.
 */
- (void) sendPOSTRequestToURL:(NSURL *) url withParameters:(NSDictionary *) params andSuccessBlock:(void (^)(NSURLResponse *operation, id responseObject)) success andFailureBlock:(void (^)(NSURLResponse *operation, NSError *error)) failure {
	BOOL isInbackground = ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground);
	NSError *error = nil;
	
	// Create the session manager
	AFHTTPSessionManager *manager;
	if(isInbackground) {
		manager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration backgroundSessionConfiguration:@"co.squee.quickhac.background_request"]];
	} else {
		manager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
	}
	
	manager.responseSerializer = [AFHTTPResponseSerializer serializer];
	
	// Load the district's SSL certs, if it has one.
	NSArray *certs = [_currentDistrict districtSSLCertData];
	
	if(certs.count == 1 && [certs[0] integerValue] == 0) {
		manager.securityPolicy.allowInvalidCertificates = YES;
	} else if(certs.count != 0) {
		manager.securityPolicy.SSLPinningMode = AFSSLPinningModeCertificate;
		[manager.securityPolicy setPinnedCertificates:certs];
	}
	
	// Prepare the request.
    NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] requestWithMethod:@"POST" URLString:[url absoluteString] parameters:params error:nil];
	
	if(error) {
		NSLog(@"POST create error: %@", error);
		return;
	}
	
	// Shove data into a temp file
	NSURL *tempFile = [self createRequestTempFileForIOSToBeHappy:[[NSMutableURLRequest encodeFormPostParameters:params] dataUsingEncoding:NSUTF8StringEncoding]];
	
	// Send off a request.
	NSURLSessionUploadTask *task = [manager uploadTaskWithRequest:request fromFile:tempFile progress:nil completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
		if(error) {
			failure(response, error);
		} else {
			success(response, responseObject);
		}
		
		[[NSFileManager defaultManager] removeItemAtURL:tempFile error:nil];
	}];
	[task resume];
}

#pragma mark - District interfacing
/**
 * Sends the actual login request.
 */
- (void) performActualLoginRequestWithUser:(NSString *) username usingPassword:(NSString *) password andCallback:(SQUDistrictCallback) callback {
	NSDictionary *loginRequest = [_currentDistrict buildLoginRequestWithUser:username usingPassword:password andUserData:nil];
	NSLog(@"Actual login");
	NSURL *url = loginRequest[@"request"][@"URL"];
	
	// Called on success of the operation (200 OK)
	void (^loginSuccess)(NSURLResponse*operation, id responseObject) = ^(NSURLResponse*operation, id responseObject) {		
		[_currentDistrict updateDistrictStateWithPostLoginData:responseObject];
		
		// The server accepted our request, now check if the request succeeded
		if([_currentDistrict didLoginSucceedWithLoginData:responseObject]) {
			NSMutableDictionary *response = [NSMutableDictionary new];
			response[@"username"] = username;
			response[@"password"] = password;
			response[@"serverResponse"] = responseObject;
			
			callback(nil, response);
		} else {
			callback(nil, nil);
		}
	};
	
	// Called if the request fails for some reason (500, network error, etc)
	void (^loginFailure)(NSURLResponse*operation, NSError *error) = ^(NSURLResponse*operation, NSError *error) {
		callback(error, nil);
	};
	
	/*
	 * If any gradebook software out there does a login using GET, they're a
	 * bunch of fuckwits and should die in a fire.
	 */
	if([loginRequest[@"request"][@"method"] isEqualToString:@"POST"]) {
		[self sendPOSTRequestToURL:url withParameters:loginRequest[@"params"] andSuccessBlock:loginSuccess andFailureBlock:loginFailure];
	} else {
		NSLog(@"Unsupported login method: %@", loginRequest[@"request"][@"method"]);
		return;
	}
}

/**
 * Performs a login for the user, handling any pre-login requests if they are
 * required.
 *
 * @param username: The username to log in with.
 * @param password: The password to log in with.
 * @param callback: Callback block to execute in response to login state.
 */
- (void) performLoginRequestWithUser:(NSString *) username usingPassword:(NSString *) password andCallback:(SQUDistrictCallback) callback {
	// Perform the pre-login request, if it's a thing
	NSDictionary *preLogin = [_currentDistrict buildPreLoginRequestWithUserData:nil];
	
	NSLog(@"PreLogin");
	
	// Support districts that don't require a pre-login request
	if(preLogin) {
		// Called if the pre-login succeeds
		void (^preLoginSuccess)(NSURLResponse*operation, id responseObject) = ^(NSURLResponse*operation, id responseObject) {
			[_currentDistrict updateDistrictStateWithPreLoginData:(NSData *) responseObject];
			
			// Perform the actual login, as the pre log-in request was success
			[self performActualLoginRequestWithUser:username usingPassword:password andCallback:callback];
		};
		
		// Called on server error
		void (^preLoginFailure)(NSURLResponse*operation, NSError *error) = ^(NSURLResponse*operation, NSError *error) {
			callback(error, nil);
			NSLog(@"Pre log-in error: %@", error);
		};
		
		// Set up the request
		NSURL *url = preLogin[@"request"][@"URL"];
		
		if([preLogin[@"request"][@"method"] isEqualToString:@"GET"]) {
			[self sendGETRequestToURL:url withParameters:preLogin[@"params"] andSuccessBlock:preLoginSuccess andFailureBlock:preLoginFailure];
		} else {
			NSLog(@"Unsupported pre-login method: %@", preLogin[@"request"][@"method"]);
			return;
		}
	} else { // We do not have a pre-login request
		[self performActualLoginRequestWithUser:username usingPassword:password andCallback:callback];
	}
}

/**
 * Disambiguates, or selects, a specific student on the account. This is required
 * before accessing any other parts of the gradebook software, especially if the
 * account has multiple students on it.
 *
 * @param sid: Student ID to select.
 * @param callback: Callback block to execute.
 */
- (void) performDisambiguationRequestWithStudentID:(NSString *) sid andCallback:(SQUDistrictCallback) callback {
	// Do not perform disambiguation if there is only a single student on the account.
	if(!_currentDistrict.hasMultipleStudents) {
		NSLog(@"Ignoring disambiguation request");
		callback(nil, nil);
		return;
	}
	
	NSLog(@"Disambiguate ID %@", sid);
	
	NSDictionary *disambiguationRequest = [_currentDistrict buildDisambiguationRequestWithStudentID:sid andUserData:nil];
	
	// Called if the request succeeds
	void (^disambiguateSuccess)(NSURLResponse*operation, id responseObject) = ^(NSURLResponse*operation, id responseObject) {
		
		if([_currentDistrict didDisambiguationSucceedWithLoginData:responseObject]) {
			callback(nil, responseObject);
		} else {
			callback([NSError errorWithDomain:@"SQUDistrictManagerErrorDomain" code:kSQUDistrictManagerErrorInvalidDisambiguation userInfo:@{@"localizedDescription" : NSLocalizedString(@"The disambiguation process failed.", nil)}], nil);
		}
	};
	
	// Called on server error
	void (^disambiguateFailure)(NSURLResponse*operation, NSError *error) = ^(NSURLResponse*operation, NSError *error) {
		callback(error, nil);
		NSLog(@"Disambiguation error: %@", error);
	};
	
	// Set up the request
	NSURL *url = disambiguationRequest[@"request"][@"URL"];
	
	if([disambiguationRequest[@"request"][@"method"] isEqualToString:@"GET"]) {
		[self sendGETRequestToURL:url withParameters:disambiguationRequest[@"params"] andSuccessBlock:disambiguateSuccess andFailureBlock:disambiguateFailure];
	} else if([disambiguationRequest[@"request"][@"method"] isEqualToString:@"POST"]) {
		[self sendPOSTRequestToURL:url withParameters:disambiguationRequest[@"params"] andSuccessBlock:disambiguateSuccess andFailureBlock:disambiguateFailure];
	} else {
		NSLog(@"Unsupported disambiguation method: %@", disambiguationRequest[@"request"][@"method"]);
		return;
	}
}

/**
 * Fetches class averages from the server, parsing the data appropriately and
 * returning it to the callback.
 *
 * @param callback: Callback block to execute with parsed class averages.
 */
- (void) performAveragesRequestWithCallback:(SQUDistrictCallback) callback {
	NSDictionary *avgRequest = [_currentDistrict buildAveragesRequestWithUserData:nil];
	NSLog(@"Averages request");
	
	// Called if the request succeeds
	void (^averagesSuccess)(NSURLResponse*operation, id responseObject) = ^(NSURLResponse*operation, id responseObject) {
		NSString *string = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
		NSArray *averages = [[SQUGradeManager sharedInstance].currentDriver parseAveragesForDistrict:_currentDistrict withString:string];
		
		if(averages != nil) {
			NSString *studentName = [[SQUGradeManager sharedInstance].currentDriver getStudentNameForDistrict:_currentDistrict withString:string];
			NSString *studentSchool = [[SQUGradeManager sharedInstance].currentDriver getStudentSchoolForDistrict:_currentDistrict withString:string];
			
			[SQUGradeManager sharedInstance].student.name = studentName;
			[SQUGradeManager sharedInstance].student.school = studentSchool;
			
			NSLog(@"Got avg data");
			
			[_currentDistrict updateDistrictStateWithClassGrades:averages];

			callback(nil, averages);
		} else {
			callback([NSError errorWithDomain:@"SQUDistrictManagerErrorDomain" code:kSQUDistrictManagerErrorInvalidDataReceived userInfo:@{@"localizedDescription" : NSLocalizedString(@"The gradebook returned invalid data.", nil)}], nil);
			// NSLog(@"Got screwy response from gradebook: %@", [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]);
		}
	};
	
	// Called on server error
	void (^averagesFailure)(NSURLResponse*operation, NSError *error) = ^(NSURLResponse*operation, NSError *error) {
		callback(error, nil);
		NSLog(@"Averages error: %@", error);
	};
	
	// Set up the request
	NSURL *url = avgRequest[@"request"][@"URL"];
	
	if([avgRequest[@"request"][@"method"] isEqualToString:@"GET"]) {
		[self sendGETRequestToURL:url withParameters:avgRequest[@"params"] andSuccessBlock:averagesSuccess andFailureBlock:averagesFailure];
	} else {
		NSLog(@"Unsupported average fetching method: %@", avgRequest[@"request"][@"method"]);
		return;
	}
}

/**
 * Performs a request to fetch the grades for a specific class.
 *
 * @param course: Course code whose grades to look up.
 * @param cycle: Cycle to load.
 * @param semester: Semester containing the cycle.
 * @param callback: Callback block to execute.
 */
- (void) performClassGradesRequestWithCourseCode:(NSString *) course andCycle:(NSUInteger) cycle inSemester:(NSUInteger) semester andCallback:(SQUDistrictCallback) callback {
	NSDictionary *classGradesRequest = [_currentDistrict buildClassGradesRequestWithCourseCode:course andSemester:semester andCycle:cycle andUserData:nil];
	
	if(!classGradesRequest) {
		callback([NSError errorWithDomain:@"SQUDistrictManagerErrorDomain" code:kSQUDistrictManagerErrorNoDataAvailable userInfo:@{@"localizedDescription" : NSLocalizedString(@"No data is available for the selected cycle.", nil)}], nil);
		return;
	}
	
	// Called if the request succeeds
	void (^callbackSuccess)(NSURLResponse*operation, id responseObject) = ^(NSURLResponse*operation, id responseObject) {
		NSDictionary *classGrades = [[SQUGradeManager sharedInstance].currentDriver getClassGradesForDistrict:_currentDistrict withString:[[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]];
		
		if(classGrades != nil) {
			callback(nil, classGrades);
		} else {
			callback([NSError errorWithDomain:@"SQUDistrictManagerErrorDomain" code:kSQUDistrictManagerErrorInvalidDataReceived userInfo:@{@"localizedDescription" : NSLocalizedString(@"The gradebook returned invalid data.", nil)}], nil);
		}
	};
	
	// Called on server error
	void (^callbackFailure)(NSURLResponse*operation, NSError *error) = ^(NSURLResponse*operation, NSError *error) {
		callback(error, nil);
		NSLog(@"Class grade fetching error: %@", error);
	};
	
	// Set up the request
	NSURL *url = classGradesRequest[@"request"][@"URL"];
	
	if([classGradesRequest[@"request"][@"method"] isEqualToString:@"GET"]) {
		[self sendGETRequestToURL:url withParameters:classGradesRequest[@"params"] andSuccessBlock:callbackSuccess andFailureBlock:callbackFailure];
	} else {
		callback([NSError errorWithDomain:@"SQUDistrictManagerErrorDomain" code:kSQUDistrictManagerErrorInvalidDataReceived userInfo:@{@"localizedDescription" : NSLocalizedString(@"The gradebook returned invalid data.", nil)}], nil);
		NSLog(@"Unsupported class grades fetching method: %@", classGradesRequest[@"request"][@"method"]);
		return;
	}
}

/**
 * Calls the login verification method on the district.
 *
 * @param callback: Callback block to execute to validate if the login was
 * successful or not.
 */
- (void) checkIfLoggedIn:(SQULoggedInCallback) callback {
	[_currentDistrict isLoggedInWithCallback:callback];
}

/**
 * Returns the cycles that data is available for in a specific course.
 *
 * @param course: Course code to check for.
 * @return An array of NSNumbers of cycles that have data available.
 */
- (NSArray *) cyclesWithDataAvailableForCourse:(NSString *) course {
	return [_currentDistrict cyclesWithDataForCourse:course];
}

@end
