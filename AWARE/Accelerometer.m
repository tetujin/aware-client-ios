//
//  Accelerometer.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/19/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "Accelerometer.h"

@implementation Accelerometer{
    CMMotionManager *manager;
    NSTimer *timer;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        manager = [[CMMotionManager alloc] init];
    }
    return self;
}

- (instancetype)initWithSensorName:(NSString *)sensorName{
    self = [super init];
    if (self) {
        manager = [[CMMotionManager alloc] init];
        [super setSensorName:sensorName];
    }
    return self;
}

-(BOOL)startSensor:(double)upInterval withSettings:(NSArray *)settings{
    NSLog(@"Start Accelerometer!");
    timer = [NSTimer scheduledTimerWithTimeInterval:upInterval
                                             target:self selector:@selector(uploadSensorData) userInfo:nil repeats:YES];
    manager.accelerometerUpdateInterval = 0.1f; //default value
    
    // Get settings from setting list
    
    [manager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue]
                                  withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
                                      if( error ) {
                                          NSLog(@"%@:%ld", [error domain], [error code] );
                                      } else {
                                          NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
                                          NSNumber* unixtime = [NSNumber numberWithDouble:timeStamp];
                                          NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
                                          [dic setObject:unixtime forKey:@"timestamp"];
                                          [dic setObject:[self getDeviceId] forKey:@"device_id"];
                                          [dic setObject:[NSNumber numberWithDouble:accelerometerData.acceleration.x] forKey:@"double_values_0"];
                                          [dic setObject:[NSNumber numberWithDouble:accelerometerData.acceleration.y] forKey:@"double_values_1"];
                                          [dic setObject:[NSNumber numberWithDouble:accelerometerData.acceleration.z] forKey:@"double_values_2"];
                                          [dic setObject:@0 forKey:@"accuracy"];
                                          [dic setObject:@"text" forKey:@"label"];
                                          [self setLatestValue:[NSString stringWithFormat:
                                                                @"%f, %f, %f",
                                                                accelerometerData.acceleration.x,
                                                                accelerometerData.acceleration.y,
                                                                accelerometerData.acceleration.z]];
                                          [self saveData:dic toLocalFile:SENSOR_ACCELEROMETER];
                                      }
                                  }];
    return YES;
}

-(BOOL) stopSensor{
    [manager stopAccelerometerUpdates];
    [timer invalidate];
    return YES;
}

-(void) uploadSensorData{
    NSString * jsonStr = nil;
//    @autoreleasepool {
        jsonStr = [self getData:SENSOR_ACCELEROMETER withJsonArrayFormat:YES];
        [self insertSensorData:jsonStr withDeviceId:[self getDeviceId] url:[self getInsertUrl:SENSOR_ACCELEROMETER]];
//    }
}

@end
