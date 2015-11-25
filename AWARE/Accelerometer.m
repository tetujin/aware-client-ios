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
    NSTimer *testTimer;
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
    self = [super initWithSensorName:sensorName ];
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
//    testTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(test) userInfo:nil repeats:YES];
    // Get settings from setting list
//    [self setBufferLimit:10000];
    [self startWriteAbleTimer];
    
    double frequency = [self getSensorSetting:settings withKey:@"frequency_accelerometer"];
    if(frequency != -1){
        NSLog(@"Accelerometer's frequency is %f !!", frequency);
        double iOSfrequency = [self convertMotionSensorFrequecyFromAndroid:frequency];
        manager.accelerometerUpdateInterval = iOSfrequency;
    }else{
        manager.accelerometerUpdateInterval = 0.1f; //default value
    }
    
//    manager.accelerometerUpdateInterval = 0.05f; //default value

    [manager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue]
                                  withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
                                      if( error ) {
                                          NSLog(@"%@:%ld", [error domain], [error code] );
                                      } else {
//                                          dispatch_sync(dispatch_get_main_queue(), ^{
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
//
                                               [self saveData:dic toLocalFile:SENSOR_ACCELEROMETER];
//                                            });
                                        }
                                  }];
    return YES;
}

-(BOOL) stopSensor{
    [manager stopAccelerometerUpdates];
    [timer invalidate];
    [self stopWriteableTimer];
    return YES;
}

-(void) uploadSensorData{
    NSString * jsonStr = nil;
//    @autoreleasepool {
        jsonStr = [self getData:SENSOR_ACCELEROMETER withJsonArrayFormat:YES];
        [self insertSensorData:jsonStr withDeviceId:[self getDeviceId] url:[self getInsertUrl:SENSOR_ACCELEROMETER]];
//    }
}

- (void) test{
    
    // Make new file
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString * path = [documentsDirectory stringByAppendingPathComponent:[self getSensorName]];
    NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:path];
    if (fh == nil) {
        NSLog(@"[test sensor] Not hudled");
    }else{
        NSLog(@"[test sensor] Hudled");
    }
//    if (!fh) { // no
//        NSLog(@"You don't have a file for %@, then system recreated new file!", [self getSensorName]);
//        NSFileManager *m = [NSFileManager defaultManager];
//        if (![m fileExistsAtPath:path]) { // yes
//            BOOL result = [m createFileAtPath:path
//                                     contents:[NSData data] attributes:nil];
//            if (!result) {
//                NSLog(@"Failed to create the file at %@", path);
//            }else{
//                NSLog(@"Create the file at %@", path);
////                NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
////                NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
////                NSNumber* unixtime = [NSNumber numberWithDouble:timeStamp];
////                [dic setObject:unixtime forKey:@"timestamp"];
////                [dic setObject:[self getDeviceId] forKey:@"device_id"];
////                [dic setObject:@0 forKey:@"double_values_0"];
////                [dic setObject:@0 forKey:@"double_values_1"];
////                [dic setObject:@0 forKey:@"double_values_2"];
////                [dic setObject:@0 forKey:@"accuracy"];
////                [dic setObject:@"text" forKey:@"label"];
////                [self saveData:dic toLocalFile:SENSOR_ACCELEROMETER];
//            }
//        }
//    }else{
        [fh writeData:[@"---" dataUsingEncoding:NSUTF8StringEncoding]]; //write temp data to
        [fh closeFile];
//    }

//    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
//    NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
//    NSNumber* unixtime = [NSNumber numberWithDouble:timeStamp];
//    [dic setObject:unixtime forKey:@"timestamp"];
//    [dic setObject:[self getDeviceId] forKey:@"device_id"];
//    [dic setObject:@0 forKey:@"double_values_0"];
//    [dic setObject:@0 forKey:@"double_values_1"];
//    [dic setObject:@0 forKey:@"double_values_2"];
//    [dic setObject:@0 forKey:@"accuracy"];
//    [dic setObject:@"text" forKey:@"label"];
//    [self saveData:dic toLocalFile:SENSOR_ACCELEROMETER];
}

@end
