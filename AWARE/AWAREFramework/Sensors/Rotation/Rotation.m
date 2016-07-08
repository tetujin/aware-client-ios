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
#import "AppDelegate.h"
#import "EntityRotation.h"

@implementation Rotation {
    CMMotionManager* motionManager;
    double defaultInterval;
    int dbWriteInterval;
}


- (instancetype)initWithAwareStudy:(AWAREStudy *)study{
    self = [super initWithAwareStudy:study
                          sensorName:SENSOR_ROTATION
                        dbEntityName:NSStringFromClass([EntityRotation class])
                              dbType:AwareDBTypeCoreData];
    if (self) {
        motionManager = [[CMMotionManager alloc] init];
        defaultInterval = 0.1f;
        dbWriteInterval = 30;
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

- (BOOL)startSensorWithSettings:(NSArray *)settings{
    // Get a sensing frequency
    int interval = defaultInterval;
    double frequency = [self getSensorSetting:settings withKey:@"frequency_rotation"];
    if(frequency != -1){
        NSLog(@"Accelerometer's frequency is %f !!", frequency);
        double iOSfrequency = [self convertMotionSensorFrequecyFromAndroid:frequency];
        interval = iOSfrequency;
    }
    int buffer = dbWriteInterval/interval;
    return [self startSensorWithInterval:interval bufferSize:buffer];
}

- (BOOL)startSensor{
    return [self startSensorWithInterval:defaultInterval];
}

- (BOOL)startSensorWithInterval:(double)interval{
    return [self startSensorWithInterval:interval bufferSize:[self getBufferSize]];
}

- (BOOL)startSensorWithInterval:(double)interval bufferSize:(int)buffer{
    return [self startSensorWithInterval:interval bufferSize:buffer fetchLimit:[self getFetchLimit]];
}


- (BOOL)startSensorWithInterval:(double)interval bufferSize:(int)buffer fetchLimit:(int)fetchLimit{
    
    [self setBufferSize:buffer];
    
    [self setFetchLimit:fetchLimit];
    
    // Set and start motion sensor
    NSLog(@"[%@] Start Rotation Sensor", [self getSensorName]);
    if( motionManager.deviceMotionAvailable ){
        motionManager.deviceMotionUpdateInterval = interval;
        [motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue new]
                                           withHandler:^(CMDeviceMotion *motion, NSError *error){
                                               // Save sensor data to the local database.
                                               NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
                                               // AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
                                               EntityRotation* data = (EntityRotation *)[NSEntityDescription
                                                                                        insertNewObjectForEntityForName:[self getEntityName]
                                                                                    inManagedObjectContext:[self getSensorManagedObjectContext]];
                                               
                                               data.device_id = [self getDeviceId];
                                               data.timestamp = unixtime;
                                               data.double_values_0 = @(motion.attitude.pitch);
                                               data.double_values_1 = @(motion.attitude.roll);
                                               data.double_values_2 = @(motion.attitude.yaw);
                                               data.double_values_3 = @0;
                                               data.accuracy = @0;
                                               data.label =  @"";
                                               
                                               NSDictionary *userInfo = [NSDictionary dictionaryWithObject:data
                                                                                                    forKey:EXTRA_DATA];
                                               [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_ROTATION
                                                                                                   object:nil
                                                                                                 userInfo:userInfo];
                                               
                                               [self saveDataToDB];
                                               [self setLatestValue:[NSString stringWithFormat:@"%f, %f, %f",motion.attitude.pitch, motion.attitude.roll,motion.attitude.yaw]];

//                                               NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
//                                               [dic setObject:unixtime forKey:@"timestamp"];
//                                               [dic setObject:[self getDeviceId] forKey:@"device_id"];
//                                               [dic setObject:[NSNumber numberWithDouble:motion.attitude.pitch] forKey:@"double_values_0"]; //double
//                                               [dic setObject:[NSNumber numberWithDouble:motion.attitude.roll]  forKey:@"double_values_1"]; //double
//                                               [dic setObject:[NSNumber numberWithDouble:motion.attitude.yaw]  forKey:@"double_values_2"]; //double
//                                               [dic setObject:@0 forKey:@"double_values_3"]; //double
//                                               [dic setObject:@0 forKey:@"accuracy"];//int
//                                               [dic setObject:@"" forKey:@"label"]; //text
//                                              dispatch_async(dispatch_get_main_queue(), ^{
//                                                   [self saveData:dic toLocalFile:SENSOR_ROTATION];
//                                               });
                                           }];
    }
    return YES;
}

- (BOOL)stopSensor{
    // Stop a sync timer
    [motionManager stopDeviceMotionUpdates];
    motionManager = nil;
    return YES;
}


@end
