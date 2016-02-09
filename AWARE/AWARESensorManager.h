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

@interface AWARESensorManager : NSObject{
    NSMutableArray* awareSensors;
}

- (void) stopAllSensors;
- (void) stopASensor:(NSString *) sensorName;
- (void) addNewSensor:(AWARESensor *) sensor;
- (bool) addNewSensorWithSensorName:(NSString *)sensorName
                           settings:(NSArray*)settings
                            plugins:(NSArray*)plugins
                     uploadInterval:(double) uploadTime;
- (NSString*)getLatestSensorData:(NSString *)sensorName;
- (bool) syncAllSensorsWithDB;
@end
