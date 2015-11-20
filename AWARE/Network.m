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
    self = [super init];
    if (self) {
        [super setSensorName:sensorName];
        networkState= YES;
        networkType = @0;
        networkSubtype = @"";
    }
    return self;
}

- (BOOL)startSensor:(double)interval withUploadInterval:(double)upInterval{
    NSLog(@"Start Network Sensing!");
    
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
    uploadTimer = [NSTimer scheduledTimerWithTimeInterval:upInterval target:self selector:@selector(uploadSensorData) userInfo:nil repeats:YES];
    
    return YES;
}


- (BOOL)stopSensor{
    [sensingTimer invalidate];
    [uploadTimer invalidate];
    return YES;
}


- (void)uploadSensorData{
    NSString * jsonStr = [self getData:SENSOR_NETWORK withJsonArrayFormat:YES];
    [self insertSensorData:jsonStr withDeviceId:[self getDeviceId] url:[self getInsertUrl:SENSOR_NETWORK]];
}


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
//    NSLog(@"%@",dic);
    
//    NSArray *subviews = [[[[UIApplication sharedApplication] valueForKey:@"statusBar"] valueForKey:@"foregroundView"]subviews];
//    NSNumber *dataNetworkItemView = nil;
//    NSString *provideNameView = @"";
//    for (id subview in subviews) {
//        if([subview isKindOfClass:[NSClassFromString(@"UIStatusBarDataNetworkItemView") class]]) {
//            dataNetworkItemView = subview;
//        }else if([subview isKindOfClass:[NSClassFromString(@"UIStatusBarServiceItemView") class]]){
//            provideNameView = subview;
//        }
//    }
    //    NSString *provideName = [provideNameView valueForKey:@"serviceString"];
    //    NSString *networkTypeName = @"";
    //    NSNumber *networkType = [NSNumber numberWithInteger:[[dataNetworkItemView valueForKey:@"dataNetworkType"] integerValue]];
    //    switch ([networkType intValue]) {
    //        case 0:
    //            networkTypeName = @"No wifi or cellular";
    //            break;
    //        case 1:
    //            networkTypeName = @"2G";
    //            break;
    //        case 2:
    //            networkTypeName = @"3G";
    //            break;
    //        case 3:
    //            networkTypeName = @"4G";
    //            break;
    //        case 4:
    //            networkTypeName = @"LTE";
    //            break;
    //        case 5:
    //            networkTypeName = @"WIFI";
    //            break;
    //        default:
    //            break;
    //    }
}


@end
