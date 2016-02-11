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

// Plugins
#import "GoogleCalPush.h"
#import "Pedometer.h"
#import "Debug.h"
#import "AWAREHealthKit.h"

@interface ViewController ()
@end

@implementation ViewController{
    /**  Keys for contetns of a table view raw */
    /// A key for a title of a raw
    NSString *KEY_CEL_TITLE;
    /// A key for a description of a raw
    NSString *KEY_CEL_DESC;
    /// A key for a image of a raw
    NSString *KEY_CEL_IMAGE;
    /// A key for a status of a raw
    NSString *KEY_CEL_STATE;
    /// A key for a sensor name of a raw
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
     * Every 2AM, AWARE iOS refresh the jointed study in the background.
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
    [runLoop addTimer:dailyUpdateTimer forMode:NSDefaultRunLoopMode];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    /// Set defualt settings
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if (![userDefaults boolForKey:@"aware_inited"]) {
        [userDefaults setBool:NO forKey:SETTING_DEBUG_STATE];
        [userDefaults setBool:YES forKey:SETTING_SYNC_WIFI_ONLY];
        [userDefaults setDouble:uploadInterval forKey:SETTING_SYNC_INT];
        [userDefaults setBool:YES forKey:@"aware_inited"];
        [userDefaults setBool:NO forKey:KEY_APP_TERMINATED];
        [userDefaults setInteger:0 forKey:KEY_MARK];
        [userDefaults setInteger:1000 * 100 forKey:KEY_MAX_DATA_SIZE]; // 100 KB
    }
    
    /**
     * Init a Debug Sensor for collecting a debug message.
     * A developer can store debug messages to an aware database
     * by using the -saveDebugEventWithText:type:label: method on the debugSensor.
     */
    debugSensor = [[Debug alloc] init];
    
    /**
     * Start a location sensor for background sensing.
     * On the iOS, we have to turn on the location sensor 
     * for using application in the background.
     */
    [self initLocationSensor];
    
    /// Init sensor manager for the list view
    _sensorManager = [[AWARESensorManager alloc] init];
    
    /// Set delegates for a navigation bar and table view
    if ([AWAREUtils getCurrentOSVersionAsFloat] >= 9.0) {
        [self.navigationController.navigationBar setDelegate:self];
    }
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    /**
     * The "-initList" method **initialize contetns of list view**, and **starts/stops sensors**.
     * WIP: I want to split a "list view initializer" and "sensor initializer".
     */
    [self initContentsOnTableView];
    [self initSensors];
    
    _refreshButton.enabled = NO;
    [self performSelector:@selector(refreshButtonEnableYes) withObject:0 afterDelay:8];
    
    /// Start an update timer for list view. This timer refreshed the list view every 0.1 sec.
    listUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self.tableView selector:@selector(reloadData) userInfo:nil repeats:YES];
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
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSLog(@" Hello ESM view !");
    if ([segue.identifier isEqualToString:@"esmView"]) {
        AWAREEsmViewController *esmView = [segue destinationViewController];    // <- 1
    }
}


/**
 * This method is an initializers for a location sensor.
 * On the iOS, we have to turn on the location sensor
 * for using application in the background.
 * And also, this sensing interval is the most low level.
 */
- (void) initLocationSensor {
    NSLog(@"start location sensing!");
    if ( nil == _homeLocationManager ) {
        _homeLocationManager = [[CLLocationManager alloc] init];
        _homeLocationManager.delegate = self;
        _homeLocationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
        _homeLocationManager.pausesLocationUpdatesAutomatically = NO;
        _homeLocationManager.activityType = CLActivityTypeOther;
        if ([AWAREUtils getCurrentOSVersionAsFloat] >= 9.0) {
             /// After iOS 9.0, we have to set "YES" for background sensing.
            _homeLocationManager.allowsBackgroundLocationUpdates = YES;
        }
        if ([_homeLocationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
            [_homeLocationManager requestAlwaysAuthorization];
        }
        // Set a movement threshold for new events.
        _homeLocationManager.distanceFilter = 300; // meters
        [_homeLocationManager startUpdatingLocation];
    }
}

/**
 * The method is called by location sensor when the device location is changed.
 */
- (void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    bool appTerminated = [userDefaults boolForKey:KEY_APP_TERMINATED];
    if (appTerminated) {
        NSString * message = @"AWARE iOS is rebooted!";
        [AWAREUtils sendLocalNotificationForMessage:message soundFlag:YES];
        [debugSensor saveDebugEventWithText:message type:DebugTypeInfo label:@""];
        [userDefaults setBool:NO forKey:KEY_APP_TERMINATED];
    }else{
//        [self sendLocalNotificationForMessage:@"" soundFlag:YES];
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
    _sensors = [[NSMutableArray alloc] init];
    
    // Get a study and device information from local default storage
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults synchronize];
    NSString *email = [userDefaults objectForKey:@"GOOGLE_EMAIL"];
    NSString *name = [userDefaults objectForKey:@"GOOGLE_NAME"];
    NSInteger maximumFileSize = [userDefaults integerForKey:KEY_MAX_DATA_SIZE];
    NSString *accountInfo = [NSString stringWithFormat:@"%@ (%@)", name, email];
    if(name == nil) accountInfo = @"";
    if(email == nil) email = @"";
    
    AWAREStudy *awareStudy = [[AWAREStudy alloc] init];
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
//    [_sensors addObject:[self getCelContent:@"MQTT Server" desc:mqttServerName image:@"" key:@"STUDY_CELL_VIEW"]];
    // Google Account Information if a user registered him/her google account.
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
    // Microsoft Band
    [_sensors addObject:[self getCelContent:@"Micrsoft Band" desc:@"Wearable sensor data (such as Heart Rate, UV, and Skin Temperature) from Microsoft Band." image:@"ic_action_msband" key:SENSOR_PLUGIN_MSBAND]];
    // Google Login
    [_sensors addObject:[self getCelContent:@"Google Login" desc:@"Multi-device management using Google Account." image:@"google_logo" key:SENSOR_PLUGIN_GOOGLE_LOGIN]];
    // Balanced Campus Calendar
    [_sensors addObject:[self getCelContent:@"Balanced Campus Calendar" desc:@"This plugin gathers calendar events from all Google Calendars from the phone." image:@"ic_action_google_cal_grab" key:SENSOR_PLUGIN_GOOGLE_CAL_PULL]];
    // Balanced Campus Journal
    [_sensors addObject:[self getCelContent:@"Balanced Campus Journal" desc:@"This plugin creates new events in the journal calendar and sends a reminder email to the user to update the journal." image:@"ic_action_google_cal_push" key:SENSOR_PLUGIN_GOOGLE_CAL_PUSH]];
    // Balanced Campus ESMs (ESM Scheduler)
    [_sensors addObject:[self getCelContent:@"Balanced Campus ESMs" desc:@"ESM Plugin" image:@"ic_action_campus" key:SENSOR_PLUGIN_CAMPUS]];
    // HealthKit
    [_sensors addObject:[self getCelContent:@"HealthKit" desc:@"This plugin collects stored data in HealthKit App on iOS" image:@"ic_action_health_kit" key:@"sensor_plugin_health_kit"]];

    
    /**
     * Setting
     */
    // Title
    [_sensors addObject:[self getCelContent:@"Settings" desc:@"" image:@"" key:@"TITLE_CELL_VIEW"]];
    // A Debug mode on/off
    [_sensors addObject:[self getCelContent:@"Debug" desc:debugState image:@"" key:@"STUDY_CELL_DEBUG"]];
    // A Sync interval
    [_sensors addObject:[self getCelContent:@"Sync Interval to AWARE Server (min)" desc:syncInterval image:@"" key:@"STUDY_CELL_SYNC"]];
    // A Sync network condition
    [_sensors addObject:[self getCelContent:@"Sync only wifi" desc:wifiOnly image:@"" key:@"STUDY_CELL_WIFI"]];
    // A maximum data size per one HTTP/POST
    [_sensors addObject:[self getCelContent:@"Maximum file size" desc:maximumFileSizeDesc image:@"" key:@"STUDY_CELL_MAX_FILE_SIZE"]];
    // A current version of AWARE iOS
    NSString* version = [NSString stringWithFormat:@"%@",[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    [_sensors addObject:[self getCelContent:@"Version" desc:version image:@"" key:@"STUDY_CELL_VIEW"]];
    // A manual data upload button
    [_sensors addObject:[self getCelContent:@"Manual Data Upload" desc:@"Please push this row for uploading sensor data!" image:@"" key:@"STUDY_CELL_MANULA_UPLOAD"]];
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
    if(_sensorManager != nil){
        bool exist = [_sensorManager isExist:key];
        if (exist) {
            [dic setObject:@"true" forKey:KEY_CEL_STATE];
        }
    }
    return dic;
}


- (void) initSensors {
    
    for (NSMutableDictionary * sensor in _sensors) {
        // Get sensors information and plugin information from NSUserDedaults class
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSArray *sensors = [userDefaults objectForKey:KEY_SENSORS];
        NSArray *plugins = [userDefaults objectForKey:KEY_PLUGINS];
        // [NOTE] If this sensor is "active", addNewSensorWithSensorName method return TRUE value.
        uploadInterval = [userDefaults doubleForKey:SETTING_SYNC_INT];
        NSString * key = [sensor objectForKey:KEY_CEL_SENSOR_NAME];
        bool state = [_sensorManager addNewSensorWithSensorName:key settings:sensors plugins:plugins uploadInterval:uploadInterval];
        if (state) {
            [sensor setObject:@"true" forKey:KEY_CEL_STATE];
        }
    }
    
    /**
     * [Additional hidden sensors]
     * You can add your own AWARESensor and AWAREPlugin to AWARESensorManager directly using following source code.
     * The "-addNewSensor" method is versy userful for testing and debuging a AWARESensor without registlating a study.
     */
    // Pedometer
    AWARESensor * steps = [[Pedometer alloc] initWithSensorName:SENSOR_PLUGIN_PEDOMETER];
    [steps startSensor:60*15 withSettings:nil];
    [_sensorManager addNewSensor:steps];
    
    // HealthKit
    // AWARESensor * healthKit = [[AWAREHealthKit alloc] initWithPluginName:@"sensor_aware_health_kit" deviceId:@""];
    // [healthKit startSensor:60 withSettings:nil];
    
    
    /**
     * Debug Sensor
     * NOTE: don't remove this sensor. This sensor collects and upload debug message to the server each 15 min.
     */
    AWARESensor * debug = [[Debug alloc] init];
    [debug startSensor:60*15 withSettings:nil];
    [_sensorManager addNewSensor:debug];
}


/**
 When a study is refreshed (e.g., pushed refresh button, changed settings, 
 and/or done daily study update), this method is called before the -initList.
 */
- (IBAction)pushedStudyRefreshButton:(id)sender {
    // Inactivate the refresh button on the navigation bar
    _refreshButton.enabled = NO;
    
    @autoreleasepool {
        NSLog(@"Atop and remove all sensors from AWARESensorManager.");
        [_sensorManager stopAllSensors];
    }
    
    // Refresh a study: Donwlod configurations and set it on the device
    AWAREStudy *awareStudy = [[AWAREStudy alloc] init];
    [awareStudy refreshStudy];
    
    // Init sensors
    // TODO: The study refresh and initList is not synced, then if the user calls lots of times during sort time, AWARE make a doublicate sensor and uploader.
    [self performSelector:@selector(initContentsOnTableView) withObject:0 afterDelay:2];
    [self performSelector:@selector(initSensors) withObject:0 afterDelay:3];
    
    // Refresh the table view after 4 second
    [self.tableView performSelector:@selector(reloadData) withObject:0 afterDelay:4];
    
    // Activate the refresh button on the navigation bar fater 8 second
    [self performSelector:@selector(refreshButtonEnableYes) withObject:0 afterDelay:8];
    
    if ([AWAREUtils isForeground]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"AWARE Study"
                                                        message:@"AWARE Study was refreshed!"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        // Save a debug message to a Debug Sensor.
        [debugSensor saveDebugEventWithText:@"[study] Refresh in the foreground" type:DebugTypeInfo label:@""];
    } else {
        [AWAREUtils sendLocalNotificationForMessage:@"AWARE Configuration was refreshed in the background!" soundFlag:NO];
        // Save a debug message to a Debug Sensor.
        [debugSensor saveDebugEventWithText:@"[study] Refresh in the background" type:DebugTypeInfo label:@""];
    }
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
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Sync Statement" message:@"Do you want to sync your data only WiFi enviroment?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"YES",@"NO",nil];
        alert.tag = 3;
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
        NSString* schedules = [_sensorManager getLatestSensorData:SENSOR_PLUGIN_CAMPUS];
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
        NSLog(@"%ld", buttonIndex);
        if (buttonIndex == 1){ //yes
            [userDefaults setBool:YES forKey:SETTING_DEBUG_STATE];
            [self initContentsOnTableView];
//            [self pushedStudyRefreshButton:alertView];
        } else if (buttonIndex == 2){ // no
            //reset clicked
            [userDefaults setBool:NO forKey:SETTING_DEBUG_STATE];
            [self initContentsOnTableView];
//            [self pushedStudyRefreshButton:alertView];
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
    }else if([title isEqualToString:@"Sync Statement"]){
        NSLog(@"%ld", buttonIndex);
        if (buttonIndex == 1){ //yes
            [userDefaults setBool:YES forKey:SETTING_SYNC_WIFI_ONLY];
//            [self pushedStudyRefreshButton:alertView];
            [self initContentsOnTableView];
        } else if (buttonIndex == 2){ // no
            //reset clicked
            [userDefaults setBool:NO forKey:SETTING_SYNC_WIFI_ONLY];
            [self initContentsOnTableView];
//            [self pushedStudyRefreshButton:alertView];
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
//        [self pushedStudyRefreshButton:alertView];
        [self initContentsOnTableView];
    }else if(alertView.tag == 8){ //manual data upload
        if (buttonIndex == [alertView cancelButtonIndex]) {
            
        }else if (buttonIndex == 1){
            [_sensorManager syncAllSensorsWithDB];
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


- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    @autoreleasepool {
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
        NSString* latestSensorData = [_sensorManager getLatestSensorData:sensorKey];
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
