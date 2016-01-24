//
//  Timezone.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 12/14/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "Timezone.h"

@implementation Timezone{
    NSTimer * uploadTimer;
    NSTimer * sensingTimer;
}

- (instancetype)initWithSensorName:(NSString *)sensorName{
    self = [super initWithSensorName:sensorName];
    if (self) {
        [super setSensorName:sensorName];
    }
    return self;
}

- (void) createTable{
    NSString *query = [[NSString alloc] init];
    query = @"_id integer primary key autoincrement,"
    "timestamp real default 0,"
    "device_id text default '',"
    "timezone text default '',"
    "UNIQUE (timestamp,device_id)";
    [super createTable:query];
}


- (BOOL)startSensor:(double)upInterval withSettings:(NSArray *)settings{
    NSLog(@"[%@] Create Table", [self getSensorName]);
    [self createTable];
    
    NSLog(@"[%@] Start Device Usage Sensor", [self getSensorName]);

    double frequency = [self getSensorSetting:settings withKey:@"frequency_timezone"];
    if (frequency == -1) {
        frequency = 60*60;//3600 sec = 1 hour
    }
    
    [self getTimezone];
    // set sensing timer
    sensingTimer = [NSTimer scheduledTimerWithTimeInterval:frequency
                                                    target:self
                                                  selector:@selector(getTimezone)
                                                  userInfo:nil
                                                   repeats:YES];
    
    // set sync timer
    uploadTimer = [NSTimer scheduledTimerWithTimeInterval:upInterval
                                                   target:self
                                                 selector:@selector(syncAwareDB)
                                                 userInfo:nil
                                                  repeats:YES];
    return YES;
}

- (void) getTimezone {
    [NSTimeZone localTimeZone];
//    NSLog(@"Timezone: %@", [[NSTimeZone localTimeZone] description]);
//    double timeStamp = [[NSDate date] timeIntervalSince1970] * 1000;
//    NSNumber* unixtime = [NSNumber numberWithLong:timeStamp];
    NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setObject:unixtime forKey:@"timestamp"];
    [dic setObject:[self getDeviceId] forKey:@"device_id"];
    [dic setObject:[[NSTimeZone localTimeZone] description] forKey:@"timezone"]; // real
    [self setLatestValue:[NSString stringWithFormat:@"%@", [[NSTimeZone localTimeZone] description]]];
    [self saveData:dic];
}


- (BOOL)stopSensor{
    [uploadTimer invalidate];
    [sensingTimer invalidate];
    [UIDevice currentDevice].proximityMonitoringEnabled = NO;
    return YES;
}

@end
