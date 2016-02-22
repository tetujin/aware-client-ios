//
//  linearAccelerometer.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/21/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

/**
 * [CoreMotion API]
 * https://developer.apple.com/library/ios/documentation/EventHandling/Conceptual/EventHandlingiPhoneOS/motion_event_basics/motion_event_basics.html
 *
 * [CMDeviceMotion API]
 * https://developer.apple.com/library/ios/documentation/CoreMotion/Reference/CMDeviceMotion_Class/index.html#//apple_ref/occ/cl/CMDeviceMotion
 */

//    deviceMotion.magneticField.field.x; done
//    deviceMotion.magneticField.field.y; done
//    deviceMotion.magneticField.field.z; done
//    deviceMotion.magneticField.accuracy;

//    deviceMotion.gravity.x;
//    deviceMotion.gravity.y;
//    deviceMotion.gravity.z;
//    deviceMotion.attitude.pitch;
//    deviceMotion.attitude.roll;
//    deviceMotion.attitude.yaw;
//    deviceMotion.rotationRate.x;
//    deviceMotion.rotationRate.y;
//    deviceMotion.rotationRate.z;

//    deviceMotion.timestamp;
//    deviceMotion.userAcceleration.x;
//    deviceMotion.userAcceleration.y;
//    deviceMotion.userAcceleration.z;


#import "LinearAccelerometer.h"

@implementation LinearAccelerometer {
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
    NSString *query = @"_id integer primary key autoincrement,"
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
    NSLog(@"[%@] Create Table", [self getSensorName]);
    // Send a table create query
    [self createTable];
    
    // Get sensing interval(frequency) from settings
    double interval = 0.1f; //default interval
    double frequency = [self getSensorSetting:settings withKey:@"frequency_linear_accelerometer"];
    if(frequency != -1){
        NSLog(@"Linear Accelerometer's frequency is %f !!", frequency);
        double iOSfrequency = [self convertMotionSensorFrequecyFromAndroid:frequency];
        interval = iOSfrequency;
    }
    
    // Set and start a sensor data uploader
//    uploadTimer = [NSTimer scheduledTimerWithTimeInterval:upInterval
//                                                   target:self
//                                                 selector:@selector(syncAwareDB)
//                                                 userInfo:nil
//                                                  repeats:YES];
    
    // Set a buffer size for reducing file access
    [self setBufferSize:100];
    
    // Start a motion sensor
    NSLog(@"[%@] Start Linear Acc Sensor", [self getSensorName]);
    if( motionManager.deviceMotionAvailable ){
        motionManager.deviceMotionUpdateInterval = interval;
        [motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue new]
                                           withHandler:^(CMDeviceMotion *motion, NSError *error){
                                               // Save sensor data to the local database
                                               NSNumber *unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
                                               NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
                                               [dic setObject:unixtime forKey:@"timestamp"];
                                               [dic setObject:[self getDeviceId] forKey:@"device_id"];
                                               [dic setObject:[NSNumber numberWithDouble:motion.userAcceleration.x] forKey:@"double_values_0"]; //double
                                               [dic setObject:[NSNumber numberWithDouble:motion.userAcceleration.y]  forKey:@"double_values_1"]; //double
                                               [dic setObject:[NSNumber numberWithDouble:motion.userAcceleration.z]  forKey:@"double_values_2"]; //double
                                               [dic setObject:@0 forKey:@"accuracy"];//int
                                               [dic setObject:@"" forKey:@"label"]; //text
                                               [self setLatestValue:[NSString stringWithFormat:@"%f, %f, %f",motion.userAcceleration.x, motion.userAcceleration.y,motion.userAcceleration.z]];
                                               [self saveData:dic toLocalFile:SENSOR_LINEAR_ACCELEROMETER];
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
