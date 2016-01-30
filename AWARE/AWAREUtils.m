//
//  AWAREUtils.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 1/23/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWAREUtils.h"
#import <CommonCrypto/CommonDigest.h>
#import <UIKit/UIKit.h>
#import <sys/utsname.h>

@implementation AWAREUtils


+ (NSString *)getSystemUUID {
    NSString * uuid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    uuid = [uuid lowercaseString];
    return uuid;
}

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

/**
 * The methods from http://www.makebetterthings.com/iphone/how-to-get-md5-and-sha1-in-objective-c-ios-sdk/
 */
+ (NSString*) sha1:(NSString*)input
{
    NSLog(@"Before: %@", input);
    const char *cstr = [input cStringUsingEncoding:NSUTF8StringEncoding];
    NSData *data = [NSData dataWithBytes:cstr length:input.length];
    
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    
    CC_SHA1(data.bytes, data.length, digest);
    
    NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    
    NSLog(@"After: %@", output);
    
    return output;
    
}

+ (NSString *) md5:(NSString *) input
{
    const char *cStr = [input UTF8String];
    unsigned char digest[16];
    CC_MD5( cStr, strlen(cStr), digest ); // This is the md5 call
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    
    return  output;
}

+ (BOOL)validateEmailWithString:(NSString *)str
{
    if (!str || [str length] == 0) {
        return NO;
    }
    
    BOOL stricterFilter = NO;
    
    NSString *stricterFilterString = @"[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}";
    NSString *laxString = @".+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2}[A-Za-z]*";
    NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];

    return [emailTest evaluateWithObject:str];
}

@end

