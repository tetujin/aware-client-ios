//
//  Gyroscope.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/20/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "Gyroscope.h"
#import "AWAREUtils.h"
#import "EntityGyroscope.h"
#import "AppDelegate.h"

@implementation Gyroscope{
    CMMotionManager* gyroManager;
    double defaultInterval;
    int dbWriteInterval;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study{
    self = [super initWithAwareStudy:study
                          sensorName:SENSOR_GYROSCOPE
                        dbEntityName:NSStringFromClass([EntityGyroscope class])
                              dbType:AwareDBTypeCoreData];
    if (self) {
        gyroManager = [[CMMotionManager alloc] init];
        defaultInterval = 0.1f;
        dbWriteInterval = 10;
    }
    return self;
}

- (void) createTable{
    // Send a table create query
    NSLog(@"[%@] Create Table", [self getSensorName]);
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


- (BOOL)startSensorWithSettings:(NSArray *)settings{
    // Set and start a data uploader
    NSLog(@"[%@] Start Gyro Sensor", [self getSensorName]);
    
    // Get a sensing frequency from settings
    double interval = defaultInterval;
    if(settings != nil){
        double frequency = [self getSensorSetting:settings withKey:@"frequency_gyroscope"];
        if(frequency != -1){
            interval = [self convertMotionSensorFrequecyFromAndroid:frequency];
        }
    }
    
    int buffer = dbWriteInterval/interval;
    
    [self startSensorWithInterval:interval bufferSize:buffer];
    
    return YES;
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
    
    [self setBufferSize:buffer];
    
    [self setFetchLimit:fetchLimit];
    
    gyroManager.gyroUpdateInterval = interval;
    
    // Start a sensor
    [gyroManager startGyroUpdatesToQueue:[NSOperationQueue currentQueue]
                             withHandler:^(CMGyroData * _Nullable gyroData,
                                           NSError * _Nullable error) {
                                 
                                 dispatch_async(dispatch_get_main_queue(),^{
                                     
                                     if( error ) {
                                         NSLog(@"%@:%ld", [error domain], [error code] );
                                     } else {
                                         AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
                                         EntityGyroscope* data = (EntityGyroscope *)[NSEntityDescription
                                                                                     insertNewObjectForEntityForName:[self getEntityName]
                                                                                     inManagedObjectContext:delegate.managedObjectContext];
                                         
                                         data.device_id = [self getDeviceId];
                                         data.timestamp = [AWAREUtils getUnixTimestamp:[NSDate new]];
                                         data.axis_x = [NSNumber numberWithDouble:gyroData.rotationRate.x];
                                         data.axis_y = [NSNumber numberWithDouble:gyroData.rotationRate.y];
                                         data.axis_z = [NSNumber numberWithDouble:gyroData.rotationRate.z];
                                         data.accuracy = @0;
                                         data.label =  @"";
                                         
                                         [self setLatestValue:[NSString stringWithFormat:@"%f, %f, %f",gyroData.rotationRate.x,gyroData.rotationRate.y,gyroData.rotationRate.z]];
                                         
                                         NSDictionary *userInfo = [NSDictionary dictionaryWithObject:data
                                                                                              forKey:EXTRA_DATA];
                                         [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_GYROSCOPE
                                                                                             object:nil
                                                                                           userInfo:userInfo];
                                         
                                         [self saveDataToDB];
                                         
                                         
                                         //            NSNumber *unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
                                         //            NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
                                         //            [dic setObject:unixtime forKey:@"timestamp"];
                                         //            [dic setObject:[self getDeviceId] forKey:@"device_id"];
                                         //            [dic setObject:[NSNumber numberWithDouble:gyroData.rotationRate.x] forKey:@"axis_x"];
                                         //            [dic setObject:[NSNumber numberWithDouble:gyroData.rotationRate.y] forKey:@"axis_y"];
                                         //            [dic setObject:[NSNumber numberWithDouble:gyroData.rotationRate.z] forKey:@"axis_z"];
                                         //            [dic setObject:@0 forKey:@"accuracy"];
                                         //            [dic setObject:@"" forKey:@"label"];
                                         //            [self setLatestValue:[NSString stringWithFormat:@"%f, %f, %f",gyroData.rotationRate.x,gyroData.rotationRate.y,gyroData.rotationRate.z]];
                                         //            dispatch_async(dispatch_get_main_queue(), ^{
                                         //                [self saveData:dic];
                                         //            });
                                         
                                     }
                                 });
                             }];
    return YES;
}

- (BOOL)stopSensor{
    [gyroManager stopGyroUpdates];
    return YES;
}


@end
