//
//  Magnetometer.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/20/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "Magnetometer.h"
#import "EntityMagnetometer.h"
#import "AppDelegate.h"

@implementation Magnetometer{
    CMMotionManager* manager;
    double defaultInterval;
    int dbWriteInterval;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study{
    self = [super initWithAwareStudy:study
                          sensorName:SENSOR_MAGNETOMETER
                        dbEntityName:NSStringFromClass([EntityMagnetometer class])
                              dbType:AwareDBTypeCoreData];
    if (self) {
        manager = [[CMMotionManager alloc] init];
        defaultInterval = 0.1f;
        dbWriteInterval = 10;
    }
    return self;
}


- (void) createTable{
    // Send a table craete query
    NSLog(@"[%@] Create table", [self getSensorName]);
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


- (BOOL)startSensorWithSettings:(NSArray *)settings{
    
    // Get and set a sensng frequency to CMMotionManager
    double frequency = [self getSensorSetting:settings withKey:@"frequency_magnetometer"];
    if(frequency != -1){
        NSLog(@"Accelerometer's frequency is %f !!", frequency);
        double iOSfrequency = [self convertMotionSensorFrequecyFromAndroid:frequency];
        frequency = iOSfrequency;
    }else{
        frequency = defaultInterval;
    }
    int buffer = dbWriteInterval/frequency;
    return [self startSensorWithInterval:frequency bufferSize:buffer];
}

- (BOOL) startSensor{
    return [self startSensorWithInterval:defaultInterval];
}

- (BOOL) startSensorWithInterval:(double)interval{
    return [self startSensorWithInterval:interval bufferSize:[self getBufferSize]];
}

- (BOOL) startSensorWithInterval:(double)interval bufferSize:(int)buffer{
    return [self startSensorWithInterval:interval bufferSize:buffer fetchLimit:[self getFetchLimit]];
}

- (BOOL) startSensorWithInterval:(double)interval bufferSize:(int)buffer fetchLimit:(int)fetchLimit{
    
    // Set a buffer size for reducing file access
    [self setBufferSize:buffer];
    
    [self setFetchLimit:fetchLimit];
    
    // Set and start a sensor
    NSLog(@"[%@] Start Mag sensor", [self getSensorName]);
    
    manager.magnetometerUpdateInterval = interval;
    
    [manager startMagnetometerUpdatesToQueue:[NSOperationQueue currentQueue]
                                 withHandler:^(CMMagnetometerData * _Nullable magnetometerData,
                                               NSError * _Nullable error) {
                                     if( error ) {
                                         NSLog(@"%@:%ld", [error domain], [error code] );
                                     } else {
                                         
                                         dispatch_async(dispatch_get_main_queue(),^{
                                             // AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
                                             EntityMagnetometer* data = (EntityMagnetometer *)[NSEntityDescription
                                                                                               insertNewObjectForEntityForName:[self getEntityName]
                                                                                               inManagedObjectContext:[self getSensorManagedObjectContext]];
                                             
                                             data.device_id = [self getDeviceId];
                                             data.timestamp = [AWAREUtils getUnixTimestamp:[NSDate new]];
                                             data.double_values_0 = [NSNumber numberWithDouble:magnetometerData.magneticField.x];
                                             data.double_values_1 = [NSNumber numberWithDouble:magnetometerData.magneticField.y];
                                             data.double_values_2 = [NSNumber numberWithDouble:magnetometerData.magneticField.z];
                                             data.accuracy = @0;
                                             data.label =  @"";
                                             
                                             NSDictionary *userInfo = [NSDictionary dictionaryWithObject:data
                                                                                                  forKey:EXTRA_DATA];
                                             [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_MAGNETOMETER
                                                                                                 object:nil
                                                                                               userInfo:userInfo];
                                             
//                                             if(bufferCount > [self getBufferSize] ){
//                                                 NSError * e = nil;
//                                                 [delegate.managedObjectContext save:&e];
//                                                 if (e) {
//                                                     NSLog(@"%@", e.description);
//                                                 }
//                                                 NSLog(@"Save magnetometer data to SQLite");
//                                                 bufferCount = 0;
//                                             }else{
//                                                 bufferCount++;
//                                             }
                                             [self saveDataToDB];
                                             
                                             [self setLatestValue:[NSString stringWithFormat:@"%f, %f, %f",
                                                                   magnetometerData.magneticField.x,
                                                                   magnetometerData.magneticField.y,
                                                                   magnetometerData.magneticField.z]];
                                         });
                                         //            NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
                                         //            NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
                                         //            [dic setObject:unixtime forKey:@"timestamp"];
                                         //            [dic setObject:[self getDeviceId] forKey:@"device_id"];
                                         //            [dic setObject:[NSNumber numberWithDouble:magnetometerData.magneticField.x] forKey:@"double_values_0"];
                                         //            [dic setObject:[NSNumber numberWithDouble:magnetometerData.magneticField.y] forKey:@"double_values_1"];
                                         //            [dic setObject:[NSNumber numberWithDouble:magnetometerData.magneticField.z] forKey:@"double_values_2"];
                                         //            [dic setObject:@0 forKey:@"accuracy"];
                                         //            [dic setObject:@"" forKey:@"label"];
                                         //            [self setLatestValue:[NSString stringWithFormat:@"%f, %f, %f",magnetometerData.magneticField.x, magnetometerData.magneticField.y, magnetometerData.magneticField.z]];
                                         //            dispatch_async(dispatch_get_main_queue(), ^{
                                         //                [self saveData:dic];
                                         //            });
                                     }
                                 }];

    return YES;
}

- (BOOL)stopSensor{
    // Stop a motion sensor
    [manager stopMagnetometerUpdates];
    manager = nil;
    return YES;
}


@end
