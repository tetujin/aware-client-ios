//
//  Timezone.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 12/14/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "Timezone.h"
#import "AppDelegate.h"
#import "EntityTimezone.h"
#import "AWAREKeys.h"

@implementation Timezone{
    NSTimer * sensingTimer;
    double defaultInterval;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study{
    self = [super initWithAwareStudy:study
                          sensorName:SENSOR_TIMEZONE
                        dbEntityName:NSStringFromClass([EntityTimezone class])
                              dbType:AwareDBTypeCoreData];
    if (self) {
        defaultInterval = 60*60;// 3600 sec. = 1 hour
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


- (BOOL)startSensorWithSettings:(NSArray *)settings{
    // Get a frequency of data upload from settings
    double frequency = [self getSensorSetting:settings withKey:@"frequency_timezone"];
    if (frequency <= 0) {
        frequency = defaultInterval ;//60*60;//3600 sec = 1 hour
    }
    return [self startSensorWithInterval:frequency];
}


- (BOOL) startSensor{
    return [self startSensorWithInterval:defaultInterval];
}

- (BOOL) startSensorWithInterval:(double)interval{
    // Set and start sensing timer
    NSLog(@"[%@] Start Device Usage Sensor", [self getSensorName]);
    [self getTimezone];
    sensingTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                    target:self
                                                  selector:@selector(getTimezone)
                                                  userInfo:nil
                                                   repeats:YES];
    return YES;
}



- (BOOL)stopSensor{
    // Stop a sync timer
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
    AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
    EntityTimezone* data = (EntityTimezone *)[NSEntityDescription
                                          insertNewObjectForEntityForName:[self getEntityName]
                                          inManagedObjectContext:delegate.managedObjectContext];
    
    data.device_id = [self getDeviceId];
    data.timestamp = unixtime;
    data.timezone = [[NSTimeZone localTimeZone] description];
    
    [self saveDataToDB];

    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:data
                                                         forKey:EXTRA_DATA];
    [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_TIMEZONE
                                                        object:nil
                                                      userInfo:userInfo];

    
//    NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
//    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
//    [dic setObject:unixtime forKey:@"timestamp"];
//    [dic setObject:[self getDeviceId] forKey:@"device_id"];
//    [dic setObject:[[NSTimeZone localTimeZone] description] forKey:@"timezone"];
    [self setLatestValue:[NSString stringWithFormat:@"%@", [[NSTimeZone localTimeZone] description]]];
//    [self saveData:dic];
}

@end
