//
//  AWARESensorManager.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/19/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//
// This class manages AWARESensors' start and stop operation.
// And also, you can upload sensor data manually by using this class.
//
//

#import "AWARESensorManager.h"
#import "AWAREStudy.h"
#import "AWAREKeys.h"
#import "AWAREPlugin.h"

// AWARE Sensors
#import "Accelerometer.h"
#import "Gyroscope.h"
#import "Magnetometer.h"
#import "Battery.h"
#import "Barometer.h"
#import "Locations.h"
#import "Network.h"
#import "Wifi.h"
#import "Processor.h"
#import "Gravity.h"
#import "LinearAccelerometer.h"
#import "Bluetooth.h"
#import "AmbientNoise.h"
#import "Screen.h"
#import "NTPTime.h"
#import "Proximity.h"
#import "Timezone.h"
#import "Calls.h"
#import "ESM.h"

// AWARE Plugins
#import "ActivityRecognition.h"
#import "OpenWeather.h"
#import "DeviceUsage.h"
#import "MSBand.h"
#import "GoogleCalPull.h"
#import "GoogleCalPush.h"
#import "GoogleLogin.h"
#import "Scheduler.h"
#import "FusedLocations.h"

@implementation AWARESensorManager{
    NSTimer * uploadTimer;
}


- (instancetype)init {
    return [self initWithAWAREStudy:[[AWAREStudy alloc]init]];
}

- (instancetype)initWithAWAREStudy:(AWAREStudy *) study {
    self = [super init];
    if (self) {
        awareSensors = [[NSMutableArray alloc] init];
        awareStudy = study;
    }
    return self;
}


/**
 * Add a new sensor with upload interval
 * 
 * @param key           A key for a sensor with NSString
 * @param settings      Settings of AWARE Study with NSArray
 * @param plugings      Plugin sessings of AWARE Setudy with NSArray
 * @param uploadTime    An upload insterval (second) with double
 * @return A result of the generation of new sensor
 */
- (bool) addNewSensorWithSensorName:(NSString *)key
                     uploadInterval:(double) uploadTime{
    
    if ([[awareStudy getStudyId] isEqualToString:@""]) {
        NSLog( @"[%@] ERROR: You did not have a StudyID. Please check your study configuration.", key );
        return NO;
    }
    
    // sensors settings
    NSArray *sensors = [awareStudy getSensors];
    
    // plugins settings
    NSArray *plugins = [awareStudy  getPlugins];
    
    /// start and make a sensor instance
    AWARESensor* awareSensor = nil;
    for (int i=0; i<sensors.count; i++) {
        NSString *setting = [[sensors objectAtIndex:i] objectForKey:@"setting"];
        NSString *settingKey = [NSString stringWithFormat:@"status_%@",key];
        if ([setting isEqualToString:settingKey]) {
            NSString * value = [[sensors objectAtIndex:i] objectForKey:@"value"];
            bool exit = [self isExist:key];
            if ([value isEqualToString:@"true"] && !exit) {
                if ([key isEqualToString:SENSOR_ACCELEROMETER]) {
                    awareSensor= [[Accelerometer alloc] initWithSensorName:SENSOR_ACCELEROMETER withAwareStudy:awareStudy];
                }else if([key isEqualToString:SENSOR_BAROMETER]){
                    awareSensor = [[Barometer alloc] initWithSensorName:SENSOR_BAROMETER withAwareStudy:awareStudy];
                }else if([key isEqualToString:SENSOR_GYROSCOPE]){
                    awareSensor = [[Gyroscope alloc] initWithSensorName:SENSOR_GYROSCOPE withAwareStudy:awareStudy];
                }else if([key isEqualToString:SENSOR_MAGNETOMETER]){
                    awareSensor = [[Magnetometer alloc] initWithSensorName:SENSOR_MAGNETOMETER  withAwareStudy:awareStudy];
                }else if([key isEqualToString:SENSOR_BATTERY]){
                    awareSensor = [[Battery alloc] initWithSensorName:SENSOR_BATTERY  withAwareStudy:awareStudy];
                }else if([key isEqualToString:SENSOR_LOCATIONS]){
                    awareSensor = [[Locations alloc] initWithSensorName:SENSOR_LOCATIONS  withAwareStudy:awareStudy];
                }else if([key isEqualToString:SENSOR_NETWORK]){
                    awareSensor = [[Network alloc] initWithSensorName:SENSOR_NETWORK withAwareStudy:awareStudy];
                }else if([key isEqualToString:SENSOR_WIFI]){
                    awareSensor = [[Wifi alloc] initWithSensorName:SENSOR_WIFI withAwareStudy:awareStudy];
                }else if ([key isEqualToString:SENSOR_PROCESSOR]){
                    awareSensor = [[Processor alloc] initWithSensorName:SENSOR_PROCESSOR withAwareStudy:awareStudy];
                }else if ([key isEqualToString:SENSOR_GRAVITY]){
                    awareSensor = [[Gravity alloc] initWithSensorName:SENSOR_GRAVITY withAwareStudy:awareStudy];
                }else if([key isEqualToString:SENSOR_LINEAR_ACCELEROMETER]){
                    awareSensor = [[LinearAccelerometer alloc] initWithSensorName:SENSOR_LINEAR_ACCELEROMETER withAwareStudy:awareStudy];
                }else if([key isEqualToString:SENSOR_BLUETOOTH]){
                    awareSensor = [[Bluetooth alloc] initWithSensorName:SENSOR_BLUETOOTH withAwareStudy:awareStudy];
                }else if([key isEqualToString:SENSOR_SCREEN]){
                    awareSensor = [[Screen alloc] initWithSensorName:SENSOR_SCREEN withAwareStudy:awareStudy];
                }else if([key isEqualToString:SENSOR_PROXIMITY]){
                    awareSensor = [[Proximity alloc] initWithSensorName:SENSOR_PROXIMITY withAwareStudy:awareStudy];
                }else if([key isEqualToString:SENSOR_TIMEZONE]){
                    awareSensor = [[Timezone alloc] initWithSensorName:SENSOR_TIMEZONE withAwareStudy:awareStudy];
                }else if([key isEqualToString:SENSOR_ESMS]){
                    awareSensor = [[ESM alloc] initWithSensorName:SENSOR_ESMS withAwareStudy:awareStudy];
                }else if([key isEqualToString:SENSOR_CALLS]){
                    awareSensor = [[Calls alloc] initWithSensorName:SENSOR_CALLS withAwareStudy:awareStudy];
                }
//                 Start AWARESensor with some delay (0.5 sec) by each sensor for reducing memory stress
//                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, i * 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    [awareSensor startSensor:uploadTime withSettings:sensors];
//                });
                break;
            }
        }
    }
    
    
//     Start and make a plugin instance
    for (int i=0; i<plugins.count; i++) {
        NSDictionary *plugin = [plugins objectAtIndex:i];
        NSArray *pluginSettings = [plugin objectForKey:@"settings"];
        for (NSDictionary* pluginSetting in pluginSettings) {
            NSString *pluginStateKey = [NSString stringWithFormat:@"status_%@",key];
            NSString *pluginStateName = [pluginSetting objectForKey:@"setting"];
            if ([pluginStateKey isEqualToString:pluginStateName]) {
                bool pluginState = [pluginSetting objectForKey:@"value"];
                if (pluginState) {
//                    NSLog(@"--> %@", key);
                    if ([key isEqualToString:SENSOR_PLUGIN_GOOGLE_ACTIVITY_RECOGNITION]) {
                        awareSensor = [[ActivityRecognition alloc] initWithSensorName:SENSOR_PLUGIN_GOOGLE_ACTIVITY_RECOGNITION  withAwareStudy:awareStudy];
                        [awareSensor startSensor:uploadTime withSettings:pluginSettings];
                    }else if([key isEqualToString:SENSOR_PLUGIN_OPEN_WEATHER]){
                        awareSensor = [[OpenWeather alloc] initWithSensorName:SENSOR_PLUGIN_OPEN_WEATHER  withAwareStudy:awareStudy];
                        [awareSensor startSensor:uploadTime withSettings:pluginSettings ];
                    }else if([key isEqualToString:SENSOR_PLUGIN_DEVICE_USAGE]){
                        awareSensor = [[DeviceUsage alloc] initWithSensorName:SENSOR_PLUGIN_DEVICE_USAGE  withAwareStudy:awareStudy];
                        [awareSensor startSensor:uploadTime withSettings:pluginSettings];
                    }else if([key isEqualToString:SENSOR_PLUGIN_NTPTIME]){
                        awareSensor = [[NTPTime alloc] initWithSensorName:SENSOR_PLUGIN_NTPTIME withAwareStudy:awareStudy];
                        [awareSensor startSensor:uploadTime withSettings:pluginSettings];
                    }else if([key isEqualToString:SENSOR_PLUGIN_MSBAND]){
                        awareSensor = [[MSBand alloc] initWithPluginName:SENSOR_PLUGIN_MSBAND awareStudy:awareStudy];
                        [awareSensor startSensor:uploadTime withSettings:pluginSettings];
                    }else if([key isEqualToString:SENSOR_PLUGIN_GOOGLE_CAL_PULL]){
                        awareSensor = [[GoogleCalPull alloc] initWithSensorName:SENSOR_PLUGIN_GOOGLE_CAL_PULL withAwareStudy:awareStudy];
                        [awareSensor startSensor:uploadTime withSettings:pluginSettings];
                    }else if([key isEqualToString:SENSOR_PLUGIN_GOOGLE_CAL_PUSH]){
                        awareSensor = [[GoogleCalPush alloc] initWithSensorName:SENSOR_PLUGIN_GOOGLE_CAL_PUSH withAwareStudy:awareStudy];
                        [awareSensor startSensor:uploadTime withSettings:pluginSettings];
                    }else if([key isEqualToString:SENSOR_PLUGIN_GOOGLE_LOGIN]){
                        awareSensor = [[GoogleLogin alloc] initWithSensorName:SENSOR_PLUGIN_GOOGLE_LOGIN withAwareStudy:awareStudy];
                        [awareSensor startSensor:uploadTime withSettings:pluginSettings];
                    }else if([key isEqualToString:SENSOR_PLUGIN_CAMPUS]){
                        awareSensor = [[Scheduler alloc] initWithSensorName:SENSOR_PLUGIN_CAMPUS withAwareStudy:awareStudy];
                        [awareSensor startSensor:uploadTime withSettings:pluginSettings];
                    }else if([key isEqualToString:SENSOR_GOOGLE_FUSED_LOCATION]){
                        awareSensor = [[FusedLocations alloc] initWithSensorName:SENSOR_GOOGLE_FUSED_LOCATION withAwareStudy:awareStudy];
                        [awareSensor startSensor:uploadTime withSettings:pluginSettings];
                    }
                    
                    break;
                }
            }
        }
    }
    
    /// Add the sensor to the sensor manager with debugger.
    if (awareSensor != NULL) {
        if (![self isExist:key]) {
            if(![key isEqualToString:SENSOR_AWARE_DEBUG]){
                // NOTE: Please don't call -trackDebguEvents method on the Debug sensor. The operation makes an infonity loop.
                [awareSensor trackDebugEvents];
                NSString *startSensorMessage = [NSString stringWithFormat:@"[%@] Start %@ sensor", key, key];
                [awareSensor saveDebugEventWithText:startSensorMessage type:DebugTypeInfo label:key];
            }
            [self addNewSensor:awareSensor];
            return YES;
        }
    }
    return NO;
}

/**
 * Check an existance of a sensor by a sensor name
 * You can find and edit the keys on AWAREKeys.h and AWAREKeys.m
 *
 * @param   key A NSString key for a sensor
 * @return  An existance of the target sensor as a boolean value
 */
- (BOOL) isExist :(NSString *) key {
    for (AWARESensor* sensor in awareSensors) {
        if([[sensor getSensorName] isEqualToString:key]){
            return YES;
        }
    }
    return NO;
}


/**
 * Add a new sensor to a aware sensor manager
 *
 * @param sensor An AWARESensor object (A null value is not an acceptable)
 */
- (void) addNewSensor : (AWARESensor *) sensor {
    if (sensor == nil) return;
    [awareSensors addObject:sensor];
}


/**
 * Remove all sensors from the manager after stop the sensors
 */
- (void) stopAndRemoveAllSensors {
    NSString * message = nil;
    @autoreleasepool {
        for (AWARESensor* sensor in awareSensors) {
            message = [NSString stringWithFormat:@"[%@] Stop %@ sensor",[sensor getSensorName], [sensor getSensorName]];
            NSLog(@"%@", message);
            [sensor saveDebugEventWithText:message type:DebugTypeInfo label:@"stop"];
            [sensor stopSensor];
        }
        [awareSensors removeAllObjects];
    }
//    awareSensors = [[NSMutableArray alloc] init];
}

/**
 * Stop a sensor with the sensor name.
 * You can find the sensor name (key) on AWAREKeys.h and .m.
 * 
 * @param sensorName A NSString sensor name (key)
 */
- (void) stopASensor:(NSString *)sensorName{
    for (AWARESensor* sensor in awareSensors) {
        if ([sensor.getSensorName isEqualToString:sensorName]) {
            [sensor stopSensor];
        }
        [sensor stopSensor];
    }
}


/**
 * Provide latest sensor data by each sensor as NSString value.
 * You can access the data by using sensor names (keys) on AWAREKeys.h and .m.
 *
 * @param sensorName A NSString sensor name (key)
 * @return A latest sensor value as
 */
- (NSString*) getLatestSensorData:(NSString *) sensorName {
    for (AWARESensor* sensor in awareSensors) {
        if ([sensor.getSensorName isEqualToString:sensorName]) {
            NSString *sensorValue = [sensor getLatestValue];
            return sensorValue;
        }
    }
    return @"";
}


/**
 * Upload sensor data manually in the foreground
 *
 * NOTE: 
 * This method works in the foreground only, and lock the uploading file.
 * During an uploading process, an AWARE can not access to the file.
 *
 */
- (bool) syncAllSensorsWithDBInForeground {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        @autoreleasepool{
            bool sucessOfUpload = true;
            // Show progress bar
            dispatch_sync(dispatch_get_main_queue(), ^{
                [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeBlack];
            });
            // Sync local stored data with aware server.
            for ( int i=0; i<awareSensors.count; i++) {
                AWARESensor* sensor = [awareSensors objectAtIndex:i];
                dispatch_sync(dispatch_get_main_queue(), ^{
                    NSString *message = [NSString stringWithFormat:@"Uploading %@ data %@",
                                                                     [sensor getSensorName],
                                                                     [sensor getSyncProgressAsText]];
                    [SVProgressHUD setStatus:message];
                });
                [sensor sensorLock];
                if (![sensor syncAwareDBInForeground]) {
                    sucessOfUpload = false;
                }
                [sensor sensorUnLock];
                // Update UI in the main thread.
            }
            // Dissmiss a Progress View
            dispatch_sync(dispatch_get_main_queue(), ^{
                if (sucessOfUpload) {
                    [SVProgressHUD showSuccessWithStatus:@"Success to upload your data to the server!"];
                    AudioServicesPlayAlertSound(1000);
                }else{
                    [SVProgressHUD showErrorWithStatus:@"Fail to upload your data to the server."];
                    AudioServicesPlayAlertSound(1324);
                }
                [SVProgressHUD performSelector:@selector(dismiss) withObject:nil afterDelay:3.0f];
                
            });
        }
    });

    return YES;
}



/**
 * Sync All Sensors with DB in the bacground
 *
 */
- (bool) syncAllSensorsWithDBInBackground {
    // Sync local stored data with aware server.
    if(awareSensors == nil){
        return NO;
    }
    for ( int i=0; i < awareSensors.count; i++) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, i * 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            @try {
                if (i < awareSensors.count ) {
                    AWARESensor* sensor = [awareSensors objectAtIndex:i];
                    [sensor syncAwareDB];
                }else{
                    NSLog(@"error");
                }
            } @catch (NSException *e) {
                NSLog(@"An exception was appeared: %@",e.name);
                NSLog(@"The reason: %@",e.reason);
            }
        });
    }
    return YES;
}



- (void) startUploadTimerWithInterval:(double) interval {
    if (uploadTimer != nil) {
        [uploadTimer invalidate];
        uploadTimer = nil;
    }
    uploadTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                   target:self
                                                 selector:@selector(syncAllSensorsWithDBInBackground)
                                                 userInfo:nil
                                                  repeats:YES];
}

- (void) stopUploadTimer{
    [uploadTimer invalidate];
    uploadTimer = nil;
}


@end
