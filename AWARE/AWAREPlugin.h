//
//  AWAREPlugin.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 12/19/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"


@protocol AWAREPluginDelegate <NSObject>
- (instancetype)initWithPluginName:(NSString *)pluginName deviceId:(NSString*) deviceId;
- (BOOL) startAllSensors:(double)upInterval withSettings:(NSArray *)settings;
- (BOOL) stopAndRemoveAllSensors;
@end

@interface AWAREPlugin : AWARESensor <AWAREPluginDelegate> //[TODO] I want to remove AWARESensor. This is bad part..

@property (strong, nonatomic) IBOutlet NSString* pluginName;
@property (strong, nonatomic) IBOutlet NSString* deviceId;

/**
 * Init
 */
- (instancetype) initWithPluginName:(NSString *)pluginName deviceId:(NSString *)deviceId;


- (NSString *) getDeviceId ;

/**
 * Add new AWARE Sensor
 */
- (void) addAnAwareSensor:(AWARESensor *) sensor ;


///**
// * Stop and Remove an AWARE sensor
// */
//- (void) stopAndRemoveAnAwareSensor:(NSString *) sensorName;

/**
 * Start All sensors
 */
- (BOOL)startAllSensors:(double)upInterval withSettings:(NSArray *)settings;

/**
 * Stop and remove all sensors
 */
- (BOOL)stopAndRemoveAllSensors;


- (BOOL) startSensor:(double)upInterval withSettings:(NSArray *)settings;

- (BOOL) stopSensor;

@end
