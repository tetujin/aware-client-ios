//
//  proximity.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 12/14/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "proximity.h"

@implementation Proximity{
    NSTimer * uploadTimer;
    NSTimer * sensingTimer;
    //    NetAssociation * netAssociation;
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
    "double_proximity real default 0,"
    "accuracy real default 0,"
    "label text default '',"
    "UNIQUE (timestamp,device_id)";
    [super createTable:query];
}


- (BOOL)startSensor:(double)upInterval withSettings:(NSArray *)settings{
    NSLog(@"[%@] Create Table", [self getSensorName]);
    [self createTable];
    
    NSLog(@"[%@] Start Device Usage Sensor", [self getSensorName]);
    
//    double frequency = [self getSensorSetting:settings withKey:@"frequency_proximity"];
//    if ( frequency != -1 ) {
//        NSLog(@"Proximity's frequency is %f !!", frequency);
//        frequency = [self convertMotionSensorFrequecyFromAndroid:frequency];
//        [UIDevice currentDevice].proximityMonitoringEnabled = YES;
//        sensingTimer = [NSTimer scheduledTimerWithTimeInterval:frequency
//                                                        target:self
//                                                      selector:@selector(proximitySensorStateDidChange:)
//                                                      userInfo:nil
//                                                       repeats:YES];
//    } else {
        [UIDevice currentDevice].proximityMonitoringEnabled = YES;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(proximitySensorStateDidChange:)
                                                     name:UIDeviceProximityStateDidChangeNotification
                                                   object:nil];
//    }
    
    // set sync timer
    uploadTimer = [NSTimer scheduledTimerWithTimeInterval:upInterval
                                                   target:self
                                                 selector:@selector(syncAwareDB)
                                                 userInfo:nil
                                                  repeats:YES];
    return YES;
}

- (void)proximitySensorStateDidChange:(NSNotification *)notification {
    //"double_proximity real default 0,"
    //"accuracy real default 0,"
    //"label text default '',"
    int state = [UIDevice currentDevice].proximityState;
    NSLog(@"Proximity: %d", state );
    double timeStamp = [[NSDate date] timeIntervalSince1970] * 1000;
    NSNumber* unixtime = [NSNumber numberWithLong:timeStamp];
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setObject:unixtime forKey:@"timestamp"];
    [dic setObject:[self getDeviceId] forKey:@"device_id"];
    [dic setObject:[NSNumber numberWithInt:state] forKey:@"double_proximity"]; // real
    [dic setObject:@0 forKey:@"accuracy"]; // real
    [dic setObject:@"" forKey:@"label"]; // real
    [self setLatestValue:[NSString stringWithFormat:@"[%d]", state ]];
    [self saveData:dic];
}


- (BOOL)stopSensor{
    [uploadTimer invalidate];
    [sensingTimer invalidate];
    [UIDevice currentDevice].proximityMonitoringEnabled = NO;
    return YES;
}


@end
