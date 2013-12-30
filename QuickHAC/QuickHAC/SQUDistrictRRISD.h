//
//  SQUDistrictRRISD.h
//  QuickHAC
//
//  Created by Tristan Seifert on 12/27/13.
//  See README.MD for licensing and copyright information.
//

#import "SQUDistrict.h"

@interface SQUDistrictRRISD : SQUDistrict {
@public
	
@private
	NSMutableDictionary *_loginASPNetInfo;
	NSMutableDictionary *_classToHashMap;
}

@end
