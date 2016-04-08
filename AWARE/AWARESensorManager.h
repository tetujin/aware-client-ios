//
//  AWARESensorManager.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/19/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SVProgressHUD.h>
#import <AudioToolbox/AudioServices.h>

#import "AWARESensor.h"
#import "AWAREStudy.h"

@interface AWARESensorManager : NSObject

/** Initializer */
- (instancetype)initWithAWAREStudy:(AWAREStudy *) study;

// lock and unlock the sensor manager
- (void) lock;
- (void) unlock;
- (BOOL) isLocked;

// add a new sensor
- (void) addNewSensor:(AWARESensor *) sensor;
- (BOOL) isExist :(NSString *) key;
//- (bool) addNewSensorWithSensorName:(NSString *)sensorName
//                     uploadInterval:(double) uploadTime;


// sensor manager (start and stop)
- (BOOL) startAllSensors;
- (BOOL) startAllSensorsWithStudy:(AWAREStudy *) study;
- (BOOL) createAllTables;

- (void) stopAndRemoveAllSensors;
- (void) stopASensor:(NSString *) sensorName;


// uploader in the foreground and background
- (bool) syncAllSensorsWithDBInForeground;
- (bool) syncAllSensorsWithDBInBackground;

// upload timer
- (void) startUploadTimerWithInterval:(double) interval;
- (void) stopUploadTimer;

// get latest sensor data with sensor name
- (NSString*)getLatestSensorData:(NSString *)sensorName;


@end
