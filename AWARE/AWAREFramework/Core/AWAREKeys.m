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
NSString* const KEY_UPLOAD_MARK = @"key_data_mark_";

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
NSString* const SETTING_SYNC_WIFI_ONLY = @"setting_sync_wifi_only";
NSString* const SETTING_SYNC_INT = @"setting_sync_interval";
NSString* const SETTING_SYNC_BATTERY_CHARGING_ONLY = @"setting_sync_battery_charging_only";
NSString* const SETTING_FREQUENCY_CLEAN_OLD_DATA = @"setting_frequency_clean_old_data";


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
NSString* const SENSOR_BLE_HEARTRATE = @"ble_heartrate";
NSString* const SENSOR_GRAVITY = @"gravity";
NSString* const SENSOR_LINEAR_ACCELEROMETER = @"linear_accelerometer";
NSString* const SENSOR_TIMEZONE = @"timezone";
NSString* const SENSOR_AMBIENT_NOISE = @"plugin_ambient_noise";
NSString* const SENSOR_SCHEDULER = @"scheduler";
NSString* const SENSOR_CALLS = @"calls";
NSString* const SENSOR_LABELS = @"labels";
NSString* const SENSOR_ORIENTATION = @"orientation";


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
NSString* const SENSOR_PLUGIN_CAMPUS = @"plugin_cmu_esm";
NSString* const SENSOR_PLUGIN_PEDOMETER = @"plugin_pedometer";
NSString* const SENSOR_AWARE_DEBUG = @"aware_debug";

NSString* const SENSOR_APPLICATION_HISTORY = @"applications_history";


NSString * const NotificationCategoryIdent  = @"ACTIONABLE";
NSString * const NotificationActionOneIdent = @"ACTION_ONE";
NSString * const NotificationActionTwoIdent = @"ACTION_TWO";


NSString* const SENSOR_LABELS_TYPE_TEXT = @"labels_text";
NSString* const SENSOR_LABELS_TYPE_BOOLEAN = @"labels_boolean";


NSString* const SENSOR_PLUGIN_CAMPUS_ESM_NOTIFICATION_BOOLEAN = @"plugin_cmu_esm_notification_boolean";
NSString* const SENSOR_PLUGIN_CAMPUS_ESM_NOTIFICATION_LABEL = @"plugin_cmu_esm_notification_label";


///////////////////////////////////////
NSString* const EXTRA_DATA = @"EXTRA_DATA";
NSString* const ACTION_AWARE_ACCELEROMETER = @"ACTION_AWARE_ACCELEROMETER";
NSString* const ACTION_AWARE_BAROMETER = @"ACTION_AWARE_BAROMETER";

NSString * const ACTION_AWARE_BATTERY_CHANGED = @"ACTION_AWARE_BATTERY_CHANGED";
NSString * const ACTION_AWARE_BATTERY_CHARGING = @"ACTION_AWARE_BATTERY_CHARGING";
//NSString * const ACTION_AWARE_BATTERY_CHARGING_AC = @"ACTION_AWARE_BATTERY_CHARGING_AC";
//NSString * const ACTION_AWARE_BATTERY_CHARGING_USB = @"ACTION_AWARE_BATTERY_CHARGING_USB";
NSString * const ACTION_AWARE_BATTERY_DISCHARGING = @"ACTION_AWARE_BATTERY_DISCHARGING";
NSString * const ACTION_AWARE_BATTERY_FULL = @"ACTION_AWARE_BATTERY_FULL";
//NSString * const ACTION_AWARE_BATTERY_LOW = @"ACTION_AWARE_BATTERY_LOW";
//NSString * const ACTION_AWARE_PHONE_SHUTDOWN = @"ACTION_AWARE_PHONE_SHUTDOWN";
//NSString * const ACTION_AWARE_PHONE_REBOOT = @"ACTION_AWARE_PHONE_REBOOT";

// bluetooth
NSString * const ACTION_AWARE_BLUETOOTH_NEW_DEVICE = @"ACTION_AWARE_BLUETOOTH_NEW_DEVICE";
NSString * const ACTION_AWARE_BLUETOOTH_SCAN_STARTED = @"ACTION_AWARE_BLUETOOTH_SCAN_STARTED";
NSString * const ACTION_AWARE_BLUETOOTH_SCAN_ENDED = @"ACTION_AWARE_BLUETOOTH_SCAN_ENDED";
//NSString * const ACTION_AWARE_BLUETOOTH_REQUEST_SCAN = @"ACTION_AWARE_BLUETOOTH_REQUEST_SCAN";

// Communication (Phone Call Events)
NSString * const ACTION_AWARE_CALL_ACCEPTED = @"ACTION_AWARE_CALL_ACCEPTED";//: broadcasted when the user accepts an incoming call.
NSString * const ACTION_AWARE_CALL_RINGING = @"ACTION_AWARE_CALL_RINGING"; //: broadcasted when the phone is ringing.
NSString * const ACTION_AWARE_CALL_MISSED = @"ACTION_AWARE_CALL_MISSED"; //: broadcasted when the user lost a call.
NSString * const ACTION_AWARE_CALL_MADE = @"ACTION_AWARE_CALL_MADE"; //: broadcasted when the user is making a call.
NSString * const ACTION_AWARE_USER_IN_CALL = @"ACTION_AWARE_USER_IN_CALL"; //: broadcasted when the user is currently in a call.
NSString * const ACTION_AWARE_USER_NOT_IN_CALL = @"ACTION_AWARE_USER_NOT_IN_CALL"; //: broadcasted when the user is not in a call.

// Debug
NSString * const ACTION_AWARE_DEBUG = @"ACTION_AWARE_DEBUG";

// Gravity
NSString * const ACTION_AWARE_GRAVITY = @"ACTION_AWARE_GRAVITY";

// Gyroscope
NSString * const ACTION_AWARE_GYROSCOPE = @"ACTION_AWARE_GYROSCOPE";

// Liner Accelerometer
NSString * const ACTION_AWARE_LINEAR_ACCELEROMETER = @"ACTION_AWARE_LINEAR_ACCELEROMETER";

// Locations
NSString * const ACTION_AWARE_LOCATIONS = @"ACTION_AWARE_LOCATIONS"; //: new location available.
//NSString * const ACTION_AWARE_GPS_LOCATION_ENABLED;//: GPS location is active.
//NSString * const ACTION_AWARE_NETWORK_LOCATION_ENABLED;//: network location is active.
//NSString * const ACTION_AWARE_GPS_LOCATION_DISABLED;//: GPS location disabled.
//NSString * const ACTION_AWARE_NETWORK_LOCATION_DISABLED;//: network location disabled.

// Magnetometer
NSString * const ACTION_AWARE_MAGNETOMETER = @"ACTION_AWARE_MAGNETOMETER";

// Network
//extern NSString * const ACTION_AWARE_AIRPLANE_ON;// broadcasted when airplane mode is activated.
//extern NSString * const ACTION_AWARE_AIRPLANE_OFF;// broadcasted when airplane mode is deactivated.
NSString * const ACTION_AWARE_WIFI_ON = @"ACTION_AWARE_WIFI_ON";// broadcasted when Wi-Fi is activated.
NSString * const ACTION_AWARE_WIFI_OFF = @"ACTION_AWARE_WIFI_OFF";// broadcasted when Wi-Fi is deactivated.
NSString * const ACTION_AWARE_MOBILE_ON = @"ACTION_AWARE_MOBILE_ON";// broadcasted when mobile network is activated.
NSString * const ACTION_AWARE_MOBILE_OFF = @"ACTION_AWARE_MOBILE_OFF";// broadcasted when mobile network is deactivated.
//extern NSString * const ACTION_AWARE_WIMAX_ON;// broadcasted when WIMAX is activated.
//extern NSString * const ACTION_AWARE_WIMAX_OFF;// broadcasted when WIMAX is deactivated.
//extern NSString * const ACTION_AWARE_BLUETOOTH_ON;// broadcasted when Bluetooth is activated.
//extern NSString * const ACTION_AWARE_BLUETOOTH_OFF;// broadcasted when Bluetooth is deactivated.
//extern NSString * const ACTION_AWARE_GPS_ON;// broadcasted when GPS is activated.
//extern NSString * const ACTION_AWARE_GPS_OFF;// broadcasted when GPS is deactivated.
NSString * const ACTION_AWARE_INTERNET_AVAILABLE = @"ACTION_AWARE_INTERNET_AVAILABLE";// broadcasted when the device is connected to the internet. One extra is included to provide the active internet access network:
//extern NSString * const EXTRA_ACCESS;// an integer with one of the following constants: 1=Wi-Fi, 2= Bluetooth, 4= Mobile, 5= WIMAX
NSString * const ACTION_AWARE_INTERNET_UNAVAILABLE = @"ACTION_AWARE_INTERNET_UNAVAILABLE";// broadcasted when the device is not connected to the internet.
//NSString * const ACTION_AWARE_NETWORK_TRAFFIC = @"ACTION_AWARE_NETWORK_TRAFFIC";// broadcasted when new traffic information is available for both Wi-Fi and mobile data.

NSString * const ACTION_AWARE_ROTATION = @"ACTION_AWARE_ROTATION";

// Screen
NSString * const ACTION_AWARE_SCREEN_ON = @"ACTION_AWARE_SCREEN_ON";
NSString * const ACTION_AWARE_SCREEN_OFF = @"ACTION_AWARE_SCREEN_OFF";
NSString * const ACTION_AWARE_SCREEN_LOCKED = @"ACTION_AWARE_SCREEN_LOCKED";
NSString * const ACTION_AWARE_SCREEN_UNLOCKED = @"ACTION_AWARE_SCREEN_UNLOCKED";

// Timezone
NSString * const ACTION_AWARE_TIMEZONE = @"ACTION_AWARE_TIMEZONE";

//Wifi
NSString * const ACTION_AWARE_WIFI_NEW_DEVICE = @"ACTION_AWARE_WIFI_NEW_DEVICE"; //: new Wi-Fi device detected.
NSString * const ACTION_AWARE_WIFI_SCAN_STARTED = @"ACTION_AWARE_WIFI_SCAN_STARTED"; //: scan session has started.
NSString * const ACTION_AWARE_WIFI_SCAN_ENDED = @"ACTION_AWARE_WIFI_SCAN_ENDED"; //: scan session has ended.
NSString * const ACTION_AWARE_WIFI_REQUEST_SCAN = @"ACTION_AWARE_WIFI_REQUEST_SCAN"; //: request a Wi-Fi scan as soon as possible.

// Activity Recognition
NSString * const ACTION_AWARE_GOOGLE_ACTIVITY_RECOGNITION = @"ACTION_AWARE_GOOGLE_ACTIVITY_RECOGNITION";

// upload progress
NSString * const KEY_UPLOAD_PROGRESS_STR = @"KEY_UPLOAD_PROGRESS_STR";
NSString * const KEY_UPLOAD_FIN = @"KEY_UPLOAD_FIN";
NSString * const KEY_UPLOAD_SENSOR_NAME = @"KEY_UPLOAD_SENSOR_NAME";
NSString * const KEY_UPLOAD_SUCCESS = @"KEY_UPLOAD_SUCCESS";
NSString * const ACTION_AWARE_DATA_UPLOAD_PROGRESS = @"ACTION_AWARE_DATA_UPLOAD_PROGRESS";

@implementation AWAREKeys

@end
