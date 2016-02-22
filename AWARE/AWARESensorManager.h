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

@interface AWARESensorManager : NSObject{
    NSMutableArray* awareSensors;
    AWAREStudy * awareStudy;
}

- (instancetype)initWithAWAREStudy:(AWAREStudy *) study;

- (void) stopAndRemoveAllSensors;
- (void) stopASensor:(NSString *) sensorName;
- (void) addNewSensor:(AWARESensor *) sensor;
- (bool) addNewSensorWithSensorName:(NSString *)sensorName
                     uploadInterval:(double) uploadTime;
- (NSString*)getLatestSensorData:(NSString *)sensorName;
- (bool) syncAllSensorsWithDBInForeground;
- (bool) syncAllSensorsWithDBInBackground;
- (BOOL) isExist :(NSString *) key;

// uploader
- (void) startUploadTimerWithInterval:(double) interval;
- (void) stopUploadTimer;

@end
