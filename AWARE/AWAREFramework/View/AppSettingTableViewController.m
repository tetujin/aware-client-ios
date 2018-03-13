//
//  AppSettingTableViewController.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 2017/08/20.
//  Copyright © 2017 Yuuki NISHIYAMA. All rights reserved.
//

#import "AppSettingTableViewController.h"

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
#import "SVProgressHUD.h"

#import <QuartzCore/QuartzCore.h>

@interface AppSettingTableViewController ()

@end

@implementation AppSettingTableViewController{
    /** Study Settings */
    /// A deault intrval for uploading sensor data
    double uploadInterval;
    
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
    
    AWARECore * core;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    rootView = self.navigationController.view;
    
    webViewURL = [NSURL URLWithString:@"http://www.awareframework.com"];
    
    //NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    //uploadInterval = [awareStudy getUploadIntervalAsSecond];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    /// Init sensor manager for the list view
    AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
    core = delegate.sharedAWARECore;
    sensorManager =     core.sharedSensorManager;
    dailyUpdateTimer =  core.dailyUpdateTimer;
    awareStudy =        core.sharedAwareStudy;
    locationManager =   core.sharedLocationManager;
    
    _settings = [[NSMutableArray alloc] init];
    
    //dispatch_async(dispatch_get_main_queue(), ^{
    [self initContentsOnTableView];
    //});
}


- (void)appDidBecomeActive:(NSNotification *)notification {

}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


- (void) initContentsOnTableView {
    // init sensor list
    [_settings removeAllObjects];
    
    NSString *email = [GoogleLogin getGoogleAccountEmail]; // [userDefaults objectForKey:@"GOOGLE_EMAIL"];
    NSString *name  = [GoogleLogin getGoogleAccountName];  // [userDefaults objectForKey:@"GOOGLE_NAME"];
    NSString *accountInfo = [NSString stringWithFormat:@"%@ (%@)", name, email];
    if(name == nil) accountInfo = @"";
    if(email == nil) email = @"";
    
    //[userDefaults integerForKey:KEY_MAX_DATA_SIZE];
    NSInteger maximumFileSize = [awareStudy getMaximumByteSizeForDataUpload];
    
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
    
    //////////// Debug State ///////////////
    NSString* debugState = @"OFF";
    // if ([userDefaults boolForKey:SETTING_DEBUG_STATE]) {
    if ([awareStudy getDebugState]) {
        debugState = @"ON";
    }else{
        debugState = @"OFF";
    }
    
    ///////////   DB Type   ////////////////////
    NSString * dbTypeStr = @"Light Weight";
    if([awareStudy getDBType] == AwareDBTypeTextFile){
        dbTypeStr = @"Light Weight (Text File)";
    }else if([awareStudy getDBType] == AwareDBTypeCoreData){
        dbTypeStr = @"SQLite";
    }else{
        dbTypeStr = @"Unknown";
    }
    
    ///////////   CSV Export   //////////////////////
    NSString * csvExportState = @"YES";
    if([awareStudy getCSVExport]){
        csvExportState = @"YES";
    }else {
        csvExportState = @"NO";
    }
    
    /////////////  Upload Interval (min)  ///////////////
    // NSString *syncInterval = [NSString stringWithFormat:@"%d",(int)[userDefaults doubleForKey:SETTING_SYNC_INT]/60];
    NSString *syncInterval = [NSString stringWithFormat:@"%d",[awareStudy getUploadIntervalAsSecond]/60];
    
    // if ([userDefaults boolForKey:SETTING_SYNC_WIFI_ONLY]) {
    ////////// Upload State (WiFi)
    NSString *wifiOnly = @"YES";
    if ([awareStudy getDataUploadStateInWifi]) {
        wifiOnly = @"YES";
    }else{
        wifiOnly = @"NO";
    }
    
    ////////// Upload State(Battery) ///////////
    NSString * batteryChargingOnly = @"YES";
    // if ([userDefaults boolForKey:SETTING_SYNC_BATTERY_CHARGING_ONLY]) {
    if([awareStudy getDataUploadStateWithOnlyBatterChargning]){
        batteryChargingOnly = @"YES";
    }else{
        batteryChargingOnly = @"NO";
    }
    
    ///////////// Data Cleaning Frequency ////////////
    // cleanOldDataType cleanInterval = [userDefaults integerForKey:SETTING_FREQUENCY_CLEAN_OLD_DATA];
    cleanOldDataType cleanInterval = [awareStudy getCleanOldDataType];
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

    BOOL autoSyncState = [awareStudy getAutoSyncState];
    
    ///////////////////////////////////////////////
    
    [_settings addObject:[self getCelContent:@"Settings" desc:@"" image:@"" key:@"TITLE_CELL_VIEW" state:NO]];
    // debug state
    if ([debugState isEqualToString:@"ON"]) {
        [_settings addObject:[self getCelContent:@"Debug mode" desc:debugState image:@"setting_bug" key:@"STUDY_CELL_DEBUG" state:YES]];
    }else{
        [_settings addObject:[self getCelContent:@"Debug mode" desc:debugState image:@"setting_bug" key:@"STUDY_CELL_DEBUG" state:NO]];
    }
    // Database Type
    [_settings addObject:[self getCelContent:@"DB Type" desc:dbTypeStr image:@"setting_db" key:SETTING_DB_TYPE state:YES]];
    // Export CSV
    if ([csvExportState isEqualToString:@"YES"]) {
        [_settings addObject:[self getCelContent:@"CSV export" desc:csvExportState image:@"setting_csv" key:SETTING_CSV_EXPORT_STATE state:YES]];
    }else{
        [_settings addObject:[self getCelContent:@"CSV export" desc:csvExportState image:@"setting_csv" key:SETTING_CSV_EXPORT_STATE state:NO]];
    }
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm"];
    NSString *formattedDateString = @"--:--";
    if (dailyUpdateTimer != nil) {
        if (dailyUpdateTimer.fireDate != nil) {
            formattedDateString = [dateFormatter stringFromDate:dailyUpdateTimer.fireDate];
        }
    }
    [_settings addObject:[self getCelContent:@"Daily study update (time)" desc:formattedDateString image:@"setting_sync" key:@"STUDY_CELL_AUTO_STUDY_UPDATE" state:YES]];
    // Auto Sync
    [_settings addObject:[self getCelContent:@"Sync interval (min)" desc:syncInterval image:@"aware_upload_icon" key:@"STUDY_CELL_SYNC" state:YES]];
    // sync network condition
    if ([wifiOnly isEqualToString:@"YES"]) {
        [_settings addObject:[self getCelContent:@"Wi-Fi only" desc:wifiOnly image:@"setting_wifi" key:@"STUDY_CELL_WIFI" state:YES]];
    }else{
        [_settings addObject:[self getCelContent:@"Wi-Fi only" desc:wifiOnly image:@"setting_wifi" key:@"STUDY_CELL_WIFI" state:NO]];
    }
    // sync battery condition
    if([batteryChargingOnly isEqualToString:@"YES"]){
        [_settings addObject:[self getCelContent:@"Charging only" desc:batteryChargingOnly image:@"setting_battery" key:@"STUDY_CELL_BATTERY" state:YES]];
    }else{
        [_settings addObject:[self getCelContent:@"Charging only" desc:batteryChargingOnly image:@"setting_battery" key:@"STUDY_CELL_BATTERY" state:NO]];
    }
    // frequency of clean old data
    [_settings addObject:[self getCelContent:@"Frequency of clean old data" desc:cleanIntervalStr image:@"setting_db_clean" key:@"STUDY_CELL_CLEAN_OLD_DATA" state:YES]];
    // [userDefaults setInteger:10000 forKey:KEY_MAX_FETCH_SIZE_NORMAL_SENSOR];
    [_settings addObject:[self getCelContent:@"Fetch records per POST (for SQLite)" desc:fetchSizeStr image:@"setting_db" key:@"STUDY_CELL_MAX_FETCH_SIZE_NORMAL_SENSOR" state:YES]];
    // maximum data size per one HTTP/POST
    [_settings addObject:[self getCelContent:@"Fetch size(KB) per POST" desc:maximumFileSizeDesc image:@"setting_db" key:@"STUDY_CELL_MAX_FILE_SIZE" state:YES]];
    if (autoSyncState) {
        [_settings addObject:[self getCelContent:@"Auto Sync" desc:@"ON" image:@"setting_auto_sync" key:SETTING_AUTO_SYNC state:YES]];
    }else{
        [_settings addObject:[self getCelContent:@"Auto Sync" desc:@"OFF" image:@"setting_auto_sync" key:SETTING_AUTO_SYNC state:NO]];
    }
    
    //////////////////////////////////////////////////////
    PushNotification * pushToken = [[PushNotification alloc] initWithAwareStudy:awareStudy dbType:AwareDBTypeCoreData];
    NSString * token = [pushToken getPushNotificationToken];
    if(token==nil){
        token= @"";
    }
    [_settings addObject:[self getCelContent:@"Operations" desc:@"" image:@"" key:@"TITLE_CELL_VIEW" state:NO]];
    [_settings addObject:[self getCelContent:@"Upload stored data manually" desc:@"Please push this row for uploading sensor data!" image:@"aware_upload_icon" key:@"STUDY_CELL_MANULA_UPLOAD" state:YES]];
    [_settings addObject:[self getCelContent:@"Check settings for background sensing" desc:@"" image:@"setting_check_all" key:@"STUDY_CELL_CHECK_COMPLIANCE" state:YES]];
    [_settings addObject:[self getCelContent:@"Open setting.app" desc:@"Move to Settings.app which is a default app on iOS" image:@"setting_setting" key:@"STUDY_CELL_SETTINGS_APP" state:YES]];
    [_settings addObject:[self getCelContent:@"Get a push notification token" desc:token image:@"setting_notification" key:@"push_notification_device_tokens" state:YES]];
    NSString * studyInfo = @"No Study: Let's join a study!";
    if([awareStudy getMqttServer] != nil){
        studyInfo = [NSString stringWithFormat:@"%@ (%@)", awareStudy.getMqttServer, awareStudy.getStudyId];
    }
    [_settings addObject:[self getCelContent:@"Quit study" desc:studyInfo image:@"setting_quit" key:@"STUDY_CELL_QUIT_STUDY" state:YES]];
    
    /////////////////////////////////////////////////////
    // current version of AWARE iOS
    NSString* version = [NSString stringWithFormat:@"%@",[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    NSString *build = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    if(build != nil){
        version = [version stringByAppendingFormat:@"(%@)", build];
    }
    [_settings addObject:[self getCelContent:@"App information" desc:@"" image:@"" key:@"TITLE_CELL_VIEW" state:NO]];
    [_settings addObject:[self getCelContent:@"Version" desc:version image:@"" key:@"STUDY_CELL_VIEW" state:NO]];
    [_settings addObject:[self getCelContent:@"About AWARE" desc:@"" image:@"" key:@"STUDY_CELL_ABOUT_AWARE" state:NO]];
    [_settings addObject:[self getCelContent:@"Team" desc:@"" image:@"" key:@"STUDY_CELL_TEAM" state:NO]];
    [_settings addObject:[self getCelContent:@"Introduction" desc:@"" image:@"" key:@"STUDY_CELL_SHOW_INTRODUCTION" state:NO]];
    
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
                                    key:(NSString *)key
                                  state:(BOOL)state{
    // Make a dictionary object for a raw
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setObject:title forKey:KEY_CEL_TITLE];
    [dic setObject:desc forKey:KEY_CEL_DESC];
    [dic setObject:image forKey:KEY_CEL_IMAGE];
    [dic setObject:key forKey:KEY_CEL_SENSOR_NAME];
    [dic setObject:@(state) forKey:KEY_CEL_STATE];
    return dic;
}


- (IBAction)pushedEsmButtonOnNavigationBar:(id)sender {
    NSArray * esms = [iOSESM getValidESMSchedulesWithDatetime:[NSDate new]];
    if(esms != nil && esms.count != 0 ){
        [IOSESM setAppearedState:YES];
        [self performSegueWithIdentifier:@"iOSEsmScrollView" sender:self];
    }
}

/**
 When a study is refreshed (e.g., pushed refresh button, changed settings,
 and/or done daily study update), this method is called before the -initList.
 */
- (IBAction)pushedStudyRefreshButton:(id)sender {
    // Refresh the study information
    [awareStudy refreshStudy];
    
    //_refreshButton.enabled = NO;
    [self.tableView reloadData];
    [self performSelector:@selector(initContentsOnTableView) withObject:0 afterDelay:3];
    // [self.tableView performSelector:@selector(reloadData) withObject:nil afterDelay:3.1];
    [self performSelector:@selector(refreshButtonEnableYes) withObject:0 afterDelay:10];
}

- (void) refreshButtonEnableYes {
    // _refreshButton.enabled = YES;
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
    NSDictionary *item = (NSDictionary *)[_settings objectAtIndex:indexPath.row];
    NSString *key = [item objectForKey:KEY_CEL_SENSOR_NAME];
    selectedRow = key;
    // Debug Model ON/OFF
    if([key isEqualToString:@"ADVANCED_SETTINGS"]){
        [self performSegueWithIdentifier:@"AppSettingView" sender:self];
    }else if ([key isEqualToString:@"STUDY_CELL_DEBUG"]) { //Debug
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Debug Statement" message:@"" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"ON", @"OFF", nil];
        alert.tag = 1;
        [alert show];
        // Set Sync Interval
    } else if ([key isEqualToString:@"STUDY_CELL_SYNC"]) { //Sync
        // Get the interval
        // NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        // double interval = [userDefaults doubleForKey:SETTING_SYNC_INT];
        // Set the interval
        double interval = [awareStudy getUploadIntervalAsSecond];
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
        // NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        // NSInteger maximumFileValue =  [userDefaults integerForKey:KEY_MAX_DATA_SIZE];
        NSInteger maximumFileValue = [awareStudy getMaximumByteSizeForDataUpload];
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
                                                             message:[NSString stringWithFormat:@"Now you are joining %@(%@). \n[NOTE]\n If you push the 'Quit' button, all of the stored data and study settings are removed from this app.",
                                                                      [awareStudy getMqttServer],
                                                                      [awareStudy getStudyId]]
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
        //         [intro showInView:self.view animateDuration:0.0];
        [self showIntro];
        //         NSIndexPath* indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        //         [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
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
        // NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        // NSInteger fetchSize = [userDefaults integerForKey:KEY_MAX_FETCH_SIZE_NORMAL_SENSOR];
        NSInteger fetchSize = [awareStudy getMaxFetchSize];
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
    } else if ([key isEqualToString:SETTING_DB_TYPE]) {
        NSString * awareStudyURL = [awareStudy getStudyURL];
        if(![awareStudyURL isEqualToString:@""]){
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Warning"
                                                             message:@"You can't change the DB Type during a study."
                                                            delegate:self
                                                   cancelButtonTitle:@"Close"
                                                   otherButtonTitles:nil];
            [alert show];
        }else{
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"AWARE Setting"
                                                             message:@"Please select DB Type."
                                                            delegate:self
                                                   cancelButtonTitle:@"Cancel"
                                                   otherButtonTitles:@"Light Weight (Default)",@"SQLite (Beta Version)",nil];
            alert.tag = 18;
            [alert show];
        }
    } else if ([key isEqualToString:SETTING_CSV_EXPORT_STATE]){
        NSString * awareStudyURL = [awareStudy getStudyURL];
        // NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
        // AwareDBType dbType = [userDefaults integerForKey:SETTING_DB_TYPE];
        AwareDBType dbType = [awareStudy getDBType];
        if(![awareStudyURL isEqualToString:@""]){
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Warning"
                                                             message:@"You are joining a study. During the study, you can't use the CSV Export mode."
                                                            delegate:self
                                                   cancelButtonTitle:@"Close"
                                                   otherButtonTitles:nil];
            [alert show];
        }else if (dbType == AwareDBTypeCoreData){
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Warning"
                                                             message:@"You are using SQLite database now. Please use Light Weight (= Text File) database for exporting a data to a CSV file."
                                                            delegate:self
                                                   cancelButtonTitle:@"Close"
                                                   otherButtonTitles:nil];
            [alert show];
        }else{
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"CSV File Export"
                                                             message:@"Do you need to export CSV file? If you select 'YES', the collected data is saved to a .csv file. \n[NOTE]\n The CSV export mode does not upload collected data to aware server."
                                                            delegate:self
                                                   cancelButtonTitle:@"Cancel"
                                                   otherButtonTitles:@"YES",@"NO",nil];
            alert.tag = 19;
            [alert show];
        }
    } else if ([key isEqualToString:SETTING_AUTO_SYNC_STATE]){
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"AWARE Setting"
                                                         message:@"Do you need to upload data in the background?"
                                                        delegate:self
                                               cancelButtonTitle:@"Cancel"
                                               otherButtonTitles:@"YES",@"NO",nil];
        alert.tag = 20;
        [alert show];
        
    } else if ([key isEqualToString:@"push_notification_device_tokens"]){
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Push Notification Setting"
                                                         message:nil //@"Upload a push notification token?"
                                                        delegate:self
                                               cancelButtonTitle:@"Cancel"
                                               otherButtonTitles:@"Upload current token",nil];
        alert.tag = 21;
        [alert show];
    } else if ([key isEqualToString:SENSOR_PLUGIN_CONTACTS]){
        [self performSegueWithIdentifier:@"contacts" sender:self];
    } else if ([key isEqualToString:@"STUDY_CELL_CHECK_COMPLIANCE"]){
        AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
        AWARECore * core = delegate.sharedAWARECore;
        [core checkComplianceWithViewController:self showDetail:YES];
    }else if ([key isEqualToString:SETTING_AUTO_SYNC]){
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"AWARE Setting"
                                                         message:@"Do you want to sync local-DB and remove-DB in the background automatically?"
                                                        delegate:self
                                               cancelButtonTitle:@"Cancel"
                                               otherButtonTitles:@"ON",@"OFF",nil];
        alert.tag = 22;
        [alert show];
    } else {
        // [self performSegueWithIdentifier:@"settingView" sender:self];
    }
}


/**
 * When a user select a button on the UIAlertView, this method is called with selected buttonIndex.
 */
- (void)alertView:(UIAlertView *)alertView
clickedButtonAtIndex:(NSInteger)buttonIndex{
    NSString* title = alertView.title;
    NSLog(@"%ld", buttonIndex);
    // NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    ///////////// Debug State //////////////////
    if([title isEqualToString:@"Debug Statement"]){
        if (buttonIndex == 1){ //yes
            [awareStudy setDebugState:YES];
            // [userDefaults setBool:YES forKey:SETTING_DEBUG_STATE];
            [self pushedStudyRefreshButton:alertView];
        } else if (buttonIndex == 2){ // no
            // [userDefaults setBool:NO forKey:SETTING_DEBUG_STATE];
            [awareStudy setDebugState:NO];
            [self pushedStudyRefreshButton:alertView];
        } else {
            NSLog(@"Cancel");
        }
        [self.tableView reloadData];
        [self initContentsOnTableView];
        ////////////// Sync Interval //////////////
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
        // double syncInterval = [interval doubleValue] * 60.0f;
        [awareStudy setUploadIntervalWithMinutue:[interval doubleValue]];
        [sensorManager startUploadTimerWithInterval:[interval doubleValue]*60.0f];
        
        [self.tableView reloadData];
        [self initContentsOnTableView];
        ///////////////////// Upload Setting (Wifi) ////////////////////
    }else if(alertView.tag == 3){
        if (buttonIndex == 1){ //yes
            // [userDefaults setBool:YES forKey:SETTING_SYNC_WIFI_ONLY];
            [awareStudy setDataUploadStateInWifi:YES];
            [self pushedStudyRefreshButton:alertView];
        } else if (buttonIndex == 2){ // no
            // [userDefaults setBool:NO forKey:SETTING_SYNC_WIFI_ONLY];
            [awareStudy setDataUploadStateInWifi:NO];
            [self pushedStudyRefreshButton:alertView];
        } else {
            NSLog(@"Cancel");
        }
        [self.tableView reloadData];
        [self initContentsOnTableView];
        ///////////////// Upload Setting (Battery) //////////////////////////
    }else if (alertView.tag == 9){ // Set Sync Setting
        if (buttonIndex == 1){ //yes
            // [userDefaults setBool:YES forKey:SETTING_SYNC_BATTERY_CHARGING_ONLY];
            [awareStudy setDataUploadStateWithOnlyBatterChargning:YES];
            [self pushedStudyRefreshButton:alertView];
        } else if (buttonIndex == 2){ // no
            // [userDefaults setBool:NO forKey:SETTING_SYNC_BATTERY_CHARGING_ONLY];
            [awareStudy setDataUploadStateWithOnlyBatterChargning:NO];
            [self pushedStudyRefreshButton:alertView];
        } else {
            NSLog(@"Cancel");
        }
        [self.tableView reloadData];
        [self initContentsOnTableView];
        
        /////////// Maximum Size of Post Data(KB) //////////////
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
        [awareStudy setMaximumByteSizeForDataUpload:maximumValue];
        // [userDefaults setObject:[NSNumber numberWithInteger:maximumValue] forKey:KEY_MAX_DATA_SIZE];
        [self pushedStudyRefreshButton:alertView];
        [self.tableView reloadData];
        [self initContentsOnTableView];
        ////////////////////// Button for manual upload  /////////////////
    }else if(alertView.tag == 8){ //manual data upload
        if (buttonIndex == 1){
            [sensorManager syncAllSensorsWithDBInForeground];
        }
        //////////////////////  Link to Settings.app ////////////////////////
    }else if(alertView.tag == 10){
        if (buttonIndex == 1){
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
            //            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"prefs://"]];
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
        ////////////////////// Study Quit Operation ///////////
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
        ////////////////////////// data cleaning ///////////////
    }else if (alertView.tag == 14){
        switch (buttonIndex) {
            case 0:
                NSLog(@"cancel");
                break;
            case 1:
                //[userDefaults setInteger:cleanOldDataTypeNever forKey:SETTING_FREQUENCY_CLEAN_OLD_DATA];
                [awareStudy setCleanOldDataType:cleanOldDataTypeNever];
                break;
            case 2:
                //[userDefaults setInteger:cleanOldDataTypeWeekly forKey:SETTING_FREQUENCY_CLEAN_OLD_DATA];
                [awareStudy setCleanOldDataType:cleanOldDataTypeWeekly];
                break;
            case 3:
                //[userDefaults setInteger:cleanOldDataTypeMonthly forKey:SETTING_FREQUENCY_CLEAN_OLD_DATA];
                [awareStudy setCleanOldDataType:cleanOldDataTypeMonthly];
                break;
            case 4:
                //[userDefaults setInteger:cleanOldDataTypeDaily forKey:SETTING_FREQUENCY_CLEAN_OLD_DATA];
                [awareStudy setCleanOldDataType:cleanOldDataTypeDaily];
                break;
            case 5:
                //[userDefaults setInteger:cleanOldDataTypeAlways forKey:SETTING_FREQUENCY_CLEAN_OLD_DATA];
                [awareStudy setCleanOldDataType:cleanOldDataTypeAlways];
                break;
            default:
                break;
        }
        [self.tableView reloadData];
        [self initContentsOnTableView];
        ///////////////////  Maximum Fetch Size for SQLite ///////////////////////
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
        [awareStudy setMaximumNumberOfRecordsForDataUpload:maximumValue];
        // [userDefaults setObject:[NSNumber numberWithInteger:maximumValue] forKey:KEY_MAX_FETCH_SIZE_NORMAL_SENSOR];
        // [userDefaults synchronize];
        
        [self pushedStudyRefreshButton:alertView];
        
        [self.tableView reloadData];
        [self initContentsOnTableView];
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
        /////////////////// DB Type ////////////////////
    }else if (alertView.tag == 18){
        if(buttonIndex == [alertView cancelButtonIndex]){
            return;
        }else{
            switch (buttonIndex) {
                case 1:
                    // [userDefaults setInteger:AwareDBTypeTextFile forKey:SETTING_DB_TYPE];
                    [awareStudy setDBType:AwareDBTypeTextFile];
                    [self pushedStudyRefreshButton:alertView];
                    break;
                case 2:
                    // [userDefaults setInteger:AwareDBTypeCoreData forKey:SETTING_DB_TYPE];
                    [awareStudy setDBType:AwareDBTypeCoreData];
                    [self pushedStudyRefreshButton:alertView];
                default:
                    break;
            }
        }
        ///////////////////// CSV Export  ///////////////////////
    }else if (alertView.tag == 19){
        if(buttonIndex == [alertView cancelButtonIndex]){
            return;
        }else{
            // NSLog(@"%ld",buttonIndex);
            switch (buttonIndex) {
                case 1:
                    [awareStudy setCSVExport:YES];
                    [self pushedStudyRefreshButton:alertView];
                    break;
                case 2:
                    [awareStudy setCSVExport:NO];
                    [self pushedStudyRefreshButton:alertView];
                    break;
                default:
                    break;
            }
        }
        ///////////////////// Push Notification //////////////////////
    }else if(alertView.tag == 21){
        PushNotification * pushNotification = [[PushNotification alloc] initWithAwareStudy:awareStudy dbType:AwareDBTypeCoreData];
        [pushNotification allowsDateUploadWithoutBatteryCharging];
        [pushNotification allowsCellularAccess];
        switch (buttonIndex) {
            case 1:
                [pushNotification saveStoredPushNotificationDeviceToken];
                [pushNotification performSelector:@selector(syncAwareDBInBackground) withObject:nil afterDelay:1];
                break;
            default:
                break;
        }
    }else if(alertView.tag == 22){
        switch (buttonIndex) {
            case 1:
                [awareStudy setAutoSyncState:YES];
                [core deactivate];
                [core activate];
                break;
            case 2:
                [awareStudy setAutoSyncState:NO];
                [core deactivate];
                [core activate];
                break;
            default:
                break;
        }
        [self.tableView reloadData];
        [self initContentsOnTableView];
    }
}


-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_settings count];
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    NSDictionary *item = (NSDictionary *)[_settings objectAtIndex:indexPath.row];
    if ([[item objectForKey:KEY_CEL_SENSOR_NAME] isEqualToString:@"TITLE_CELL_VIEW"]) {
        return 40;
    }else if ([[item objectForKey:KEY_CEL_SENSOR_NAME] isEqualToString:@"STUDY_CELL_VIEW"]){
        return 60;
    }else{
        // return [tableView rowHeight];
        return 60;
    }
}



- (void)updateVisibleCells {
    for (UITableViewCell *cell in [self.tableView visibleCells]){
        [self updateCell:cell atIndexPath:[self.tableView indexPathForCell:cell]];
    }
}


//for cell updating
- (void)updateCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *item = (NSDictionary *)[_settings objectAtIndex:indexPath.row];
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
        NSDictionary *item = (NSDictionary *)[_settings objectAtIndex:indexPath.row];
        //
        //        /// Make a cell by _settings (sensor list on ViewController.)
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
        NSNumber * state = [item objectForKey:KEY_CEL_STATE];
        cell.imageView.image = theImage;
        
        NSString *sensorKey = [item objectForKey:KEY_CEL_SENSOR_NAME];
        NSString* latestSensorData = [sensorManager getLatestSensorValue:sensorKey];
        
        
        latestSensorData = [sensorManager getLatestSensorValue:sensorKey];
        //update latest sensor data
        if(![latestSensorData isEqualToString:@""]){
            [cell.detailTextLabel setText:latestSensorData];
        }
        if (state.boolValue) {
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
    page1.desc = @"AWARE Client iOS is a sensing framework dedicated to an instrument, infer, log and share mobile context information, for smartphone users and researchers. AWARE captures hardware-, software-, and human-based data.";
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
    page4.desc = @"1.Set a study on AWARE Dashboard and make a QRcode for the study\n2.Read the QRcode by AWARE client's QRcode reader\n3.Install SSL certificiation file and push a 'Refresh button'\n3.AWARE client start sensing and uploading your contexts in the background\n4.You can quit the study by 'Quit Study' button";
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
    
}

- (IBAction)pushedNextButton:(id)sender {
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
