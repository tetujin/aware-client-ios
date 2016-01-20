//
//  Telephony.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 1/19/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "Telephony.h"

@implementation Telephony {
    NSTimer * timer;
}


- (instancetype)initWithSensorName:(NSString *)sensorName{
    self = [super initWithSensorName:sensorName ];
    if (self) {

    }
    return self;
}

- (void) createTable{
//    NSString *query = [[NSString alloc] init];
//    query = @"_id integer primary key autoincrement,"
//    "timestamp real default 0,"
//    "device_id text default '',"
//    "double_values_0 real default 0,"
//    "double_values_1 real default 0,"
//    "double_values_2 real default 0,"
//    "accuracy integer default 0,"
//    "label text default '',"
//    "UNIQUE (timestamp,device_id)";
//    [super createTable:query];
}

-(BOOL)startSensor:(double)upInterval withSettings:(NSArray *)settings{
//    NSLog(@"[%@] Create Telephony Sensor Table", [self getSensorName]);
//    [self createTable];
//    
//    NSLog(@"[%@] Start Telephony Sensor!", [self getSensorName]);
//    timer = [NSTimer scheduledTimerWithTimeInterval:upInterval
//                                             target:self selector:@selector(syncAwareDB) userInfo:nil repeats:YES];
//    
    
    
//    double timeStamp = [[NSDate date] timeIntervalSince1970] * 1000;
//    NSNumber* unixtime = [NSNumber numberWithLong:timeStamp];
//    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
//    [dic setObject:unixtime forKey:@"timestamp"];
//    [dic setObject:[self getDeviceId] forKey:@"device_id"];
//    [dic setObject:[NSNumber numberWithDouble:accelerometerData.acceleration.x] forKey:@"double_values_0"];
//    [dic setObject:[NSNumber numberWithDouble:accelerometerData.acceleration.y] forKey:@"double_values_1"];
//    [dic setObject:[NSNumber numberWithDouble:accelerometerData.acceleration.z] forKey:@"double_values_2"];
//    [dic setObject:@0 forKey:@"accuracy"];
//    [dic setObject:@"" forKey:@"label"];
//    [self setLatestValue:[NSString stringWithFormat:
//                        @"%f, %f, %f",
//                        accelerometerData.acceleration.x,
//                        accelerometerData.acceleration.y,
//                        accelerometerData.acceleration.z]];
//    [self saveData:dic];
    
    
    return YES;
}

-(BOOL) stopSensor{
    if (!timer) {
        [timer invalidate];
        timer = nil;
    }
    return YES;
}


@end
