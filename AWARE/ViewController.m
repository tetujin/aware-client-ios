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

// Util
#import "AWAREStudy.h"
#import "AWAREKeys.h"
#import "AWAREUtils.h"
#import "ESMStorageHelper.h"
#import "AppDelegate.h"
#import "Observer.h"

// Plugins
#import "GoogleCalPush.h"
#import "Pedometer.h"
#import "Orientation.h"
#import "Debug.h"
#import "AWAREHealthKit.h"
#import "Scheduler.h"
#import "Memory.h"
#import "Labels.h"
#import "BLEHeartRate.h"
#import "AmbientLight.h"

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
    /// A timer for a daily sync
    NSTimer * dailyUpdateTimer;
    /// A Debug sensor object
    Debug *debugSensor;

    /** View */
    /// A timer for updating a list view
    NSTimer *listUpdateTimer;
    
    AWAREStudy * awareStudy;
    
    AWARESensorManager * sensorManager;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    /// Init keys and default interval
    KEY_CEL_TITLE = @"title";
    KEY_CEL_DESC = @"desc";
    KEY_CEL_IMAGE = @"image";
    KEY_CEL_STATE = @"state";
    KEY_CEL_SENSOR_NAME = @"sensorName";
    uploadInterval = 60*15;
    
    /// Set a timer for a daily sync update
    /**
     * Every 2AM, AWARE iOS refresh the joining study in the background.
     * A developer can change the time (2AM to xxxAM/PM) by changing the dailyUpdateTime(NSDate) Object
     */
    NSDate* dailyUpdateTime = [AWAREUtils getTargetNSDate:[NSDate new] hour:2 minute:0 second:0 nextDay:YES]; //2AM
    dailyUpdateTimer = [[NSTimer alloc] initWithFireDate:dailyUpdateTime
                                                interval:60*60*24 // daily
                                                  target:self
                                                selector:@selector(pushedStudyRefreshButton:)
                                                userInfo:nil
                                                 repeats:YES];
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
//    [runLoop addTimer:dailyUpdateTimer forMode:NSDefaultRunLoopMode];
    [runLoop addTimer:dailyUpdateTimer forMode:NSRunLoopCommonModes];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    /// Set defualt settings
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
//    [userDefaults setBool:NO forKey:@"aware_inited"];
    if (![userDefaults boolForKey:@"aware_inited"]) {
        [userDefaults setBool:NO forKey:SETTING_DEBUG_STATE];
        [userDefaults setBool:YES forKey:SETTING_SYNC_WIFI_ONLY];
        [userDefaults setBool:YES forKey:SETTING_SYNC_BATTERY_CHARGING_ONLY];
        [userDefaults setDouble:uploadInterval forKey:SETTING_SYNC_INT];
        [userDefaults setBool:YES forKey:@"aware_inited"];
        [userDefaults setBool:NO forKey:KEY_APP_TERMINATED];
        [userDefaults setInteger:0 forKey:KEY_UPLOAD_MARK];
        [userDefaults setInteger:1000 * 100 forKey:KEY_MAX_DATA_SIZE]; // 100 KB
    }
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;

    // A sensor list for table view
    _sensors = [[NSMutableArray alloc] init];
    
    // AWAREStudy manages a study configurate
    awareStudy = [[AWAREStudy alloc] initWithReachability:YES];
    
    /**
     * Init a Debug Sensor for collecting a debug message.
     * A developer can store debug messages to an aware database
     * by using the -saveDebugEventWithText:type:label: method on the debugSensor.
     */
    debugSensor = [[Debug alloc] initWithAwareStudy:awareStudy];
    
    /// Init sensor manager for the list view
    AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
    sensorManager = delegate.sharedSensorManager;
    
    [self initContentsOnTableView];
    
    /// Set delegates for a navigation bar and table view
    if ([AWAREUtils getCurrentOSVersionAsFloat] >= 9.0) {
        [self.navigationController.navigationBar setDelegate:self];
    }
    
    /// Start an update timer for list view. This timer refreshed the list view every 0.1 sec.
    listUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self.tableView selector:@selector(reloadData) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:listUpdateTimer forMode:NSRunLoopCommonModes];

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
        if (storedEsms.count > 0) {
            [self performSegueWithIdentifier:@"esmView" sender:self];
        }
    }else{
        NSLog(@"----------");
    }
    
    if([AWAREUtils getCurrentOSVersionAsFloat] >= 9.0){
        if ([NSProcessInfo processInfo].lowPowerModeEnabled ) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"prefs:root=BATTERY_USAGE"]];
        }
    }
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSLog(@" Hello ESM view !");
    if ([segue.identifier isEqualToString:@"esmView"]) {
//        AWAREEsmViewController *esmView = [segue destinationViewController];    // <- 1
    }
}




- (void)didReceiveMemoryWarning {
    [debugSensor saveDebugEventWithText:@"didReceiveMemoryWarning" type:DebugTypeWarn label:@""];
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
    
    NSString *deviceId = [awareStudy getDeviceId];
    NSString *awareStudyId = [awareStudy getStudyId];
    NSString *mqttServerName = [awareStudy getMqttServer];
    if(deviceId == nil) deviceId = @"";
    if(awareStudyId == nil) awareStudyId = @"";
    if(mqttServerName == nil) mqttServerName = @"";
    
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
    
    // Get maximum data per a HTTP/POST request
    if (maximumFileSize > 0 ) {
        maximumFileSize = maximumFileSize/1000;
    }
    NSString *maximumFileSizeDesc = [NSString stringWithFormat:@"%ld (KB)", maximumFileSize];
    
    /**
     * Study and Device Information
     */
    // title
    [_sensors addObject:[self getCelContent:@"Study" desc:@"" image:@"" key:@"TITLE_CELL_VIEW"]];
    // device_id
    [_sensors addObject:[self getCelContent:@"AWARE Device ID" desc:deviceId image:@"" key:@"STUDY_CELL_VIEW"]];
    // study_number
    [_sensors addObject:[self getCelContent:@"AWARE Study" desc:awareStudyId image:@"" key:@"STUDY_CELL_VIEW"]];
    // aware server information
    [_sensors addObject:[self getCelContent:@"AWARE Server" desc:mqttServerName image:@"" key:@"STUDY_CELL_VIEW"]];
//     Google Account Information if a user registered him/her google account.
    [_sensors addObject:[self getCelContent:@"Google Account" desc:accountInfo image:@"" key:@"STUDY_CELL_VIEW"]];
    
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
    [_sensors addObject:[self getCelContent:@"Google Fused Location" desc:@"Google's Locations API provider. This plugin provides the user's current location in an energy efficient way." image:@"ic_action_google_fused_location" key:SENSOR_GOOGLE_FUSED_LOCATION]];
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
    [_sensors addObject:[self getCelContent:@"Pedometer" desc:@"This plugin collects user's daily steps." image:@"ic_action_steps" key:SENSOR_PLUGIN_PEDOMETER]];
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
    // HealthKit
    [_sensors addObject:[self getCelContent:@"HealthKit" desc:@"This plugin collects stored data in HealthKit App on iOS" image:@"ic_action_health_kit" key:@"sensor_plugin_health_kit"]];

    // [_sensors addObject:[self getCelContent:@"Direction (iOS)" desc:@"Device's direction (0-360)" image:@"safari_copyrighted" key:SENSOR_DIRECTION]];
    //    [_sensors addObject:[self getCelContent:@"Rotation (iOS)" desc:@"Orientation of the device" image:@"ic_action_rotation" key:SENSOR_ROTATION]];
    

    
    /**
     * Setting
     */
    // Title
    [_sensors addObject:[self getCelContent:@"Settings" desc:@"" image:@"" key:@"TITLE_CELL_VIEW"]];
    // A Debug mode on/off
    [_sensors addObject:[self getCelContent:@"Debug" desc:debugState image:@"" key:@"STUDY_CELL_DEBUG"]];
    // A Sync interval
    [_sensors addObject:[self getCelContent:@"Sync Interval (min)" desc:syncInterval image:@"" key:@"STUDY_CELL_SYNC"]];
    // A Sync network condition
    [_sensors addObject:[self getCelContent:@"Auto sync with only Wi-Fi" desc:wifiOnly image:@"" key:@"STUDY_CELL_WIFI"]];
    // A Sync battery condition
    [_sensors addObject:[self getCelContent:@"Auto sync with only battery charging" desc:batteryChargingOnly image:@"" key:@"STUDY_CELL_BATTERY"]];
    // A maximum data size per one HTTP/POST
    [_sensors addObject:[self getCelContent:@"Maximum file size" desc:maximumFileSizeDesc image:@"" key:@"STUDY_CELL_MAX_FILE_SIZE"]];
    // A current version of AWARE iOS
    NSString* version = [NSString stringWithFormat:@"%@",[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    [_sensors addObject:[self getCelContent:@"Version" desc:version image:@"" key:@"STUDY_CELL_VIEW"]];
        // A manual data upload button
    [_sensors addObject:[self getCelContent:@"Manual Data Upload" desc:@"Please push this row for uploading sensor data!" image:@"" key:@"STUDY_CELL_MANULA_UPLOAD"]];
    [_sensors addObject:[self getCelContent:@"General App Settings" desc:@"Move to the Settings app" image:@"" key:@"STUDY_CELL_SETTINGS_APP"]];
    // Auto Study Update
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm"];
    NSString *formattedDateString = @"--:--";
    if (dailyUpdateTimer != nil) {
        if (dailyUpdateTimer.fireDate != nil) {
            formattedDateString = [dateFormatter stringFromDate:dailyUpdateTimer.fireDate];
        }
    }
    [_sensors addObject:[self getCelContent:@"Auto Study Update" desc:formattedDateString image:@"" key:@"STUDY_CELL_AUTO_STUDY_UPDATE"]];

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


/**
 When a study is refreshed (e.g., pushed refresh button, changed settings, 
 and/or done daily study update), this method is called before the -initList.
 */
- (IBAction)pushedStudyRefreshButton:(id)sender {
    // Refresh the study information
    [awareStudy refreshStudy];
    
    _refreshButton.enabled = NO;
    [self performSelector:@selector(initContentsOnTableView) withObject:0 afterDelay:5];
    [self performSelector:@selector(refreshButtonEnableYes) withObject:0 afterDelay:10];
}

- (void) refreshButtonEnableYes {
    _refreshButton.enabled = YES;
}

- (IBAction)pushedGoogleLogin:(id)sender {
    
}


-(BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item
{
    NSLog(@"Back button is pressed!");
    [self.navigationController popToRootViewControllerAnimated:YES];
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
    NSLog(@"%ld is selected!", indexPath.row);
    NSDictionary *item = (NSDictionary *)[_sensors objectAtIndex:indexPath.row];
    NSString *key = [item objectForKey:KEY_CEL_SENSOR_NAME];
    // Debug Model ON/OFF
    if ([key isEqualToString:@"STUDY_CELL_DEBUG"]) { //Debug
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Debug Statement" message:@"" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"ON", @"OFF", nil];
        alert.tag = 1;
        [alert show];
    // Set Sync Interval
    } else if ([key isEqualToString:@"STUDY_CELL_SYNC"]) { //Sync
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Sync Interval (min)" message:@"Please inpute a sync interval to the server." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Done",nil];
        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
        [[alert textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeNumberPad];
        [[alert textFieldAtIndex:0] becomeFirstResponder];
        [alert textFieldAtIndex:0].text = [NSString stringWithFormat:@"%d", (int)uploadInterval/60];
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
    // Google Calendar Journal Plugin
    }else if ([key isEqualToString:SENSOR_PLUGIN_GOOGLE_CAL_PUSH]) {
        GoogleCalPush *googlePush = [[GoogleCalPush alloc] init];
        [googlePush showTargetCalendarCondition];
    // Google Calendar Calendar Plugin
    }else if([key isEqualToString:SENSOR_PLUGIN_CAMPUS]){
        NSString* schedules = [sensorManager getLatestSensorData:SENSOR_PLUGIN_CAMPUS];
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
//            [self initContentsOnTableView];
            [self pushedStudyRefreshButton:alertView];
        } else if (buttonIndex == 2){ // no
            //reset clicked
            [userDefaults setBool:NO forKey:SETTING_DEBUG_STATE];
//            [self initContentsOnTableView];
            [self pushedStudyRefreshButton:alertView];
        } else {
            NSLog(@"Cancel");
        }
    }else if([title isEqualToString:@"Sync Interval (min)"]){
        if ( buttonIndex == [alertView cancelButtonIndex]){
            NSLog(@"Cancel");
            return;
        }
        NSString *interval = [alertView textFieldAtIndex:0].text;
        if ([interval isEqualToString:@""] || [interval isEqualToString:@"0"]) {
            return;
        }
        double syncInterval = [interval doubleValue] * 60.0f;
        [userDefaults setObject:[NSNumber numberWithDouble:syncInterval] forKey:SETTING_SYNC_INT];
        [self pushedStudyRefreshButton:alertView];
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
    }else if (alertView.tag == 9){ // Set Sync Setting
//        NSLog(@"%ld", buttonIndex);
        if (buttonIndex == 1){ //yes
            [userDefaults setBool:YES forKey:SETTING_SYNC_BATTERY_CHARGING_ONLY];
            [self initContentsOnTableView];
        } else if (buttonIndex == 2){ // no
            [userDefaults setBool:NO forKey:SETTING_SYNC_BATTERY_CHARGING_ONLY];
            [self initContentsOnTableView];
        } else {
            NSLog(@"Cancel");
        }
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
//        [self initContentsOnTableView];
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
        Labels * labelsSensor = [[Labels alloc] initWithSensorName:SENSOR_LABELS withAwareStudy:awareStudy];
        [labelsSensor saveLabel:label withKey:@"top" type:@"text" body:@"" triggerTime:[NSDate new] answeredTime:[NSDate new]];
        [labelsSensor syncAwareDB];
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


- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    @autoreleasepool {
//        NSLog(@"%ld",indexPath.row);
        static NSString *MyIdentifier = @"MyReuseIdentifier";
        
        NSDictionary *item = (NSDictionary *)[_sensors objectAtIndex:indexPath.row];
        
        /// Make a cell by _sensors (sensor list on ViewController.)
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
        
        //update latest sensor data
        NSString *sensorKey = [item objectForKey:KEY_CEL_SENSOR_NAME];
        NSString* latestSensorData = [sensorManager getLatestSensorData:sensorKey];
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


@end
