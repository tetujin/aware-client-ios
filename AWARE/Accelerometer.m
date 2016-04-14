//
//  Accelerometer.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/19/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "Accelerometer.h"
#import "AWAREUtils.h"

@implementation Accelerometer{
    CMMotionManager *manager;
//    NSTimer *timer;
}

- (instancetype)initWithSensorName:(NSString *)sensorName withAwareStudy:(AWAREStudy *)study{
    self = [super initWithSensorName:sensorName withAwareStudy:study];
    if (self) {
        manager = [[CMMotionManager alloc] init];
    }
    return self;
}

- (void) createTable{
    NSLog(@"[%@] Create Table", [self getSensorName]);
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


-(BOOL)startSensor:(double)upInterval withSettings:(NSArray *)settings{
    // Send a create table query
//    [self createTable];
    
    // Set and start a data uploader
    NSLog(@"[%@] Start Sensor!", [self getSensorName]);
//    timer = [NSTimer scheduledTimerWithTimeInterval:upInterval
//                                             target:self
//                                           selector:@selector(syncAwareDB)
//                                           userInfo:nil
//                                            repeats:YES];
    // Set buffer size for reducing file access
    [self setBufferSize:1000];
    
    // Get a sensing frequency from settings
    double frequency = [self getSensorSetting:settings withKey:@"frequency_accelerometer"];
    if(frequency != -1){
        NSLog(@"Accelerometer's frequency is %f !!", frequency);
        double iOSfrequency = [self convertMotionSensorFrequecyFromAndroid:frequency];
        manager.accelerometerUpdateInterval = iOSfrequency;
    }else{
        manager.accelerometerUpdateInterval = 0.1f; //default value
    }
    
    // Set and start a motion sensor
    [manager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue]
                                  withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
                                      if( error ) {
                                          NSLog(@"%@:%ld", [error domain], [error code] );
                                      } else {
                                              NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
                                              [dic setObject:[AWAREUtils getUnixTimestamp:[NSDate new]] forKey:@"timestamp"];
                                              [dic setObject:[self getDeviceId] forKey:@"device_id"];
                                              [dic setObject:[NSNumber numberWithDouble:accelerometerData.acceleration.x] forKey:@"double_values_0"];
                                              [dic setObject:[NSNumber numberWithDouble:accelerometerData.acceleration.y] forKey:@"double_values_1"];
                                              [dic setObject:[NSNumber numberWithDouble:accelerometerData.acceleration.z] forKey:@"double_values_2"];
                                              [dic setObject:@0 forKey:@"accuracy"];
                                              [dic setObject:@"" forKey:@"label"];
                                              [self setLatestValue:[NSString stringWithFormat:
                                                                    @"%f, %f, %f",
                                                                    accelerometerData.acceleration.x,
                                                                accelerometerData.acceleration.y,
                                                                accelerometerData.acceleration.z]];
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                              [self saveData:dic];
                                            });
                                        }
                                  }];
    return YES;
}

-(BOOL) stopSensor{
    [manager stopAccelerometerUpdates];
//    [timer invalidate];
    return YES;
}


@end
