//
//  Gyroscope.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/20/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "Gyroscope.h"


@implementation Gyroscope{
    CMMotionManager* gyroManager;
    NSTimer* gTimer;
}

- (instancetype)initWithSensorName:(NSString *)sensorName{
    self = [super initWithSensorName:sensorName];
    if (self) {
        gyroManager = [[CMMotionManager alloc] init];
        [super setSensorName:sensorName];
    }
    return self;
}

- (void) createTable{
    NSString *query = [[NSString alloc] init];
    query = @"_id integer primary key autoincrement,"
    "timestamp real default 0,"
    "device_id text default '',"
    "double_values_x real default 0,"
    "double_values_y real default 0,"
    "double_values_z real default 0,"
    "accuracy integer default 0,"
    "label text default '',"
    "UNIQUE (timestamp,device_id)";
    [super createTable:query];
}


//- (BOOL)startSensor:(double)interval withUploadInterval:(double)upInterval{
- (BOOL)startSensor:(double)upInterval withSettings:(NSArray *)settings{
    NSLog(@"[%@] Create Table", [self getSensorName]);
    [self createTable];
    NSLog(@"[%@] Start Gyro Sensor", [self getSensorName]);
    gTimer = [NSTimer scheduledTimerWithTimeInterval:upInterval target:self selector:@selector(syncAwareDB) userInfo:nil repeats:YES];
    
    [self setBufferLimit:10000];
    [self startWriteAbleTimer];
    
    double frequency = [self getSensorSetting:settings withKey:@"frequency_gyroscope"];
    if(frequency != -1){
        NSLog(@"Accelerometer's frequency is %f !!", frequency);
        double iOSfrequency = [self convertMotionSensorFrequecyFromAndroid:frequency];
        gyroManager.gyroUpdateInterval = iOSfrequency;
    }else{
        gyroManager.gyroUpdateInterval = 0.1f;//default value
    }
    
    
    [gyroManager startGyroUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMGyroData * _Nullable gyroData, NSError * _Nullable error) {
        if( error ) {
            NSLog(@"%@:%ld", [error domain], [error code] );
        } else {
            NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970] * 10000;
            NSNumber* unixtime = [NSNumber numberWithDouble:timeStamp];
            NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
            [dic setObject:unixtime forKey:@"timestamp"];
            [dic setObject:[self getDeviceId] forKey:@"device_id"];
            [dic setObject:[NSNumber numberWithDouble:gyroData.rotationRate.x] forKey:@"axis_x"];
            [dic setObject:[NSNumber numberWithDouble:gyroData.rotationRate.y] forKey:@"axis_y"];
            [dic setObject:[NSNumber numberWithDouble:gyroData.rotationRate.z] forKey:@"axis_z"];
            [dic setObject:@0 forKey:@"accuracy"];
            [dic setObject:@"text" forKey:@"label"];
            [self setLatestValue:[NSString stringWithFormat:@"%f, %f, %f",gyroData.rotationRate.x,gyroData.rotationRate.y,gyroData.rotationRate.z]];
//            [self saveData:dic toLocalFile:SENSOR_GYROSCOPE];
            [self saveData:dic];
        }
    }];
    return YES;
}

- (BOOL)stopSensor{
    [gyroManager stopGyroUpdates];
    [gTimer invalidate];
    [self stopWriteableTimer];
    return YES;
}

//- (void)uploadSensorData{
//    [self syncAwareDB];
////    NSString * jsonStr = [self getData:SENSOR_GYROSCOPE withJsonArrayFormat:YES];
////    [self insertSensorData:jsonStr withDeviceId:[self getDeviceId] url:[self getInsertUrl:SENSOR_GYROSCOPE ]];
//}


@end
