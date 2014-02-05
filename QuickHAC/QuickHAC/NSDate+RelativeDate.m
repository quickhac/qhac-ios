//
//  NSDate+RelativeDate.m
//  QuickHAC
//
//  Created by Tristan Seifert on 1/6/14.
//  See README.MD for licensing and copyright information.
//

#pragma mark Constants
#define SECOND  1
#define MINUTE  (SECOND * 60)
#define HOUR    (MINUTE * 60)
#define DAY     (HOUR   * 24)
#define WEEK	(DAY    * 7)
#define MONTH   (DAY    * 31)
#define YEAR    (DAY    * 365.24)

#import "NSDate+RelativeDate.h"

#pragma mark - Private methods
@interface NSDate (RelativeDate_Private)

- (BOOL) isSameDayAs:(NSDate *) comparisonDate;
- (BOOL) isYesterday:(NSDate *) now;
- (BOOL) isLastWeek:(NSTimeInterval) secondsSince;
- (BOOL) isLastMonth:(NSTimeInterval) secondsSince;
- (BOOL) isLastYear:(NSTimeInterval) secondsSince;

- (NSString *) formatSecondsAgo:(NSTimeInterval) secondsSince;
- (NSString *) formatMinutesAgo:(NSTimeInterval) secondsSince;
- (NSString *) formatAsToday:(NSTimeInterval) secondsSince;
- (NSString *) formatAsYesterday;
- (NSString *) formatAsLastWeek;
- (NSString *) formatAsLastMonth;
- (NSString *) formatAsLastYear;
- (NSString *) formatAsOther;

@end

#pragma mark - Relative date category
@implementation NSDate (RelativeDate)

/**
 * Returns the date formatted as a relative date, e.g. "Yesterday at 1:28 PM" or
 * "3 minutes ago."
 *
 * @return The above relative date string.
 */
- (NSString *) relativeDate {
    NSDate *now = [NSDate date];
    NSTimeInterval secondsSince = -(int) [self timeIntervalSinceDate:now];
    
    // < 1 minute = "Just now"
    if(secondsSince < MINUTE) {
        return [self formatSecondsAgo:secondsSince];
	} else if(secondsSince < HOUR) { // x minutes ago
        return [self formatMinutesAgo:secondsSince];
	} else if([self isSameDayAs:now]) { // x hours ago
        return [self formatAsToday:secondsSince];
	} else if([self isYesterday:now]) { // Yesterday at 1:28 PM
        return [self formatAsYesterday];
	} else if([self isLastWeek:secondsSince]) { // Friday at 1:48 AM
        return [self formatAsLastWeek];
	} else if([self isLastMonth:secondsSince]) { // March 30 at 1:14 PM
        return [self formatAsLastMonth];
	} else if([self isLastYear:secondsSince]) { // September 15
        return [self formatAsLastYear];
	} else { // September 9, 2011
		return [self formatAsOther];
	}
    
}

#pragma mark Helper Methods
/**
 * Determines if the date is the same day as the specified one.
 */
- (BOOL) isSameDayAs:(NSDate *) comparisonDate {
    NSDateFormatter *dateComparisonFormatter = [[NSDateFormatter alloc] init];
    [dateComparisonFormatter setDateFormat:@"yyyy-MM-dd"];
    
    //Return true if they are the same
    return [[dateComparisonFormatter stringFromDate:self] isEqualToString:[dateComparisonFormatter stringFromDate:comparisonDate]];
}

/**
 * Determines if this date is yesterday compared to now.
 */
- (BOOL) isYesterday:(NSDate *) now {
    return [self isSameDayAs:[now dateBySubtractingDays:1]];
}

- (NSDate *) dateBySubtractingDays: (NSInteger) numDays {
	NSTimeInterval aTimeInterval = [self timeIntervalSinceReferenceDate] + DAY * -numDays;
	NSDate *newDate = [NSDate dateWithTimeIntervalSinceReferenceDate:aTimeInterval];
	return newDate;
}

/**
 * Determines if the time interval is less than a week.
 */
- (BOOL) isLastWeek:(NSTimeInterval) secondsSince {
    return secondsSince < WEEK;
}

/**
 * Determines if the time interval is less than a month.
 */
- (BOOL) isLastMonth:(NSTimeInterval) secondsSince {
    return secondsSince < MONTH;
}

/**
 * Determines if the time interval is less than a year.
 */
- (BOOL) isLastYear:(NSTimeInterval) secondsSince {
    return secondsSince < YEAR;
}

#pragma mark Formatting methods
/**
 * Formats a date less than 1 minute ago as "42 seconds ago"
 */
- (NSString *) formatSecondsAgo:(NSTimeInterval) secondsSince {
    if(secondsSince == 0) {
        return NSLocalizedString(@"Just Now", @"relative date seconds ago");
    } else if(secondsSince == 1) {
        return NSLocalizedString(@"1 second ago", @"relative date seconds ago");
    } else {
        return [NSString stringWithFormat:NSLocalizedString(@"%d seconds ago", @"relative date seconds ago"), (int) secondsSince];
	}
}

/**
 * Formats a date less than 60 minutes ago as "42 minutes ago"
 */
- (NSString *) formatMinutesAgo:(NSTimeInterval) secondsSince {
    // Convert to minutes
    int minutesSince = (int) secondsSince / MINUTE;
    
    // Handle Plural
    if(minutesSince == 1) {
        return NSLocalizedString(@"1 minute ago", @"relative date minutes ago");
    } else {
        return [NSString stringWithFormat:NSLocalizedString(@"%d minutes ago", @"relative date minutes ago"), minutesSince];
	}
}


/**
 * Formats a date less than 24 hours ago as "2 hours ago"
 */
- (NSString *) formatAsToday:(NSTimeInterval) secondsSince {
    int hoursSince = (int) secondsSince / HOUR;
    
    // Handle Plural
    if(hoursSince == 1) {
        return NSLocalizedString(@"1 hour ago", @"relative date hours ago");
    } else {
        return [NSString stringWithFormat:NSLocalizedString(@"%d hours ago", @"relative date hours ago"), hoursSince];
	}
}


/**
 * Formats a date yesterday as "Yesterday at 1:28 PM"
 */
- (NSString *) formatAsYesterday {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    // Format
    [dateFormatter setDateFormat:NSLocalizedString(@"'Yesterday at' h:mm a", @"relative date yesterday")];
    return [dateFormatter stringFromDate:self];
}


/**
 * Formats a date within the last week as "Friday at 1:48 AM"
 */
- (NSString *) formatAsLastWeek {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	
    // Format
    [dateFormatter setDateFormat:NSLocalizedString(@"EEEE 'at' h:mm a", @"relative date last week")];
    return [dateFormatter stringFromDate:self];
}


/**
 * Formats a date less than two months ago as "March 30 at 1:14 PM".
 */
- (NSString *) formatAsLastMonth {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    // Format
    [dateFormatter setDateFormat:NSLocalizedString(@"MMMM d 'at' h:mm a", @"relative date last month")];
    return [dateFormatter stringFromDate:self];
}


/**
 * Formats a date less than a year ago as "September 9"
 */
- (NSString *) formatAsLastYear {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    // Format
    [dateFormatter setDateFormat:NSLocalizedString(@"MMMM d", @"relative date last year")];
    return [dateFormatter stringFromDate:self];
}


/**
 * Formats a date in "September 9, 2009" format.
 */
- (NSString *) formatAsOther {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    // Format
    [dateFormatter setDateFormat:NSLocalizedString(@"LLLL d, yyyy", @"relative date")];
    return [dateFormatter stringFromDate:self];
}

@end