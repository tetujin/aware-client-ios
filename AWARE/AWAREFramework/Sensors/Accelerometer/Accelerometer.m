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
    int bufferCount;
    double sensingInterval;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study{
    self = [super initWithAwareStudy:study
                          sensorName:@"accelerometer"
                        dbEntityName:NSStringFromClass([EntityAccelerometer class])
                              dbType:AwareDBTypeCoreData];
    if (self) {
        manager = [[CMMotionManager alloc] init];
        bufferCount = 0;
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
    
    //    NSString *query = [[NSString alloc] init];
    //    query = @"_id integer primary key autoincrement,"
    //    "timestamp real default 0,"
    //    "device_id text default '',"
    //    "double_values_0 real default 0,"
    //    "double_values_1 real default 0,"
    //    "double_values_2 real default 0,"
    //    "accuracy integer default 0,"
    //    "label text default '',"
    //    "UNIQUE (timestamp,device_id)";
    
}

-(BOOL)startSensorWithSettings:(NSArray *)settings{
    
    // Set and start a data uploader
    NSLog(@"[%@] Start Sensor!", [self getSensorName]);
    
    // Set buffer size for reducing file access
    [self setBufferSize:100];
    
    
    double frequency = 0.1f;//default value
    if(settings != nil){
        // Get a sensing frequency from settings
        double tempFrequency = [self getSensorSetting:settings withKey:@"frequency_accelerometer"];
        if(tempFrequency != -1){
            NSLog(@"Accelerometer's frequency is %f !!", tempFrequency);
            frequency = [self convertMotionSensorFrequecyFromAndroid:tempFrequency];
        }
    }else{
        if (sensingInterval > 0) {
            frequency = sensingInterval;
        }
    }
    
    manager.accelerometerUpdateInterval = frequency;

    // Set and start a motion sensor
    [manager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue]
                                  withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
                                      if( error )
                                      
                                      {
                                          NSLog(@"%@:%ld", [error domain], [error code] );
                                      } else {
                                          
                                        AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
                                              
                                        EntityAccelerometer * acc = (EntityAccelerometer *)[NSEntityDescription
                                                                                                  insertNewObjectForEntityForName:[self getEntityName]
                                                                                                                                                inManagedObjectContext:delegate.managedObjectContext];

                                                      acc.device_id = [self getDeviceId];
                                                                                                          
                                                      acc.timestamp = [AWAREUtils getUnixTimestamp:[NSDate new]];
                                                      acc.double_values_0 = [NSNumber numberWithDouble:accelerometerData.acceleration.x];
                                                      acc.double_values_1 = [NSNumber numberWithDouble:accelerometerData.acceleration.y];
                                                      acc.double_values_2 = [NSNumber numberWithDouble:accelerometerData.acceleration.z];
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
    //                                                  NSLog(@"%d > %d", bufferCount , [self getBufferSize]);
                                                      if( bufferCount > [self getBufferSize]){
                                                          if(![self saveDataToDB]){
                                                              NSLog(@"[%@] DB is not ready now", [self getEntityName]);
                                                          }
//                                                          NSError *error = nil;
//                                                          if (! [delegate.managedObjectContext save:&error]) {
//                                                              NSLog(@"Error saving context: %@\n%@",
//                                                                    [error localizedDescription], [error userInfo]);
//                                                          }
//                                                          NSLog(@"Save acc data to SQLite");
                                                          bufferCount = 0;
                                                      }else{
                                                          bufferCount++;
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

- (void)setSensingInterval:(double)interval{
    if(interval > 0){
        sensingInterval = interval;
    }else{
        NSLog(@"[NOTE] '%f' is wrong value for this sensor.", interval);
    }
}


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
