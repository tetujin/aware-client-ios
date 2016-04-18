//
//  AWAREPlugin.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 12/19/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWAREPlugin.h"
#import "AWARESensor.h"
#import "AWAREKeys.h"

@implementation AWAREPlugin {
    NSMutableArray* awareSensors;
}

/**
 * Initialization of AWARE Plugin
 */
- (instancetype) initWithPluginName:(NSString *)pluginName awareStudy:(AWAREStudy *) study {
    self = [super initWithSensorName:pluginName withAwareStudy:study];
    if (self) {
        _pluginName = pluginName;
        _deviceId = [study getDeviceId];
        awareSensors = [[NSMutableArray alloc] init];
    }
    return self;
}

- (instancetype)initWithSensorName:(NSString *)sensorName {
    self = [super initWithSensorName:sensorName withAwareStudy:nil];
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
    if (sensor != nil) {
        [awareSensors addObject:sensor];
    }
}
//
//
///**
// * Stop and Remove an AWARE sensor
// */
//- (void) stopAndRemoveAnAwareSensor:(NSString *) sensorName {
//    for ( AWARESensor *sensor in awareSensors ) {
//        if ([sensorName isEqualToString:[sensor getSensorName]]) {
//            [awareSensors removeObject:sensor];
//            
//        }
//    }
//}

- (BOOL) startSensor:(double)upInterval withSettings:(NSArray *)settings{
    [self startAllSensors:upInterval withSettings:settings];
    return YES;
}

/**
 * Start All sensors
 */
- (BOOL)startAllSensors:(double)upInterval
           withSettings:(NSArray *)settings{
//        timer = [NSTimer scheduledTimerWithTimeInterval:upInterval
//                                                          target:self
//                                                        selector:@selector(syncAwareDB)
//                                                        userInfo:nil
//                                                         repeats:YES];
//        [timer fire];
    return YES;
}

- (void)syncAwareDB {
     for (AWARESensor* sensor in awareSensors) {
         [sensor syncAwareDB];
     }
}

- (BOOL)syncAwareDBInForeground {
    bool result = YES;
    for (AWARESensor* sensor in awareSensors) {
        if(![sensor syncAwareDBInForeground]){
            result = NO;
        }
    }
    return result;
}

/**
 * Stop and remove all sensors
 */
- (BOOL)stopAndRemoveAllSensors {
//    if (timer != nil) {
//        [timer invalidate];
//        timer = nil;
//    }
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
