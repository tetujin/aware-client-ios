//
//  NTPTime.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 12/14/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "NTPTime.h"
#import "ios-ntp.h"

@implementation NTPTime  {
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
    "drift real default 0," //clocks drift from ntp time
    "ntp_time real default 0," //actual ntp timestamp in milliseconds
    "UNIQUE (timestamp,device_id)";
    [super createTable:query];
}


- (BOOL)startSensor:(double)upInterval withSettings:(NSArray *)settings{
    NSLog(@"[%@] Create Table", [self getSensorName]);
    [self createTable];
    
    NSLog(@"[%@] Start Device Usage Sensor", [self getSensorName]);
    //    [self registerAppforDetectLockState];
//    lastTime = [[[NSDate alloc] init] timeIntervalSince1970];
    
//    netAssociation = [[NetAssociation alloc] initWithServerName:@"time.apple.com"];
//    netAssociation.delegate = self;
    
    sensingTimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                    target:self
                                                  selector:@selector(getNTPTime)
                                                  userInfo:nil
                                                   repeats:YES];
    
    uploadTimer = [NSTimer scheduledTimerWithTimeInterval:upInterval
                                                   target:self
                                                 selector:@selector(syncAwareDB)
                                                 userInfo:nil
                                                  repeats:YES];
    return YES;
}

- (void) getNTPTime {
    NetworkClock * nc = [NetworkClock sharedNetworkClock];
    NSDate * nt = nc.networkTime;
    double offset = nc.networkOffset;
    NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
    NSNumber* unixtime = [NSNumber numberWithDouble:timeStamp];
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setObject:unixtime forKey:@"timestamp"];
    [dic setObject:[self getDeviceId] forKey:@"device_id"];
    [dic setObject:[NSNumber numberWithDouble:offset] forKey:@"drift"]; // real
    [dic setObject:[NSNumber numberWithDouble:nt.timeIntervalSince1970] forKey:@"ntp_time"]; // real
    [self setLatestValue:[NSString stringWithFormat:@"[%f] %@",offset, nt ]];
    [self saveData:dic];
}


- (BOOL)stopSensor{
    [uploadTimer invalidate];
    [sensingTimer invalidate];
    return YES;
}


@end
