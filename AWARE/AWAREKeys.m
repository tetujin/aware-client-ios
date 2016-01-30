//
//  AWAREStudyManager.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/18/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWAREKeys.h"

NSString* const KEY_APNS_TOKEN = @"key_apns_token";
NSString* const KEY_AWARE_STUDY = @"key_aware_study";
NSString* const KEY_APP_TERMINATED = @"key_app_terminated";

NSString* const KEY_MAX_DATA_SIZE = @"key_max_data_size_";
NSString* const KEY_MARK = @"key_data_mark_";

NSString* const KEY_SENSORS = @"sensors";
NSString* const KEY_PLUGINS = @"plugins";
NSString* const KEY_PLUGIN = @"plugin";

NSString* const KEY_STUDY_QR_CODE = @"study_qr_code";

NSString* const KEY_MQTT_PASS = @"mqtt_password";
NSString* const KEY_MQTT_USERNAME = @"mqtt_username";
NSString* const KEY_MQTT_SERVER = @"mqtt_server";
NSString* const KEY_MQTT_PORT = @"mqtt_port";
NSString* const KEY_MQTT_KEEP_ALIVE = @"mqtt_keep_alive";
NSString* const KEY_MQTT_QOS = @"mqtt_qos";
NSString* const KEY_STUDY_ID = @"study_id";
NSString* const KEY_WEBSERVICE_SERVER = @"webservice_server";

NSString* const SETTING_DEBUG_STATE = @"setting_debug_state";
NSString *const SETTING_SYNC_WIFI_ONLY = @"setting_sync_wifi_only";
NSString* const SETTING_SYNC_INT = @"setting_sync_interval";


NSString* const TABLE_INSERT = @"insert";
NSString* const TABLE_LATEST = @"latest";
NSString* const TABLE_CREATE = @"create";
NSString* const TABLE_CLEAR = @"clear";

NSString* const SENSOR_ACCELEROMETER = @"accelerometer";//accelerometer
NSString* const SENSOR_BAROMETER = @"barometer";//barometer
NSString* const SENSOR_BATTERY = @"battery";
NSString* const SENSOR_BLUETOOTH = @"bluetooth";
NSString* const SENSOR_MAGNETOMETER = @"magnetometer";
NSString* const SENSOR_ESMS = @"esm";
NSString* const SENSOR_GYROSCOPE = @"gyroscope";//Gyroscope
NSString* const SENSOR_LOCATIONS = @"location_gps";
NSString* const SENSOR_NETWORK = @"network";
NSString* const SENSOR_PROCESSOR = @"processor";
NSString* const SENSOR_PROXIMITY = @"proximity";
NSString* const SENSOR_ROTATION = @"rotation";
NSString* const SENSOR_SCREEN = @"screen";
NSString* const SENSOR_TELEPHONY = @"telephony";
NSString* const SENSOR_WIFI = @"wifi";
NSString* const SENSOR_GRAVITY = @"gravity";
NSString* const SENSOR_LINEAR_ACCELEROMETER = @"linear_accelerometer";
NSString* const SENSOR_TIMEZONE = @"timezone";
NSString* const SENSOR_AMBIENT_NOISE = @"plugin_ambient_noise";
NSString* const SENSOR_SCHEDULER = @"scheduler";
NSString* const SENSOR_CALLS = @"calls";
NSString* const SENSOR_PLUGIN_GOOGLE_ACTIVITY_RECOGNITION = @"plugin_google_activity_recognition";
NSString* const SENSOR_GOOGLE_FUSED_LOCATION = @"google_fused_location";
NSString* const SENSOR_PLUGIN_GOOGLE_CAL_PULL = @"plugin_balancedcampuscalendar";
NSString* const SENSOR_PLUGIN_GOOGLE_CAL_PUSH = @"plugin_balancedcampusjournal";
NSString* const SENSOR_PLUGIN_GOOGLE_LOGIN = @"plugin_google_login";
NSString* const SENSOR_PLUGIN_OPEN_WEATHER = @"plugin_openweather";
NSString* const SENSOR_PLUGIN_MSBAND = @"plugin_msband_sensors";
NSString* const SENSOR_PLUGIN_DEVICE_USAGE = @"plugin_device_usage";
NSString* const SENSOR_PLUGIN_NTPTIME = @"plugin_ntptime";
NSString* const SENSOR_PLUGIN_SCHEDULER = @"scheduler";
NSString* const SENSOR_PLUGIN_STUDENTLIFE_AUDIO = @"plugin_studentlife_audio";
//NSString* const SENSOR_PLUGIN_CAMPUS = @"plugin_campus";
NSString* const SENSOR_PLUGIN_CAMPUS = @"plugin_cmu_esm";


NSString* const SENSOR_APPLICATION_HISTORY = @"applications_history";


NSString * const NotificationCategoryIdent  = @"ACTIONABLE";
NSString * const NotificationActionOneIdent = @"ACTION_ONE";
NSString * const NotificationActionTwoIdent = @"ACTION_TWO";

@implementation AWAREKeys

@end
