//
//  SQUClassAssignment.h
//  QuickHAC
//
//  Created by Tristan Seifert on 10/09/2013.
//  Copyright (c) 2013 Squee! Apps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class SQUGradeCategory;

@interface SQUClassAssignment : NSManagedObject

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * grade;
@property (nonatomic, retain) NSNumber * weight;
@property (nonatomic, retain) SQUGradeCategory *category;

@end
