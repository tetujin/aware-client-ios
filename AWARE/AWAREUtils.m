//
//  AWAREUtils.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 1/23/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWAREUtils.h"

@implementation AWAREUtils

+ (NSNumber *)getUnixTimestamp:(NSDate *)nsdate{
    NSTimeInterval timeStamp = [nsdate timeIntervalSince1970] * 1000;
//    double errorValue = [nsdate timeIntervalSince1970] * 1000;
    NSNumber* unixtime = [NSNumber numberWithLongLong:timeStamp];
    return unixtime;
}


+ (NSDate *)getTargetNSDate:(NSDate *)nsDate hour:(int)hour nextDay:(BOOL)nextDay{
    return [self getTargetNSDate:nsDate hour:hour minute:0 second:0 nextDay:nextDay];
}


+ (NSDate *) getTargetNSDate:(NSDate *) nsDate
                              hour:(int) hour
                            minute:(int) minute
                            second:(int) second
                           nextDay:(BOOL)nextDay {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dateComps = [calendar components:NSYearCalendarUnit |
                                   NSMonthCalendarUnit  |
                                   NSDayCalendarUnit    |
                                   NSHourCalendarUnit   |
                                   NSMinuteCalendarUnit |
                                   NSSecondCalendarUnit fromDate:nsDate];
    [dateComps setDay:dateComps.day];
    [dateComps setHour:hour];
    [dateComps setMinute:minute];
    [dateComps setSecond:second];
    NSDate * targetNSDate = [calendar dateFromComponents:dateComps];
    //    return targetNSDate;
    
    if (nextDay) {
        if ([targetNSDate timeIntervalSince1970] < [nsDate timeIntervalSince1970]) {
            [dateComps setDay:dateComps.day + 1];
            NSDate * tomorrowNSDate = [calendar dateFromComponents:dateComps];
            return tomorrowNSDate;
        }else{
            return targetNSDate;
        }
    }else{
        return targetNSDate;
    }
}

@end

