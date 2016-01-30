//
//  AWAREUtils.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 1/23/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AWAREUtils : NSObject

+ (NSString *)getSystemUUID;
+ (NSNumber *) getUnixTimestamp:(NSDate *)nsdate;

+ (NSDate *) getTargetNSDate:(NSDate *) nsDate
                        hour:(int)hour
                     nextDay:(BOOL)nextDay;

+ (NSDate *)getTargetNSDate:(NSDate *)nsDate
                       hour:(int)hour
                     minute:(int)minute
                     second:(int)second
                    nextDay:(BOOL)nextDay;

+ (NSString*) sha1:(NSString*)input;
+ (NSString*) md5:(NSString*)input;
+ (BOOL)validateEmailWithString:(NSString *)str;

@end
