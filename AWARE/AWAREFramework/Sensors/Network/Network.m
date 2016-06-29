//
//  Network.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/20/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "Network.h"
#import "SCNetworkReachability.h"
#import "EntityNetwork.h"
#import "AppDelegate.h"

@implementation Network{
    SCNetworkReachability *reachability;
    NSTimer* sensingTimer;
    bool networkState;
    NSNumber* networkType;
    NSString* networkSubtype;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study{
    self = [super initWithAwareStudy:study
                          sensorName:SENSOR_NETWORK
                        dbEntityName:NSStringFromClass([EntityNetwork class])
                              dbType:AwareDBTypeCoreData];
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

- (BOOL)startSensor{
    return [self startSensorWithSettings:nil];
}

- (BOOL)startSensorWithSettings:(NSArray *)settings {
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

                 [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_INTERNET_AVAILABLE object:nil];
                 [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_WIFI_ON object:nil];
                 [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_MOBILE_OFF object:nil];
                 
                 break;
             case SCNetworkStatusReachableViaCellular:
                 NSLog(@"Reachable via Cellular");
                 networkState= YES;
                 networkType = @4;
                 networkSubtype = @"MOBILE";
                 [self getNetworkInfo];
                 
                 [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_INTERNET_AVAILABLE object:nil];
                 [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_WIFI_OFF object:nil];
                 [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_MOBILE_ON object:nil];
                 
                 break;
             case SCNetworkStatusNotReachable:
                 NSLog(@"Not Reachable");
                 networkType = @0;
                 networkState= NO;
                 networkSubtype = @"";
                 [self getNetworkInfo];
                 
                 [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_INTERNET_UNAVAILABLE object:nil];
                 [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_WIFI_OFF object:nil];
                 [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_MOBILE_OFF object:nil];
                 
                 break;
         }
     }];
    return YES;
}


- (BOOL)stopSensor{
    // stop a reachability timer
    reachability = nil;
    
    return YES;
}


//////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////

- (void) getNetworkInfo{
    
    AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
    EntityNetwork* data = (EntityNetwork *)[NSEntityDescription
                                        insertNewObjectForEntityForName:[self getEntityName]
                                        inManagedObjectContext:delegate.managedObjectContext];
    
    data.device_id = [self getDeviceId];
    data.timestamp = [AWAREUtils getUnixTimestamp:[NSDate new]];
    data.network_type = networkType;
    data.network_state = [NSNumber numberWithInt:networkState];
    data.network_subtype = networkSubtype;
    
    [self saveDataToDB];
//    NSError * e = nil;
//    [delegate.managedObjectContext save:&e];
//    if (e) {
//        NSLog(@"%@", e.description);
//    }
    
//    NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
//    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
//    [dic setObject:unixtime forKey:@"timestamp"];
//    [dic setObject:[self getDeviceId] forKey:@"device_id"];
//    [dic setObject:networkType forKey:@"network_type"];
//    [dic setObject:networkSubtype forKey:@"network_subtype"];
//    [dic setObject:[NSNumber numberWithInt:networkState] forKey:@"network_state"];
    [self setLatestValue:[NSString stringWithFormat:@"%@", networkSubtype]];
//    [self saveData:dic toLocalFile:SENSOR_NETWORK];
}


@end
