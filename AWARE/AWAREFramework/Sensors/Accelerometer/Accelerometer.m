//
//  Accelerometer.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/19/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "Accelerometer.h"
#import "AWAREUtils.h"
#import "AppDelegate.h"
#import "EntityAccelerometer.h"


@implementation Accelerometer{
    CMMotionManager *manager;
    double defaultInterval;
    int dbWriteInterval; //second
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study{
    self = [super initWithAwareStudy:study
                          sensorName:@"accelerometer"
                        dbEntityName:NSStringFromClass([EntityAccelerometer class])
                              dbType:AwareDBTypeCoreData];
    if (self) {
        manager = [[CMMotionManager alloc] init];
        defaultInterval = 0.1f;
        dbWriteInterval = 10;
    }
    return self;
}

- (void) createTable {
    NSLog(@"[%@] Create Table", [self getSensorName]);
    TCQMaker * queryMaker = [[TCQMaker alloc] init];
    [queryMaker addColumn:@"double_values_0" type:TCQTypeReal default:@"0"];
    [queryMaker addColumn:@"double_values_1" type:TCQTypeReal default:@"0"];
    [queryMaker addColumn:@"double_values_2" type:TCQTypeReal default:@"0"];
    [queryMaker addColumn:@"accuracy" type:TCQTypeInteger default:@"0"];
    [queryMaker addColumn:@"label" type:TCQTypeText default:@"''"];
    NSString * query = [queryMaker getDefaudltTableCreateQuery];
    [super createTable:query];
}


/**
 *
 */
- (BOOL) startSensorWithSettings:(NSArray *)settings{
    double frequency = defaultInterval;//default value
    if(settings != nil){
        // Get a sensing frequency from settings
        double tempFrequency = [self getSensorSetting:settings withKey:@"frequency_accelerometer"];
        if(tempFrequency != -1){
            NSLog(@"Accelerometer's frequency is %f !!", tempFrequency);
            frequency = [self convertMotionSensorFrequecyFromAndroid:tempFrequency];
        }
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
            
/**
 * Start sensor with interval and buffer, fetchLimit
 */
- (BOOL) startSensorWithInterval:(double)interval bufferSize:(int)buffer fetchLimit:(int)fetchLimit{
    // Set and start a data uploader
    NSLog(@"[%@] Start Sensor!", [self getSensorName]);
    
    // Set buffer size for reducing file access
    [self setBufferSize:buffer];
    
    [self setFetchLimit:fetchLimit];
    
    manager.accelerometerUpdateInterval = interval;
    
    // Set and start a motion sensor
    [manager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue]
                                  withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
                                      if( error )
                                          
                                      {
                                          NSLog(@"%@:%ld", [error domain], [error code] );
                                      } else {
                                         // SQLite
                                          // @autoreleasepool {
                                              if([self getDBType] == AwareDBTypeCoreData){
                                                
                                                  EntityAccelerometer * acc = nil;
                                                  @autoreleasepool {
                                                      //AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
                                                      acc = (EntityAccelerometer *)[NSEntityDescription
                                                                                insertNewObjectForEntityForName:[self getEntityName]
                                                                                inManagedObjectContext:[self getSensorManagedObjectContext]];
                                                                                //inManagedObjectContext:delegate.managedObjectContext];
                                                      
                                                      acc.device_id = [self getDeviceId];
                                                      
                                                      acc.timestamp = [AWAREUtils getUnixTimestamp:[NSDate new]];
                                                      acc.double_values_0 = @(accelerometerData.acceleration.x);
                                                      acc.double_values_1 = @(accelerometerData.acceleration.y);
                                                      acc.double_values_2 = @(accelerometerData.acceleration.z);
                                                      acc.accuracy = @0;
                                                      acc.label = @"";
                                                      
                                                      [self setLatestValue:[NSString stringWithFormat:@"%f, %f, %f",
                                                                            accelerometerData.acceleration.x,
                                                                            accelerometerData.acceleration.y,
                                                                            accelerometerData.acceleration.z]];
                                                      
                                                      NSDictionary *userInfo = [NSDictionary dictionaryWithObject:acc
                                                                                                           forKey:EXTRA_DATA];
                                                      [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_ACCELEROMETER
                                                                                                          object:nil
                                                                                       userInfo:userInfo];
                                                      [self saveDataToDB];
                                                  }
                                            // Text File
                                              } else if ([self getDBType] == AwareDBTypeTextFile){
                                                    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
                                                    [dic setObject:[AWAREUtils getUnixTimestamp:[NSDate new]] forKey:@"timestamp"];
                                                    [dic setObject:[self getDeviceId] forKey:@"device_id"];
                                                    [dic setObject:[NSNumber numberWithDouble:accelerometerData.acceleration.x] forKey:@"double_values_0"];
                                                    [dic setObject:[NSNumber numberWithDouble:accelerometerData.acceleration.y] forKey:@"double_values_1"];
                                                    [dic setObject:[NSNumber numberWithDouble:accelerometerData.acceleration.z] forKey:@"double_values_2"];
                                                    [dic setObject:@0 forKey:@"accuracy"];
                                                    [dic setObject:@"" forKey:@"label"];
                                                    [self setLatestValue:[NSString stringWithFormat:
                                                                          @"%f, %f, %f",
                                                                          accelerometerData.acceleration.x,
                                                                      accelerometerData.acceleration.y,
                                                                      accelerometerData.acceleration.z]];
                                                    dispatch_async(dispatch_get_main_queue(), ^{
                                                         [self saveData:dic];
                                                    });

                                              }
                                          
                                          
                                      }
                                      
                                  }];

    return YES;
}


-(BOOL) stopSensor{
    [manager stopAccelerometerUpdates];
    return YES;
}



////////////////////////////////////////////////////
///////////////////////////////////////////////////

- (void)syncAwareDB{
    [super syncAwareDB];
}


///////////////////////////////////////////////////
///////////////////////////////////////////////////

//- (void)setSensingInterval:(double)interval{
//    if(interval > 0){
//        sensingInterval = interval;
//    }else{
//        NSLog(@"[NOTE] '%f' is wrong value for this sensor.", interval);
//    }
//}


// The observer object is needed when unregistering
//    NSObject * observer =
//    [[NSNotificationCenter defaultCenter] addObserverForName:@"Accelerometer.ACTION_AWARE_ACCELEROMETER" object:nil queue:nil usingBlock:^(NSNotification *notif) {
//
//        if ([[notif name] isEqualToString:@"Accelerometer.ACTION_AWARE_ACCELEROMETER"]) {
//            NSDictionary *userInfo = notif.userInfo;
//            CMAccelerometerData *dataObject = [userInfo objectForKey:@"Accelerometer.EXTRA_DATA"];
//            // Your response to the notification should be placed here
//            NSLog(@"acc x %f", dataObject.acceleration.x);
//        }
//    }];





//                                              NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
//                                              [dic setObject:[AWAREUtils getUnixTimestamp:[NSDate new]] forKey:@"timestamp"];
//                                              [dic setObject:[self getDeviceId] forKey:@"device_id"];
//                                              [dic setObject:[NSNumber numberWithDouble:accelerometerData.acceleration.x] forKey:@"double_values_0"];
//                                              [dic setObject:[NSNumber numberWithDouble:accelerometerData.acceleration.y] forKey:@"double_values_1"];
//                                              [dic setObject:[NSNumber numberWithDouble:accelerometerData.acceleration.z] forKey:@"double_values_2"];
//                                              [dic setObject:@0 forKey:@"accuracy"];
//                                              [dic setObject:@"" forKey:@"label"];
//                                              [self setLatestValue:[NSString stringWithFormat:
//                                                                    @"%f, %f, %f",
//                                                                    accelerometerData.acceleration.x,
//                                                                accelerometerData.acceleration.y,
//                                                                accelerometerData.acceleration.z]];
//                                            dispatch_async(dispatch_get_main_queue(), ^{
//                                                NSDictionary *userInfo = [NSDictionary dictionaryWithObject:accelerometerData
//                                                                                                     forKey:@"Accelerometer.EXTRA_DATA"];
//
//                                                [[NSNotificationCenter defaultCenter] postNotificationName:@"Accelerometer.ACTION_AWARE_ACCELEROMETER"
//                                                                                                    object:nil
//                                                                                                  userInfo:userInfo];
////                                              [self saveData:dic];
//                                                // You can also unregister notification types/names using
//                                                [[NSNotificationCenter defaultCenter] removeObserver:self name:@"Accelerometer.ACTION_AWARE_ACCELEROMETER" object:nil];
//
//
//                                            });

@end
