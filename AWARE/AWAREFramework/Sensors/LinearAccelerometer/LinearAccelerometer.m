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
#import "EntityLinearAccelerometer.h"
#import "AppDelegate.h"

@implementation LinearAccelerometer {
    CMMotionManager* motionManager;
    int bufferCount;
}


- (instancetype)initWithAwareStudy:(AWAREStudy *)study{
    self = [super initWithAwareStudy:study
                          sensorName:SENSOR_LINEAR_ACCELEROMETER
                        dbEntityName:NSStringFromClass([EntityLinearAccelerometer class])
                              dbType:AwareDBTypeCoreData];
    if (self) {
        motionManager = [[CMMotionManager alloc] init];
        bufferCount = 0;
    }
    return self;
}

- (void) createTable{
    NSLog(@"[%@] Create Table", [self getSensorName]);
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


- (BOOL)startSensorWithSettings:(NSArray *)settings{
    // Get sensing interval(frequency) from settings
    double interval = 0.1f; //default interval
    double frequency = [self getSensorSetting:settings withKey:@"frequency_linear_accelerometer"];
    if(frequency != -1){
        NSLog(@"Linear Accelerometer's frequency is %f !!", frequency);
        double iOSfrequency = [self convertMotionSensorFrequecyFromAndroid:frequency];
        interval = iOSfrequency;
    }
    
    // Set a buffer size for reducing file access
    [self setBufferSize:100];
    
    // Start a motion sensor
    NSLog(@"[%@] Start Linear Acc Sensor", [self getSensorName]);
    if( motionManager.deviceMotionAvailable ){
        motionManager.deviceMotionUpdateInterval = interval;
        [motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue]
                                           withHandler:^(CMDeviceMotion *motion, NSError *error){
                                               // Save sensor data to the local database
                                               
                                               dispatch_async(dispatch_get_main_queue(),^{
                                               AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
                                               EntityLinearAccelerometer* data = (EntityLinearAccelerometer *)[NSEntityDescription
                                                                                           insertNewObjectForEntityForName:[self getEntityName]
                                                                                           inManagedObjectContext:delegate.managedObjectContext];
                                               
                                               data.device_id = [self getDeviceId];
                                               data.timestamp = [AWAREUtils getUnixTimestamp:[NSDate new]];
                                               data.double_values_0 = [NSNumber numberWithDouble:motion.userAcceleration.x];
                                               data.double_values_1 = [NSNumber numberWithDouble:motion.userAcceleration.y];
                                               data.double_values_2 = [NSNumber numberWithDouble:motion.userAcceleration.z];
                                               data.accuracy = @0;
                                               data.label =  @"";
                                               
                                               [self setLatestValue:[NSString stringWithFormat:@"%f, %f, %f",
                                                                     motion.userAcceleration.z,
                                                                     motion.userAcceleration.y,
                                                                     motion.userAcceleration.z]];
                                               
                                               NSDictionary *userInfo = [NSDictionary dictionaryWithObject:data
                                                                                                    forKey:EXTRA_DATA];
                                               [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_LINEAR_ACCELEROMETER
                                                                                                   object:nil
                                                                                                 userInfo:userInfo];
                                               
                                               if(bufferCount > [self getBufferSize] ){
                                                   NSError * e = nil;
                                                   [delegate.managedObjectContext save:&e];
                                                   if (e) {
                                                       NSLog(@"%@", e.description);
                                                   }
                                                   NSLog(@"Save linear accelerometer data to SQLite");
                                                   bufferCount = 0;
                                               }else{
                                                   bufferCount++;
                                               }

                                               
                                               
                                               [self setLatestValue:[NSString stringWithFormat:@"%f, %f, %f",motion.userAcceleration.x, motion.userAcceleration.y,motion.userAcceleration.z]];
                                               });
                                           }];
    }
    return YES;
}


- (BOOL)stopSensor{
    [motionManager stopDeviceMotionUpdates];
    motionManager = nil;
    return YES;
}

//////////////////////////////////////////////////
//NSNumber *unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
//NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
//[dic setObject:unixtime forKey:@"timestamp"];
//[dic setObject:[self getDeviceId] forKey:@"device_id"];
//[dic setObject:[NSNumber numberWithDouble:motion.userAcceleration.x] forKey:@"double_values_0"]; //double
//[dic setObject:[NSNumber numberWithDouble:motion.userAcceleration.y]  forKey:@"double_values_1"]; //double
//[dic setObject:[NSNumber numberWithDouble:motion.userAcceleration.z]  forKey:@"double_values_2"]; //double
//[dic setObject:@0 forKey:@"accuracy"];//int
//[dic setObject:@"" forKey:@"label"]; //text
//[self setLatestValue:[NSString stringWithFormat:@"%f, %f, %f",motion.userAcceleration.x, motion.userAcceleration.y,motion.userAcceleration.z]];
//dispatch_async(dispatch_get_main_queue(), ^{
//    [self saveData:dic toLocalFile:SENSOR_LINEAR_ACCELEROMETER];
//});


@end
