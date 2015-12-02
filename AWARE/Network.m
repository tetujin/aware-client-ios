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


- (instancetype)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (instancetype)initWithSensorName:(NSString *)sensorName{
    self = [super initWithSensorName:sensorName];
    if (self) {
        [super setSensorName:sensorName];
        networkState= YES;
        networkType = @0;
        networkSubtype = @"";
    }
    return self;
}

//- (BOOL)startSensor:(double)interval withUploadInterval:(double)upInterval{
- (BOOL)startSensor:(double)upInterval withSettings:(NSArray *)settings {
    NSLog(@"Start Network Sensing!");
    double interval = 1.0f;
    reachability = [[SCNetworkReachability alloc] initWithHost:@"https://github.com"];
    [reachability reachabilityStatus:^(SCNetworkStatus status)
     {
         switch (status)
         {
             case SCNetworkStatusReachableViaWiFi:
                 NSLog(@"Reachable via WiFi");
                 networkState= YES;
                 networkType = @1;
                 networkSubtype = @"WIFI";
                 break;
                 
             case SCNetworkStatusReachableViaCellular:
                 NSLog(@"Reachable via Cellular");
                 networkState= YES;
                 networkType = @4;
                 networkSubtype = @"MOBILE";
                 break;
                 
             case SCNetworkStatusNotReachable:
                 NSLog(@"Not Reachable");
                 networkType = @0;
                 networkState= NO;
                 networkSubtype = @"";
                 break;
         }
     }];
    
    sensingTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(getNetworkInfo) userInfo:nil repeats:YES];
    uploadTimer = [NSTimer scheduledTimerWithTimeInterval:upInterval target:self selector:@selector(syncAwareDB) userInfo:nil repeats:YES];
    
    return YES;
}


- (BOOL)stopSensor{
    [sensingTimer invalidate];
    [uploadTimer invalidate];
    return YES;
}


//- (void)uploadSensorData{
//    [self syncAwareDB];
////    NSString * jsonStr = [self getData:SENSOR_NETWORK withJsonArrayFormat:YES];
////    [self insertSensorData:jsonStr withDeviceId:[self getDeviceId] url:[self getInsertUrl:SENSOR_NETWORK]];
//}


- (void) getNetworkInfo{
    // Save sensor data to the local DB.
    NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
    NSNumber* unixtime = [NSNumber numberWithDouble:timeStamp];
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
