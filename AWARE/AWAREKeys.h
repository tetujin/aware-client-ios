//
//  AWAREStudyManager.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/18/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* const KEY_APNS_TOKEN;
extern NSString* const KEY_AWARE_STUDY;

extern NSString* const KEY_MAX_DATA_SIZE;
extern NSString* const KEY_MARK;

extern NSString* const KEY_SENSORS;
extern NSString* const KEY_PLUGINS;
extern NSString* const KEY_PLUGIN;

extern NSString* const KEY_STUDY_QR_CODE;

extern NSString* const KEY_MQTT_PASS;
extern NSString* const KEY_MQTT_USERNAME;
extern NSString* const KEY_MQTT_SERVER;
extern NSString* const KEY_MQTT_PORT;
extern NSString* const KEY_MQTT_KEEP_ALIVE;
extern NSString* const KEY_MQTT_QOS;
extern NSString* const KEY_STUDY_ID;
extern NSString* const KEY_API;
extern NSString* const KEY_WEBSERVICE_SERVER;

extern NSString* const SETTING_DEBUG_STATE;
extern NSString *const SETTING_SYNC_WIFI_ONLY;
extern NSString* const SETTING_SYNC_INT;


extern NSString* const TABLE_INSER;
extern NSString* const TABLE_LATEST;
extern NSString* const TABLE_CREATE;
extern NSString* const TABLE_CLEAR;

extern NSString* const SENSOR_ACCELEROMETER;//accelerometer
extern NSString* const SENSOR_BAROMETER;//barometer
extern NSString* const SENSOR_BATTERY;
extern NSString* const SENSOR_BLUETOOTH;
extern NSString* const SENSOR_MAGNETOMETER;
extern NSString* const SENSOR_ESMS;
extern NSString* const SENSOR_GYROSCOPE;//Gyroscope
extern NSString* const SENSOR_LOCATIONS;
extern NSString* const SENSOR_NETWORK;
extern NSString* const SENSOR_PROCESSOR;
extern NSString* const SENSOR_PROXIMITY;
extern NSString* const SENSOR_ROTATION;
extern NSString* const SENSOR_SCREEN;
extern NSString* const SENSOR_TELEPHONY;
extern NSString* const SENSOR_WIFI;
extern NSString* const SENSOR_GRAVITY;
extern NSString* const SENSOR_LINEAR_ACCELEROMETER;
extern NSString* const SENSOR_TIMEZONE;
extern NSString* const SENSOR_AMBIENT_NOISE;
extern NSString* const SENSOR_SCHEDULER;
extern NSString* const SENSOR_PLUGIN_GOOGLE_ACTIVITY_RECOGNITION;
extern NSString* const SENSOR_PLUGIN_OPEN_WEATHER;
extern NSString* const SENSOR_PLUGIN_MSBAND;
extern NSString* const SENSOR_PLUGIN_DEVICE_USAGE;
extern NSString* const SENSOR_PLUGIN_NTPTIME;
extern NSString* const SENSOR_PLUGIN_SCHEDULER;
extern NSString* const SENSOR_PLUGIN_GOOGLE_CAL_PULL;
extern NSString* const SENSOR_PLUGIN_GOOGLE_CAL_PUSH;
extern NSString* const SENSOR_PLUGIN_GOOGLE_LOGIN;
extern NSString* const SENSOR_PLUGIN_STUDENTLIFE_AUDIO;
extern NSString* const SENSOR_PLUGIN_CAMPUS;

extern NSString * const NotificationCategoryIdent;
extern NSString * const NotificationActionOneIdent;
extern NSString * const NotificationActionTwoIdent;

@interface AWAREKeys: NSObject

@end
