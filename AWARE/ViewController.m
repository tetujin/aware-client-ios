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
#import "SettingTableViewController.h"
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
#import "NXOAuth2.h"
// #import "WebESM.h"

// Plugins
#import "GoogleCalPush.h"
#import "GoogleLogin.h"
#import "Pedometer.h"
#import "Orientation.h"
#import "Debug.h"
#import "AWAREHealthKit.h"
#import "BalacnedCampusESMScheduler.h"
#import "Memory.h"
#import "Labels.h"
#import "BLEHeartRate.h"
#import "AmbientLight.h"
// #import "ESM.h"
#import "IOSESM.h"
#import "Accelerometer.h"
#import "PushNotification.h"
#import "Contacts.h"

// Library
#import <SVProgressHUD.h>

#import <QuartzCore/QuartzCore.h>

@interface ViewController ()
@end

@implementation ViewController{
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
    
    // WebESM *webESM;
    IOSESM * iOSESM;
    
    CLLocationManager * locationManager;
    
    UIView *rootView;
    
    NSString * selectedRow;
    UIView * overlayView;
    UILabel * deviceIdLabel;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    rootView = self.navigationController.view;
    
    webViewURL = [NSURL URLWithString:@"http://www.awareframework.com"];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    // uploadInterval = [userDefaults doubleForKey:SETTING_SYNC_INT];
    uploadInterval = [awareStudy getUploadIntervalAsSecond];
    
    
    // [self showIntro];
    if (![userDefaults boolForKey:@"showed_introduction"]) {
        [self showIntro];
    }
    [userDefaults setBool:YES forKey:@"showed_introduction"];
    
    
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
    
    // [awareStudy setStudyInformationWithURL:@"https://AWARE_SERVER_URL/index.php/webservice/index/STUDY_ID/PASS"];
    
    /**
     * Init a Debug Sensor for collecting a debug message.
     * A developer can store debug messages to an aware database
     * by using the -saveDebugEventWithText:type:label: method on the debugSensor.
     */
    debugSensor = [[Debug alloc] initWithAwareStudy:awareStudy dbType:AwareDBTypeTextFile];
    
    [self initContentsOnOverlayVie];
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

    // webESM = [[WebESM alloc] initWithAwareStudy:awareStudy dbType:AwareDBTypeCoreData];
    iOSESM = [[IOSESM alloc] initWithAwareStudy:awareStudy dbType:AwareDBTypeCoreData];
    
    // For test
    // [sensorManager performSelector:@selector(testSensing) withObject:nil afterDelay:10];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moveToGoogleLogin:)
                                                 name:ACTION_AWARE_GOOGLE_LOGIN_REQUEST
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moveToContacts:)
                                                 name:ACTION_AWARE_CONTACT_REQUEST
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(viewDidAppear:)
                                                 name:ACTION_AWARE_SETTING_UI_UPDATE_REQUEST
                                               object:nil];
}


/**
 * This method is called when application did becase active.
 * And also, this method check ESM existance using ESMStorageHelper. 
 * If an ESM is existed, AWARE iOS move to the ESM answer page.
 */
- (void)appDidBecomeActive:(NSNotification *)notification {
    
    NSLog(@"did become active notification");
    
    NSArray * esms = [iOSESM getValidESMSchedulesWithDatetime:[NSDate new]];
    if(esms != nil && esms.count != 0 && ![IOSESM isAppearedThisSection]){
        [IOSESM setAppearedState:YES];
        [self performSegueWithIdentifier:@"iOSEsmScrollView" sender:self];
    }
    
    AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
    AWARECore * core = delegate.sharedAWARECore;
    [core checkComplianceWithViewController:self];
    
    /*
     NSArray * esms = [iOSESM getValidESMSchedulesWithDatetime:[NSDate new]];
     if(esms != nil && esms.count != 0 && ![IOSESM isAppearedThisSection]){
     [IOSESM setAppearedState:YES];
     [self performSegueWithIdentifier:@"iOSEsmView" sender:self];
     }
     
     AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
     AWARECore * core = delegate.sharedAWARECore;
     [core checkComplianceWithViewController:self];
     */
}

- (void)viewDidAppear:(BOOL)animated{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
    NSLog(@"%ld",[awareStudy getUIMode]);
        if([awareStudy getUIMode] == AwareUIModeHideAll){
            [overlayView setHidden:NO];
            [self.tableView setScrollEnabled:NO];
        }else{
            [overlayView setHidden:YES];
            [self.tableView setScrollEnabled:YES];
        }
    });
    
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSLog(@" Hello ESM view !");
    if ([segue.identifier isEqualToString:@"esmView"]) {
//        AWAREEsmViewController *esmView = [segue destinationViewController];    // <- 1
    } else if ([segue.identifier isEqualToString:@"webView"]) {
        WebViewController *webViewController = [segue destinationViewController];
        webViewController.url = webViewURL;
    } else if([segue.identifier isEqualToString:@"settingView"]){
        SettingTableViewController * settingViewController = [segue destinationViewController];
        settingViewController.selectedRowKey = selectedRow;
    }
}


- (void)didReceiveMemoryWarning {
    [debugSensor saveDebugEventWithText:@"didReceiveMemoryWarning" type:DebugTypeWarn label:@""];
    
    AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
    [delegate.managedObjectContext reset];
    
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) initContentsOnOverlayVie{
    overlayView = [[UIView alloc] initWithFrame:self.view.frame];
    [overlayView setBackgroundColor:[UIColor whiteColor]];
    [self.view addSubview:overlayView];
    
    // self.view.frame
    CGRect rect = CGRectMake(0, 100, self.view.frame.size.width, 200);
    deviceIdLabel = [[UILabel alloc] initWithFrame:rect];
    // deviceIdLabel.backgroundColor = [UIColor blueColor];
    deviceIdLabel.textAlignment = NSTextAlignmentCenter;
    deviceIdLabel.numberOfLines = 9;
    deviceIdLabel.text = [NSString stringWithFormat:@"Study ID:\n%@\n\nDevice ID:\n%@\n\nDevice Name:\n%@",
                          [awareStudy getStudyId],[awareStudy getDeviceId],[awareStudy getDeviceName]];
    [overlayView addSubview:deviceIdLabel];
    
}

/**
 When a study is refreshed (e.g., pushed refresh button, changed settings,
 and/or done daily study update), this method is called.
 */
- (void) initContentsOnTableView {
    // init sensor list
    [_sensors removeAllObjects];
    
    // Get a study and device information from local default storage
    // NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    // [userDefaults synchronize];
    
    NSString *email = [GoogleLogin getGoogleAccountEmail]; // [userDefaults objectForKey:@"GOOGLE_EMAIL"];
    NSString *name  = [GoogleLogin getGoogleAccountName];  // [userDefaults objectForKey:@"GOOGLE_NAME"];
    NSString *accountInfo = [NSString stringWithFormat:@"%@ (%@)", name, email];
    if(name == nil) accountInfo = @"";
    if(email == nil) email = @"";
    
    
    //////////////////////////////////////////////////
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

  /**
     * Study and Device Information
     */
    [_sensors addObject:[self getCelContent:@"AWARE Study" desc:@"" image:@"" key:@"TITLE_CELL_VIEW"]];
    [_sensors addObject:[self getCelContent:@"Study URL" desc:studyURL image:@"" key:@"STUDY_CELL_VIEW_STUDY_URL"]];
    [_sensors addObject:[self getCelContent:@"Study Number" desc:awareStudyId image:@"" key:@"STUDY_CELL_VIEW"]];
    [_sensors addObject:[self getCelContent:@"Server" desc:mqttServerName image:@"" key:@"STUDY_CELL_VIEW"]];
    if([awareStudy getUIMode] == AwareUIModeHideSettings){
        
    }else{
        [_sensors addObject:[self getCelContent:@"Advanced Settings" desc:@"" image:@"" key:@"ADVANCED_SETTINGS"]];
    }
    [_sensors addObject:[self getCelContent:@"Device ID" desc:deviceId image:@"" key:@"STUDY_CELL_VIEW"]];
    [_sensors addObject:[self getCelContent:@"Device Name" desc:awareDeviceName image:@"" key:KEY_AWARE_DEVICE_NAME]];
    [_sensors addObject:[self getCelContent:@"Google Account" desc:accountInfo image:@"" key:SENSOR_PLUGIN_GOOGLE_LOGIN]];

    //[_sensors addObject:[self getCelContent:@"Device" desc:@"" image:@"" key:@"TITLE_CELL_VIEW"]];
    
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
    [_sensors addObject:[self getCelContent:@"Communication" desc:@"The Communication sensor logs communication events such as calls and messages, performed by or received by the user." image:@"ic_action_communication" key:SENSOR_CALLS]];
    // [_sensors addObject:[self getCelContent:@"Label" desc:@"Save event labels to the AWARE server" image:@"ic_action_label" key:SENSOR_LABELS]];

    // [_sensors addObject:[self getCelContent:@"AmbientNoise" desc:@"AmbientNoise sensor" image:@"" key:SENSOR_AMBIENT_NOISE]];
    // [_sensors addObject:[self getCelContent:@"Light" desc:@"Ambient Light (lux)" image:@"ic_action_light"]];
    // [_sensors addObject:[self getCelContent:@"Proximity" desc:@"" image:@"ic_action_proximity"]];
    // [_sensors addObject:[self getCelContent:@"Telephony" desc:@"Mobile operator and specifications, cell tower and neighbor scanning" image:@"ic_action_telephony"
    
    
    /**
     * Plugins
     */
    [_sensors addObject:[self getCelContent:@"Plugins" desc:@"" image:@"" key:@"TITLE_CELL_VIEW"]];
    // iOS ESM
    [_sensors addObject:[self getCelContent:@"iOS ESM" desc:@"ESM plugin for iOS" image:@"ic_action_web_esm" key:SENSOR_PLUGIN_IOS_ESM]];
    // Google Fused Location
    [_sensors addObject:[self getCelContent:@"Fused Location" desc:@"Locations API provider. This plugin provides the user's current location in an energy efficient way." image:@"ic_action_google_fused_location" key:SENSOR_GOOGLE_FUSED_LOCATION]];
    // Ambient Noise
    [_sensors addObject:[self getCelContent:@"Ambient Noise" desc:@"Anbient noise sensing by using a microphone on a smartphone." image:@"ic_action_ambient_noise" key:SENSOR_AMBIENT_NOISE]];
    // Activity Recognition
    [_sensors addObject:[self getCelContent:@"Activity Recognition" desc:@"iOS Activity Recognition" image:@"ic_action_running" key:SENSOR_IOS_ACTIVITY_RECOGNITION]];
    // Device Usage
    [_sensors addObject:[self getCelContent:@"Device Usage" desc:@"This plugin measures how much you use your device" image:@"ic_action_device_usage" key:SENSOR_PLUGIN_DEVICE_USAGE]];
    // Open Weather
    [_sensors addObject:[self getCelContent:@"Open Weather" desc:@"Weather information by OpenWeatherMap API." image:@"ic_action_openweather" key:SENSOR_PLUGIN_OPEN_WEATHER]];
    // Google Login
    [_sensors addObject:[self getCelContent:@"Google Login" desc:@"Multi-device management using Google Account." image:@"google_logo" key:SENSOR_PLUGIN_GOOGLE_LOGIN]];
     // Pedometer
    [_sensors addObject:[self getCelContent:@"Pedometer" desc:@"This plugin collects user's daily steps." image:@"ic_action_steps" key:SENSOR_PLUGIN_PEDOMETER]];
    // NTPTime
    [_sensors addObject:[self getCelContent:@"NTPTime" desc:@"Measure device's clock drift from an NTP server." image:@"ic_action_ntptime" key:SENSOR_PLUGIN_NTPTIME]];
    [_sensors addObject:[self getCelContent:@"BLE Heart Rate" desc:@"Collect heart rate data from an external heart rate sensor via BLE." image:@"ic_action_heartrate" key:SENSOR_PLUGIN_BLE_HR]];
    // [_sensors addObject:[self getCelContent:@"HealthKit" desc:@"This plugin collects stored data in HealthKit App on iOS" image:@"ic_action_health_kit" key:SENSOR_HEALTH_KIT]];
     // Microsoft Band
    [_sensors addObject:[self getCelContent:@"Microsoft Band" desc:@"Wearable sensor data (such as Heart Rate, UV, and Skin Temperature) from Microsoft Band." image:@"ic_action_msband" key:SENSOR_PLUGIN_MSBAND]];
        // Fitbit
    [_sensors addObject:[self getCelContent:@"Fitbit" desc:@"Fitbit Plugin" image:@"ic_action_fitbit" key:SENSOR_PLUGIN_FITBIT]];
    [_sensors addObject:[self getCelContent:@"Contacts" desc:@"This plugin get your contacts" image:@"ic_action_contacts" key:SENSOR_PLUGIN_CONTACTS]];
    
    // Balanced Campus Calendar
    [_sensors addObject:[self getCelContent:@"Balanced Campus Calendar" desc:@"This plugin gathers calendar events from all Google Calendars from the phone." image:@"ic_action_google_cal_grab" key:@"balancedcampuscalendar"]];
    // Balanced Campus Journal
    [_sensors addObject:[self getCelContent:@"Balanced Campus Journal" desc:@"This plugin creates new events in the journal calendar and sends a reminder email to the user to update the journal." image:@"ic_action_google_cal_push" key:SENSOR_PLUGIN_GOOGLE_CAL_PUSH]];
    // Balanced Campus ESMs (ESM Scheduler)
    [_sensors addObject:[self getCelContent:@"Balanced Campus ESMs" desc:@"ESM Plugin" image:@"ic_action_campus" key:SENSOR_PLUGIN_CAMPUS]];

    //  [_sensors addObject:[self getCelContent:@"Direction (iOS)" desc:@"Device's direction (0-360)" image:@"safari_copyrighted" key:SENSOR_DIRECTION]];
    //  [_sensors addObject:[self getCelContent:@"Rotation (iOS)" desc:@"Orientation of the device" image:@"ic_action_rotation" key:SENSOR_ROTATION]];

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
//    ESMStorageHelper * helper = [[ESMStorageHelper alloc] init];
//    NSArray * storedEsms = [helper getEsmTexts];
//    if(storedEsms != nil){
//        if (storedEsms.count > 0 ){
//            [IOSESM setAppearedState:YES];
//            [self performSegueWithIdentifier:@"esmView" sender:self];
//        }
//    }
    
    /*
    NSArray * esms = [iOSESM getValidESMSchedulesWithDatetime:[NSDate new]];
    if(esms != nil && esms.count != 0 ){
        [IOSESM setAppearedState:YES];
        [self performSegueWithIdentifier:@"iOSEsmView" sender:self];
    }
     */
    
    NSArray * esms = [iOSESM getValidESMSchedulesWithDatetime:[NSDate new]];
    if(esms != nil && esms.count != 0 ){
        [IOSESM setAppearedState:YES];
        [self performSegueWithIdentifier:@"iOSEsmScrollView" sender:self];
    }
    
}

- (IBAction)pushedUploadButton:(id)sender {
    [sensorManager syncAllSensorsWithDBInForeground];
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
    [self performSelector:@selector(viewDidAppear:) withObject:0 afterDelay:10];
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
    selectedRow = key;
    // Debug Model ON/OFF
    if([key isEqualToString:@"ADVANCED_SETTINGS"]){
        [self performSegueWithIdentifier:@"AppSettingView" sender:self];
    }else if([key isEqualToString:SENSOR_ESMS]){
        // [TODO] For testing ESM Module...
        [self performSegueWithIdentifier:@"esmView" sender:self];
    }else if([key isEqualToString:SENSOR_PLUGIN_GOOGLE_LOGIN]){
        [self performSegueWithIdentifier:@"googleLogin" sender:self];
    }else if ([key isEqualToString:SENSOR_PLUGIN_FITBIT]) {
        [self performSegueWithIdentifier:@"fitbitView" sender:self];
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
    }else if([key isEqualToString:SENSOR_LABELS]){
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Event Label" message:@"Please edit current your condition!" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Done",nil];
        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
        alert.tag = 11;
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
    } else if ([key isEqualToString:SENSOR_PLUGIN_CONTACTS]){
        [self performSegueWithIdentifier:@"contacts" sender:self];
    } else {
        [self performSegueWithIdentifier:@"settingView" sender:self];
    }
}


/**
 * When a user select a button on the UIAlertView, this method is called with selected buttonIndex.
 */
- (void)alertView:(UIAlertView *)alertView
clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(alertView.tag == 10){
        if (buttonIndex == 1){
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
            //[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"prefs://"]];
        }
    ///////////////////// Label  ////////////////////////////////
    }else if(alertView.tag == 11){
        if ( buttonIndex == [alertView cancelButtonIndex]){
            NSLog(@"Cancel");
            return;
        }
        NSString *label = [alertView textFieldAtIndex:0].text;
        Labels * labelsSensor = [[Labels alloc] initWithAwareStudy:awareStudy dbType:AwareDBTypeTextFile];
        [labelsSensor saveLabel:label withKey:@"top" type:@"text" body:@"" triggerTime:[NSDate new] answeredTime:[NSDate new]];
        [labelsSensor syncAwareDB];
    ///////////////  Device Name ///////////////
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
    //////////////////// Study URL /////////////////
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
    NSString * cellName = [item objectForKey:KEY_CEL_SENSOR_NAME];

    if([cellName isEqualToString:@"STUDY_CELL_VIEW_STUDY_URL"] ||
       [cellName isEqualToString:@"STUDY_CELL_VIEW"] ||
       [cellName isEqualToString: @"STUDY_CELL_VIEW"] ||
       [cellName isEqualToString:@"ADVANCED_SETTINGS"] ||
       [cellName isEqualToString:KEY_AWARE_DEVICE_NAME] ||
       [cellName isEqualToString:@"STUDY_CELL_VIEW"] ||
       [cellName isEqualToString:SENSOR_PLUGIN_GOOGLE_LOGIN]){
        return 60;
    }else if ([cellName isEqualToString:@"TITLE_CELL_VIEW"]) {
        return 40;
    }else if ([cellName isEqualToString:@"STUDY_CELL_VIEW"]){
        return 70;
    }else{
        return 70;//[tableView rowHeight];
    }
}



- (void)updateVisibleCells {
    for (UITableViewCell *cell in [self.tableView visibleCells]){
        [self updateCell:cell atIndexPath:[self.tableView indexPathForCell:cell]];
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
        cell.detailTextLabel.numberOfLines = 3;
        cell.detailTextLabel.textColor = [UIColor darkGrayColor];
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

- (void) moveToGoogleLogin:(id)sender{
    if([AWAREUtils isForeground]){
        [self performSegueWithIdentifier:@"googleLogin" sender:self];
    }
}

- (void) moveToContacts:(id)sender{
    if([AWAREUtils isForeground]){
        [self performSegueWithIdentifier:@"contacts" sender:self];
    }
}

///////////////////////////////////////////////
///////////////////////////////////////////////

- (void) showIntro {
    // basic
    EAIntroPage *page1 = [EAIntroPage page];
    page1.title = @"About AWARE";
    page1.desc = @"AWARE Client is a sensing framework dedicated to an instrument, infer, log and share mobile context information, for smartphone users and researchers. AWARE captures hardware-, software-, and human-based data.\n\n For instance, ";
    page1.titlePositionY = 350;
    page1.descPositionY = 300;
    page1.titleColor = [UIColor darkGrayColor];
    page1.descColor = [UIColor darkGrayColor];
    //page1.bgColor = [UIColor whiteColor];
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
    // page2.bgColor = [UIColor whiteColor];
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
    //page3.bgColor = [UIColor whiteColor];
    page3.titleIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"scientist"]];
    [page3.titleIconView setBounds:CGRectMake(0,0,200,200)];
    
    EAIntroPage *page4 = [EAIntroPage page];
    page4.title = @"How to Use AWARE Client";
    page4.desc = @"1.Set a study on AWARE Dashboard and make a QRcode for the study\n2.Read the QRcode by AWARE client's QRcode reader\n3. Please permit to access required APIs if the study required it.\n4.AWARE client start sensing and uploading your contexts in the background\n5.You can quit the study by 'Quit Study' button";
    page4.titlePositionY = 350;
    page4.descPositionY = 300;
    page4.titleColor = [UIColor darkGrayColor];
    page4.descColor = [UIColor darkGrayColor];
    //page4.bgColor = [UIColor whiteColor];
    page4.titleIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"aware_qrcode"]];
    [page4.titleIconView setBounds:CGRectMake(0,0,200,200)];
    
    // EAIntroPage *page5 = [EAIntroPage pageWithCustomViewFromNibNamed:@"IntroPage5"];
    
    EAIntroPage *page6 = [EAIntroPage page];
    page6.titleColor = [UIColor darkGrayColor];
    page6.title = @"Welcome to AWARE Framework!!";
    page6.titleFont = [UIFont fontWithName:@"Georgia-BoldItalic" size:30];
    page6.titlePositionY = 500;
    page6.descColor = [UIColor darkGrayColor];
    page6.desc = @"You can get more detail information about AWARE Framework from the following URL.\nhttp://www.awareframework.com/";
    page6.descPositionY = 400;
    // page5.bgColor = [UIColor whiteColor];
    
    //NSArray * pages = [[NSArray alloc] initWithObjects:page1,page2,page3,page4,page5,page6,nil];
    NSMutableArray * pages = [[NSMutableArray alloc] initWithObjects:page1,page2,page3,page4,page6,nil];
    
    intro = [[EAIntroView alloc] initWithFrame:rootView.bounds andPages:pages];
    [intro setDelegate:self];
    intro.swipeToExit = NO;
    intro.showSkipButtonOnlyOnLastPage = YES;
    // intro.scrollingEnabled = NO;
    
    intro.backgroundColor = [UIColor whiteColor];
    intro.pageControl.pageIndicatorTintColor = [UIColor lightGrayColor];
    intro.pageControl.currentPageIndicatorTintColor = [UIColor darkGrayColor];
    [intro.skipButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [intro.skipButton setTitle:@"Let's Start!" forState:UIControlStateNormal];
    
    [intro showInView:rootView animateDuration:0.3];
    
    //page2.bgImage = [UIImage imageNamed:@"bg2"];
//    UIButton *nextButton = (UIButton *)[page5.pageView viewWithTag:1];
//    nextButton.hidden = YES;
//    if(nextButton) {
//        [nextButton addTarget:self action:@selector(pushedNextButton:) forControlEvents:UIControlEventTouchDown];
//    }
//    
//    UIButton *locationButton = (UIButton *)[page5.pageView viewWithTag:2];
//    if(locationButton){
//        [locationButton addTarget:self action:@selector(pushedLocationButton:) forControlEvents:UIControlEventTouchDown];
//    }
//    
//    UIButton *activityButton = (UIButton *)[page5.pageView viewWithTag:3];
//    if(activityButton){
//        [activityButton addTarget:self action:@selector(pushedActivityButton:) forControlEvents:UIControlEventTouchDown];
//    }
//    
//    UIButton *notificationButton = (UIButton *)[page5.pageView viewWithTag:4];
//    if(notificationButton){
//        [notificationButton addTarget:self action:@selector(pushedNotificationButton:) forControlEvents:UIControlEventTouchDown];
//    }
    
}

- (IBAction)pushedNextButton:(id)sender {
//    UIButton * nextButton = (UIButton *) sender;
//    NSLog(@"%d", [nextButton isSelected]);
//    if (nextButton.selected) {
//        nextButton.selected = NO;
//    }else{
//        [intro setCurrentPageIndex:intro.currentPageIndex+1];
//        nextButton.selected = YES;
//    }
//    UISwitch *switchControl = (UISwitch *) sender;
//    NSLog(@"%@", switchControl.on ? @"On" : @"Off");
//    
//    // limit scrolling on one, currently visible page (can't go previous or next page)
//    //[_intro setScrollingEnabled:switchControl.on];
//    
//    if(!switchControl.on) {
//        // scroll no further selected page (can go previous pages, but not next)
//        // _intro.limitPageIndex = _intro.visiblePageIndex;
//    } else {
//        // [_intro setScrollingEnabled:YES];
//    }
}

- (IBAction)pushedLocationButton:(id)sender {
    UIButton * button = (UIButton *) sender;
    
    if (button.selected) {
        button.selected = NO;
        [button setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
    }else{
        [button setBackgroundColor:self.view.tintColor];
        button.selected = YES;
    }
}

- (IBAction)pushedActivityButton:(id)sender {
    UIButton * button = (UIButton *) sender;
    if (button.selected) {
        [button setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
        button.selected = NO;
    }else{
        [button setBackgroundColor:self.view.tintColor];
        button.selected = YES;
    }
}

- (IBAction)pushedNotificationButton:(id)sender {
    UIButton * button = (UIButton *) sender;
    if (button.selected) {
        [button setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
        button.selected = NO;
    }else{
        [button setBackgroundColor:self.view.tintColor];
        button.selected = YES;
    }
}



/////////////////////////////////////////////////////////////////////////////////

- (void)intro:(EAIntroView *)introView pageAppeared:(EAIntroPage *)page withIndex:(NSUInteger)pageIndex{
    
}

- (void)intro:(EAIntroView *)introView pageStartScrolling:(EAIntroPage *)page withIndex:(NSUInteger)pageIndex{
    
}

- (void)intro:(EAIntroView *)introView pageEndScrolling:(EAIntroPage *)page withIndex:(NSUInteger)pageIndex{
    
}

- (void)introDidFinish:(EAIntroView *)introView wasSkipped:(BOOL)wasSkipped{
    
    AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
    
    if ([locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        [locationManager requestAlwaysAuthorization];
        AWARECore * core = delegate.sharedAWARECore;
        [core activate];
    }
    
    [delegate setNotification:[UIApplication sharedApplication]];
    
}

@end
