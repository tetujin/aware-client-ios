//
//  proximity.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 12/14/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "proximity.h"

@implementation Proximity {
//    NSTimer * uploadTimer;
}

- (instancetype)initWithSensorName:(NSString *)sensorName withAwareStudy:(AWAREStudy *)study{
    self = [super initWithSensorName:sensorName withAwareStudy:study];
    if (self) {
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
    // Set and start proximity sensor
    // NOTE: This sensor is not working in the background
    [UIDevice currentDevice].proximityMonitoringEnabled = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(proximitySensorStateDidChange:)
                                                 name:UIDeviceProximityStateDidChangeNotification
                                               object:nil];
    
    // set and start a data upload timer
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
    // Remove a notification event from a default center
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIDeviceProximityStateDidChangeNotification
                                                  object:nil];
    [UIDevice currentDevice].proximityMonitoringEnabled = NO;
    return YES;
}


/////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////


- (void)proximitySensorStateDidChange:(NSNotification *)notification {
    int state = [UIDevice currentDevice].proximityState;
    // NSLog(@"Proximity: %d", state );
    NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setObject:unixtime forKey:@"timestamp"];
    [dic setObject:[self getDeviceId] forKey:@"device_id"];
    [dic setObject:[NSNumber numberWithInt:state] forKey:@"double_proximity"];
    [dic setObject:@0 forKey:@"accuracy"];
    [dic setObject:@"" forKey:@"label"];
    [self setLatestValue:[NSString stringWithFormat:@"[%d]", state ]];
    [self saveData:dic];
}





@end
