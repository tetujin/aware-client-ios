//
//  ViewController.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/18/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//
// This branch is for BalancedCampus Project
//

// Views
#import "ViewController.h"
#import "GoogleLoginViewController.h"
#import "AWAREEsmViewController.h"
#import "AWARECore.h"
#import "WebViewController.h"

// Util
#import "AWAREStudy.h"
#import "AWAREKeys.h"
#import "AWAREUtils.h"
#import "ESMStorageHelper.h"
#import "AppDelegate.h"
#import "Observer.h"
#import "WebESM.h"

// Plugins
#import "GoogleCalPush.h"
#import "Pedometer.h"
#import "Orientation.h"
#import "Debug.h"
#import "AWAREHealthKit.h"
#import "BalacnedCampusESMScheduler.h"
#import "Memory.h"
#import "Labels.h"
#import "BLEHeartRate.h"
#import "AmbientLight.h"
#import "ESM.h"
#import "Accelerometer.h"

// Library
#import <SVProgressHUD.h>

#import <QuartzCore/QuartzCore.h>

@interface ViewController ()
@end

@implementation ViewController{
    /**  Keys for contetns of a table view raw */
    /// A key for a title in a raw
    NSString *KEY_CEL_TITLE;
    /// A key for a description in a raw
    NSString *KEY_CEL_DESC;
    /// A key for a image in a raw
    NSString *KEY_CEL_IMAGE;
    /// A key for a status in a raw
    NSString *KEY_CEL_STATE;
    /// A key for a sensor_name in a raw
    NSString *KEY_CEL_SENSOR_NAME;
    
    /** Study Settings */
    /// A deault intrval for uploading sensor data
    double uploadInterval;
    /// A Debug sensor object
    Debug *debugSensor;
    //
    NSTimer * dailyUpdateTimer;
    
    /** View */
    /// A timer for updating a list view
    NSTimer *listUpdateTimer;
    
    AWAREStudy * awareStudy;
    
    AWARESensorManager * sensorManager;
    
    NSURL * webViewURL;
    
    EAIntroView *intro;
    
    WebESM *webESM;
    
    CLLocationManager * locationManager;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    /// Init keys and default interval
    KEY_CEL_TITLE = @"title";
    KEY_CEL_DESC = @"desc";
    KEY_CEL_IMAGE = @"image";
    KEY_CEL_STATE = @"state";
    KEY_CEL_SENSOR_NAME = @"sensorName";
    
    webViewURL = [NSURL URLWithString:@"http://www.awareframework.com"];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    uploadInterval = [userDefaults doubleForKey:SETTING_SYNC_INT];
    
    
    // EAIntroView
    intro = [[EAIntroView alloc] initWithFrame:self.view.bounds andPages:[self getIntroPages]];
    [intro setDelegate:self];
//    if (![userDefaults boolForKey:@"showed_introduction"]) {
//         [intro showInView:self.view animateDuration:0.0];
//    }
//    [userDefaults setBool:YES forKey:@"showed_introduction"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];

    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;

    /// Init sensor manager for the list view
    AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
    AWARECore * core = delegate.sharedAWARECore;
    sensorManager =     core.sharedSensorManager;
    dailyUpdateTimer =  core.dailyUpdateTimer;
    awareStudy =        core.sharedAwareStudy;
    locationManager =   core.sharedLocationManager;
    
    // A sensor list for table view
    _sensors = [[NSMutableArray alloc] init];
    
    //[[AWAREStudy alloc] initWithReachability:YES];
    
    /**
     * Init a Debug Sensor for collecting a debug message.
     * A developer can store debug messages to an aware database
     * by using the -saveDebugEventWithText:type:label: method on the debugSensor.
     */
    debugSensor = [[Debug alloc] initWithAwareStudy:awareStudy dbType:AwareDBTypeTextFile];
    
    [self initContentsOnTableView];
    
    /// Set delegates for a navigation bar and table view
    if ([AWAREUtils getCurrentOSVersionAsFloat] >= 9.0) {
        [self.navigationController.navigationBar setDelegate:self];
    }
    
    /// Start an update timer for list view. This timer refreshed the list view every 0.1 sec.
    listUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f
                                                       target:self
                                                     selector:@selector(updateVisibleCells)
                                                     userInfo:nil
                                                      repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:listUpdateTimer forMode:NSRunLoopCommonModes];

    webESM = [[WebESM alloc] initWithAwareStudy:awareStudy dbType:AwareDBTypeCoreData];
    
    // [sensorManager performSelector:@selector(testSensing) withObject:nil afterDelay:10];
}


/**
 * This method is called when application did becase active.
 * And also, this method check ESM existance using ESMStorageHelper. 
 * If an ESM is existed, AWARE iOS move to the ESM answer page.
 */
- (void)appDidBecomeActive:(NSNotification *)notification {
    
    NSLog(@"did become active notification");
    
    ESMStorageHelper * helper = [[ESMStorageHelper alloc] init];
    NSArray * storedEsms = [helper getEsmTexts];
    if(storedEsms != nil){
        if (storedEsms.count > 0 && ![ESM isAppearedThisSection]) {
            [ESM setAppearedState:YES];
            [self performSegueWithIdentifier:@"esmView" sender:self];
        }
    }
    
    NSArray * esms = [webESM getValidESMsWithDatetime:[NSDate new]];
    if(esms != nil && esms.count != 0 && ![ESM isAppearedThisSection]){
        [ESM setAppearedState:YES];
        [self performSegueWithIdentifier:@"webEsmView" sender:self];
    }
    
    AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
    AWARECore * core = delegate.sharedAWARECore;
    [core checkComplianceWithViewController:self];

}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSLog(@" Hello ESM view !");
    if ([segue.identifier isEqualToString:@"esmView"]) {
//        AWAREEsmViewController *esmView = [segue destinationViewController];    // <- 1
    } else if ([segue.identifier isEqualToString:@"webView"]) {
        WebViewController *webViewController = [segue destinationViewController];
        webViewController.url = webViewURL;
    }
}


- (void)didReceiveMemoryWarning {
    [debugSensor saveDebugEventWithText:@"didReceiveMemoryWarning" type:DebugTypeWarn label:@""];
    
    AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
    [delegate.managedObjectContext reset];
    
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


/**
 When a study is refreshed (e.g., pushed refresh button, changed settings,
 and/or done daily study update), this method is called.
 */
- (void) initContentsOnTableView {
    // init sensor list
    [_sensors removeAllObjects];
    
    // Get a study and device information from local default storage
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults synchronize];
    
    NSString *email = [userDefaults objectForKey:@"GOOGLE_EMAIL"];
    NSString *name = [userDefaults objectForKey:@"GOOGLE_NAME"];
    NSInteger maximumFileSize = [userDefaults integerForKey:KEY_MAX_DATA_SIZE];
    NSString *accountInfo = [NSString stringWithFormat:@"%@ (%@)", name, email];
    if(name == nil) accountInfo = @"";
    if(email == nil) email = @"";
    
    NSString *studyURL = [awareStudy getStudyURL];
    NSString *deviceId = [awareStudy getDeviceId];
    NSString *awareStudyId = [awareStudy getStudyId];
    NSString *mqttServerName = [awareStudy getMqttServer];
    NSString *awareDeviceName = [awareStudy getDeviceName];
    if(studyURL == nil) studyURL = @"";
    if(deviceId == nil) deviceId = @"";
    if(awareStudyId == nil) awareStudyId = @"";
    if(mqttServerName == nil) mqttServerName = @"";
    if(awareDeviceName == nil) awareDeviceName = @"";
    
    // Get debug state (bool)
    NSString* debugState = @"OFF";
    if ([userDefaults boolForKey:SETTING_DEBUG_STATE]) {
        debugState = @"ON";
    }else{
        debugState = @"OFF";
    }
    
    // Get sync interval (min)
    NSString *syncInterval = [NSString stringWithFormat:@"%d",(int)[userDefaults doubleForKey:SETTING_SYNC_INT]/60];
    
    // Get data uploading network for sensor data
    NSString *wifiOnly = @"YES";
    if ([userDefaults boolForKey:SETTING_SYNC_WIFI_ONLY]) {
        wifiOnly = @"YES";
    }else{
        wifiOnly = @"NO";
    }
    
    
    NSString * batteryChargingOnly = @"YES";
    if ([userDefaults boolForKey:SETTING_SYNC_BATTERY_CHARGING_ONLY]) {
        batteryChargingOnly = @"YES";
    }else{
        batteryChargingOnly = @"NO";
    }
    
    
    cleanOldDataType cleanInterval = [userDefaults integerForKey:SETTING_FREQUENCY_CLEAN_OLD_DATA];
    NSString * cleanIntervalStr = @"";
    switch (cleanInterval) {
        case cleanOldDataTypeNever:
            cleanIntervalStr = @"Never";
            break;
        case cleanOldDataTypeWeekly:
            cleanIntervalStr = @"Weekly";
            break;
        case cleanOldDataTypeMonthly:
            cleanIntervalStr = @"Monthly";
            break;
        case cleanOldDataTypeDaily:
            cleanIntervalStr = @"Daily";
            break;
        case cleanOldDataTypeAlways:
            cleanIntervalStr = @"Always";
            break;
        default:
            break;
    }
    
    // Get maximum data size per POST
    if (maximumFileSize > 0 ) {
        maximumFileSize = maximumFileSize/1000;
    }
    NSString *maximumFileSizeDesc = [NSString stringWithFormat:@"%ld (KB)", maximumFileSize];
    //NSString *maximumFileSizeDesc = @"Not support now";
    
    
    // Get maximum fetch size per post
    NSString * fetchSizeStr = [NSString stringWithFormat:@"%ld records per post",[awareStudy getMaxFetchSize]];
    
    /**
     * Study and Device Information
     */
    // title
    [_sensors addObject:[self getCelContent:@"Study" desc:@"" image:@"" key:@"TITLE_CELL_VIEW"]];
    // study_url
    [_sensors addObject:[self getCelContent:@"AWARE Study URL" desc:studyURL image:@"" key:@"STUDY_CELL_VIEW_STUDY_URL"]];
    // device_id
    [_sensors addObject:[self getCelContent:@"AWARE Device ID" desc:deviceId image:@"" key:@"STUDY_CELL_VIEW"]];
    // study_number
    [_sensors addObject:[self getCelContent:@"AWARE Study Number" desc:awareStudyId image:@"" key:@"STUDY_CELL_VIEW"]];
    // aware server information
    [_sensors addObject:[self getCelContent:@"AWARE Server" desc:mqttServerName image:@"" key:@"STUDY_CELL_VIEW"]];
    
    [_sensors addObject:[self getCelContent:@"Device Name" desc:awareDeviceName image:@"" key:KEY_AWARE_DEVICE_NAME]];
    
//     Google Account Information if a user registered him/her google account. //@"STUDY_CELL_VIEW"]];
    [_sensors addObject:[self getCelContent:@"Google Account" desc:accountInfo image:@"" key:SENSOR_PLUGIN_GOOGLE_LOGIN]];
    
    
    /**
     * Defualt iOS supported sensors
     */
    // title
    [_sensors addObject:[self getCelContent:@"Sensors" desc:@"" image:@"" key:@"TITLE_CELL_VIEW"]];
    // accelerometer
    [_sensors addObject:[self getCelContent:@"Accelerometer" desc:@"Acceleration, including the force of gravity(m/s^2)" image:@"ic_action_accelerometer" key:SENSOR_ACCELEROMETER]];
    // barometer
    [_sensors addObject:[self getCelContent:@"Barometer" desc:@"Atomospheric air pressure (mbar/hPa)" image:@"ic_action_barometer" key:SENSOR_BAROMETER]];
    // battery
    [_sensors addObject:[self getCelContent:@"Battery" desc:@"Battery and power event" image:@"ic_action_battery" key:SENSOR_BATTERY]];
    // bluetooth
    [_sensors addObject:[self getCelContent:@"Bluetooth" desc:@"Bluetooth sensing" image:@"ic_action_bluetooth" key:SENSOR_BLUETOOTH]];
    // gyroscope
    [_sensors addObject:[self getCelContent:@"Gyroscope" desc:@"Rate of rotation of device (rad/s)" image:@"ic_action_gyroscope" key:SENSOR_GYROSCOPE]];
    // gravity
    [_sensors addObject:[self getCelContent:@"Gravity" desc:@"Gravity provides a three dimensional vector indicating the direction and magnitude of gravity (in m/s²)" image:@"ic_action_gravity" key:SENSOR_GRAVITY]];
    // linear  accelerometer
    [_sensors addObject:[self getCelContent:@"Linear Accelerometer" desc:@"The linear accelerometer measures the acceleration applied to the sensor built-in into the device, excluding the force of gravity, in m/s" image:@"ic_action_linear_acceleration" key:SENSOR_LINEAR_ACCELEROMETER]];
    // rotation
    [_sensors addObject:[self getCelContent:@"Rotation" desc:@"Orientation of the device in all axis" image:@"ic_action_rotation" key:SENSOR_ROTATION]];
    // locations (GPS)
    [_sensors addObject:[self getCelContent:@"Locations" desc:@"User's estimated location by GPS and network triangulation" image:@"ic_action_locations" key:SENSOR_LOCATIONS]];
    // magnetometer
    [_sensors addObject:[self getCelContent:@"Magnetometer" desc:@"Geomagnetic field strength around the device (uT)" image:@"ic_action_magnetometer" key:SENSOR_MAGNETOMETER]];
    // ESM
    [_sensors addObject:[self getCelContent:@"Mobile ESM/EMA" desc:@"Mobile questionnaries" image:@"ic_action_esm" key:SENSOR_ESMS]];
    // network
    [_sensors addObject:[self getCelContent:@"Network" desc:@"Network usage and traffic" image:@"ic_action_network" key:SENSOR_NETWORK]];
    // proximity
    [_sensors addObject:[self getCelContent:@"Proximity" desc:@"The proximity sensor measures the distance to an object in front of the mobile device. Depending on the hardware, it can be in centimeters or binary." image:@"ic_action_proximity" key:SENSOR_PROXIMITY]];
    // screen
    [_sensors addObject:[self getCelContent:@"Screen" desc:@"Screen events (on/off, locked/unlocked)" image:@"ic_action_screen" key:SENSOR_SCREEN]];
    // timezone
    [_sensors addObject:[self getCelContent:@"Timezone" desc:@"The timezone sensor keeps track of the user’s current timezone." image:@"ic_action_timezone" key:SENSOR_TIMEZONE]];
    // processor
    [_sensors addObject:[self getCelContent:@"Processor" desc:@"CPU workload for user, system and idle(%)" image:@"ic_action_processor" key:SENSOR_PROCESSOR]];
    // WiFi sensing
    [_sensors addObject:[self getCelContent:@"WiFi" desc:@"Wi-Fi sensing" image:@"ic_action_wifi" key:SENSOR_WIFI]];
    [_sensors addObject:[self getCelContent:@"BLE Heart Rate" desc:@"Collect heart rate data from an external heart rate sensor via BLE." image:@"ic_action_heartrate" key:SENSOR_BLE_HEARTRATE]];
    
    // [_sensors addObject:[self getCelContent:@"AmbientNoise" desc:@"AmbientNoise sensor" image:@"" key:SENSOR_AMBIENT_NOISE]];
    // [_sensors addObject:[self getCelContent:@"Light" desc:@"Ambient Light (lux)" image:@"ic_action_light"]];
    // [_sensors addObject:[self getCelContent:@"Proximity" desc:@"" image:@"ic_action_proximity"]];
    // [_sensors addObject:[self getCelContent:@"Telephony" desc:@"Mobile operator and specifications, cell tower and neighbor scanning" image:@"ic_action_telephony"
    
    
    /**
     * Plugins
     */
    // Google Fused Location
    [_sensors addObject:[self getCelContent:@"Fused Location" desc:@"Locations API provider. This plugin provides the user's current location in an energy efficient way." image:@"ic_action_google_fused_location" key:SENSOR_GOOGLE_FUSED_LOCATION]];
    // Ambient Noise
    [_sensors addObject:[self getCelContent:@"Ambient Noise" desc:@"Anbient noise sensing by using a microphone on a smartphone." image:@"ic_action_ambient_noise" key:SENSOR_AMBIENT_NOISE]];
    // Activity Recognition
    [_sensors addObject:[self getCelContent:@"Activity Recognition" desc:@"iOS Activity Recognition" image:@"ic_action_running" key:SENSOR_PLUGIN_GOOGLE_ACTIVITY_RECOGNITION]];
    // Device Usage
    [_sensors addObject:[self getCelContent:@"Device Usage" desc:@"This plugin measures how much you use your device" image:@"ic_action_device_usage" key:SENSOR_PLUGIN_DEVICE_USAGE]];
    // Open Weather
    [_sensors addObject:[self getCelContent:@"Open Weather" desc:@"Weather information by OpenWeatherMap API." image:@"ic_action_openweather" key:SENSOR_PLUGIN_OPEN_WEATHER]];
    // NTPTime
    [_sensors addObject:[self getCelContent:@"NTPTime" desc:@"Measure device's clock drift from an NTP server." image:@"ic_action_ntptime" key:SENSOR_PLUGIN_NTPTIME]];
    // Pedometer
//    [_sensors addObject:[self getCelContent:@"Pedometer" desc:@"This plugin collects user's daily steps." image:@"ic_action_steps" key:SENSOR_PLUGIN_PEDOMETER]];
    // communication
    [_sensors addObject:[self getCelContent:@"Communication" desc:@"The Communication sensor logs communication events such as calls and messages, performed by or received by the user." image:@"ic_action_communication" key:SENSOR_CALLS]];
    [_sensors addObject:[self getCelContent:@"Label" desc:@"Save event labels to the AWARE server" image:@"ic_action_label" key:SENSOR_LABELS]];
     // Microsoft Band
    [_sensors addObject:[self getCelContent:@"Microsoft Band" desc:@"Wearable sensor data (such as Heart Rate, UV, and Skin Temperature) from Microsoft Band." image:@"ic_action_msband" key:SENSOR_PLUGIN_MSBAND]];
    // Google Login
    [_sensors addObject:[self getCelContent:@"Google Login" desc:@"Multi-device management using Google Account." image:@"google_logo" key:SENSOR_PLUGIN_GOOGLE_LOGIN]];
    // Balanced Campus Calendar
    [_sensors addObject:[self getCelContent:@"Balanced Campus Calendar" desc:@"This plugin gathers calendar events from all Google Calendars from the phone." image:@"ic_action_google_cal_grab" key:@"balancedcampuscalendar"]];
    // Balanced Campus Journal
    [_sensors addObject:[self getCelContent:@"Balanced Campus Journal" desc:@"This plugin creates new events in the journal calendar and sends a reminder email to the user to update the journal." image:@"ic_action_google_cal_push" key:SENSOR_PLUGIN_GOOGLE_CAL_PUSH]];
    // Balanced Campus ESMs (ESM Scheduler)
    [_sensors addObject:[self getCelContent:@"Balanced Campus ESMs" desc:@"ESM Plugin" image:@"ic_action_campus" key:SENSOR_PLUGIN_CAMPUS]];
    //
    [_sensors addObject:[self getCelContent:@"Web ESMs" desc:@"Web ESM Plugin" image:@"ic_action_web_esm" key:SENSOR_PLUGIN_WEB_ESM]];
    // HealthKit
//    [_sensors addObject:[self getCelContent:@"HealthKit" desc:@"This plugin collects stored data in HealthKit App on iOS" image:@"ic_action_health_kit" key:@"sensor_plugin_health_kit"]];

    // [_sensors addObject:[self getCelContent:@"Direction (iOS)" desc:@"Device's direction (0-360)" image:@"safari_copyrighted" key:SENSOR_DIRECTION]];
    //    [_sensors addObject:[self getCelContent:@"Rotation (iOS)" desc:@"Orientation of the device" image:@"ic_action_rotation" key:SENSOR_ROTATION]];
    

    
    /**
     * Setting
     */
    // title for settings
    [_sensors addObject:[self getCelContent:@"Settings" desc:@"" image:@"" key:@"TITLE_CELL_VIEW"]];
    // debug state
    [_sensors addObject:[self getCelContent:@"Debug" desc:debugState image:@"" key:@"STUDY_CELL_DEBUG"]];
    // sync interval
    [_sensors addObject:[self getCelContent:@"Sync Interval (min)" desc:syncInterval image:@"" key:@"STUDY_CELL_SYNC"]];
    // sync network condition
    [_sensors addObject:[self getCelContent:@"Auto sync with only Wi-Fi" desc:wifiOnly image:@"" key:@"STUDY_CELL_WIFI"]];
    // sync battery condition
    [_sensors addObject:[self getCelContent:@"Auto sync with only battery charging" desc:batteryChargingOnly image:@"" key:@"STUDY_CELL_BATTERY"]];
    // frequency of clean old data
    [_sensors addObject:[self getCelContent:@"Frequency of clean old data" desc:cleanIntervalStr image:@"" key:@"STUDY_CELL_CLEAN_OLD_DATA"]];
    // [userDefaults setInteger:10000 forKey:KEY_MAX_FETCH_SIZE_NORMAL_SENSOR];
    [_sensors addObject:[self getCelContent:@"Maximum fetch records per POST (for SQLite)" desc:fetchSizeStr image:@"" key:@"STUDY_CELL_MAX_FETCH_SIZE_NORMAL_SENSOR"]];
    // maximum data size per one HTTP/POST
    [_sensors addObject:[self getCelContent:@"Maximum fetch size(KB) per POST" desc:maximumFileSizeDesc image:@"" key:@"STUDY_CELL_MAX_FILE_SIZE"]];
    // current version of AWARE iOS
    NSString* version = [NSString stringWithFormat:@"%@",[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    NSString *build = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    if(build != nil){
        version = [version stringByAppendingFormat:@"(%@)", build];
    }
    [_sensors addObject:[self getCelContent:@"Version" desc:version image:@"" key:@"STUDY_CELL_VIEW"]];
    // manual data upload button
    [_sensors addObject:[self getCelContent:@"Manual Data Upload" desc:@"Please push this row for uploading sensor data!" image:@"" key:@"STUDY_CELL_MANULA_UPLOAD"]];
    [_sensors addObject:[self getCelContent:@"General App Settings" desc:@"Move to the Settings app" image:@"" key:@"STUDY_CELL_SETTINGS_APP"]];
    // daily study update
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm"];
    NSString *formattedDateString = @"--:--";
    if (dailyUpdateTimer != nil) {
        if (dailyUpdateTimer.fireDate != nil) {
            formattedDateString = [dateFormatter stringFromDate:dailyUpdateTimer.fireDate];
        }
    }
    [_sensors addObject:[self getCelContent:@"Auto Study Update" desc:formattedDateString image:@"" key:@"STUDY_CELL_AUTO_STUDY_UPDATE"]];
    
    [awareStudy refreshAllSetting];
    NSString * studyInfo = @"No Study: Let's join a study!";
    if([awareStudy getMqttServer] != nil){
        studyInfo = [NSString stringWithFormat:@"%@ (%@)", awareStudy.getMqttServer, awareStudy.getStudyId];
    }
    [_sensors addObject:[self getCelContent:@"Quit Study" desc:studyInfo image:@"" key:@"STUDY_CELL_QUIT_STUDY"]];
//    [_sensors addObject:[self getCelContent:@"Privacy Policy" desc:@"" image:@"" key:@"STUDY_CELL_PRIVACY_POLICY"]];
    [_sensors addObject:[self getCelContent:@"About AWARE" desc:@"" image:@"" key:@"STUDY_CELL_ABOUT_AWARE"]];
    [_sensors addObject:[self getCelContent:@"Team" desc:@"" image:@"" key:@"STUDY_CELL_TEAM"]];
//    [_sensors addObject:[self getCelContent:@"Terms of Use" desc:@"" image:@"" key:@"STUDY_CELL_TERMS_OF_USE"]];
    [_sensors addObject:[self getCelContent:@"Introduction" desc:@"" image:@"" key:@"STUDY_CELL_SHOW_INTRODUCTION"]];
    
    [self.tableView reloadData];
}



/**
 * This method adds an AWARESensor to _sensorManagaer using the -addNewSensorWithSensorName:settings:plugins:uploadInterva: method.
 * And also, this method return the document type variable for the sensor list.
 *
 * @param title A sensor name
 * @param desc  A Description of the sensor
 * @param image An image file name in the Assets.xcassets
 * @param key   An unique key of the sensor in the AWAREKey class
 * @return Return a NSDictionary object for sensor list
 */
- (NSMutableDictionary *) getCelContent:(NSString *)title
                                   desc:(NSString *)desc
                                  image:(NSString *)image
                                    key:(NSString *)key {
    // Make a dictionary object for a raw
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setObject:title forKey:KEY_CEL_TITLE];
    [dic setObject:desc forKey:KEY_CEL_DESC];
    [dic setObject:image forKey:KEY_CEL_IMAGE];
    [dic setObject:key forKey:KEY_CEL_SENSOR_NAME];

    if(sensorManager != nil){
        bool exist = [sensorManager isExist:key];
        if (exist) {
            [dic setObject:@"true" forKey:KEY_CEL_STATE];
        }
    }
    return dic;
}


- (IBAction)pushedEsmButtonOnNavigationBar:(id)sender {
//    [self performSegueWithIdentifier:@"esmView" sender:self];
//    [self performSegueWithIdentifier:@"webEsmView" sender:self];
    
    ESMStorageHelper * helper = [[ESMStorageHelper alloc] init];
    NSArray * storedEsms = [helper getEsmTexts];
    if(storedEsms != nil){
        if (storedEsms.count > 0 ){
            [ESM setAppearedState:YES];
            [self performSegueWithIdentifier:@"esmView" sender:self];
        }
    }
    
    NSArray * esms = [webESM getValidESMsWithDatetime:[NSDate new]];
    if(esms != nil && esms.count != 0 ){
        [ESM setAppearedState:YES];
        [self performSegueWithIdentifier:@"webEsmView" sender:self];
    }
    
}

/**
 When a study is refreshed (e.g., pushed refresh button, changed settings, 
 and/or done daily study update), this method is called before the -initList.
 */
- (IBAction)pushedStudyRefreshButton:(id)sender {
    // Refresh the study information
    [awareStudy refreshStudy];
    
    _refreshButton.enabled = NO;
    [self.tableView reloadData];
    [self performSelector:@selector(initContentsOnTableView) withObject:0 afterDelay:3];
    // [self.tableView performSelector:@selector(reloadData) withObject:nil afterDelay:3.1];
    [self performSelector:@selector(refreshButtonEnableYes) withObject:0 afterDelay:10];
}

- (void) refreshButtonEnableYes {
    _refreshButton.enabled = YES;
}


-(BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item
{
    NSLog(@"Back button is pressed!");
    [self.navigationController popToRootViewControllerAnimated:YES];
    [self performSelector:@selector(initContentsOnTableView) withObject:0 afterDelay:3];
    return YES;
}



//////////////////////////////
//// Table View Operations
//////////////////////////////

/**
 * This is the delegate of TableView. When the table row is selected, the method is called.
 * If an AWARESensor need specific fanction (such as settings, view, conformation), we can add the function to this method.
 */
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
//    NSLog(@"%ld is selected!", indexPath.row);
    NSDictionary *item = (NSDictionary *)[_sensors objectAtIndex:indexPath.row];
    NSString *key = [item objectForKey:KEY_CEL_SENSOR_NAME];
    // Debug Model ON/OFF
    if ([key isEqualToString:@"STUDY_CELL_DEBUG"]) { //Debug
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Debug Statement" message:@"" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"ON", @"OFF", nil];
        alert.tag = 1;
        [alert show];
    // Set Sync Interval
    } else if ([key isEqualToString:@"STUDY_CELL_SYNC"]) { //Sync
        // Get the interval
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        double interval = [userDefaults doubleForKey:SETTING_SYNC_INT];
        // Set the interval
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Sync Interval (min)" message:@"Please inpute a sync interval to the server." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Done",nil];
        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
        [[alert textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeNumberPad];
        [[alert textFieldAtIndex:0] becomeFirstResponder];
        [alert textFieldAtIndex:0].text = [NSString stringWithFormat:@"%d", (int)(interval/60)];
        alert.tag = 2;
        [alert show];
    // Set Wi-Fi and mobile network setting
    }else if([key isEqualToString:@"STUDY_CELL_WIFI"]){ //wifi
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Sync Statement (Network)" message:@"Do you want to sync your data with only Wi-Fi enviroment?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"YES",@"NO",nil];
        alert.tag = 3;
        [alert show];
    }else if([key isEqualToString:@"STUDY_CELL_BATTERY"]){
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Sync Statement (Battery)" message:@"Do you want to sync your data with only battery charging condition?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"YES",@"NO",nil];
        alert.tag = 9;
        [alert show];
    // Set maximum file size
    }else if([key isEqualToString:@"STUDY_CELL_MAX_FILE_SIZE"]){ //max file size
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Maximum Size of Post Data(KB)" message:@"Please input a maximum file size for uploading sensor data." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Done",nil];
        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSInteger maximumFileValue =  [userDefaults integerForKey:KEY_MAX_DATA_SIZE];
        if (maximumFileValue > 0 ) {
            maximumFileValue = maximumFileValue/1000;
        }
        NSString *maximumFileSizeDesc = [NSString stringWithFormat:@"%ld", maximumFileValue];
        [[alert textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeNumberPad];
        [[alert textFieldAtIndex:0] becomeFirstResponder];
        [alert textFieldAtIndex:0].text = maximumFileSizeDesc;
        alert.tag = 4;
        [alert show];
    // ESM View
    }else if([key isEqualToString:SENSOR_ESMS]){
        // [TODO] For testing ESM Module...
        [self performSegueWithIdentifier:@"esmView" sender:self];
    }else if([key isEqualToString:SENSOR_PLUGIN_GOOGLE_LOGIN]){
        [self performSegueWithIdentifier:@"googleLogin" sender:self];
    // Google Calendar Journal Plugin
    }else if ([key isEqualToString:SENSOR_PLUGIN_GOOGLE_CAL_PUSH]) {
        GoogleCalPush *googlePush = [[GoogleCalPush alloc] init];
        [googlePush showTargetCalendarCondition];
    // Google Calendar Calendar Plugin
    }else if([key isEqualToString:SENSOR_PLUGIN_CAMPUS]){
        NSString* schedules = [sensorManager getLatestSensorValue:SENSOR_PLUGIN_CAMPUS];
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Current ESM Schedules" message:schedules delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        alert.tag = 7;
        [alert show];
    // Do manula data upload
    }else if ([key isEqualToString:@"STUDY_CELL_MANULA_UPLOAD"]){
         UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Start Uploading Data?"
                                                          message:@"Please push the 'YES' button if you want to upload sensor data to the server. Also, please don't close this application and keep connecting to Wi-Fi during uploading the data."
                                                         delegate:self
                                                cancelButtonTitle:@"Not Now"
                                                otherButtonTitles:@"YES",nil];
        alert.tag = 8;
        [alert show];
    }else if([key isEqualToString:@"STUDY_CELL_SETTINGS_APP"]){
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Move to Settings App?"
                                                         message:@"You can change the allow to access APIs on the Settings app."
                                                        delegate:self
                                               cancelButtonTitle:@"NO"
                                               otherButtonTitles:@"YES",nil];
        alert.tag = 10;
        [alert show];
    }else if([key isEqualToString:SENSOR_LABELS]){
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Event Label" message:@"Please edit current your condition!" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Done",nil];
        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
        alert.tag = 11;
        [alert show];
    }else if ([key isEqualToString:@"STUDY_CELL_QUIT_STUDY"]){
        
        if([awareStudy getMqttServer] != nil){
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Quit the current study?"
                                                             message:[NSString stringWithFormat:@"Now you are joining %@(%@)", [awareStudy getMqttServer], [awareStudy getStudyId]]
                                                            delegate:self
                                                   cancelButtonTitle:@"Cancel"
                                                   otherButtonTitles:@"Quit",nil];
            alert.tag = 12;
            [alert show];
        }
    } else if([key isEqualToString:@"STUDY_CELL_PRIVACY_POLICY"]){
//        webViewURL = [NSURL URLWithString:@""];
        [self performSegueWithIdentifier:@"webView" sender:self];
    } else if ([key isEqualToString:@"STUDY_CELL_ABOUT_AWARE"]){
        webViewURL = [NSURL URLWithString:@"http://www.awareframework.com/"];
        [self performSegueWithIdentifier:@"webView" sender:self];
    } else if ([key isEqualToString:@"STUDY_CELL_TEAM"]){
        webViewURL = [NSURL URLWithString:@"http://www.awareframework.com/team/"];
        [self performSegueWithIdentifier:@"webView" sender:self];
    } else if ([key isEqualToString:@"STUDY_CELL_SHOW_INTRODUCTION"]){
         [intro showInView:self.view animateDuration:0.0];
         NSIndexPath* indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
         [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
    } else if ([key isEqualToString:@"STUDY_CELL_CLEAN_OLD_DATA"]){
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"AWARE Setting"
                                                         message:@"Please select when old data will be cleared."
                                                        delegate:self
                                               cancelButtonTitle:@"Cancel"
                                               otherButtonTitles:@"Never",@"Weekly",@"Monthly",@"Daily",@"Always",nil];
        alert.tag = 14;
        [alert show];
    } else if ([key isEqualToString:@"STUDY_CELL_MAX_FETCH_SIZE_NORMAL_SENSOR"]){
        // @"Maximum fetch size for SQLite"
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Maximum Fetch Records Per POST" message:@"Please input the maximum fetch records per POST." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Done",nil];
        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSInteger fetchSize = [userDefaults integerForKey:KEY_MAX_FETCH_SIZE_NORMAL_SENSOR];
        [[alert textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeNumberPad];
        [[alert textFieldAtIndex:0] becomeFirstResponder];
        [alert textFieldAtIndex:0].text = [NSString stringWithFormat:@"%ld", fetchSize];
        alert.tag = 15;
        [alert show];
    } else if ([key isEqualToString:KEY_AWARE_DEVICE_NAME]){
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Device Name Setting" message:@"Please edit your new device name!" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Done",nil];
        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
        [alert textFieldAtIndex:0].text = awareStudy.getDeviceName;
        alert.tag = 16;
        [alert show];
    } else if ([key isEqualToString:@"STUDY_CELL_VIEW_STUDY_URL"]){
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Study URL" message:@"Please edit a study URL to join the aware study." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Done", nil];
        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
        [alert textFieldAtIndex:0].text = awareStudy.getStudyURL;
        alert.tag = 17;
        [alert show];
    }
}


/**
 * When a user select a button on the UIAlertView, this method is called with selected buttonIndex.
 */
- (void)alertView:(UIAlertView *)alertView
clickedButtonAtIndex:(NSInteger)buttonIndex{
    NSString* title = alertView.title;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    if([title isEqualToString:@"Debug Statement"]){
//        NSLog(@"%ld", buttonIndex);
        if (buttonIndex == 1){ //yes
            [userDefaults setBool:YES forKey:SETTING_DEBUG_STATE];
            [self pushedStudyRefreshButton:alertView];
        } else if (buttonIndex == 2){ // no
            //reset clicked
            [userDefaults setBool:NO forKey:SETTING_DEBUG_STATE];
            [self pushedStudyRefreshButton:alertView];
        } else {
            NSLog(@"Cancel");
        }
        [self.tableView reloadData];
        [self initContentsOnTableView];
    }else if([title isEqualToString:@"Sync Interval (min)"]){
        // cancel
        if ( buttonIndex == [alertView cancelButtonIndex]){
            NSLog(@"Cancel");
            return;
        }
        // Set value
        NSString *interval = [alertView textFieldAtIndex:0].text;
        if ([interval isEqualToString:@""] || [interval isEqualToString:@"0"]) {
            return;
        }
        // Set the sync interval to userDedaults
        double syncInterval = [interval doubleValue] * 60.0f;
        [userDefaults setObject:[NSNumber numberWithDouble:syncInterval] forKey:SETTING_SYNC_INT];
        [userDefaults synchronize];
        
        // restart uploader
        [sensorManager startUploadTimerWithInterval:syncInterval];
        
        [self.tableView reloadData];
        [self initContentsOnTableView];
        
    }else if(alertView.tag == 3){
//        NSLog(@"%ld", buttonIndex);
        if (buttonIndex == 1){ //yes
            [userDefaults setBool:YES forKey:SETTING_SYNC_WIFI_ONLY];
            [self pushedStudyRefreshButton:alertView];
//            [self initContentsOnTableView];
        } else if (buttonIndex == 2){ // no
            //reset clicked
            [userDefaults setBool:NO forKey:SETTING_SYNC_WIFI_ONLY];
//            [self initContentsOnTableView];
            [self pushedStudyRefreshButton:alertView];
        } else {
            NSLog(@"Cancel");
        }
        [self.tableView reloadData];
        [self initContentsOnTableView];
    }else if (alertView.tag == 9){ // Set Sync Setting
//        NSLog(@"%ld", buttonIndex);
        if (buttonIndex == 1){ //yes
            [userDefaults setBool:YES forKey:SETTING_SYNC_BATTERY_CHARGING_ONLY];
            [self pushedStudyRefreshButton:alertView];
        } else if (buttonIndex == 2){ // no
            [userDefaults setBool:NO forKey:SETTING_SYNC_BATTERY_CHARGING_ONLY];
            [self pushedStudyRefreshButton:alertView];
        } else {
            NSLog(@"Cancel");
        }
        [self.tableView reloadData];
        [self initContentsOnTableView];
    }else if([title isEqualToString:@"Maximum Size of Post Data(KB)"]){
        if ( buttonIndex == [alertView cancelButtonIndex]){
            NSLog(@"Cancel");
            return;
        }
        NSString *maximumValueStr = [alertView textFieldAtIndex:0].text;
        if ([maximumValueStr isEqualToString:@""] || [maximumValueStr isEqualToString:@"0"]) {
            return;
        }
        NSInteger maximumValue = [maximumValueStr integerValue] * 1000;
        [userDefaults setObject:[NSNumber numberWithInteger:maximumValue] forKey:KEY_MAX_DATA_SIZE];
        [self pushedStudyRefreshButton:alertView];
        
        [self.tableView reloadData];
        [self initContentsOnTableView];
    }else if(alertView.tag == 8){ //manual data upload
        if (buttonIndex == [alertView cancelButtonIndex]) {
            
        }else if (buttonIndex == 1){
            [sensorManager syncAllSensorsWithDBInForeground];
        }
    }else if(alertView.tag == 10){
        if (buttonIndex == [alertView cancelButtonIndex]) {
            
        }else if (buttonIndex == 1){
//            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"prefs://"]];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
        }
    }else if(alertView.tag == 11){
        if ( buttonIndex == [alertView cancelButtonIndex]){
            NSLog(@"Cancel");
            return;
        }
        NSString *label = [alertView textFieldAtIndex:0].text;
        Labels * labelsSensor = [[Labels alloc] initWithAwareStudy:awareStudy dbType:AwareDBTypeTextFile];
        [labelsSensor saveLabel:label withKey:@"top" type:@"text" body:@"" triggerTime:[NSDate new] answeredTime:[NSDate new]];
        [labelsSensor syncAwareDB];
    }else if (alertView.tag == 12){
        if(buttonIndex == 1){
            [sensorManager stopAndRemoveAllSensors];
            [awareStudy clearAllSetting];
            [self pushedStudyRefreshButton:nil];
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"The study is quitted"
                                                             message:nil
                                                            delegate:self
                                                   cancelButtonTitle:@"Close"
                                                   otherButtonTitles:nil];
            [alert show];
        }
    }else if (alertView.tag == 14){
        switch (buttonIndex) {
            case 0:
                NSLog(@"cancel");
                break;
            case 1:
                [userDefaults setInteger:cleanOldDataTypeNever forKey:SETTING_FREQUENCY_CLEAN_OLD_DATA];
                break;
            case 2:
                [userDefaults setInteger:cleanOldDataTypeWeekly forKey:SETTING_FREQUENCY_CLEAN_OLD_DATA];
                break;
            case 3:
                [userDefaults setInteger:cleanOldDataTypeMonthly forKey:SETTING_FREQUENCY_CLEAN_OLD_DATA];
                break;
            case 4:
                [userDefaults setInteger:cleanOldDataTypeDaily forKey:SETTING_FREQUENCY_CLEAN_OLD_DATA];
                break;
            case 5:
                [userDefaults setInteger:cleanOldDataTypeAlways forKey:SETTING_FREQUENCY_CLEAN_OLD_DATA];
                break;
            default:
                
                break;
        }
        [self.tableView reloadData];
        [self initContentsOnTableView];
    }else if (alertView.tag == 15){
        if ( buttonIndex == [alertView cancelButtonIndex]){
            NSLog(@"Cancel");
            return;
        }
        NSString *maximumValueStr = [alertView textFieldAtIndex:0].text;
        if ([maximumValueStr isEqualToString:@""] || [maximumValueStr isEqualToString:@"0"]) {
            return;
        }
        NSInteger maximumValue = [maximumValueStr integerValue];
        [userDefaults setObject:[NSNumber numberWithInteger:maximumValue] forKey:KEY_MAX_FETCH_SIZE_NORMAL_SENSOR];
        [userDefaults synchronize];
        
        [self pushedStudyRefreshButton:alertView];
        
        [self.tableView reloadData];
        [self initContentsOnTableView];
    }else if(alertView.tag == 16){
        if ( buttonIndex == [alertView cancelButtonIndex]){
            NSLog(@"Cancel");
            return;
        }
        NSString *newDeviceName = [alertView textFieldAtIndex:0].text;
        if ([newDeviceName isEqualToString:@""]) {
            return;
        }
        [awareStudy setDeviceName:newDeviceName];
        [self.tableView reloadData];
        [self initContentsOnTableView];
    }else if(alertView.tag == 17){
        if(buttonIndex == [alertView cancelButtonIndex]){
            NSLog(@"Cancel");
            return;
        }else{
            NSString * awareURL = [alertView textFieldAtIndex:0].text;
            if([awareURL isEqualToString:@""]){
                return;
            }else{
                BOOL state = [awareStudy setStudyInformationWithURL:awareURL];
                if(state){
                    [self.tableView reloadData];
                    [self initContentsOnTableView];
                }else{
                    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"The URL is wrong!" message:@"Please edit a correct URL." delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                    [alert show];
                }
            }
        }
    }
}


-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_sensors count];
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = (NSDictionary *)[_sensors objectAtIndex:indexPath.row];
    if ([[item objectForKey:KEY_CEL_SENSOR_NAME] isEqualToString:@"TITLE_CELL_VIEW"]) {
        return 40;
    }else if ([[item objectForKey:KEY_CEL_SENSOR_NAME] isEqualToString:@"STUDY_CELL_VIEW"]){
        return 80;
    }else{
        return [tableView rowHeight];
    }
}



- (void)updateVisibleCells {
    for (UITableViewCell *cell in [self.tableView visibleCells]){
        [self updateCell:cell atIndexPath:[self.tableView indexPathForCell:cell]];
//        NSLog(@"%@", cell);
    }
}


//for cell updating
- (void)updateCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *item = (NSDictionary *)[_sensors objectAtIndex:indexPath.row];
    NSString *sensorKey = [item objectForKey:KEY_CEL_SENSOR_NAME];
    NSString* latestSensorData = nil;
    @autoreleasepool {
        latestSensorData = [sensorManager getLatestSensorValue:sensorKey];
        //update latest sensor data
        if(![latestSensorData isEqualToString:@""]){
            [cell.detailTextLabel setText:latestSensorData];
        }
    }
}



- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    @autoreleasepool {
        static NSString *MyIdentifier = @"MyReuseIdentifier";
//
        NSDictionary *item = (NSDictionary *)[_sensors objectAtIndex:indexPath.row];
//
//        /// Make a cell by _sensors (sensor list on ViewController.)
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle  reuseIdentifier:MyIdentifier];
        }
        cell.textLabel.text = [item objectForKey:KEY_CEL_TITLE];
        cell.detailTextLabel.text = [item objectForKey:KEY_CEL_DESC];
        NSString * imageName = [item objectForKey:KEY_CEL_IMAGE];
        UIImage *theImage= nil;
        if (![imageName isEqualToString:@""]) {
            theImage = [UIImage imageNamed:imageName];
        }
        NSString *stateStr = [item objectForKey:KEY_CEL_STATE];
        cell.imageView.image = theImage;
    
        NSString *sensorKey = [item objectForKey:KEY_CEL_SENSOR_NAME];
        NSString* latestSensorData = [sensorManager getLatestSensorValue:sensorKey];
    
    
         latestSensorData = [sensorManager getLatestSensorValue:sensorKey];
         //update latest sensor data
        if(![latestSensorData isEqualToString:@""]){
            [cell.detailTextLabel setText:latestSensorData];
        }
        if ([stateStr isEqualToString:@"true"]) {
             theImage = [theImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
             UIImageView *aImageView = [[UIImageView alloc] initWithImage:theImage];
             aImageView.tintColor = UIColor.redColor;
             cell.imageView.image = theImage;
        }
        return cell;
    }
    
}



///////////////////////////////////////////////
///////////////////////////////////////////////

- (NSArray *) getIntroPages {
    NSMutableArray * pages = [[NSMutableArray alloc] init];
    
    // basic
    EAIntroPage *page1 = [EAIntroPage page];
    page1.title = @"About AWARE";
    page1.desc = @"AWARE Client iOS is a sensing framework dedicated to an instrument, infer, log and share mobile context information, for smartphone users and researchers. AWARE captures hardware-, software-, and human-based data.";
    page1.titlePositionY = 350;
    page1.descPositionY = 300;
    page1.titleColor = [UIColor darkGrayColor];
    page1.descColor = [UIColor darkGrayColor];
    page1.bgColor = [UIColor whiteColor];
    page1.titleIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ic_launcher_aware-web"]];
    [page1.titleIconView setBounds:CGRectMake(0,0,200,200)];
    
    // custom
    EAIntroPage *page2 = [EAIntroPage page];
    page2.title = @"Individuals: Record your data";
    page2.desc = @"By using the AWARE Dashboard, you can enable or disable sensors. Privacy is enforced by design, so AWARE does not log personal information, such as phone numbers or contacts information. Also, the data is saved locally on your mobile phone temporary. AWARE upload the data to the AWARE server automatically if the device has a Wi-Fi network and is charged battery.";
    page2.titlePositionY = 350;
    page2.descPositionY = 300;
    page2.titleColor = [UIColor darkGrayColor];
    page2.descColor = [UIColor darkGrayColor];
    page2.bgColor = [UIColor whiteColor];
    page2.titleIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"personal"]];
    [page2.titleIconView setBounds:CGRectMake(0,0,200,200)];
    
    // page 3
    EAIntroPage *page3 = [EAIntroPage page];
    page3.title = @"Scientists: Run studies";
    page3.desc = @"Running a mobile related study has never been easier. Install AWARE on the participants phone, select the data you want to collect and that is it. If you use the own AWARE server, you can set mobile questionary.";
    page3.titlePositionY = 350;
    page3.descPositionY = 300;
    page3.titleColor = [UIColor darkGrayColor];
    page3.descColor = [UIColor darkGrayColor];
    page3.bgColor = [UIColor whiteColor];
    page3.titleIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"scientist"]];
    [page3.titleIconView setBounds:CGRectMake(0,0,200,200)];
    
    EAIntroPage *page4 = [EAIntroPage page];
    page4.title = @"How to Use AWARE Client";
    page4.desc = @"1.Set a study on AWARE Dashboard and make a QRcode for the study\n2.Read the QRcode by AWARE client's QRcode reader\n3.Install SSL certificiation file and push a 'Refresh button'\n3.AWARE client start sensing and uploading your contexts in the background\n4.You can quit the study by 'Quit Study' button";
    page4.titlePositionY = 350;
    page4.descPositionY = 300;
    page4.titleColor = [UIColor darkGrayColor];
    page4.descColor = [UIColor darkGrayColor];
    page4.bgColor = [UIColor whiteColor];
    page4.titleIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"aware_qrcode"]];
    [page4.titleIconView setBounds:CGRectMake(0,0,200,200)];
    
    EAIntroPage *page5 = [EAIntroPage page];
    page5.titleColor = [UIColor darkGrayColor];
    page5.title = @"Welcome to AWARE Framework!!";
    page5.titleFont = [UIFont fontWithName:@"Georgia-BoldItalic" size:30];
    page5.titlePositionY = 500;
    page5.descColor = [UIColor darkGrayColor];
    page5.desc = @"You can get more detail information about AWARE Framework from the following URL.\nhttp://www.awareframework.com/";
    page5.descPositionY = 400;
    page5.bgColor = [UIColor whiteColor];
    
    [pages addObject:page1];
    [pages addObject:page2];
    [pages addObject:page3];
    [pages addObject:page4];
    [pages addObject:page5];
    
    return pages;
}



@end
