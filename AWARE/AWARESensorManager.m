//
//  AWARESensorManager.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/19/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensorManager.h"

@implementation AWARESensorManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        awareSensors = [[NSMutableArray alloc] init];
    }
    return self;
}


- (void)addNewSensor:(AWARESensor *)sensor{
    [awareSensors addObject:sensor];
}

- (void)stopAllSensors{
    for (AWARESensor* sensor in awareSensors) {
        [sensor stopSensor];
    }
    awareSensors = [[NSMutableArray alloc] init];
}


- (void)stopASensor:(NSString *)sensorName{
    for (AWARESensor* sensor in awareSensors) {
        if ([sensor.getSensorName isEqualToString:sensorName]) {
            [sensor stopSensor];
        }
        [sensor stopSensor];
    }
}

- (NSString*)getLatestSensorData:(NSString *)sensorName{
    for (AWARESensor* sensor in awareSensors) {
//        NSLog(@"%@ <---> %@", sensor.getSensorName, sensorName);
        if ([sensor.getSensorName isEqualToString:sensorName]) {
            NSString *sensorValue = [sensor getLatestValue];
            return sensorValue;
        }
    }
    return @"";
}

@end
