//
//  SQUDistrictRRISD.m
//  QuickHAC
//
//  Created by Tristan Seifert on 12/27/13.
//  See README.MD for licensing and copyright information.
//

#import "TFHpple.h"
#import "AFNetworking.h"

#import "SQUDistrictRRISD.h"
#import "SQUDistrictManager.h"

@implementation SQUDistrictRRISD

+ (void) load {
	[[SQUDistrictManager sharedInstance] registerDistrict:[self class]];
}

- (id) init {
	if(self = [super init]) {
		_name = @"Round Rock ISD";
		_driver = @"gradespeed";
		_examWeight = 15.0f;
		
		_tableOffsets.title = 0;
		_tableOffsets.grades = 2;
		
		_district_id = 1;
	}
	
	return self;
}

#pragma mark - Request building
/*
 * Builds a request to run directly before the login to, for example, fetch some
 * parameters from the form that are needed for the login process to complete
 * successfully. (Yes, ASP.NET, we're looking at you…)
 */
- (NSDictionary *) buildPreLoginRequestWithUserData:(id) userData {
	NSMutableDictionary *dictionary = [NSMutableDictionary new];
	dictionary[@"request"] = [NSMutableDictionary new];
	
	// Request information (URL, method, etc)
	dictionary[@"request"][@"URL"] = [NSURL URLWithString:@"https://accesscenter.roundrockisd.org/homeaccess/default.aspx"];
	dictionary[@"request"][@"method"] = @"GET";
	
	return dictionary;
}

/*
 * This method would build a login request for the username and password given,
 * possibly using the user data, depending on district.
 */
- (NSDictionary *) buildLoginRequestWithUser:(NSString *) username usingPassword:(NSString *) password andUserData:(id) userData {
	NSMutableDictionary *dictionary = [NSMutableDictionary new];
	dictionary[@"request"] = [NSMutableDictionary new];
	dictionary[@"params"] = [NSMutableDictionary new];
	
	// Request information (URL, method, etc)
	dictionary[@"request"][@"URL"] = [NSURL URLWithString:@"https://accesscenter.roundrockisd.org/homeaccess/default.aspx"];
	dictionary[@"request"][@"method"] = @"POST";
	
	// Form fields
	dictionary[@"params"][@"ctl00$plnMain$txtLogin"] = username;
	dictionary[@"params"][@"ctl00$plnMain$txtPassword"] = password;
	dictionary[@"params"][@"ctl00$plnMain$Submit1"] = @"Log In";
	dictionary[@"params"][@"ctl00$strHiddenPageTitle"] = @"";
	
	// ASP.NET fields
	dictionary[@"params"][@"__VIEWSTATE"] = _loginASPNetInfo[@"__VIEWSTATE"];
	dictionary[@"params"][@"__EVENTVALIDATION"] = _loginASPNetInfo[@"__EVENTVALIDATION"];
	dictionary[@"params"][@"__EVENTTARGET"] = @"";
	dictionary[@"params"][@"__EVENTARGUMENT"] = @"";
	
	return dictionary;
}

/*
 * Build a request to disambiguate the student ID specified.
 */
- (NSDictionary *) buildDisambiguationRequestWithStudentID:(NSString *) sid andUserData:(id) userData {
	NSLog(@"%s(%i) %s: SQUDistrict method not overridden or no subclass used", __FILE__, __LINE__, __func__);
	return nil;
}

/*
 * Build a request to fetch the class averages for the currently logged-in
 * student ID.
 */
- (NSDictionary *) buildAveragesRequestWithUserData:(id) userData {
	NSLog(@"%s(%i) %s: SQUDistrict method not overridden or no subclass used", __FILE__, __LINE__, __func__);
	return nil;
}

/*
 * Builds a request to fetch the class grades for the specified course and
 * cycle.
 */
- (NSDictionary *) buildClassGradesRequestWithCourseCode:(NSString *) course andCycle:(NSUInteger) cycle andUserData:(id) userData {
	NSLog(@"%s(%i) %s: SQUDistrict method not overridden or no subclass used", __FILE__, __LINE__, __func__);
	return nil;
}

#pragma mark - Data callbacks
/*
 * This method is called whenever the overall averages for all classes is
 * updated, so the district code can perform internal housekeeping, like keeping
 * track of the URLs for specifc class grades information.
 */
- (void) updateDistrictStateWithClassGrades:(NSArray *) grade {
	NSLog(@"%s(%i) %s: SQUDistrict method not overridden or no subclass used", __FILE__, __LINE__, __func__);
}

/*
 * Called on completion of the pre-login request, if it is required, with the
 * data returned by the request.
 */
- (void) updateDistrictStateWithPreLoginData:(NSData *) data {
	if(!_loginASPNetInfo) {
		_loginASPNetInfo = [NSMutableDictionary new];
	} else {
		[_loginASPNetInfo removeAllObjects];
	}
	
	// Set up a parser
	TFHpple *parser = [TFHpple hppleWithHTMLData:data];
	TFHppleElement *form = [parser searchWithXPathQuery:@"//form[@name='aspnetForm']"][0];
	
	// Find children of the form
	NSArray *formChildren = [form childrenWithTagName:@"input"];
	
	for (TFHppleElement *input in formChildren) {
		if([input[@"name"] isEqualToString:@"__VIEWSTATE"]) {
			_loginASPNetInfo[@"__VIEWSTATE"] = input[@"value"];
		} else if([input[@"name"] isEqualToString:@"__EVENTVALIDATION"]) {
			_loginASPNetInfo[@"__EVENTVALIDATION"] = input[@"value"];
		}
	}
}

/*
 * Called after the completion of the actual login request with the data that
 * the web server returned.
 */
- (void) updateDistrictStateWithPostLoginData:(NSData *) data {
	// NSLog(@"Login data: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
}

/*
 * Called with the data returned by the login request to validate if the login
 * was a success.
 */
- (BOOL) didLoginSucceedWithLoginData:(NSData *) data {
	TFHpple *parser = [TFHpple hppleWithHTMLData:data];
	TFHppleElement *form = [parser searchWithXPathQuery:@"//form[@name='aspnetForm']"][0];
	
	/* 
	 * If the ASP form has a target of "default.aspx", we can assume the login
	 * failed. We can further check if this is the case by testing if the div
	 * with id "ctl00_plnMain_ValidationSummary1" contains any text.
	 */
	if([form[@"action"] isEqualToString:@"default.aspx"]) {
		TFHppleElement *validationErrorContainer = [parser searchWithXPathQuery:@"//div[@id='ctl00_plnMain_ValidationSummary1']"][0];
		NSArray *children = [validationErrorContainer childrenWithTagName:@"font"];
		
		if(children.count > 0) {
			// NSLog(@"//div[@id='ctl00_plnMain_ValidationSummary1']: %@", children);
		}
		
		return NO;
	}
	
	return YES;
}

@end
