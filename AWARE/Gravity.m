//
//  Gravity.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/21/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "Gravity.h"

@implementation Gravity
{
    CMMotionManager* motionManager;
    NSTimer * uploadTimer;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
//        motionManager = [[CMMotionManager alloc] init];
    }
    return self;
}

- (instancetype)initWithSensorName:(NSString *)sensorName{
    self = [super initWithSensorName:sensorName];
    if (self) {
        [super setSensorName:sensorName];
        motionManager = [[CMMotionManager alloc] init];
    }
    return self;
}

/**
 * [CoreMotion API]
 * https://developer.apple.com/library/ios/documentation/EventHandling/Conceptual/EventHandlingiPhoneOS/motion_event_basics/motion_event_basics.html
 *
 * [CMDeviceMotion API]
 * https://developer.apple.com/library/ios/documentation/CoreMotion/Reference/CMDeviceMotion_Class/index.html#//apple_ref/occ/cl/CMDeviceMotion
 */

//- (BOOL)startSensor:(double)interval withUploadInterval:(double)upInterval{
- (BOOL)startSensor:(double)upInterval withSettings:(NSArray *)settings{
    NSLog(@"Start Gravity sensing !");
    double interval = 0.1f;
    
//    [self setBufferLimit:10000];
    [self startWriteAbleTimer];
    double frequency = [self getSensorSetting:settings withKey:@"frequency_gravity"];
    if(frequency != -1){
        NSLog(@"Accelerometer's frequency is %f !!", frequency);
        double iOSfrequency = [self convertMotionSensorFrequecyFromAndroid:frequency];
        interval = iOSfrequency;
    }
    
    
    
    uploadTimer = [NSTimer scheduledTimerWithTimeInterval:upInterval target:self selector:@selector(syncAwareDB) userInfo:nil repeats:YES];
    /** motion */
    if( motionManager.deviceMotionAvailable ){
        motionManager.deviceMotionUpdateInterval = interval;
        [motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue new]
                                           withHandler:^(CMDeviceMotion *motion, NSError *error){
                                               // Save sensor data to the local database.
                                               NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
                                               NSNumber* unixtime = [NSNumber numberWithDouble:timeStamp];
                                               NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
                                               [dic setObject:unixtime forKey:@"timestamp"];
                                               [dic setObject:[self getDeviceId] forKey:@"device_id"];
                                               [dic setObject:[NSNumber numberWithDouble:motion.gravity.x] forKey:@"double_values_0"]; //double
                                               [dic setObject:[NSNumber numberWithDouble:motion.gravity.y]  forKey:@"double_values_1"]; //double
                                               [dic setObject:[NSNumber numberWithDouble:motion.gravity.z]  forKey:@"double_values_2"]; //double
                                               [dic setObject:@0 forKey:@"accuracy"];//int
                                               [dic setObject:@"" forKey:@"label"]; //text
                                               [self setLatestValue:[NSString stringWithFormat:@"%f, %f, %f",motion.attitude.pitch, motion.attitude.roll,motion.attitude.yaw]];
                                               [self saveData:dic toLocalFile:SENSOR_GRAVITY];
                                           }];
    }
    return YES;
}



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


- (BOOL)stopSensor{
    [uploadTimer invalidate];
    [motionManager stopDeviceMotionUpdates];
    [self stopWriteableTimer];
    return YES;
}

//- (void)uploadSensorData{
//    [self syncAwareDB];
////    NSString * jsonStr = [self getData:SENSOR_GRAVITY withJsonArrayFormat:YES];
////    [self insertSensorData:jsonStr withDeviceId:[self getDeviceId] url:[self getInsertUrl:SENSOR_GRAVITY]];
//}

@end
