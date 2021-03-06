//
//  SQUGradeManager.m
//  QuickHAC
//
//  Created by Tristan Seifert on 12/27/13.
//  See README.MD for licensing and copyright information.
//

#import <UIKit/UIKit.h>
#import <math.h>

#import "SQUPersistence.h"
#import "SQUDistrictManager.h"
#import "SQUCoreData.h"
#import "SQUGradeManager.h"

#import "Lockbox.h"

static SQUGradeManager *_sharedInstance = nil;

@implementation SQUGradeManager
@synthesize student = _student, currentDriver = _currentDriver;

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
			_coreDataMOContext = [[SQUPersistence sharedInstance] managedObjectContext];
			_gradebookDrivers = [NSMutableArray new];
        }
		
        return self;
    }
}

#pragma mark - Gradebook Driver management
/**
 * Registers a gradebook driver.
 *
 * @param driver: Class to register.
 */
- (void) registerDriver:(Class) driver {
	SQUGradebookDriver *driverInitialised = [[driver alloc] init];
	[_gradebookDrivers addObject:driverInitialised];
	
//	NSLog(@"Loaded gradebook driver %@ (%@)", driver, driverInitialised.identifier);
}

/**
 * Returns an array of SQUGradebookDriver subclasses that have been registered.
 *
 * @return All drivers currently registered.
 */
- (NSArray *) loadedDrivers {
	return [NSArray arrayWithArray:_gradebookDrivers];
}

/**
 * Searches for a gradebook driver with the same identifier, and marks it as
 * the selected one.
 *
 * @param driverID: String identifying the driver.
 * @return YES on success, NO if not found.
 */
- (BOOL) selectDriverWithID:(NSString *) driverID {
	for(SQUGradebookDriver *driver in _gradebookDrivers) {
		if([driver.identifier isEqualToString:driverID]) {
			// we found a matching driver, activate it
			_currentDriver = driver;
			return YES;
		}
	}
	
	NSLog(@"No gradebook driver matched ID '%@'", driverID);
	return NO;
}

#pragma mark - Grade updating
/**
 * Logs in and fetches the latest class grades from the server.
 *
 * @param callback Callback block to be executed depending on requests.
 */
- (void) fetchNewClassGradesFromServerWithDoneCallback:(void (^)(NSError *)) callback {
	// Fetch username/pw from keychain
	NSString *username, *password, *studentID;
	
	SQUStudent *studentToUpdate = _student;
	
	username = studentToUpdate.hacUsername;
	password = [Lockbox stringForKey:username];
	studentID = studentToUpdate.student_id;
	
	[[SQUDistrictManager sharedInstance] checkIfLoggedIn:^(BOOL loggedIn) {
		void (^doGradeChecking)(void) = ^{
			[[SQUDistrictManager sharedInstance] performDisambiguationRequestWithStudentID:studentID andCallback:^(NSError *error, id returnData) {
				if(!error) {
					// We successfully selected this student, so update grades.
					[[SQUDistrictManager sharedInstance] performAveragesRequestWithCallback:^(NSError *error, id returnData) {
						if(!error) {
							// If no return data is specified, this update is ignored
							if(returnData) {
								[self updateStudent:studentToUpdate withClassAverages:returnData];
							}
							
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
						UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error Authenticating", nil) message:NSLocalizedString(@"Your username or password were rejected by HAC. Please update your password, if it was changed, and try again.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
						[alert show];
						callback([NSError errorWithDomain:@"SQUInvalidHACUsername" code:kSQUDistrictManagerErrorInvalidDisambiguation userInfo:@{@"localizedDescription" : NSLocalizedString(@"The login was rejected.", nil)}]);
					} else {
						doGradeChecking();
					}
				} else {
					if(callback) callback(error);
				}
			}];
		}
	}];
}

/**
 * Fetches the grades for a cycle of a class from the server.
 *
 * @param course Course identifier
 * @param cycle Cycle whose grades to retrieve.
 * @param semester Semester in which the cycle is.
 * @param callback Callback block executed in response to the request state.
 */
- (void) fetchNewCycleGradesFromServerForCourse:(NSString *) course withCycle:(NSUInteger) cycle andSemester:(NSUInteger) semester andDoneCallback:(void (^)(NSError *)) callback {
	// Fetch username/pw from keychain
	NSString *username, *password, *studentID;
	
	SQUStudent *studentToUpdate = _student;
	
	username = studentToUpdate.hacUsername;
	password = [Lockbox stringForKey:username];
	studentID = studentToUpdate.student_id;
	
	[[SQUDistrictManager sharedInstance] checkIfLoggedIn:^(BOOL loggedIn) {
		
		void (^doGradeChecking)(void) = ^{
			[[SQUDistrictManager sharedInstance] performDisambiguationRequestWithStudentID:studentID andCallback:^(NSError *error, id returnData) {
				if(!error) {
					// We successfully selected this student, so update grades.
					[[SQUDistrictManager sharedInstance] performClassGradesRequestWithCourseCode:course andCycle:cycle inSemester:semester andCallback:^(NSError *error, id returnData) {
						if(!error) {
							NSDictionary *grades = (NSDictionary *) returnData;
							
							[self updateStudent:studentToUpdate withClassGrades:grades forClass:course andCycle:cycle andSemester:semester];
							[[NSNotificationCenter defaultCenter] postNotificationName:SQUGradesDataUpdatedNotification object:nil];
							
							if(callback) callback(nil);
						} else {
							if(callback) callback(error);
						}
					}];
				} else {
					if(callback) callback(error);
				}
			}];
		};
		
		// If we're logged in, just run the above block.
		if(loggedIn) {
			doGradeChecking();
		} else {
			// NSLog(@"We have to do a login to fetch class grades");
			
			// Ask the current district instance to do a log in to validate we're still valid
			[[SQUDistrictManager sharedInstance] performLoginRequestWithUser:username usingPassword:password andCallback:^(NSError *error, id returnData){
				if(!error) {
					if(!returnData) {
						// Tell the user what happened
						UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error Authenticating", nil) message:NSLocalizedString(@"Your username or password were rejected by HAC. Please update your password, if it was changed, and try again.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
						[alert show];
						callback([NSError errorWithDomain:@"SQUInvalidHACUsername" code:kSQUDistrictManagerErrorInvalidDisambiguation userInfo:@{@"localizedDescription" : NSLocalizedString(@"The login was rejected.", nil)}]);
					} else {
						// NSLog(@"post-login grade overview update");
						
						// Update overall grades to get hashes
						[self fetchNewClassGradesFromServerWithDoneCallback:^(NSError *err) {
							NSLog(@"Overview update completed");
							
							if(!err) {
								// NSLog(@"got hashes");
								doGradeChecking();
							} else {
								if(callback) callback(err);
							}
						}];
					}
				} else {
					if(callback) callback(error);
				}
			}];
		}
	}];
}

#pragma mark - Data retrieval
/**
 * @return The courses the student is enrolled in, according to the last
 * gradebook scrape.
 */
- (NSOrderedSet *) getCoursesForCurrentStudent {
	return _student.courses;
}

#pragma mark - Database interfacing
/**
 * Checks if the student has a course entry for the specified course.
 *
 * This checks through both the course code and the course title.
 */
- (BOOL) classEntryExists:(NSDictionary *) class andStudent:(SQUStudent *) student {
	NSError *err = nil;
	
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity =
	[NSEntityDescription entityForName:@"SQUCourse" inManagedObjectContext:_coreDataMOContext];
	[request setEntity:entity];
	
	// Search by title OR course number, current student, and period
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"((courseCode == %@) OR (title LIKE[c] %@)) AND (student = %@) AND (period = %@)", class[@"courseNum"], class[@"title"], student, class[@"period"]];
	[request setPredicate:predicate];
	
	NSUInteger count = [_coreDataMOContext countForFetchRequest:request error:&err];
	
	if(count != 0) return YES;
	
	return NO;
}

/**
 * Attempts to find a course entity in the database for the specified course.
 *
 * @param class A dictionary describing the course.
 * @return Pointer to the SQUCourse object, or nil.
 */
- (SQUCourse *) courseEntryForClass:(NSDictionary *) class andStudent:(SQUStudent *) student {
	NSError *err = nil;
	
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity =
	[NSEntityDescription entityForName:@"SQUCourse" inManagedObjectContext:_coreDataMOContext];
	[request setEntity:entity];
	
	// Search by title OR course number, current student, and period
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"((courseCode == %@) OR (title LIKE[c] %@)) AND (student = %@) AND (period = %@)", class[@"courseNum"], class[@"title"], student, class[@"period"]];
	[request setPredicate:predicate];
	
	NSArray *matches = [_coreDataMOContext executeFetchRequest:request error:&err];
	
	if(matches.count != 0) {
		return matches[0];
	} else {
		return nil;
	}
}

/**
 * Updates a specific cycle with information.
 */
- (void) updateCycle:(SQUCycle *) cycle withCycleInfo:(NSDictionary *) dict {
	/*
	 * If this grade changed, set a flag that indicates to our notifications
	 * GUI that it did. This flag will be cleared when the user acknowledges the
	 * change by either a) viewing the cycle, or b) tapping the notification in
	 * the notifications drawer.
	 */
	if(cycle.average.floatValue != 0) { // prevent notifications for all grades on first launch
		if(cycle.average.floatValue != [dict[@"average"] floatValue]) {
			cycle.changedSinceLastFetch = @(YES);
			cycle.preChangeGrade = cycle.average;
		}
	}
	
	cycle.last_updated = [NSDate new];
	cycle.average = dict[@"average"];
	
	// Apply the letter grade, if applicable.
	if(dict[@"letterGrade"]) {
		cycle.usesLetterGrades = @YES;
		cycle.letterGrade = dict[@"letterGrade"];
	} else {
		cycle.usesLetterGrades = @NO;
	}
}

#pragma mark - Database updates
/**
 * Updates the assignments associated with a category, by removing the old ones,
 * and re-creating them from the data given.
 */
- (void) updateCategory:(SQUCategory *) category withAssignments:(NSArray *) array {
	/*
	 * Remove old assignments from persistent store, which nullifies the
	 * relationship they had with the category, removing them from the set.
	 */
	for(SQUAssignment *assignment in category.assignments) {
		[_coreDataMOContext deleteObject:assignment];
	}
	
	// Re-create assignments.
	for(NSDictionary *assignment in array) {
		SQUAssignment *dbAssignment = [NSEntityDescription insertNewObjectForEntityForName:@"SQUAssignment" inManagedObjectContext:_coreDataMOContext];
		
		dbAssignment.date_assigned = assignment[@"assignedDate"];
		dbAssignment.date_due = assignment[@"dueDate"];
		dbAssignment.extra_credit = assignment[@"extraCredit"];
		dbAssignment.note = assignment[@"note"];
		dbAssignment.pts_earned = assignment[@"ptsEarned"];
		dbAssignment.pts_possible = assignment[@"ptsPossible"];
		dbAssignment.title = assignment[@"title"];
		dbAssignment.weight = assignment[@"weight"];
		dbAssignment.category = category;
		
		[category addAssignmentsObject:dbAssignment];
	}
}

/**
 * Updates the database with the specified class averages.
 *
 * @param classAvgs Array containing info about the class averages, as output
 * by the gradebook drivers.
 */
- (void) updateStudent:(SQUStudent *) student withClassAverages:(NSArray *) classAvgs {
	_coreDataMOContext = [[SQUPersistence sharedInstance] managedObjectContext];
	
	NSAssert(student != NULL, @"Student may not be NULL");
	NSAssert(classAvgs != NULL, @"Grades may not be NULL");
	
	// Set up variables.
	NSError *err = nil;
	
	// Process each class.
	for(NSDictionary *class in classAvgs) {
		SQUCourse *course;
		
		if([self classEntryExists:class andStudent:student]) {
			course = [self courseEntryForClass:class andStudent:student];
			NSAssert(course != NULL, @"Course supposedly exists but we can't find it");
		} else {
			// We need to create a new course entry.
			course = [NSEntityDescription insertNewObjectForEntityForName:@"SQUCourse" inManagedObjectContext:_coreDataMOContext];
			if([class[@"courseNum"] length] > 0) {
				course.courseCode = class[@"courseNum"];
			}
			
			course.title = class[@"title"];
			course.teacher_name = class[@"teacherName"];
			course.teacher_email = class[@"teacherEmail"];
			course.period = class[@"period"];
			course.student = student;
			
			/*
			 * Attempt to detect if a course is honours or not by checking for
			 * "AP", "IB" or "TAG" in the title, ignoring the case of the text.
			 */
			if(!NSEqualRanges([course.title rangeOfString:@"IB" options:NSCaseInsensitiveSearch], NSMakeRange(NSNotFound, 0))) {
				course.isHonours = @(YES);
			} else if(!NSEqualRanges([course.title rangeOfString:@"AP" options:NSCaseInsensitiveSearch], NSMakeRange(NSNotFound, 0))) {
				course.isHonours = @(YES);
			} else if(!NSEqualRanges([course.title rangeOfString:@"TAG" options:NSCaseInsensitiveSearch], NSMakeRange(NSNotFound, 0))) {
				course.isHonours = @(YES);
			} else {
				course.isHonours = @(NO);
			}
			 
			[student addCoursesObject:course];

			// Generate empty cycle objects
			NSUInteger numCycles = ([class[@"semesters"] count]) * ([class[@"semesters"][0][@"cycles"] count]);
			NSUInteger cyclesPerSemester = [class[@"semesters"][0][@"cycles"] count];
			
			student.cyclesPerSemester = @(cyclesPerSemester);
			student.numSemesters = @([class[@"semesters"] count]);

			for(NSUInteger i = 0; i < numCycles; i++) {
				SQUCycle *cycle = [NSEntityDescription insertNewObjectForEntityForName:@"SQUCycle" inManagedObjectContext:_coreDataMOContext];
				
				cycle.cycleIndex = @(i);
				cycle.semester = @(i / cyclesPerSemester);
				cycle.course = course;
				
				[course addCyclesObject:cycle];
			}
			
			// NSLog(@"Created %i cycles in course %@.", course.cycles.count, course.courseCode);
		}
		
		// If the course code is nil, try to find it
		if(!course.courseCode) {
			NSLog(@"Could not find course code for `%@`", course.title);
			if([class[@"courseNum"] length] > 0) {
				course.courseCode = class[@"courseNum"];
			}
		}
		
		// Check which cycles have data available
		NSArray *dataAvailableForCycle = [[SQUDistrictManager sharedInstance] cyclesWithDataAvailableForCourse:course.courseCode];
		
		// There should be an initialised course entity now, so populate the cycles
		NSUInteger i = 0;
		
		for(NSDictionary *semester in class[@"semesters"]) {
			for(NSDictionary *cycle in semester[@"cycles"]) {
				SQUCycle *dbCycle = (SQUCycle *) course.cycles[i];
				
				// Iterate through the cycle availability array
				for(NSNumber *cycleNum in dataAvailableForCycle) {
					if(cycleNum.unsignedIntegerValue == i) {
						dbCycle.dataAvailableInGradebook = @(YES);
						break;
					}
				}
				
				// Update cycle data
				[self updateCycle:dbCycle withCycleInfo:cycle];
				i++;
			}
			
			// Take care of the exams here.
			SQUSemester *dbSemester;
			
			if(course.semesters.count != [class[@"semesters"] count]) {
				dbSemester = [NSEntityDescription insertNewObjectForEntityForName:@"SQUSemester" inManagedObjectContext:_coreDataMOContext];
				[course addSemestersObject:dbSemester];
			} else {
				dbSemester = course.semesters[[semester[@"index"] integerValue]];
			}
			
			// Set a flag if this grade changed
			if(!dbSemester.average.floatValue != [semester[@"semesterAverage"] floatValue]) {
				dbSemester.changedSinceLastFetch = @(YES);
				dbSemester.preChangeGrade = @(dbSemester.average.floatValue);
			} else {
				dbSemester.changedSinceLastFetch = @(NO);
			}
			
			dbSemester.examIsExempt = semester[@"examIsExempt"];
			dbSemester.examGrade = semester[@"examGrade"];
			dbSemester.semester = semester[@"index"];
			dbSemester.average = semester[@"semesterAverage"];
		}

/*		NSLog(@"Course entry for ID %@: %@", course.courseCode, course);
		NSLog(@"Cycles for course %@: %i\n\tCycle 1:\n%@", course.courseCode, course.cycles.count, course.cycles[0]);
		NSLog(@"Exams for course %@: %i\n\tExam 1:\n%@", course.courseCode, course.exams.count, course.exams[0]);*/
	}
	
	// Sort the classes by the period code.
	NSSortDescriptor *periodSort = [NSSortDescriptor sortDescriptorWithKey:@"period" ascending:YES];
	[student.courses sortedArrayUsingDescriptors:@[periodSort]];
	student.courses = [NSOrderedSet orderedSetWithArray:[student.courses sortedArrayUsingDescriptors:@[periodSort]]];
	
	// Set "last updated" date
	student.lastAveragesUpdate = [NSDate new];
	
	// Write changes to the database.
	if(![_coreDataMOContext save:&err]) {
		NSLog(@"Could not save class averages data: %@", err);
		
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Database Error", nil) message:err.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
		[alert show];
	} else {
		// NSLog(@"Saved class averages information.");
	}
}

/**
 * Update assignments and grades for a course during a specific cycle in the
 * specified semester.
 *
 * @param classGrades Grades for a particular class, as output by gradebook
 * parsers.
 * @param class Class identifier of the class the grades belong to.
 * @param numCycle Cycle in which the grades are.
 * @param numSemester Semester in which the grades are.
 */
- (void) updateStudent:(SQUStudent *) student withClassGrades:(NSDictionary *) classGrades forClass:(NSString *) class andCycle:(NSUInteger) numCycle andSemester:(NSUInteger) numSemester {
	_coreDataMOContext = [[SQUPersistence sharedInstance] managedObjectContext];
	
	NSUInteger cycleOffset = numCycle + (numSemester * 3);
	SQUCourse *course = nil;
	NSError *err = nil;
	
	// Locate the course
	for(SQUCourse *dbCourse in student.courses) {
		if([dbCourse.courseCode isEqualToString:class]) {
			course = dbCourse;
			break;
		}
	}
	
	if(!course) return;
	
	// Fetch the cycle.
	SQUCycle *cycle = course.cycles[cycleOffset];
	NSUInteger numCategories = [classGrades[@"categories"] count];
	
	// Create the necessary SQUCategory instances
	if(cycle.categories.count == 0) {
		for(NSUInteger i = 0; i < numCategories; i++) {
			SQUCategory *category = [NSEntityDescription insertNewObjectForEntityForName:@"SQUCategory"
																  inManagedObjectContext:_coreDataMOContext];
			[cycle addCategoriesObject:category];
			category.title = classGrades[@"categories"][i][@"name"];
			category.cycle = cycle;
			
			[cycle addCategoriesObject:category];
		}
	}
	
	// Loop through the categories in the array
	for(NSDictionary *category in classGrades[@"categories"]) {
		NSFetchRequest *request = [[NSFetchRequest alloc] init];
		NSEntityDescription *entity =
		[NSEntityDescription entityForName:@"SQUCategory" inManagedObjectContext:_coreDataMOContext];
		[request setEntity:entity];
		
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(cycle == %@) AND (title LIKE[c] %@)",
								  cycle, category[@"name"]];
		[request setPredicate:predicate];
		
		NSArray *array = [_coreDataMOContext executeFetchRequest:request error:&err];

		if(array && array.count > 0) {
			// Set up the weight
			SQUCategory *dbCategory = array[0];
			dbCategory.weight = category[@"weight"];
			dbCategory.average = category[@"average"];
			dbCategory.is100PtsBased = category[@"is100PtsBased"];
			
			// Update assignments
			[self updateCategory:dbCategory withAssignments:category[@"assignments"]];
		} else if(array && array.count == 0) {
			// The teacher added a category
			
			SQUCategory *dbCategory = [NSEntityDescription insertNewObjectForEntityForName:@"SQUCategory"
																	inManagedObjectContext:_coreDataMOContext];
			[cycle addCategoriesObject:dbCategory];
			dbCategory.title = category[@"name"];
			dbCategory.cycle = cycle;
			
			[cycle addCategoriesObject:dbCategory];
			
			// Update assignments
			[self updateCategory:dbCategory withAssignments:category[@"assignments"]];
		} else {
			NSLog(@"Error fetching category: %@", err);
			
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Database Error", nil) message:err.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
			[alert show];
			
			return;
		}
	}
	
	cycle.last_updated = [NSDate new];
	
	// Write changes to the database.
	if(![_coreDataMOContext save:&err]) {
		NSLog(@"Could not save grades for class %@, cycle %lu semester %lu",
			  class, (unsigned long) (numCycle + 1), (unsigned long) (numSemester + 1));
		
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Database Error", nil) message:err.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
		[alert show];
	} else {
		// NSLog(@"Saved grades for class %@, cycle %u semester %u.", class, numCycle+1, numSemester+1);
	}
}

/**
 * Converts a name in the "Last, First" format to the "First Last" format.
 */
+ (NSString *) convertGradebookToHumanNames:(NSString *) name {
	NSArray *c = [name componentsSeparatedByString: @","];
	NSString *f = [[c objectAtIndex:1] stringByAppendingString:@" "];
	NSString *l = [c objectAtIndex:0];
	NSString *n = [f stringByAppendingString:l];
	NSCharacterSet *trimBy = [NSCharacterSet whitespaceCharacterSet];
	return [n stringByTrimmingCharactersInSet:trimBy];
}

#pragma mark - Student management
/**
 * Updates the selected student. Passing `nil` causes the preference to be
 * deleted from the user default store.
 *
 * @param student The student to select.
 */
- (void) changeSelectedStudent:(SQUStudent *) student {
	if(student) {
		NSManagedObjectID *objID = student.objectID;
		NSString *str = objID.URIRepresentation.absoluteString;
		
		[[NSUserDefaults standardUserDefaults] setObject:str forKey:@"currentStudent"];
		[[NSUserDefaults standardUserDefaults] synchronize];
	} else {
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"currentStudent"];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
	
	//NSLog(@"Changed selected student: %@", str);
}

/**
 * Reads the user defaults for the current student.
 *
 * @return The SQUStudent object of the active student, or nil if it hasn't been set
 */
- (SQUStudent *) getSelectedStudent {
	NSString *objectID = [[NSUserDefaults standardUserDefaults] objectForKey:@"currentStudent"];
	//NSLog(@"Selected student: %@", objectID);
	if(!objectID) return nil;
	
	NSManagedObjectID *id = [[SQUPersistence sharedInstance].persistentStoreCoordinator managedObjectIDForURIRepresentation:[NSURL URLWithString:objectID]];
	return (SQUStudent *) [[SQUPersistence sharedInstance].managedObjectContext objectWithID:id];
}

/**
 * Sets the current student.
 */
- (void) setStudent:(SQUStudent *) student {
	// Different HAC usernames?
	if(![student.hacUsername isEqualToString:_student.hacUsername]) {
		// Clear munchies.
		NSArray *munchies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
		for (NSHTTPCookie *cookie in munchies) {
			[[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
		}
		
		// Require login
		[[SQUDistrictManager sharedInstance] setNeedsRelogon];
	}
	
	// Set student
	_student = student;
}

@end
