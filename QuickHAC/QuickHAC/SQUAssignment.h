//
//  SQUAssignment.h
//  QuickHAC
//
//  Created by Tristan Seifert on 12/28/13.
//  See README.MD for licensing and copyright information.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class SQUCategory;

@interface SQUAssignment : NSManagedObject

@property (nonatomic, retain) NSDate * date_assigned;
@property (nonatomic, retain) NSDate * date_due;
@property (nonatomic, retain) NSNumber * extra_credit;
@property (nonatomic, retain) NSString * note;
@property (nonatomic, retain) NSNumber * pts_earned;
@property (nonatomic, retain) NSNumber * pts_possible;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * weight;
@property (nonatomic, retain) SQUCategory *category;

@end
