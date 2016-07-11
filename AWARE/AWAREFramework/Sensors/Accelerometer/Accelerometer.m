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
#import "EntityAccelerometer+CoreDataProperties.h"


@implementation Accelerometer{
    CMMotionManager *manager;
    double sensingInterval;
    int dbWriteInterval; //second
    int currentBufferSize;
    NSMutableArray * bufferArray;
    // NSManagedObjectContext * tempManagedObjectContext;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study{
    self = [super initWithAwareStudy:study
                          sensorName:@"accelerometer"
                        dbEntityName:NSStringFromClass([EntityAccelerometer class])
                              dbType:AwareDBTypeCoreData];
    if (self) {
        manager = [[CMMotionManager alloc] init];
        sensingInterval = 0.1f;
        dbWriteInterval = 30;
        bufferArray = [[NSMutableArray alloc] init];
        currentBufferSize = 0;
        // tempManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        
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
    
    double frequency = sensingInterval;//default value
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
    return [self startSensorWithInterval:sensingInterval];
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
    
    [super startSensor];
    
    // Set and start a data uploader
    NSLog(@"[%@] Start Sensor!", [self getSensorName]);
    
    // Set buffer size for reducing file access
    [self setBufferSize:buffer];
    
    [self setFetchLimit:fetchLimit];
    
    manager.accelerometerUpdateInterval = interval;
    
    // Set and start a motion sensor
    [manager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue]
                                  withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
                                      if( error ) {
                                          NSLog(@"%@:%ld", [error domain], [error code] );
                                      } else {
                                          
                                         // SQLite
                                          
                                          NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
                                          [dict setObject:[AWAREUtils getUnixTimestamp:[NSDate new]] forKey:@"timestamp"];
                                          [dict setObject:[self getDeviceId] forKey:@"device_id"];
                                          [dict setObject:@(accelerometerData.acceleration.x) forKey:@"double_values_0"];
                                          [dict setObject:@(accelerometerData.acceleration.y) forKey:@"double_values_1"];
                                          [dict setObject:@(accelerometerData.acceleration.z) forKey:@"double_values_2"];
                                          [dict setObject:@0 forKey:@"accuracy"];
                                          [dict setObject:@"" forKey:@"label"];
                                          
                                          [self setLatestValue:[NSString stringWithFormat:
                                                                @"%f, %f, %f",
                                                                accelerometerData.acceleration.x,
                                                                accelerometerData.acceleration.y,
                                                                accelerometerData.acceleration.z]];
                                          
                                          NSDictionary *userInfo = [NSDictionary dictionaryWithObject:dict
                                                                                               forKey:EXTRA_DATA];
                                          [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_ACCELEROMETER
                                                                                              object:nil
                                                                                            userInfo:userInfo];
                                          ////// SQLite DB ////////
                                          if([self getDBType] == AwareDBTypeCoreData) {
                                              
                                              // add current sensor data to the buffer array
                                              [bufferArray addObject:dict];
                                              
                                              if (currentBufferSize > [self getBufferSize]) {
                                                  currentBufferSize = 0;
                                                  
                                                  // make parent and child context from background data save
                                                  AppDelegate * delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
                                                  NSManagedObjectContext* parentContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
                                                  [parentContext setPersistentStoreCoordinator:delegate.persistentStoreCoordinator];
                                                  
                                                  NSManagedObjectContext* childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
                                                  [childContext setParentContext:parentContext];
                                                  
                                                  // Copy the buffer and remove the buffer objects
                                                  NSArray * array = [bufferArray copy];
                                                  [bufferArray removeAllObjects];
                                                  
                                                  [childContext performBlock:^{
                                                      if(![self isDBLock]){
                                                          [self lockDB];
                                                          // Convert a NSDictionary to a SQLite Entity
                                                          for (NSDictionary * bufferedData in array) {
                                                              // insert new data
                                                              [self insertNewEntityWithData:bufferedData managedObjectContext:childContext entityName:[self getEntityName]];
                                                          }
                                                          NSError *error = nil;
                                                          if (![childContext save:&error]) {
                                                              // An error is occued
                                                              NSLog(@"Error saving context: %@\n%@", [error localizedDescription], [error userInfo]);
                                                              [bufferArray addObjectsFromArray:array];
                                                          }else{
                                                              // sucess to marge diff to the main context manager
                                                              [parentContext performBlock:^{
                                                                  if(![parentContext save:nil]){
                                                                      // An error is occued
                                                                      NSLog(@"Error saving context");
                                                                      [bufferArray addObjectsFromArray:array];
                                                                  }
                                                                  [self unlockDB];
                                                              }];
                                                          }
                                                          
                                                      }else{
                                                          NSLog(@"[%@] The DB is lock by the other thread", [self getEntityName]);
                                                          [bufferArray addObjectsFromArray:array];
                                                      }
                                                  }];
                                                  
                                              }else{
                                                  currentBufferSize++;
                                              }
                                              
                                            
                                         //////////// Text File based DB ///////////////////////////////////
                                          } else if ([self getDBType] == AwareDBTypeTextFile){
                                                dispatch_async(dispatch_get_main_queue(), ^{
                                                     [self saveData:dict];
                                                });
                                          }
                                      }
                                  }];

    return YES;
}

- (void) insertNewEntityWithData:(NSDictionary *)data managedObjectContext:(NSManagedObjectContext *)context entityName:(NSString *) entityName {
    EntityAccelerometer * entity = (EntityAccelerometer *)[NSEntityDescription
                                                           insertNewObjectForEntityForName:NSStringFromClass([EntityAccelerometer class])
                                                           inManagedObjectContext:context];
    entity.device_id = [self getDeviceId];
    entity.timestamp = [data objectForKey:@"timestamp"];
    entity.double_values_0 = [data objectForKey:@"double_values_0"];
    entity.double_values_1 = [data objectForKey:@"double_values_1"];
    entity.double_values_2 = [data objectForKey:@"double_values_2"];
    entity.accuracy = [data objectForKey:@"accuracy"];
    entity.label = [data objectForKey:@"label"];
}


-(BOOL) stopSensor {
    [super stopSensor];
    [manager stopAccelerometerUpdates];
    return YES;
}


///////////////////////////////////////////////////
///////////////////////////////////////////////////

- (BOOL) setInterval:(double)interval{
    sensingInterval = interval;
    return YES;
}

- (double) getInterval{
    return sensingInterval;
}

- (BOOL)syncAwareDBInForeground{
    return [super syncAwareDBInForeground];
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





//////////////////////////////////////////////////////
//                                              AppDelegate * delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
//                                              NSManagedObjectContext* parentContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
//                                              [parentContext setPersistentStoreCoordinator:delegate.persistentStoreCoordinator];
//
//                                              NSManagedObjectContext* childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
//                                              [childContext setParentContext:parentContext];
//                                              [childContext performBlock:^{
//                                                  EntityAccelerometer * acc = (EntityAccelerometer *)[NSEntityDescription
//                                                                            insertNewObjectForEntityForName:[self getEntityName]
//                                                                            inManagedObjectContext:childContext];
//                                                                            //inManagedObjectContext:delegate.managedObjectContext];
//
//                                                  acc.device_id = [self getDeviceId];
//
//                                                  acc.timestamp = [AWAREUtils getUnixTimestamp:[NSDate new]];
//                                                  acc.double_values_0 = @(accelerometerData.acceleration.x);
//                                                  acc.double_values_1 = @(accelerometerData.acceleration.y);
//                                                  acc.double_values_2 = @(accelerometerData.acceleration.z);
//                                                  acc.accuracy = @0;
//                                                  acc.label = @"";
//
//                                                  NSError *error = nil;
//                                                    [self lockDB];
//                                                    if (![childContext save:&error]) {
//                                                        NSLog(@"Error saving context: %@\n%@", [error localizedDescription], [error userInfo]);
//                                                        // abort();
//                                                    }
//                                                    [parentContext performBlock:^{
//                                                        if(![parentContext save:nil]){
//                                                        }else{
//                                                            [bufferArray removeAllObjects];
//                                                        }
//                                                        [self unlockDB];
//                                                        NSLog(@"[%@] Unlock DB", [self getEntityName]);
//                                                        // NSLog(@"save");
//                                                    }];
//                                              }];

//////////////////////////////////////////////////

//                                                  EntityAccelerometer * acc = nil;
//                                                  @autoreleasepool {
//                                                      //AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
//                                                      acc = (EntityAccelerometer *)[NSEntityDescription
//                                                                                insertNewObjectForEntityForName:[self getEntityName]
//                                                                                inManagedObjectContext:[self getSensorManagedObjectContext]];
//                                                                                //inManagedObjectContext:delegate.managedObjectContext];
//
//                                                      acc.device_id = [self getDeviceId];
//
//                                                      acc.timestamp = [AWAREUtils getUnixTimestamp:[NSDate new]];
//                                                      acc.double_values_0 = @(accelerometerData.acceleration.x);
//                                                      acc.double_values_1 = @(accelerometerData.acceleration.y);
//                                                      acc.double_values_2 = @(accelerometerData.acceleration.z);
//                                                      acc.accuracy = @0;
//                                                      acc.label = @"";
//
//                                                      [self setLatestValue:[NSString stringWithFormat:@"%f, %f, %f",
//                                                                            accelerometerData.acceleration.x,
//                                                                            accelerometerData.acceleration.y,
//                                                                            accelerometerData.acceleration.z]];
//
//                                                      NSDictionary *userInfo = [NSDictionary dictionaryWithObject:acc
//                                                                                                           forKey:EXTRA_DATA];
//                                                      [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_ACCELEROMETER
//                                                                                                          object:nil
//                                                                                       userInfo:userInfo];
//                                                      [self saveDataToDB];
//                                                  }


@end
