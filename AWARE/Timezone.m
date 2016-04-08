//
//  Timezone.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 12/14/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "Timezone.h"

@implementation Timezone{
//    NSTimer * uploadTimer;
    NSTimer * sensingTimer;
}

- (instancetype)initWithSensorName:(NSString *)sensorName withAwareStudy:(AWAREStudy *)study{
    self = [super initWithSensorName:sensorName withAwareStudy:study];
    
    if (self) {
    }
    return self;
}

- (void) createTable{
    NSLog(@"[%@] Create Table", [self getSensorName]);
    NSString *query = [[NSString alloc] init];
    query = @"_id integer primary key autoincrement,"
    "timestamp real default 0,"
    "device_id text default '',"
    "timezone text default '',"
    "UNIQUE (timestamp,device_id)";
    [super createTable:query];
}


- (BOOL)startSensor:(double)upInterval withSettings:(NSArray *)settings{
    // Get a frequency of data upload from settings
    double frequency = [self getSensorSetting:settings withKey:@"frequency_timezone"];
    if (frequency == -1) {
        frequency = 60*60;//3600 sec = 1 hour
    }
    
    // Set and start sensing timer
    NSLog(@"[%@] Start Device Usage Sensor", [self getSensorName]);
    [self getTimezone];
    sensingTimer = [NSTimer scheduledTimerWithTimeInterval:frequency
                                                    target:self
                                                  selector:@selector(getTimezone)
                                                  userInfo:nil
                                                   repeats:YES];
    
    // Set and start sync timer
//    uploadTimer = [NSTimer scheduledTimerWithTimeInterval:upInterval
//                                                   target:self
//                                                 selector:@selector(syncAwareDB)
//                                                 userInfo:nil
//                                                  repeats:YES];
    return YES;
}

- (BOOL)stopSensor{
    // Stop a sync timer
//    [uploadTimer invalidate];
//    uploadTimer = nil;
    // Stop a sensing timer
    [sensingTimer invalidate];
    sensingTimer = nil;
    [UIDevice currentDevice].proximityMonitoringEnabled = NO;
    return YES;
}



/////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////


- (void) getTimezone {
    [NSTimeZone localTimeZone];
    NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setObject:unixtime forKey:@"timestamp"];
    [dic setObject:[self getDeviceId] forKey:@"device_id"];
    [dic setObject:[[NSTimeZone localTimeZone] description] forKey:@"timezone"];
    [self setLatestValue:[NSString stringWithFormat:@"%@", [[NSTimeZone localTimeZone] description]]];
    [self saveData:dic];
}

@end
