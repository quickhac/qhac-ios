//
//  SQUDistrictManager.m
//  QuickHAC
//
//	Management of districts loaded into the app and interfacing with them.
//
//  Created by Tristan Seifert on 12/27/13.
//  See README.MD for licensing and copyright information.
//

#import "SQUDistrictManager.h"
#import "SQUDistrict.h"
#import "SQUGradeManager.h"
#import "SQUGradeParser.h"
#import "SQUCoreData.h"

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
/*
 * Registers the specified district with the manager.
 */
- (void) registerDistrict:(Class) district {
	if([district conformsToProtocol:@protocol(SQUDistrictProtocol)]) {
		[_loadedDistricts addObject:district];
		NSUInteger index = [_loadedDistricts indexOfObject:district];
		
		SQUDistrict *districtInitialised = [[district alloc] init];
		[_initialisedDistricts insertObject:districtInitialised atIndex:index];
		
		NSLog(@"Loaded district %@ (%@, using driver %@)",  district, districtInitialised.name, districtInitialised.driver);
	} else {
		NSLog(@"Tried to load %@, but %@ does not conform to SQUDistrictProtocol.", district, NSStringFromClass(district));
	}
}

/*
 * Returns an array of SQUDistrict subclasses that have been registered.
 */
- (NSArray *) loadedDistricts {
	return [NSArray arrayWithArray:_initialisedDistricts];
}

/*
 * Searches through all loaded districts for one that matches the ID, then sets
 * it as the active district.
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

#pragma mark - Request helper methods
/*
 * Creates a GET request with the specified URL, parameters, and success and
 * failure callback blocks.
 */
- (void) sendGETRequestToURL:(NSURL *) url withParameters:(NSDictionary *) params andSuccessBlock:(void (^)(AFHTTPRequestOperation *operation, id responseObject)) success andFailureBlock:(void (^)(AFHTTPRequestOperation *operation, NSError *error)) failure {
	AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
	manager.responseSerializer = [AFHTTPResponseSerializer serializer];
	[manager GET:[url absoluteString] parameters:params success:success failure:failure];
}

/*
 * Creates a POST request with the specified URL, parameters, and success and
 * failure callback blocks.
 */
- (void) sendPOSTRequestToURL:(NSURL *) url withParameters:(NSDictionary *) params andSuccessBlock:(void (^)(AFHTTPRequestOperation *operation, id responseObject)) success andFailureBlock:(void (^)(AFHTTPRequestOperation *operation, NSError *error)) failure {
	AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
	manager.responseSerializer = [AFHTTPResponseSerializer serializer];
	[manager POST:[url absoluteString] parameters:params success:success failure:failure];
}

#pragma mark - District interfacing
/*
 * Sends the actual login request.
 */
- (void) performActualLoginRequestWithUser:(NSString *) username usingPassword:(NSString *) password andCallback:(SQUDistrictCallback) callback {
	NSDictionary *loginRequest = [_currentDistrict buildLoginRequestWithUser:username usingPassword:password andUserData:nil];
	
	NSURL *url = loginRequest[@"request"][@"URL"];
	
	// Called on success of the operation (200 OK)
	void (^loginSuccess)(AFHTTPRequestOperation *operation, id responseObject) = ^(AFHTTPRequestOperation *operation, id responseObject) {
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
	void (^loginFailure)(AFHTTPRequestOperation *operation, NSError *error) = ^(AFHTTPRequestOperation *operation, NSError *error) {
		callback(error, nil);
	};
	
	// We only support POST requests for security reasons
	if([loginRequest[@"request"][@"method"] isEqualToString:@"POST"]) {
		[self sendPOSTRequestToURL:url withParameters:loginRequest[@"params"] andSuccessBlock:loginSuccess andFailureBlock:loginFailure];
	} else {
		NSLog(@"Unsupported login method: %@", loginRequest[@"request"][@"method"]);
		return;
	}
}

/*
 * Handles pre-login requests, if they exist.
 */
- (void) performLoginRequestWithUser:(NSString *) username usingPassword:(NSString *) password andCallback:(SQUDistrictCallback) callback {
	// Perform the pre-login request, if it's a thing
	NSDictionary *preLogin = [_currentDistrict buildPreLoginRequestWithUserData:nil];
	
	// Support districts that don't require a pre-login request
	if(preLogin) {
		// Called if the pre-login succeeds
		void (^preLoginSuccess)(AFHTTPRequestOperation *operation, id responseObject) = ^(AFHTTPRequestOperation *operation, id responseObject) {
			[_currentDistrict updateDistrictStateWithPreLoginData:(NSData *) responseObject];
			
			// Perform the actual login, as the pre log-in request was success
			[self performActualLoginRequestWithUser:username usingPassword:password andCallback:callback];
		};
		
		// Called on server error
		void (^preLoginFailure)(AFHTTPRequestOperation *operation, NSError *error) = ^(AFHTTPRequestOperation *operation, NSError *error) {
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

/*
 * Makes sure the correct user is selected
 */
- (void) performDisambiguationRequestWithStudentID:(NSString *) sid andCallback:(SQUDistrictCallback) callback {
	NSDictionary *disambiguationRequest = [_currentDistrict buildDisambiguationRequestWithStudentID:sid andUserData:nil];
	
	// Called if the request succeeds
	void (^disambiguateSuccess)(AFHTTPRequestOperation *operation, id responseObject) = ^(AFHTTPRequestOperation *operation, id responseObject) {
		
		if([_currentDistrict didDisambiguationSucceedWithLoginData:responseObject]) {
			callback(nil, responseObject);
		} else {
			callback([NSError errorWithDomain:@"SQUDistrictManagerErrorDomain" code:kSQUDistrictManagerErrorInvalidDisambiguation userInfo:@{@"localizedDescription" : NSLocalizedString(@"The disambiguation process failed.", nil)}], nil);
		}
	};
	
	// Called on server error
	void (^disambiguateFailure)(AFHTTPRequestOperation *operation, NSError *error) = ^(AFHTTPRequestOperation *operation, NSError *error) {
		callback(error, nil);
		NSLog(@"Disambiguation error: %@", error);
	};
	
	// Set up the request
	NSURL *url = disambiguationRequest[@"request"][@"URL"];
	
	if([disambiguationRequest[@"request"][@"method"] isEqualToString:@"GET"]) {
		[self sendGETRequestToURL:url withParameters:disambiguationRequest[@"params"] andSuccessBlock:disambiguateSuccess andFailureBlock:disambiguateFailure];
	} else {
		NSLog(@"Unsupported disambiguation method: %@", disambiguationRequest[@"request"][@"method"]);
		return;
	}
}

/*
 * Fetches class averages from the server, parsing the data appropriately and
 * returning it to the callback.
 */
- (void) performAveragesRequestWithCallback:(SQUDistrictCallback) callback {
	NSDictionary *avgRequest = [_currentDistrict buildAveragesRequestWithUserData:nil];
	
	// Called if the request succeeds
	void (^averagesSuccess)(AFHTTPRequestOperation *operation, id responseObject) = ^(AFHTTPRequestOperation *operation, id responseObject) {
		NSString *string = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
		
		NSArray *averages = [[SQUGradeParser sharedInstance] parseAveragesForDistrict:_currentDistrict withString:string];
		
		if(averages != nil) {
			NSString *studentName = [[SQUGradeParser sharedInstance] getStudentNameForDistrict:_currentDistrict withString:string];
			[SQUGradeManager sharedInstance].student.name = studentName;
			
			[_currentDistrict updateDistrictStateWithClassGrades:averages];

			callback(nil, averages);
		} else {
			callback([NSError errorWithDomain:@"SQUDistrictManagerErrorDomain" code:kSQUDistrictManagerErrorInvalidDataReceived userInfo:@{@"localizedDescription" : NSLocalizedString(@"The gradebook returned invalid data.", nil)}], nil);
		}
	};
	
	// Called on server error
	void (^averagesFailure)(AFHTTPRequestOperation *operation, NSError *error) = ^(AFHTTPRequestOperation *operation, NSError *error) {
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

/*
 * Performs a request to fetch the grades for a specific class.
 */
- (void) performClassGradesRequestWithCourseCode:(NSString *) course andCycle:(NSUInteger) cycle inSemester:(NSUInteger) semester andCallback:(SQUDistrictCallback) callback {
	NSDictionary *classGradesRequest = [_currentDistrict buildClassGradesRequestWithCourseCode:course andSemester:semester andCycle:cycle andUserData:nil];
	
	if(!classGradesRequest) {
		callback([NSError errorWithDomain:@"SQUDistrictManagerErrorDomain" code:kSQUDistrictManagerErrorNoDataAvailable userInfo:@{@"localizedDescription" : NSLocalizedString(@"No data is available for the selected cycle.", nil)}], nil);
		return;
	}
	
	// Called if the request succeeds
	void (^callbackSuccess)(AFHTTPRequestOperation *operation, id responseObject) = ^(AFHTTPRequestOperation *operation, id responseObject) {
		NSDictionary *classGrades = [[SQUGradeParser sharedInstance] getClassGradesForDistrict:_currentDistrict withString:[[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]];
		
		if(classGrades != nil) {
			callback(nil, classGrades);
		} else {
			callback([NSError errorWithDomain:@"SQUDistrictManagerErrorDomain" code:kSQUDistrictManagerErrorInvalidDataReceived userInfo:@{@"localizedDescription" : NSLocalizedString(@"The gradebook returned invalid data.", nil)}], nil);
		}
	};
	
	// Called on server error
	void (^callbackFailure)(AFHTTPRequestOperation *operation, NSError *error) = ^(AFHTTPRequestOperation *operation, NSError *error) {
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

/*
 * Calls the login verification method on the district.
 */
- (void) checkIfLoggedIn:(SQULoggedInCallback) callback {
	[_currentDistrict isLoggedInWithCallback:callback];
}

/*
 * Returns the cycles that data is available for in a specific course.
 */
- (NSArray *) cyclesWithDataAvailableForCourse:(NSString *) course {
	return [_currentDistrict cyclesWithDataForCourse:course];
}

@end
