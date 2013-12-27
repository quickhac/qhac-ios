//
//  SQUDistrictManager.h
//  QuickHAC
//
//  Created by Tristan Seifert on 12/27/13.
//  Copyright (c) 2013 Squee! Apps. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^ SQUDistrictCallback)(NSError *error, id returnData);

@class SQUDistrict;
@interface SQUDistrictManager : NSObject {
	NSMutableArray *_loadedDistricts;
	NSMutableArray *_initialisedDistricts;
	
	SQUDistrict *_currentDistrict;
}

@property (nonatomic, readwrite) SQUDistrict *currentDistrict;

+ (SQUDistrictManager *) sharedInstance;
- (void) registerDistrict:(Class) district;

- (NSArray *) loadedDistricts;
- (BOOL) selectDistrictWithID:(NSInteger) districtID;

// The methods below operate on the _currentDistrict.
- (void) performLoginRequestWithUser:(NSString *) username usingPassword:(NSString *) password andCallback:(SQUDistrictCallback) callback;
- (void) performDisambiguationRequestWithStudentID:(NSString *) sid andCallback:(SQUDistrictCallback) callback;
- (void) performAveragesRequestWithUserDataAndCallback:(SQUDistrictCallback) callback;
- (void) performClassGradesRequestWithCourseCode:(NSString *) course andCycle:(NSUInteger) cycle andCallback:(SQUDistrictCallback) callback;

@end
