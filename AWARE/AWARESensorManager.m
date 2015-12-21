//
//  AWARESensorManager.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/19/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensorManager.h"
#import "AWAREKeys.h"
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
#import "ActivityRecognition.h"
#import "OpenWeather.h"
#import "Screen.h"
#import "DeviceUsage.h"
#import "NTPTime.h"
#import "Proximity.h"
#import "Timezone.h"
#import "ESM.h"
#import "MSBand.h"

@implementation AWARESensorManager

- (instancetype)init {
    self = [super init];
    if (self) {
        awareSensors = [[NSMutableArray alloc] init];
    }
    return self;
}

-(bool)addNewSensorWithSensorName:(NSString *)key
                         settings:(NSArray*)settings
                          plugins:(NSArray*)plugins
                   uploadInterval:(double) uploadTime{
//    double uploadTime = 10.0f;
    NSLog(@"[%@] Upload interval is %f.", key, uploadTime);
    AWARESensor* awareSensor = nil;
    for (int i=0; i<settings.count; i++) {
        NSString *setting = [[settings objectAtIndex:i] objectForKey:@"setting"];
        NSString *settingKey = [NSString stringWithFormat:@"status_%@",key];
        if ([setting isEqualToString:settingKey]) {
            NSString * value = [[settings objectAtIndex:i] objectForKey:@"value"];
            if ([value isEqualToString:@"true"]) {
//                [_sensorManager addNewSensorWithSensorName:key settings:(NSArray*)sensors];
                if ([key isEqualToString:SENSOR_ACCELEROMETER]) {
                    awareSensor= [[Accelerometer alloc] initWithSensorName:SENSOR_ACCELEROMETER];
//                    [awareSensor startSensor:uploadTime withSettings:settings];
                }else if([key isEqualToString:SENSOR_BAROMETER]){
                    awareSensor = [[Barometer alloc] initWithSensorName:SENSOR_BAROMETER];
//                    [awareSensor startSensor:uploadTime withSettings:settings];
                }else if([key isEqualToString:SENSOR_GYROSCOPE]){
                    awareSensor = [[Gyroscope alloc] initWithSensorName:SENSOR_GYROSCOPE];
//                    [awareSensor startSensor:uploadTime withSettings:settings];
                }else if([key isEqualToString:SENSOR_MAGNETOMETER]){
                    awareSensor = [[Magnetometer alloc] initWithSensorName:SENSOR_MAGNETOMETER];
//                    [awareSensor startSensor:uploadTime withSettings:settings];
                }else if([key isEqualToString:SENSOR_BATTERY]){
                    awareSensor = [[Battery alloc] initWithSensorName:SENSOR_BATTERY];
//                    [awareSensor startSensor:uploadTime withSettings:settings];
                }else if([key isEqualToString:SENSOR_LOCATIONS]){
                    awareSensor = [[Locations alloc] initWithSensorName:SENSOR_LOCATIONS];
//                    [awareSensor startSensor:uploadTime withSettings:settings];//0=>auto
                }else if([key isEqualToString:SENSOR_NETWORK]){
                    awareSensor = [[Network alloc] initWithSensorName:SENSOR_NETWORK];
//                    [awareSensor startSensor:uploadTime withSettings:settings];
                }else if([key isEqualToString:SENSOR_WIFI]){
                    awareSensor = [[Wifi alloc] initWithSensorName:SENSOR_WIFI];
//                    [awareSensor startSensor:uploadTime withSettings:settings];
                }else if ([key isEqualToString:SENSOR_PROCESSOR]){
                    awareSensor = [[Processor alloc] initWithSensorName:SENSOR_PROCESSOR];
//                    [awareSensor startSensor:uploadTime withSettings:settings];
                }else if ([key isEqualToString:SENSOR_GRAVITY]){
                    awareSensor = [[Gravity alloc] initWithSensorName:SENSOR_GRAVITY];
//                    [awareSensor startSensor:uploadTime withSettings:settings];
                }else if([key isEqualToString:SENSOR_LINEAR_ACCELEROMETER]){
                    awareSensor = [[LinearAccelerometer alloc] initWithSensorName:SENSOR_LINEAR_ACCELEROMETER];
//                    [awareSensor startSensor:uploadTime withSettings:settings];
                }else if([key isEqualToString:SENSOR_BLUETOOTH]){
                    awareSensor = [[Bluetooth alloc] initWithSensorName:SENSOR_BLUETOOTH];
//                    [awareSensor startSensor:uploadTime withSettings:settings];
                }else if([key isEqualToString:SENSOR_SCREEN]){
                    awareSensor = [[Screen alloc] initWithSensorName:SENSOR_SCREEN];
//                    [awareSensor startSensor:uploadTime withSettings:settings];
                }else if([key isEqualToString:SENSOR_PROXIMITY]){
                    awareSensor = [[Proximity alloc] initWithSensorName:SENSOR_PROXIMITY];
//                    [awareSensor startSensor:uploadTime withSettings:settings];
                }else if([key isEqualToString:SENSOR_TIMEZONE]){
                    awareSensor = [[Timezone alloc] initWithSensorName:SENSOR_TIMEZONE];
//                    [awareSensor startSensor:uploadTime withSettings:settings];
                }else if([key isEqualToString:SENSOR_ESMS]){
                    awareSensor = [[ESM alloc] initWithSensorName:SENSOR_ESMS];
//                    [awareSensor startSensor:uploadTime withSettings:settings];
                }
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, i * 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    [awareSensor startSensor:uploadTime withSettings:settings];
                });
//                if (awareSensor != NULL) {
//                    [self addNewSensor:awareSensor];
////                    return YES;
//                }
            }
        }
    }
    
    for (int i=0; i<plugins.count; i++) {
        NSDictionary *plugin = [plugins objectAtIndex:i];
        NSArray *pluginSettings = [plugin objectForKey:@"settings"];
        for (NSDictionary* pluginSetting in pluginSettings) {
            NSString *pluginStateKey = [NSString stringWithFormat:@"status_%@",key];
            NSString *pluginStateName = [pluginSetting objectForKey:@"setting"];
            if ([pluginStateKey isEqualToString:pluginStateName]) {
                bool pluginState = [pluginSetting objectForKey:@"value"];
                if (pluginState) {
                    if ([key isEqualToString:SENSOR_PLUGIN_GOOGLE_ACTIVITY_RECOGNITION]) {
                        awareSensor = [[ActivityRecognition alloc] initWithSensorName:SENSOR_PLUGIN_GOOGLE_ACTIVITY_RECOGNITION];
                        [awareSensor startSensor:uploadTime withSettings:settings];
                    }else if([key isEqualToString:SENSOR_AMBIENT_NOISE]){
                        awareSensor = [[AmbientNoise alloc] initWithSensorName:SENSOR_AMBIENT_NOISE];
                        [awareSensor startSensor:uploadTime withSettings:settings];
                    }else if([key isEqualToString:SENSOR_PLUGIN_OPEN_WEATHER]){
                        awareSensor = [[OpenWeather alloc] initWithSensorName:SENSOR_PLUGIN_OPEN_WEATHER];
                        [awareSensor startSensor:uploadTime withSettings:settings];
                    }else if([key isEqualToString:SENSOR_PLUGIN_DEVICE_USAGE]){
                        awareSensor = [[DeviceUsage alloc] initWithSensorName:SENSOR_PLUGIN_DEVICE_USAGE];
                        [awareSensor startSensor:uploadTime withSettings:settings];
                    }else if([key isEqualToString:SENSOR_PLUGIN_NTPTIME]){
                        awareSensor = [[NTPTime alloc] initWithSensorName:SENSOR_PLUGIN_NTPTIME];
                        [awareSensor startSensor:uploadTime withSettings:settings];
                    }else if([key isEqualToString:SENSOR_PLUGIN_MSBAND]){
                        awareSensor = [[MSBand alloc] initWithSensorName:SENSOR_PLUGIN_MSBAND];
                        [awareSensor startSensor:uploadTime withSettings:settings];
                    }
                }
            }
        }
    }
    
    if (awareSensor != NULL) {
        [self addNewSensor:awareSensor];
        return YES;
    }

    return NO;
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

- (void) syncAllSensorsWithDB{
    for (AWARESensor* sensor in awareSensors) {
        [sensor syncAwareDB];
    }
}

@end
