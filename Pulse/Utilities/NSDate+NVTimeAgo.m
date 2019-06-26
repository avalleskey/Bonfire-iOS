//
//  NSDate+NVTimeAgo.m
//  Adventures
//
//  Created by Nikil Viswanathan on 4/18/13.
//  Copyright (c) 2013 Nikil Viswanathan. All rights reserved.
//

#import "NSDate+NVTimeAgo.h"

@implementation NSDate (NVFacebookTimeAgo)


#define SECOND  1
#define MINUTE  (SECOND * 60)
#define HOUR    (MINUTE * 60)
#define DAY     (HOUR   * 24)
#define WEEK    (DAY    * 7)
#define MONTH   (DAY    * 31)
#define YEAR    (DAY    * 365.24)

/*
    Mysql Datetime Formatted As Time Ago
    Takes in a mysql datetime string and returns the Time Ago date format
 */
+ (NSString *)mysqlDatetimeFormattedAsTimeAgo:(NSString *)mysqlDatetime withForm:(TimeAgoForm)form
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    
    NSDate *date = [formatter dateFromString:mysqlDatetime];
    
    return [date formattedAsTimeAgoWithForm:form];
    
}


/*
    Formatted As Time Ago
    Returns the date formatted as Time Ago (in the style of the mobile time ago date formatting for Facebook)
 */
- (NSString *)formattedAsTimeAgoWithForm:(TimeAgoForm)form
{    
    //Now
    NSDate *now = [NSDate date];
    NSTimeInterval secondsSince = -(NSInteger)[self timeIntervalSinceDate:now];
    
    //Should never hit this but handle the future case
    if(secondsSince < 0)
        return @"In The Future";
    
    // < 1 minute = "Just now"
    if(secondsSince < MINUTE)
        return @"1s";
    
    
    // < 1 hour = "x minutes ago"
    if(secondsSince < HOUR)
        return [self formatMinutesAgo:secondsSince withForm:form];
  
    
    // Today = "x hours ago"
    if(secondsSince < DAY)
        return [self formatAsToday:secondsSince withForm:form];
 
    
    // Yesterday = "Yesterday at 1:28 PM"
    if([self isYesterday:now])
        return [self formatAsYesterdayWithForm:form];
  
    
    // < Last 7 days = "Friday at 1:48 AM"
    if([self isLastWeek:secondsSince])
        return [self formatAsLastWeek:secondsSince withForm:form];

    
    // < Last 30 days = "March 30 at 1:14 PM"
    if([self isLastMonth:secondsSince])
        return [self formatAsLastMonthWithForm:form];
    
    // < 1 year = "September 15"
    if([self isLastYear:secondsSince])
        return [self formatAsLastYearWithForm:form];
    
    // Anything else = "September 9, 2011"
    return [self formatAsOther];
    
}



/*
 ========================== Date Comparison Methods ==========================
 */

/*
    Is Same Day As
    Checks to see if the dates are the same calendar day
 */
- (BOOL)isSameDayAs:(NSDate *)comparisonDate
{
    //Check by matching the date strings
    NSDateFormatter *dateComparisonFormatter = [[NSDateFormatter alloc] init];
    [dateComparisonFormatter setDateFormat:@"yyyy-MM-dd"];
    
    //Return true if they are the same
    return [[dateComparisonFormatter stringFromDate:self] isEqualToString:[dateComparisonFormatter stringFromDate:comparisonDate]];
}




/*
 If the current date is yesterday relative to now
 Pasing in now to be more accurate (time shift during execution) in the calculations
 */
- (BOOL)isYesterday:(NSDate *)now
{
    return [self isSameDayAs:[now dateBySubtractingDays:1]];
}


//From https://github.com/erica/NSDate-Extensions/blob/master/NSDate-Utilities.m
- (NSDate *) dateBySubtractingDays: (NSInteger) numDays
{
	NSTimeInterval aTimeInterval = [self timeIntervalSinceReferenceDate] + DAY * -numDays;
	NSDate *newDate = [NSDate dateWithTimeIntervalSinceReferenceDate:aTimeInterval];
	return newDate;
}


/*
    Is Last Week
    We want to know if the current date object is the first occurance of
    that day of the week (ie like the first friday before today 
    - where we would colloquially say "last Friday")
    ( within 6 of the last days)
 
    TODO: make this more precise (1 week ago, if it is 7 days ago check the exact date)
 */
- (BOOL)isLastWeek:(NSTimeInterval)secondsSince
{
    return secondsSince < WEEK;
}


/*
    Is Last Month
    Previous 31 days?
    TODO: Validate on fb
    TODO: Make last day precise
 */
- (BOOL)isLastMonth:(NSTimeInterval)secondsSince
{
    return secondsSince < MONTH;
}


/*
    Is Last Year
    TODO: Make last day precise
 */

- (BOOL)isLastYear:(NSTimeInterval)secondsSince
{
    return secondsSince < YEAR;
}

/*
 =============================================================================
 */





/*
   ========================== Formatting Methods ==========================
 */


// < 1 hour = "x minutes ago"
- (NSString *)formatMinutesAgo:(NSTimeInterval)secondsSince withForm:(TimeAgoForm)form
{
    //Convert to minutes
    int minutesSince = (int)secondsSince / MINUTE;
    
    //Handle Plural
    if (form == TimeAgoShortForm) {
        return [NSString stringWithFormat:@"%dm", minutesSince];
    }
    else {
        return [NSString stringWithFormat:@"%d minute%@ ago", minutesSince, (minutesSince == 1 ? @"" : @"s")];
    }
}


// Today = "xhr"
- (NSString *)formatAsToday:(NSTimeInterval)secondsSince withForm:(TimeAgoForm)form
{
    //Convert to hours
    int hoursSince = (int)secondsSince / HOUR;
    
    if (form == TimeAgoShortForm) {
        return [NSString stringWithFormat:@"%dh", hoursSince];
    }
    else {
        return [NSString stringWithFormat:@"%d hour%@ ago", hoursSince, (hoursSince == 1 ? @"" : @"s")];
    }
}


// Yesterday = "Yesterday"
- (NSString *)formatAsYesterdayWithForm:(TimeAgoForm)form
{
    return [NSString stringWithFormat:(form == TimeAgoShortForm ? @"1d" : @"Yesterday")];
}


// < Last 7 days = "Fri"
- (NSString *)formatAsLastWeek:(NSTimeInterval)secondsSince withForm:(TimeAgoForm)form
{
    //Convert to hours
    int daysSince = (int)secondsSince / DAY;
    
    if (form == TimeAgoShortForm) {
        return [NSString stringWithFormat:@"%dd", daysSince];
    }
    else {
        return [NSString stringWithFormat:@"%d day%@ ago", daysSince, (daysSince == 1 ? @"" : @"s")];
    }
}


// < Last 30 days = "Mar 30"
- (NSString *)formatAsLastMonthWithForm:(TimeAgoForm)form
{
    //Create date formatter
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    //Format
    if (form == TimeAgoShortForm) {
        [dateFormatter setDateFormat:@"MMM d"];
    }
    else {
        [dateFormatter setDateFormat:@"MMMM d"];
    }
    
    return [dateFormatter stringFromDate:self];
}


// < 1 year = "September 15"
- (NSString *)formatAsLastYearWithForm:(TimeAgoForm)form
{
    //Create date formatter
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    //Format
    if (form == TimeAgoShortForm) {
        [dateFormatter setDateFormat:@"MMM YYYY"];
    }
    else {
        [dateFormatter setDateFormat:@"MMMM d, YYYY"];
    }
    
    return [dateFormatter stringFromDate:self];
}


// Anything else = "September 9, 2011"
- (NSString *)formatAsOther
{
    //Create date formatter
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    //Format
    [dateFormatter setDateFormat:@"MM/dd/yyyy"];
    return [dateFormatter stringFromDate:self];
}


/*
 =======================================================================
 */


@end
