//
//  SQUStudent.h
//  QuickHAC
//
//  Created by Tristan Seifert on 12/26/13.
//  Copyright (c) 2013 Squee! Apps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface SQUStudent : NSManagedObject

@property (nonatomic, retain) NSNumber * district;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * student_id;

@end
