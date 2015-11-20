//
//  AWARESensorManager.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/19/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AWARESensor.h"

@interface AWARESensorManager : NSObject{
    NSMutableArray* awareSensors;
}

- (void) stopAllSensors;
- (void) stopASensor:(NSString *) sensorName;
- (void) addNewSensor:(AWARESensor *) sensor;
- (NSString*)getLatestSensorData:(NSString *)sensorName;

@end
