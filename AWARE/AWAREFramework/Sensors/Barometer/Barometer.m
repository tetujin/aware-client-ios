//
//  Barometer.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/20/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "Barometer.h"
#import "AppDelegate.h"
#import "EntityBarometer.h"

@implementation Barometer{
    CMAltimeter* altitude;
    double defaultInterval;
    int dbWriteInterval;
}


- (instancetype)initWithAwareStudy:(AWAREStudy *)study{
    self = [super initWithAwareStudy:study sensorName:SENSOR_BAROMETER
                        dbEntityName:NSStringFromClass([EntityBarometer class])
                              dbType:AwareDBTypeCoreData];
    if (self) {
        defaultInterval = 0.2f;
        dbWriteInterval = 10;
    }
    return self;
}


- (void) createTable{
    NSLog(@"[%@] Create Table", [self getSensorName]);
    TCQMaker * tcqMaker = [[TCQMaker alloc] init];
    [tcqMaker addColumn:@"double_values_0" type:TCQTypeReal default:@"0"];
    [tcqMaker addColumn:@"accuracy" type:TCQTypeInteger default:@"0"];
    [tcqMaker addColumn:@"label" type:TCQTypeText default:@"''"];
    NSString * query = [tcqMaker getDefaudltTableCreateQuery];
    [super createTable:query];
}

- (BOOL)startSensorWithSettings:(NSArray *)settings{
    
    // Get a sensing frequency
    double frequency = [self getSensorSetting:settings withKey:@"frequency_barometer"];
    if(frequency != -1){
        // NOTE: The frequency value is a microsecond
        frequency = frequency/100000;
    }else{
        // default value = 200000(microseconds) = 0.2(second)
        frequency = defaultInterval;
    }
    
    // Set a buffer size for reducing file access
    int buffer = (int)(dbWriteInterval/frequency);
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
    [self setFetchLimit:fetchLimit];
    [self setBufferSize:buffer];
    
    // Set and start a sensor
    NSLog(@"[%@] Start Barometer Sensor", [self getSensorName]);
    if (![CMAltimeter isRelativeAltitudeAvailable]) {
        NSLog(@"This device doesen't support CMAltimeter.");
    } else {
        altitude = [[CMAltimeter alloc] init];
        [altitude startRelativeAltitudeUpdatesToQueue:[NSOperationQueue mainQueue]
                                          withHandler:^(CMAltitudeData *altitudeData, NSError *error) {
                                              
                                              dispatch_async(dispatch_get_main_queue(),^{
                                                  double pressureDouble = [altitudeData.pressure doubleValue];
                                                  
                                                  // AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
                                                  EntityBarometer * pressureData = (EntityBarometer *)[NSEntityDescription
                                                                                                       insertNewObjectForEntityForName:[self getEntityName]
                                                                                                       inManagedObjectContext:[self getSensorManagedObjectContext]];
                                                                                                       //inManagedObjectContext:delegate.managedObjectContext];
                                                  
                                                  pressureData.device_id = [self getDeviceId];
                                                  pressureData.timestamp = [AWAREUtils getUnixTimestamp:[NSDate new]];
                                                  pressureData.double_values_0 = [NSNumber numberWithDouble:(pressureDouble * 10.0f)];
                                                  pressureData.accuracy = @0;
                                                  pressureData.label = @"";
                                                  
                                                  [self setLatestValue:[NSString stringWithFormat:@"%f", (pressureDouble * 10.0f)]];
                                                  
                                                  NSDictionary *userInfo = [NSDictionary dictionaryWithObject:pressureData
                                                                                                       forKey:EXTRA_DATA];
                                                  [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_BAROMETER
                                                                                                      object:nil
                                                                                                    userInfo:userInfo];
                                                  [self saveDataToDB];
                                              });
                                              //
                                              //                                               NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
                                              //                                               NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
                                              //                                               [dic setObject:unixtime forKey:@"timestamp"];
                                              //                                               [dic setObject:[self getDeviceId] forKey:@"device_id"];
                                              //                                               [dic setObject:[NSNumber numberWithDouble:pressure_f*10.0f] forKey:@"double_values_0"];
                                              //                                               [dic setObject:@0 forKey:@"accuracy"];
                                              //                                               [dic setObject:@"" forKey:@"label"];
                                              //                                               [self setLatestValue:[NSString stringWithFormat:@"%f", pressure_f*10.0f]];
                                              //                                               
                                              //                                               dispatch_async(dispatch_get_main_queue(), ^{
                                              //                                                   [self saveData:dic];
                                              //                                               });
                                          }];
    }
    return YES;
}

- (BOOL)stopSensor{
    // Stop a altitude sensor
    [altitude stopRelativeAltitudeUpdates];
    altitude = nil;
    
    return YES;
}


@end
