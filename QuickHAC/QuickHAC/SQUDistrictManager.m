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
@synthesize currentDistrict = _currentDistrict, reachabilityManager = _reachabilityManager;

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
			
			_HTTPManager = [AFHTTPRequestOperationManager manager];
			_HTTPManager.responseSerializer = [AFHTTPResponseSerializer serializer];
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
		
		// NSLog(@"Loaded district %@ (%@, using driver %@)",  district, districtInitialised.name, districtInitialised.driver);
	} else {
		NSLog(@"Tried to load district %@, but %@ does not conform to SQUDistrictProtocol.", district, NSStringFromClass(district));
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
			self.currentDistrict = district;
			
			return YES;
		}
	}
	
	return NO;
}

/**
 * Setter for _currentDistrict.
 */
- (void) setCurrentDistrict:(SQUDistrict *) currentDistrict {
	_currentDistrict = currentDistrict;
	
	// Load the district's SSL certs, if they are specified.
	NSArray *certs = [currentDistrict districtSSLCertData];
	
	// If there's no certs, panic
	if((certs.count == 1 && [certs[0] integerValue] == 0) || !certs) {
		_HTTPManager.securityPolicy.SSLPinningMode = AFSSLPinningModeNone;
		_HTTPManager.securityPolicy.allowInvalidCertificates = YES;
		_HTTPManager.securityPolicy.pinnedCertificates = nil;
		
		// NSLog(@"SECURITY POLICY CHANGED: Accepts invalid certs (%@)", currentDistrict.name);
	} else if(certs.count != 0) {
		_HTTPManager.securityPolicy.allowInvalidCertificates = NO;
		_HTTPManager.securityPolicy.SSLPinningMode = AFSSLPinningModeCertificate;
		
		[_HTTPManager.securityPolicy setPinnedCertificates:certs];
		
		// NSLog(@"SECURITY POLICY CHANGED: Rejects invalid certs (%@)", currentDistrict.name);
	}
	
	// Clear munchies so we're logged out (prevents course mingling)
	// TODO: Fix this to clear only munchies for the district's domain!
	NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
	
	for (NSHTTPCookie *cookie in cookies) {
		[[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
	}
	
	// Update the reachability manager
//	if(currentDistrict.districtDomain) {
//		_reachabilityManager = [AFNetworkReachabilityManager managerForDomain:currentDistrict.districtDomain];
//	} else {
		_reachabilityManager = [AFNetworkReachabilityManager sharedManager];
//	}
	
	_lastRequest = nil;
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
 * Creates a GET request with the specified URL, parameters, and success and
 * failure callback blocks.
 */
- (void) sendGETRequestToURL:(NSURL *) url withParameters:(NSDictionary *) params andSuccessBlock:(void (^)(AFHTTPRequestOperation *operation, id responseObject)) success andFailureBlock:(void (^)(AFHTTPRequestOperation *operation, NSError *error)) failure {
	[_HTTPManager GET:[url absoluteString] parameters:params success:success failure:failure];
}

/**
 * Creates a POST request with the specified URL, parameters, and success and
 * failure callback blocks.
 */
- (void) sendPOSTRequestToURL:(NSURL *) url withParameters:(NSDictionary *) params andSuccessBlock:(void (^)(AFHTTPRequestOperation *operation, id responseObject)) success andFailureBlock:(void (^)(AFHTTPRequestOperation *operation, NSError *error)) failure {
	[_HTTPManager POST:[url absoluteString] parameters:params success:success failure:failure];
}

#pragma mark - District interfacing
/**
 * Sends the actual login request.
 */
- (void) performActualLoginRequestWithUser:(NSString *) username usingPassword:(NSString *) password andCallback:(SQUDistrictCallback) callback {
	NSDictionary *loginRequest = [_currentDistrict buildLoginRequestWithUser:username usingPassword:password andUserData:nil];
	NSURL *url = loginRequest[@"request"][@"URL"];
	
	// Called on success of the operation (200 OK)
	void (^loginSuccess)(AFHTTPRequestOperation*operation, id responseObject) = ^(AFHTTPRequestOperation*operation, id responseObject) {		
		[_currentDistrict updateDistrictStateWithPostLoginData:responseObject];
		
		// The server accepted our request, now check if the request succeeded
		if([_currentDistrict didLoginSucceedWithLoginData:responseObject]) {
			NSMutableDictionary *response = [NSMutableDictionary new];
			response[@"username"] = username;
			response[@"password"] = password;
			response[@"serverResponse"] = responseObject;
			
			_lastRequest = [NSDate date];
			
			callback(nil, response);
		} else {
			callback(nil, nil);
		}
	};
	
	// Called if the request fails for some reason (500, network error, etc)
	void (^loginFailure)(AFHTTPRequestOperation*operation, NSError *error) = ^(AFHTTPRequestOperation*operation, NSError *error) {
		callback(error, nil);
		_lastRequest = nil;
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
	
	// Support districts that don't require a pre-login request
	if(preLogin) {
		// Called if the pre-login succeeds
		void (^preLoginSuccess)(AFHTTPRequestOperation*operation, id responseObject) = ^(AFHTTPRequestOperation*operation, id responseObject) {
			[_currentDistrict updateDistrictStateWithPreLoginData:(NSData *) responseObject];
			
			// Perform the actual login, as the pre log-in request was success
			[self performActualLoginRequestWithUser:username usingPassword:password andCallback:callback];
		};
		
		// Called on server error
		void (^preLoginFailure)(AFHTTPRequestOperation*operation, NSError *error) = ^(AFHTTPRequestOperation*operation, NSError *error) {
			callback(error, nil);
			NSLog(@"Pre log-in error: %@", error);
			
			_lastRequest = nil;
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
	if(!_currentDistrict.hasMultipleStudents || !sid) {
		callback(nil, nil);
		return;
	}
	
	NSDictionary *disambiguationRequest = [_currentDistrict buildDisambiguationRequestWithStudentID:sid andUserData:nil];
	
	// Called if the request succeeds
	void (^disambiguateSuccess)(AFHTTPRequestOperation*operation, id responseObject) = ^(AFHTTPRequestOperation*operation, id responseObject) {
		
		if([_currentDistrict didDisambiguationSucceedWithLoginData:responseObject]) {
			callback(nil, responseObject);
		} else {
			callback([NSError errorWithDomain:@"SQUDistrictManagerErrorDomain" code:kSQUDistrictManagerErrorInvalidDisambiguation userInfo:@{@"localizedDescription" : NSLocalizedString(@"The disambiguation process failed.", nil)}], nil);
		}
	};
	
	// Called on server error
	void (^disambiguateFailure)(AFHTTPRequestOperation*operation, NSError *error) = ^(AFHTTPRequestOperation*operation, NSError *error) {
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
	
	// Called if the request succeeds
	void (^averagesSuccess)(AFHTTPRequestOperation*operation, id responseObject) = ^(AFHTTPRequestOperation*operation, id responseObject) {
		NSString *string = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
		NSArray *averages = [[SQUGradeManager sharedInstance].currentDriver parseAveragesForDistrict:_currentDistrict withString:string];
		
		if(averages != nil) {
			NSString *studentName = [[SQUGradeManager sharedInstance].currentDriver getStudentNameForDistrict:_currentDistrict withString:string];
			NSString *studentSchool = [[SQUGradeManager sharedInstance].currentDriver getStudentSchoolForDistrict:_currentDistrict withString:string];
			
			// Try to make sure that student data does not get mingled
			NSString *dbName = [SQUGradeManager sharedInstance].student.name;
			
			if(dbName) {
				// Some districts strip middle names, so we do a substring search
				if([dbName rangeOfString:studentName].location == NSNotFound) {
					NSLog(@"Got grades for `%@` but current is `%@`: ignoring update",
						  studentName, dbName);
					
					// run callback to update UI
					callback(nil, nil);
					return;
				}
			}
			
			performUpdate: ;
			[SQUGradeManager sharedInstance].student.name = studentName;
			[SQUGradeManager sharedInstance].student.school = studentSchool;
				
			[_currentDistrict updateDistrictStateWithClassGrades:averages];
			
			// Update the display name
			NSArray *components = [studentName componentsSeparatedByString:@", "];
			if(components.count == 2) {
				NSString *firstName = components[1];
				components = [firstName componentsSeparatedByString:@" "];
				
				if(components.count == 0) {
					[SQUGradeManager sharedInstance].student.display_name = firstName;
				} else {
					[SQUGradeManager sharedInstance].student.display_name = components[0];
				}
			} else {
				[SQUGradeManager sharedInstance].student.display_name = studentName;
			}
			
			// NSLog(@"Updated grades for %@ (%@)", [SQUGradeManager sharedInstance].student.name, [SQUGradeManager sharedInstance].student.display_name);
			
			// Run the callback now to appease login process
			callback(nil, averages);
			
			_lastRequest = [NSDate date];
		} else {
			callback([NSError errorWithDomain:@"SQUDistrictManagerErrorDomain" code:kSQUDistrictManagerErrorInvalidDataReceived userInfo:@{@"localizedDescription" : NSLocalizedString(@"The gradebook returned invalid data.", nil)}], nil);
			// NSLog(@"Got screwy response from gradebook: %@", [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]);
		}
	};
	
	// Called on server error
	void (^averagesFailure)(AFHTTPRequestOperation*operation, NSError *error) = ^(AFHTTPRequestOperation*operation, NSError *error) {
		callback(error, nil);
		_lastRequest = nil;
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
	void (^callbackSuccess)(AFHTTPRequestOperation*operation, id responseObject) = ^(AFHTTPRequestOperation*operation, id responseObject) {
		NSDictionary *classGrades = [[SQUGradeManager sharedInstance].currentDriver getClassGradesForDistrict:_currentDistrict withString:[[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]];
		
		if(classGrades != nil) {
			callback(nil, classGrades);
			
			_lastRequest = [NSDate date];
		} else {
			callback([NSError errorWithDomain:@"SQUDistrictManagerErrorDomain" code:kSQUDistrictManagerErrorInvalidDataReceived userInfo:@{@"localizedDescription" : NSLocalizedString(@"The gradebook returned invalid data.", nil)}], nil);
		}
	};
	
	// Called on server error
	void (^callbackFailure)(AFHTTPRequestOperation*operation, NSError *error) = ^(AFHTTPRequestOperation*operation, NSError *error) {
		callback(error, nil);
		_lastRequest = nil;
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
	NSTimeInterval diff = [[NSDate date] timeIntervalSinceDate:_lastRequest];
	
	if((diff > SQUDistrictManagerMaxRequestDelay) || !_lastRequest) {
		[_currentDistrict isLoggedInWithCallback:callback];
	} else {
		// NSLog(@"Delay not elapsed: assuming logged in (%f)", diff);
		callback(YES);
	}
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
