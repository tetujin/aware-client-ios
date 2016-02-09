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

/**
 * This method sets application condition (background or foreground).
 *
 * @param state 'YES' is foreground. 'NO' is background.
 */
+ (void)setAppState:(BOOL)state{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:state forKey:@"APP_STATE"];
    if (state) {
        NSLog(@"Application is in the foreground!");
    }else{
        NSLog(@"Application is in the background!");
    }
    
}

+ (BOOL) getAppState {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey:@"APP_STATE"];
}


+ (BOOL)isForeground{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    bool state = [defaults boolForKey:@"APP_STATE"];
    if (state) {
        NSLog(@"Application is in the foreground!");
        return YES;
    }else{
        NSLog(@"Application is in the background!");
        return NO;
   }
}

+ (BOOL)isBackground{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    bool state = [defaults boolForKey:@"APP_STATE"];
    if (state) {
        NSLog(@"Application is in the foreground!");
        return NO;
    }else{
        NSLog(@"Application is in the background!");
        return YES;
    }
}


/**
 Local push notification method
 @param message text message for notification
 @param sound type of sound for notification
 */
+ (void)sendLocalNotificationForMessage:(NSString *)message soundFlag:(BOOL)soundFlag {
    UILocalNotification *localNotification = [UILocalNotification new];
    localNotification.alertBody = message;
    //    localNotification.fireDate = [NSDate date];
    localNotification.repeatInterval = 0;
    if(soundFlag) {
        localNotification.soundName = UILocalNotificationDefaultSoundName;
    }
    localNotification.hasAction = YES;
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}



+ (float) getCurrentOSVersionAsFloat{
    float currentVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    return currentVersion;
}



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


/**
 * http://stackoverflow.com/questions/11197509/ios-how-to-get-device-make-and-model
 */
+ (NSString*) deviceName {
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString* code = [NSString stringWithCString:systemInfo.machine
                                        encoding:NSUTF8StringEncoding];
    
    static NSDictionary* deviceNamesByCode = nil;
    
    if (!deviceNamesByCode) {
        
        deviceNamesByCode = @{@"i386"      :@"Simulator",
                              @"iPod1,1"   :@"iPod Touch",      // (Original)
                              @"iPod2,1"   :@"iPod Touch",      // (Second Generation)
                              @"iPod3,1"   :@"iPod Touch",      // (Third Generation)
                              @"iPod4,1"   :@"iPod Touch",      // (Fourth Generation)
                              @"iPhone1,1" :@"iPhone",          // (Original)
                              @"iPhone1,2" :@"iPhone",          // (3G)
                              @"iPhone2,1" :@"iPhone",          // (3GS)
                              @"iPad1,1"   :@"iPad",            // (Original)
                              @"iPad2,1"   :@"iPad 2",          //
                              @"iPad3,1"   :@"iPad",            // (3rd Generation)
                              @"iPhone3,1" :@"iPhone 4",        // (GSM)
                              @"iPhone3,3" :@"iPhone 4",        // (CDMA/Verizon/Sprint)
                              @"iPhone4,1" :@"iPhone 4s",       //
                              @"iPhone5,1" :@"iPhone 5",        // (model A1428, AT&T/Canada)
                              @"iPhone5,2" :@"iPhone 5",        // (model A1429, everything else)
                              @"iPad3,4"   :@"iPad",            // (4th Generation)
                              @"iPad2,5"   :@"iPad Mini",       // (Original)
                              @"iPhone5,3" :@"iPhone 5c",       // (model A1456, A1532 | GSM)
                              @"iPhone5,4" :@"iPhone 5c",       // (model A1507, A1516, A1526 (China), A1529 | Global)
                              @"iPhone6,1" :@"iPhone 5s",       // (model A1433, A1533 | GSM)
                              @"iPhone6,2" :@"iPhone 5s",       // (model A1457, A1518, A1528 (China), A1530 | Global)
                              @"iPhone7,1" :@"iPhone 6 Plus",   //
                              @"iPhone7,2" :@"iPhone 6",        //
                              @"iPhone8,1" :@"iPhone 6s Plus",   //
                              @"iPhone8,2" :@"iPhone 6s",        //
                              @"iPad4,1"   :@"iPad Air",        // 5th Generation iPad (iPad Air) - Wifi
                              @"iPad4,2"   :@"iPad Air",        // 5th Generation iPad (iPad Air) - Cellular
                              @"iPad4,4"   :@"iPad Mini",       // (2nd Generation iPad Mini - Wifi)
                              @"iPad4,5"   :@"iPad Mini"        // (2nd Generation iPad Mini - Cellular)
                              };
    }
    
    NSString* deviceName = [deviceNamesByCode objectForKey:code];
    
    if (!deviceName) {
        // Not found on database. At least guess main device type from string contents:
        
        if ([code rangeOfString:@"iPod"].location != NSNotFound) {
            deviceName = @"iPod Touch";
        }
        else if([code rangeOfString:@"iPad"].location != NSNotFound) {
            deviceName = @"iPad";
        }
        else if([code rangeOfString:@"iPhone"].location != NSNotFound){
            deviceName = @"iPhone";
        }
    }
    
    if (deviceName == nil) {
        deviceName = @"";
    }
    return deviceName;
}

@end

