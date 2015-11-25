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
    NSTimer* timer;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
//        manager = [[CMMotionManager alloc] init];
    }
    return self;
}

- (instancetype)initWithSensorName:(NSString *)sensorName{
    self = [super initWithSensorName:sensorName];
    if (self) {
        manager = [[CMMotionManager alloc] init];
        [super setSensorName:sensorName];
    }
    return self;
}

//- (BOOL)startSensor:(double)interval withUploadInterval:(double)upInterval{
- (BOOL)startSensor:(double)upInterval withSettings:(NSArray *)settings{
    NSLog(@"Start Magnetometer!");
    timer = [NSTimer scheduledTimerWithTimeInterval:upInterval target:self selector:@selector(uploadSensorData) userInfo:nil repeats:YES];
    
//    [self setBufferLimit:10000];
    [self startWriteAbleTimer];
    double frequency = [self getSensorSetting:settings withKey:@"frequency_magnetometer"];
    if(frequency != -1){
        NSLog(@"Accelerometer's frequency is %f !!", frequency);
        double iOSfrequency = [self convertMotionSensorFrequecyFromAndroid:frequency];
        manager.magnetometerUpdateInterval = iOSfrequency;
    }else{
        manager.magnetometerUpdateInterval = 0.1f;//default value
    }
    
    [manager startMagnetometerUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMMagnetometerData * _Nullable magnetometerData, NSError * _Nullable error) {
        if( error ) {
            NSLog(@"%@:%ld", [error domain], [error code] );
        } else {
            NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
            NSNumber* unixtime = [NSNumber numberWithDouble:timeStamp];
            NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
            [dic setObject:unixtime forKey:@"timestamp"];
            [dic setObject:[self getDeviceId] forKey:@"device_id"];
            [dic setObject:[NSNumber numberWithDouble:magnetometerData.magneticField.x] forKey:@"double_values_0"];
            [dic setObject:[NSNumber numberWithDouble:magnetometerData.magneticField.y] forKey:@"double_values_1"];
            [dic setObject:[NSNumber numberWithDouble:magnetometerData.magneticField.z] forKey:@"double_values_2"];
            [dic setObject:@0 forKey:@"accuracy"];
            [dic setObject:@"text" forKey:@"label"];
            [self setLatestValue:[NSString stringWithFormat:@"%f, %f, %f",magnetometerData.magneticField.x, magnetometerData.magneticField.y, magnetometerData.magneticField.z]];
            [self saveData:dic toLocalFile:SENSOR_MAGNETOMETER];
        }
    }];
    return YES;
}

- (BOOL)stopSensor{
    [manager stopMagnetometerUpdates];
    [timer invalidate];
    [self stopWriteableTimer];
    return YES;
}

- (void)uploadSensorData{
    NSString * jsonStr = [self getData:SENSOR_MAGNETOMETER withJsonArrayFormat:YES];
    [self insertSensorData:jsonStr withDeviceId:[self getDeviceId] url:[self getInsertUrl:SENSOR_MAGNETOMETER]];
}


@end
