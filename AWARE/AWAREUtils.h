//
//  AWAREUtils.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 1/23/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AWAREUtils : NSObject

// Application state (foreground or background)
+ (void) setAppState:(BOOL)state;
+ (BOOL) getAppState;
+ (BOOL) isForeground;
+ (BOOL) isBackground;

// Notification
+ (void)sendLocalNotificationForMessage:(NSString *)message soundFlag:(BOOL)soundFlag;

// Device information
+ (float) getCurrentOSVersionAsFloat;
+ (NSString *)getSystemUUID;
+ (NSString*) deviceName;

// Date Controller
+ (NSNumber *) getUnixTimestamp:(NSDate *)nsdate;
+ (NSDate *) getTargetNSDate:(NSDate *) nsDate
                        hour:(int)hour
                     nextDay:(BOOL)nextDay;
+ (NSDate *)getTargetNSDate:(NSDate *)nsDate
                       hour:(int)hour
                     minute:(int)minute
                     second:(int)second
                    nextDay:(BOOL)nextDay;

// Hash Methods
+ (NSString*) sha1:(NSString*)input;
+ (NSString*) md5:(NSString*)input;

// Format checker
+ (BOOL)validateEmailWithString:(NSString *)str;

@end
