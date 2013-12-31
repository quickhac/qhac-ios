//
//  SQUDistrictAISD.h
//  QuickHAC
//
//  Created by Tristan Seifert on 12/30/13.
//  See README.MD for licensing and copyright information.
//

#import "SQUDistrict.h"

/**
 * District interface for Austin Independent School District.
 */
@interface SQUDistrictAISD : SQUDistrict {
@public
	
@private
	NSMutableDictionary *_loginASPNetInfo;
	NSMutableDictionary *_disambiguationASPNetInfo;
	NSMutableDictionary *_classToHashMap;
}

@end
