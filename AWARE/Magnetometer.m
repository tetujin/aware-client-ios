//
//  Magnetometer.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/20/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "Magnetometer.h"

@implementation Magnetometer{
    CMMotionManager* manager;
//    NSTimer* timer;
}

- (instancetype)initWithSensorName:(NSString *)sensorName withAwareStudy:(AWAREStudy *)study{
    self = [super initWithSensorName:sensorName withAwareStudy:study];
    if (self) {
        manager = [[CMMotionManager alloc] init];
    }
    return self;
}


- (void) createTable{
    // Send a table craete query
    NSLog(@"[%@] Create table", [self getSensorName]);
    NSString *query = [[NSString alloc] init];
    query = @"_id integer primary key autoincrement,"
    "timestamp real default 0,"
    "device_id text default '',"
    "double_values_0 real default 0,"
    "double_values_1 real default 0,"
    "double_values_2 real default 0,"
    "accuracy integer default 0,"
    "label text default '',"
    "UNIQUE (timestamp,device_id)";
    [super createTable:query];
}


- (BOOL)startSensor:(double)upInterval withSettings:(NSArray *)settings{
    // Set and start a data uploader
//    timer = [NSTimer scheduledTimerWithTimeInterval:upInterval
//                                             target:self
//                                           selector:@selector(syncAwareDB)
//                                           userInfo:nil
//                                            repeats:YES];
    
    // Set a buffer size for reducing file access
    [self setBufferSize:1000];
    
    // Get and set a sensng frequency to CMMotionManager
    double frequency = [self getSensorSetting:settings withKey:@"frequency_magnetometer"];
    if(frequency != -1){
        NSLog(@"Accelerometer's frequency is %f !!", frequency);
        double iOSfrequency = [self convertMotionSensorFrequecyFromAndroid:frequency];
        manager.magnetometerUpdateInterval = iOSfrequency;
    }else{
        manager.magnetometerUpdateInterval = 0.1f;//default value
    }
    
    // Set and start a sensor
    NSLog(@"[%@] Start Mag sensor", [self getSensorName]);
    [manager startMagnetometerUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMMagnetometerData * _Nullable magnetometerData, NSError * _Nullable error) {
        if( error ) {
            NSLog(@"%@:%ld", [error domain], [error code] );
        } else {
            NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
            NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
            [dic setObject:unixtime forKey:@"timestamp"];
            [dic setObject:[self getDeviceId] forKey:@"device_id"];
            [dic setObject:[NSNumber numberWithDouble:magnetometerData.magneticField.x] forKey:@"double_values_0"];
            [dic setObject:[NSNumber numberWithDouble:magnetometerData.magneticField.y] forKey:@"double_values_1"];
            [dic setObject:[NSNumber numberWithDouble:magnetometerData.magneticField.z] forKey:@"double_values_2"];
            [dic setObject:@0 forKey:@"accuracy"];
            [dic setObject:@"" forKey:@"label"];
            [self setLatestValue:[NSString stringWithFormat:@"%f, %f, %f",magnetometerData.magneticField.x, magnetometerData.magneticField.y, magnetometerData.magneticField.z]];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self saveData:dic];
            });
        }
    }];
    
    
    return YES;
}

- (BOOL)stopSensor{
    // Stop a sync timer
//    [timer invalidate];
//    timer = nil;
    // Stop a motion sensor
    [manager stopMagnetometerUpdates];
    manager = nil;
    return YES;
}


@end
