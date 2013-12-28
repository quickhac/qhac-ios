//
//  SQUGradeManager.h
//  QuickHAC
//
//  Created by Tristan Seifert on 12/27/13.
//  Copyright (c) 2013 Squee! Apps. All rights reserved.
//

#import <Foundation/Foundation.h>

#define SQUGradesDataUpdatedNotification @"SQUGradesDataUpdatedNotification"

@class SQUStudent;
@interface SQUGradeManager : NSObject {
	SQUStudent *_student;
	
	NSManagedObjectContext *_coreDataMOContext;
}

@property (nonatomic, readwrite, strong) SQUStudent *student;

+ (SQUGradeManager *) sharedInstance;

- (NSOrderedSet *) getCoursesForCurrentStudent;

- (void) fetchNewClassGradesFromServerWithDoneCallback:(void (^)(NSError *)) callback;
- (void) updateCurrentStudentWithClassAverages:(NSArray *) classAvgs;

@end
