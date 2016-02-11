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

@implementation AWARESensorManager

- (instancetype)init {
    self = [super init];
    if (self) {
        awareSensors = [[NSMutableArray alloc] init];
        awareStudy = [[AWAREStudy alloc] init];
    }
    return self;
}


-(bool)addNewSensorWithSensorName:(NSString *)key
                         settings:(NSArray*)settings
                          plugins:(NSArray*)plugins
                   uploadInterval:(double) uploadTime{
    
    NSString* deviceId = [awareStudy getMqttUserName];
    if (deviceId == NULL) {
        NSLog( @"[%@] ERROR: You did not have a StudyID. Please check your study configuration.", key );
        return NO;
    }
    
//    NSLog(@"[%@] Upload interval is %f.", key, uploadTime);
    AWARESensor* awareSensor = nil;
    for (int i=0; i<settings.count; i++) {
        NSString *setting = [[settings objectAtIndex:i] objectForKey:@"setting"];
        NSString *settingKey = [NSString stringWithFormat:@"status_%@",key];
        if ([setting isEqualToString:settingKey]) {
            NSString * value = [[settings objectAtIndex:i] objectForKey:@"value"];
            bool exit = [self isExist:key];
            if ([value isEqualToString:@"true"] && !exit) {
                if ([key isEqualToString:SENSOR_ACCELEROMETER]) {
                    awareSensor= [[Accelerometer alloc] initWithSensorName:SENSOR_ACCELEROMETER];
                }else if([key isEqualToString:SENSOR_BAROMETER]){
                    awareSensor = [[Barometer alloc] initWithSensorName:SENSOR_BAROMETER];
                }else if([key isEqualToString:SENSOR_GYROSCOPE]){
                    awareSensor = [[Gyroscope alloc] initWithSensorName:SENSOR_GYROSCOPE];
                }else if([key isEqualToString:SENSOR_MAGNETOMETER]){
                    awareSensor = [[Magnetometer alloc] initWithSensorName:SENSOR_MAGNETOMETER];
                }else if([key isEqualToString:SENSOR_BATTERY]){
                    awareSensor = [[Battery alloc] initWithSensorName:SENSOR_BATTERY];
                }else if([key isEqualToString:SENSOR_LOCATIONS]){
                    awareSensor = [[Locations alloc] initWithSensorName:SENSOR_LOCATIONS];
                }else if([key isEqualToString:SENSOR_NETWORK]){
                    awareSensor = [[Network alloc] initWithSensorName:SENSOR_NETWORK];
                }else if([key isEqualToString:SENSOR_WIFI]){
                    awareSensor = [[Wifi alloc] initWithSensorName:SENSOR_WIFI];
                }else if ([key isEqualToString:SENSOR_PROCESSOR]){
                    awareSensor = [[Processor alloc] initWithSensorName:SENSOR_PROCESSOR];
                }else if ([key isEqualToString:SENSOR_GRAVITY]){
                    awareSensor = [[Gravity alloc] initWithSensorName:SENSOR_GRAVITY];
                }else if([key isEqualToString:SENSOR_LINEAR_ACCELEROMETER]){
                    awareSensor = [[LinearAccelerometer alloc] initWithSensorName:SENSOR_LINEAR_ACCELEROMETER];
                }else if([key isEqualToString:SENSOR_BLUETOOTH]){
                    awareSensor = [[Bluetooth alloc] initWithSensorName:SENSOR_BLUETOOTH];
                }else if([key isEqualToString:SENSOR_SCREEN]){
                    awareSensor = [[Screen alloc] initWithSensorName:SENSOR_SCREEN];
                }else if([key isEqualToString:SENSOR_PROXIMITY]){
                    awareSensor = [[Proximity alloc] initWithSensorName:SENSOR_PROXIMITY];
                }else if([key isEqualToString:SENSOR_TIMEZONE]){
                    awareSensor = [[Timezone alloc] initWithSensorName:SENSOR_TIMEZONE];
                }else if([key isEqualToString:SENSOR_ESMS]){
                    awareSensor = [[ESM alloc] initWithSensorName:SENSOR_ESMS];
                }else if([key isEqualToString:SENSOR_CALLS]){
                    awareSensor = [[Calls alloc] initWithSensorName:SENSOR_CALLS];
                }
                // Start AWARESensor with some delay (0.5 sec) by each sensor for reducing memory stress
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, i * 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    [awareSensor startSensor:uploadTime withSettings:settings];
                });
                break;
            }
        }
    }
    
//    awareSensor = nil;
    
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
                        awareSensor = [[ActivityRecognition alloc] initWithSensorName:SENSOR_PLUGIN_GOOGLE_ACTIVITY_RECOGNITION];
                        [awareSensor startSensor:uploadTime withSettings:pluginSettings];
                    }else if([key isEqualToString:SENSOR_PLUGIN_OPEN_WEATHER]){
                        awareSensor = [[OpenWeather alloc] initWithSensorName:SENSOR_PLUGIN_OPEN_WEATHER];
                        [awareSensor startSensor:uploadTime withSettings:pluginSettings];
                    }else if([key isEqualToString:SENSOR_PLUGIN_DEVICE_USAGE]){
                        awareSensor = [[DeviceUsage alloc] initWithSensorName:SENSOR_PLUGIN_DEVICE_USAGE];
                        [awareSensor startSensor:uploadTime withSettings:pluginSettings];
                    }else if([key isEqualToString:SENSOR_PLUGIN_NTPTIME]){
                        awareSensor = [[NTPTime alloc] initWithSensorName:SENSOR_PLUGIN_NTPTIME];
                        [awareSensor startSensor:uploadTime withSettings:pluginSettings];
                    }else if([key isEqualToString:SENSOR_PLUGIN_MSBAND]){
                        awareSensor = [[MSBand alloc] initWithPluginName:SENSOR_PLUGIN_MSBAND deviceId:deviceId];
                        [awareSensor startSensor:uploadTime withSettings:pluginSettings];
                    }else if([key isEqualToString:SENSOR_PLUGIN_GOOGLE_CAL_PULL]){
                        awareSensor = [[GoogleCalPull alloc] initWithPluginName:SENSOR_PLUGIN_GOOGLE_CAL_PULL deviceId:deviceId];
                        [awareSensor startSensor:uploadTime withSettings:pluginSettings];
                    }else if([key isEqualToString:SENSOR_PLUGIN_GOOGLE_CAL_PUSH]){
                        awareSensor = [[GoogleCalPush alloc] initWithSensorName:SENSOR_PLUGIN_GOOGLE_CAL_PUSH];
                        [awareSensor startSensor:uploadTime withSettings:pluginSettings];
                    }else if([key isEqualToString:SENSOR_PLUGIN_GOOGLE_LOGIN]){
                        awareSensor = [[GoogleLogin alloc] initWithSensorName:SENSOR_PLUGIN_GOOGLE_LOGIN];
                        [awareSensor startSensor:uploadTime withSettings:pluginSettings];
                    }else if([key isEqualToString:SENSOR_PLUGIN_CAMPUS]){
                        awareSensor = [[Scheduler alloc] initWithSensorName:SENSOR_PLUGIN_CAMPUS];
                        [awareSensor startSensor:uploadTime withSettings:pluginSettings];
                    }else if([key isEqualToString:SENSOR_GOOGLE_FUSED_LOCATION]){
                        awareSensor = [[FusedLocations alloc] initWithSensorName:SENSOR_GOOGLE_FUSED_LOCATION];
                        [awareSensor startSensor:uploadTime withSettings:pluginSettings];
                    }
                    break;
                }
            }
        }
    }
    
    if (awareSensor != NULL) {
        if(![key isEqualToString:SENSOR_AWARE_DEBUG]){
            [awareSensor trackDebugEvents];
            NSString *startSensorMessage = [NSString stringWithFormat:@"[%@] Start %@ sensor", key, key];
            [awareSensor saveDebugEventWithText:startSensorMessage type:DebugTypeInfo label:key];
        }
        [self addNewSensor:awareSensor];
        return YES;
    }

    return NO;
}


- (BOOL) isExist :(NSString *) key {
    for (AWARESensor* sensor in awareSensors) {
        if([[sensor getSensorName] isEqualToString:key]){
            return YES;
        }
    }
    return NO;
}

- (void)addNewSensor:(AWARESensor *)sensor{
    [awareSensors addObject:sensor];
}

- (void)stopAllSensors{
    for (AWARESensor* sensor in awareSensors) {
        NSLog(@"Stop %@ sensor.", [sensor getSensorName]);
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
        if ([sensor.getSensorName isEqualToString:sensorName]) {
            NSString *sensorValue = [sensor getLatestValue];
            return sensorValue;
        }
    }
    return @"";
}

- (bool) syncAllSensorsWithDB {
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

@end
