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
//    NSTimer* uploadTimer;
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
    // Send a create table query
    NSLog(@"[%@] Cretate Table", [self getSensorName]);
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


- (BOOL)startSensor:(double)upInterval withSettings:(NSArray *)settings {
    // Set and start a network reachability sensor
    NSLog(@"Start Network Sensing!");
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
    
    // Start a data uploader
//    uploadTimer = [NSTimer scheduledTimerWithTimeInterval:upInterval
//                                                   target:self
//                                                 selector:@selector(syncAwareDB)
//                                                 userInfo:nil
//                                                  repeats:YES];
    
    return YES;
}


- (BOOL)stopSensor{
    // Stop a sync timer
//    if (uploadTimer != nil) {
//        [uploadTimer invalidate];
//        uploadTimer = nil;
//    }
    // stop a reachability timer
    reachability = nil;
    
    return YES;
}


//////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////

- (void) getNetworkInfo{
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
