//
//  Gyroscope.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/20/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "Gyroscope.h"
#import "AWAREUtils.h"


@implementation Gyroscope{
    CMMotionManager* gyroManager;
    NSTimer* gTimer;
}

- (instancetype)initWithSensorName:(NSString *)sensorName withAwareStudy:(AWAREStudy *)study{
    self = [super initWithSensorName:sensorName withAwareStudy:study];
    if (self) {
        gyroManager = [[CMMotionManager alloc] init];
    }
    return self;
}

- (void) createTable{
    NSString *query = [[NSString alloc] init];
    query = @"_id integer primary key autoincrement,"
    "timestamp real default 0,"
    "device_id text default '',"
    "axis_x real default 0,"
    "axis_y real default 0,"
    "axis_z real default 0,"
    "accuracy integer default 0,"
    "label text default '',"
    "UNIQUE (timestamp,device_id)";
    [super createTable:query];
}


- (BOOL)startSensor:(double)upInterval withSettings:(NSArray *)settings{
    // Send a table create query
    NSLog(@"[%@] Create Table", [self getSensorName]);
    [self createTable];
    
    // Set and start a data uploader
    NSLog(@"[%@] Start Gyro Sensor", [self getSensorName]);
    gTimer = [NSTimer scheduledTimerWithTimeInterval:upInterval
                                              target:self
                                            selector:@selector(syncAwareDB)
                                            userInfo:nil
                                             repeats:YES];
    
    // Set a buffer size for reducing file access
    [self setBufferSize:1000];
    
    
    // Get a sensing frequency from settings
    double frequency = [self getSensorSetting:settings withKey:@"frequency_gyroscope"];
    if(frequency != -1){
        NSLog(@"Gyroscope's frequency is %f !!", frequency);
        double iOSfrequency = [self convertMotionSensorFrequecyFromAndroid:frequency];
        gyroManager.gyroUpdateInterval = iOSfrequency;
    }else{
        gyroManager.gyroUpdateInterval = 0.1f;//default value
    }
    
    // Start a sensor
    [gyroManager startGyroUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMGyroData * _Nullable gyroData, NSError * _Nullable error) {
        if( error ) {
            NSLog(@"%@:%ld", [error domain], [error code] );
        } else {
            NSNumber *unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
            NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
            [dic setObject:unixtime forKey:@"timestamp"];
            [dic setObject:[self getDeviceId] forKey:@"device_id"];
            [dic setObject:[NSNumber numberWithDouble:gyroData.rotationRate.x] forKey:@"axis_x"];
            [dic setObject:[NSNumber numberWithDouble:gyroData.rotationRate.y] forKey:@"axis_y"];
            [dic setObject:[NSNumber numberWithDouble:gyroData.rotationRate.z] forKey:@"axis_z"];
            [dic setObject:@0 forKey:@"accuracy"];
            [dic setObject:@"" forKey:@"label"];
            [self setLatestValue:[NSString stringWithFormat:@"%f, %f, %f",gyroData.rotationRate.x,gyroData.rotationRate.y,gyroData.rotationRate.z]];
            [self saveData:dic];
        }
    }];
    return YES;
}

- (BOOL)stopSensor{
    [gyroManager stopGyroUpdates];
    [gTimer invalidate];
    return YES;
}


@end
