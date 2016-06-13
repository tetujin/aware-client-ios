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
    int bufferCount;
}


- (instancetype)initWithAwareStudy:(AWAREStudy *)study{
    self = [super initWithAwareStudy:study sensorName:SENSOR_BAROMETER
                        dbEntityName:NSStringFromClass([EntityBarometer class])
                              dbType:AwareDBTypeCoreData];
    if (self) {
        bufferCount = 0;
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
        frequency = 0.2;
    }
    
    // Set a buffer size for reducing file access
    [self setBufferSize:10];
    
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
                                               
                                               AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
                                               EntityBarometer * pressureData = (EntityBarometer *)[NSEntityDescription
                                                                                                   insertNewObjectForEntityForName:[self getEntityName]
                                                                                                   inManagedObjectContext:delegate.managedObjectContext];
                                               
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
                                               
                                               if( bufferCount > [self getBufferSize]  ){
                                                  NSError * error = nil;
                                                   [delegate.managedObjectContext save:&error];
                                                   if (error) {
                                                       NSLog(@"%@", error.description);
                                                   }
                                                   NSLog(@"Save barometer data to SQLite");
                                                   bufferCount = 0;
                                               }else{
                                                   bufferCount++;
                                               }
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
