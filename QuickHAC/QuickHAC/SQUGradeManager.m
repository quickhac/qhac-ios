//
//  SQUGradeManager.m
//  QuickHAC
//
//  Created by Tristan Seifert on 12/27/13.
//  Copyright (c) 2013 Squee! Apps. All rights reserved.
//

#import "SQUAppDelegate.h"
#import "SQUGradeParser.h"
#import "SQUDistrictManager.h"
#import "SQUCoreData.h"
#import "SQUGradeManager.h"

#import "Lockbox.h"

static SQUGradeManager *_sharedInstance = nil;

@implementation SQUGradeManager
@synthesize student = _student;

#pragma mark - Singleton
+ (SQUGradeManager *) sharedInstance {
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
			_coreDataMOContext = [[SQUAppDelegate sharedDelegate] managedObjectContext];
        }
		
        return self;
    }
}

#pragma mark - Grade updating
/*
 * Logs in and fetches the latest class grades from the server.
 */
- (void) fetchNewClassGradesFromServerWithDoneCallback:(void (^)(NSError *)) callback {
	// Fetch username/pw from keychain
	NSString *username, *password, *studentID;
	
	username = _student.hacUsername;
	password = [Lockbox stringForKey:username];
	studentID = _student.student_id;
	
	[[SQUDistrictManager sharedInstance] checkIfLoggedIn:^(BOOL loggedIn) {
		void (^doGradeChecking)(void) = ^{
			[[SQUDistrictManager sharedInstance] performDisambiguationRequestWithStudentID:studentID andCallback:^(NSError *error, id returnData) {
				if(!error) {
					// We successfully selected this student, so update grades.
					NSLog(@"Disambiguation succeeded");
					
					[[SQUDistrictManager sharedInstance] performAveragesRequestWithCallback:^(NSError *error, id returnData) {
						if(!error) {
							[self updateCurrentStudentWithClassAverages:returnData];
							[[NSNotificationCenter defaultCenter] postNotificationName:SQUGradesDataUpdatedNotification object:nil];
							
							if(callback) callback(nil);
						} else {
							if(callback) callback(error);
							NSLog(@"Error while fetching grades: %@", error);
						}
					}];
				} else {
					UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error Selecting Student", nil) message:error.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
					[alert show];
					
					if(callback) callback(error);
				}
			}];
		};
		
		// If we're logged in, just run the above block.
		if(loggedIn) {
			doGradeChecking();
		} else {
			// Ask the current district instance to do a log in to validate we're still valid
			[[SQUDistrictManager sharedInstance] performLoginRequestWithUser:username usingPassword:password andCallback:^(NSError *error, id returnData){
				if(!error) {
					if(!returnData) {
						// Tell the user what happened
						UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error Authenticating", nil) message:NSLocalizedString(@"Your username or password were rejected by HAC. Please update your password, if it was changed, and try again.", nil) delegate:[SQUAppDelegate sharedDelegate] cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:NSLocalizedString(@"Settings", nil), nil];
						alert.tag = kSQUAlertChangePassword;
						[alert show];
						callback([NSError errorWithDomain:@"SQUInvalidHACUsername" code:kSQUDistrictManagerErrorInvalidDisambiguation userInfo:@{@"localizedDescription" : NSLocalizedString(@"The login was rejected.", nil)}]);
					} else {
						doGradeChecking();
					}
				} else {
					UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error Authenticating", nil) message:error.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
					[alert show];
					if(callback) callback(error);
				}
			}];
		}
	}];
}

#pragma mark - Data retrieval
- (NSOrderedSet *) getCoursesForCurrentStudent {
	return _student.courses;
}

#pragma mark - Database interfacing
/*
 * Checks if the student has a course entry for the specified course.
 */
- (BOOL) classEntryExists:(NSDictionary *) class {
	for(SQUCourse *course in _student.courses) {
		if([course.courseCode isEqualToString:class[@"courseNum"]]) {
			return YES;
		}
	}
	
	return NO;
}

/*
 * Updates a specific cycle with information.
 */
- (void) updateCycle:(SQUCycle *) cycle withCycleInfo:(NSDictionary *) dict {
	cycle.average = [NSNumber numberWithInteger:[dict[@"average"] integerValue]];
	cycle.last_updated = [NSDate new];
	cycle.average = dict[@"average"];
}

#pragma mark - Database updates

/*
 * Updates the database with the specified class averages.
 */
- (void) updateCurrentStudentWithClassAverages:(NSArray *) classAvgs {
	NSAssert(_student != NULL, @"Student may not be NULL");
	NSAssert(classAvgs != NULL, @"Grades may not be NULL");
	
	// Set up variables.
	NSError *err = nil;
	
	// Process each class.
	for(NSDictionary *class in classAvgs) {
		SQUCourse *course;
		
		if([self classEntryExists:class]) {
			// Go through courses on the student record to find course ID
			for(SQUCourse *aCourse in _student.courses) {
				if([aCourse.courseCode isEqualToString:class[@"courseNum"]]) {
					course = aCourse;
				}
			}
			
			NSAssert(course != NULL, @"Course supposedly exists but we can't find it");
		} else {
			// We need to create a new course entry.
			course = [NSEntityDescription insertNewObjectForEntityForName:@"SQUCourse" inManagedObjectContext:_coreDataMOContext];
			course.courseCode = class[@"courseNum"];
			course.title = class[@"title"];
			course.teacher_name = class[@"teacherName"];
			course.teacher_email = class[@"teacherEmail"];
			course.period = class[@"period"];
			course.student = _student;
			
			[_student addCoursesObject:course];

			// Generate empty cycle objects
			NSUInteger numCycles = ([class[@"semesters"] count]) * ([class[@"semesters"][0][@"cycles"] count]);
			NSUInteger cyclesPerSemester = [class[@"semester"][0] count];
			
			for(NSUInteger i = 0; i < numCycles; i++) {
				SQUCycle *cycle = [NSEntityDescription insertNewObjectForEntityForName:@"SQUCycle" inManagedObjectContext:_coreDataMOContext];
				
				cycle.cycleIndex = @(i % cyclesPerSemester);
				cycle.semester = @(i / cyclesPerSemester);
				cycle.course = course;
				
				[course addCyclesObject:cycle];
			}
			
			NSLog(@"Created %i cycles in course %@.", course.cycles.count, course.courseCode);
		}
		
		// There should be an initialised course entity now, so populate the cycles
		NSUInteger i = 0;
		
		for(NSDictionary *semester in class[@"semesters"]) {
			for(NSDictionary *cycle in semester[@"cycles"]) {
				SQUCycle *dbCycle = (SQUCycle *) course.cycles[i];
				[self updateCycle:dbCycle withCycleInfo:cycle];
				i++;
			}
			
			// Take care of the exams here.
			SQUExam *exam;
			
			if(course.exams.count != [class[@"semesters"] count]) {
				exam = [NSEntityDescription insertNewObjectForEntityForName:@"SQUExam" inManagedObjectContext:_coreDataMOContext];
				[course addExamsObject:exam];
			} else {
				exam = course.exams[[semester[@"index"] integerValue]];
			}
			
			exam.isExempt = semester[@"examIsExempt"];
			exam.grade = semester[@"examGrade"];
			exam.semester = semester[@"index"];
		}
		
/*		NSLog(@"Course entry for ID %@: %@", course.courseCode, course);
		NSLog(@"Cycles for course %@: %i\n\tCycle 1:\n%@", course.courseCode, course.cycles.count, course.cycles[0]);
		NSLog(@"Exams for course %@: %i\n\tExam 1:\n%@", course.courseCode, course.exams.count, course.exams[0]);*/
	}
	
	// Write changes to the database.
	if(![_coreDataMOContext save:&err]) {
		NSLog(@"Could not save data: %@", err);
		
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Database Error", nil) message:err.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
		[alert show];
	} else {
		NSLog(@"Saved class averages information.");
	}
}

@end
