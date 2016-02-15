//
//  Network.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/20/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "Network.h"
#import "SCNetworkReachability.h"

@implementation Network{
    SCNetworkReachability *reachability;
    NSTimer* uploadTimer;
    NSTimer* sensingTimer;
    bool networkState;
    NSNumber* networkType;
    NSString* networkSubtype;
}

- (instancetype)initWithSensorName:(NSString *)sensorName withAwareStudy:(AWAREStudy *)study{
    self = [super initWithSensorName:sensorName withAwareStudy:study];
    if (self) {
        networkState= YES;
        networkType = @0;
        networkSubtype = @"";
    }
    return self;
}


- (void) createTable{
    NSString *query = [[NSString alloc] init];
    query = @"_id integer primary key autoincrement,"
    "timestamp real default 0,"
    "device_id text default '',"
    "network_type integer default 0,"
    "network_subtype text default '',"
    "network_state integer default 0,"
    "UNIQUE (timestamp,device_id)";
    [super createTable:query];
}


//- (BOOL)startSensor:(double)interval withUploadInterval:(double)upInterval{
- (BOOL)startSensor:(double)upInterval withSettings:(NSArray *)settings {
    // crate table
    NSLog(@"[%@] Cretate Table", [self getSensorName]);
    [self createTable];
    
    // start sensor
    NSLog(@"Start Network Sensing!");
//    double interval = 60.0f;
    reachability = [[SCNetworkReachability alloc] initWithHost:@"https://github.com"];
    [reachability reachabilityStatus:^(SCNetworkStatus status) {
         switch (status) {
             case SCNetworkStatusReachableViaWiFi:
                 NSLog(@"Reachable via WiFi");
                 networkState= YES;
                 networkType = @1;
                 networkSubtype = @"WIFI";
                 [self getNetworkInfo];
                 break;
                 
             case SCNetworkStatusReachableViaCellular:
                 NSLog(@"Reachable via Cellular");
                 networkState= YES;
                 networkType = @4;
                 networkSubtype = @"MOBILE";
                 [self getNetworkInfo];
                 break;
                 
             case SCNetworkStatusNotReachable:
                 NSLog(@"Not Reachable");
                 networkType = @0;
                 networkState= NO;
                 networkSubtype = @"";
                 [self getNetworkInfo];
                 break;
         }
     }];
    
//    sensingTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(getNetworkInfo) userInfo:nil repeats:YES];
    uploadTimer = [NSTimer scheduledTimerWithTimeInterval:upInterval target:self selector:@selector(syncAwareDB) userInfo:nil repeats:YES];
    
    return YES;
}


- (BOOL)stopSensor{
//    [sensingTimer invalidate];
    [uploadTimer invalidate];
    return YES;
}


- (void) getNetworkInfo{
    // Save sensor data to the local DB.
//    double timeStamp = [[NSDate date] timeIntervalSince1970] * 1000;
//    NSNumber* unixtime = [NSNumber numberWithLong:timeStamp];
    NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setObject:unixtime forKey:@"timestamp"];
    [dic setObject:[self getDeviceId] forKey:@"device_id"];
    [dic setObject:networkType forKey:@"network_type"];
    [dic setObject:networkSubtype forKey:@"network_subtype"];
    [dic setObject:[NSNumber numberWithInt:networkState] forKey:@"network_state"];
    [self setLatestValue:[NSString stringWithFormat:@"%@", networkSubtype]];
    [self saveData:dic toLocalFile:SENSOR_NETWORK];
}


@end
