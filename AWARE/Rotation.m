//
//  Rotation.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/20/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//
/**
 * [CoreMotion API]
 * https://developer.apple.com/library/ios/documentation/EventHandling/Conceptual/EventHandlingiPhoneOS/motion_event_basics/motion_event_basics.html
 *
 * [CMDeviceMotion API]
 * https://developer.apple.com/library/ios/documentation/CoreMotion/Reference/CMDeviceMotion_Class/index.html#//apple_ref/occ/cl/CMDeviceMotion
 */


#import "Rotation.h"

@implementation Rotation {
    CMMotionManager* motionManager;
//    NSTimer * uploadTimer;
}


- (instancetype)initWithSensorName:(NSString *)sensorName withAwareStudy:(AWAREStudy *)study{
    self = [super initWithSensorName:sensorName withAwareStudy:study];
    if (self) {
        motionManager = [[CMMotionManager alloc] init];
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
    "double_values_3 real default 0,"
    "accuracy integer default 0,"
    "label text default '',"
    "UNIQUE (timestamp,device_id)";
    [super createTable:query];
}

- (BOOL)startSensor:(double)upInterval withSettings:(NSArray *)settings{
    // Get a sensing frequency
    int interval = 0.1f;
    double frequency = [self getSensorSetting:settings withKey:@"frequency_rotation"];
    if(frequency != -1){
        NSLog(@"Accelerometer's frequency is %f !!", frequency);
        double iOSfrequency = [self convertMotionSensorFrequecyFromAndroid:frequency];
        interval = iOSfrequency;
    }
    
    // Start a data uploader
//    uploadTimer = [NSTimer scheduledTimerWithTimeInterval:upInterval
//                                                   target:self
//                                                 selector:@selector(syncAwareDB)
//                                                 userInfo:nil
//                                                  repeats:YES];
    
    // Set a buffer size for reducing file access
    [self setBufferSize:1000];
    
    // Set and start motion sensor
    NSLog(@"[%@] Start Rotation Sensor", [self getSensorName]);
    if( motionManager.deviceMotionAvailable ){
        motionManager.deviceMotionUpdateInterval = interval;
        [motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue new]
                                            withHandler:^(CMDeviceMotion *motion, NSError *error){
                                                // Save sensor data to the local database.
                                                NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
                                                NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
                                                [dic setObject:unixtime forKey:@"timestamp"];
                                                [dic setObject:[self getDeviceId] forKey:@"device_id"];
                                                [dic setObject:[NSNumber numberWithDouble:motion.attitude.pitch] forKey:@"double_values_0"]; //double
                                                [dic setObject:[NSNumber numberWithDouble:motion.attitude.roll]  forKey:@"double_values_1"]; //double
                                                [dic setObject:[NSNumber numberWithDouble:motion.attitude.yaw]  forKey:@"double_values_2"]; //double
                                                [dic setObject:@0 forKey:@"double_values_3"]; //double
                                                [dic setObject:@0 forKey:@"accuracy"];//int
                                                [dic setObject:@"" forKey:@"label"]; //text
                                                [self setLatestValue:[NSString stringWithFormat:@"%f, %f, %f",motion.attitude.pitch, motion.attitude.roll,motion.attitude.yaw]];
                                                dispatch_async(dispatch_get_main_queue(), ^{
                                                    [self saveData:dic toLocalFile:SENSOR_ROTATION];
                                                });
                                            }];
    }
    return YES;
}

- (BOOL)stopSensor{
    // Stop a sync timer
//    [uploadTimer invalidate];
//    uploadTimer = nil;
    // Stop a motion sensor
    [motionManager stopDeviceMotionUpdates];
    motionManager = nil;
    return YES;
}


@end
