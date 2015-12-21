//
//  AWAREPlugin.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 12/19/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWAREPlugin.h"
#import "AWARESensor.h"

@implementation AWAREPlugin {
    NSMutableArray* awareSensors;
}

/**
 * Initialization of AWARE Plugin
 */
- (instancetype) initWithPluginName:(NSString *)pluginName deviceId:(NSString*) deviceId {
    self = [super initWithSensorName:pluginName];
    if (self) {
        _pluginName = pluginName;
        _deviceId = deviceId;
        awareSensors = [[NSMutableArray alloc] init];
    }
    return self;
}

- (instancetype)initWithSensorName:(NSString *)sensorName {
    self = [super initWithSensorName:sensorName];
    NSLog(@"====[ERROR]====");
    NSLog(@"Please init with initWithPluginName:pluginName:deviceId method. This initializer is ilelgal for init for AWARE plugin.");
    if (self) {
        _pluginName = sensorName;
        _deviceId = [self getDeviceId];
        awareSensors = [[NSMutableArray alloc] init];
    }
    return self;
}


/**
 * Get a device Id
 */
- (NSString*) getDeviceId {
    return _deviceId;
}

/**
 * Add new AWARE Sensor
 */
- (void) addAnAwareSensor:(AWARESensor *) sensor {
    [awareSensors addObject:sensor];
}


/**
 * Stop and Remove an AWARE sensor
 */
- (void) stopAndRemoveAnAwareSensor:(NSString *) sensorName {
    for ( AWARESensor *sensor in awareSensors ) {
        if ([sensorName isEqualToString:[sensor getSensorName]]) {
            [awareSensors removeObject:sensor];
        }
    }
}

/**
 * Start All sensors
 */
- (BOOL)startAllSensors:(double)upInterval
           withSettings:(NSArray *)settings{
    for (AWARESensor* sensor in awareSensors) {
        [sensor startSensor:upInterval withSettings:settings];
    }
    return YES;
}


- (BOOL) startSensor:(double)upInterval withSettings:(NSArray *)settings{
    [self startAllSensors:upInterval withSettings:settings];
    return YES;
}

/**
 * Stop and remove all sensors
 */
- (BOOL)stopAndRemoveAllSensors {
    for (AWARESensor* sensor in awareSensors) {
        [sensor stopSensor];
    }
    [awareSensors removeAllObjects];
    return NO;
}


- (BOOL) stopSensor{
    [self stopAndRemoveAllSensors];
    return YES;
}

@end
