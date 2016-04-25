//
//  AppDelegate.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/18/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import "AWAREKeys.h"
#import "AWAREUtils.h"
#import "AWAREStudy.h"

// DeployGateSDK Libraries (https://deploygate.com/docs/ios_sdk)
#import "DeployGateSDK/DeployGateSDK.h"

// GoogleLoginPlugin Library (https://developers.google.com/identity/sign-in/ios/)
#import "GoogleLogin.h"

// DebugPlugin Library
#import "Debug.h"

#import "MSBand.h"
#import "Scheduler.h"
#import "GoogleCalPush.h"

#import "ESMStorageHelper.h"
#import "AWAREEsmUtils.h"
#import "Labels.h"
#import "ESM.h"
#import "Observer.h"


@implementation AppDelegate{
    AWAREStudy * awareStudy;
    Observer * observer;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    awareStudy = [[AWAREStudy alloc] initWithReachability:YES];
    observer = [[Observer alloc] initWithSensorName:@"" withAwareStudy:awareStudy];

    [application unregisterForRemoteNotifications];
    
    if ([AWAREUtils getCurrentOSVersionAsFloat] >= 8.0) {
        // Set remote notifications
        [application registerForRemoteNotifications];
        // Set background fetch
        [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];

        if ([AWAREUtils getCurrentOSVersionAsFloat] >= 9.0) {
            NSSet *categories = [self getNotificationCategories];
            
            // Set the category to application
            UIUserNotificationType types = UIUserNotificationTypeBadge|
            UIUserNotificationTypeSound|
            UIUserNotificationTypeNone|
            UIUserNotificationTypeAlert;
            UIUserNotificationSettings *mySettings = [UIUserNotificationSettings settingsForTypes:types categories:categories];
            [application registerUserNotificationSettings:mySettings];
        }else{
            UIUserNotificationType types = UIUserNotificationTypeBadge|
            UIUserNotificationTypeSound|
            UIUserNotificationTypeNone|
            UIUserNotificationTypeAlert;
            UIUserNotificationSettings *mySettings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
            [application registerUserNotificationSettings:mySettings];
        }
    }
    
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    
    // DeployGate SDK
    [[DeployGateSDK sharedInstance] launchApplicationWithAuthor:@"tetujin" key:@"b268f60ae48ecfca7352c0a01918c86a7bd4bc74"];
    
    // Set background fetch for updating debug information
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    
    // Google Login Plugin
    NSError* configureError;
    [[GGLContext sharedInstance] configureWithError: &configureError];
    NSAssert(!configureError, @"Error configuring Google services: %@", configureError);
    [GIDSignIn sharedInstance].delegate = self;
    
    NSLog(@"Turn 'OFF' the auto sleep mode on this app");
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    // Error Tacking
    NSSetUncaughtExceptionHandler(&exceptionHandler);
    
    /// Set defualt settings
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if (![userDefaults boolForKey:@"aware_inited"]) {
        [userDefaults setBool:NO forKey:SETTING_DEBUG_STATE];                 // Default Value: NO
        [userDefaults setBool:YES forKey:SETTING_SYNC_WIFI_ONLY];             // Default Value: YES
        [userDefaults setBool:YES forKey:SETTING_SYNC_BATTERY_CHARGING_ONLY]; // Default Value: YES
        [userDefaults setDouble:60*15 forKey:SETTING_SYNC_INT];               // Default Value: 60*15 (sec)
        [userDefaults setBool:NO forKey:KEY_APP_TERMINATED];                  // Default Value: NO
        [userDefaults setInteger:0 forKey:KEY_UPLOAD_MARK];                   // Defualt Value: 0
        [userDefaults setInteger:1000 * 100 forKey:KEY_MAX_DATA_SIZE];        // Defualt Value: 1000*100 (byte) (100 KB)
        
        [userDefaults setBool:YES forKey:@"aware_inited"];
    }
    double uploadInterval = [userDefaults doubleForKey:SETTING_SYNC_INT];
    
    // Battery Save Mode
    if([AWAREUtils getCurrentOSVersionAsFloat] >= 9.0){
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(powerStateDidChange:)
                                                     name:NSProcessInfoPowerStateDidChangeNotification
                                                   object:nil];
    }
    
    // battery state trigger
    // Set a battery state change event to a notification center
    [UIDevice currentDevice].batteryMonitoringEnabled = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(changedBatteryState:)
                                                 name:UIDeviceBatteryStateDidChangeNotification object:nil];
    
    /**
     * Start a location sensor for background sensing.
     * On the iOS, we have to turn on the location sensor
     * for using application in the background.
     */
    [self initLocationSensor];
    
    // start sensors
    [self.sharedSensorManager startAllSensors];
    [self.sharedSensorManager startUploadTimerWithInterval:uploadInterval];
//    [self.sharedSensorManager syncAllSensorsWithDBInBackground];
    
    /// Set a timer for a daily sync update
    /**
     * Every 2AM, AWARE iOS refresh the joining study in the background.
     * A developer can change the time (2AM to xxxAM/PM) by changing the dailyUpdateTime(NSDate) Object
     */
    NSDate* dailyUpdateTime = [AWAREUtils getTargetNSDate:[NSDate new] hour:2 minute:0 second:0 nextDay:YES]; //2AM
    _dailyUpdateTimer = [[NSTimer alloc] initWithFireDate:dailyUpdateTime
                                                interval:60*60*24 // daily
                                                  target:awareStudy
                                                selector:@selector(refreshStudy)
                                                userInfo:nil
                                                 repeats:YES];
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    //    [runLoop addTimer:dailyUpdateTimer forMode:NSDefaultRunLoopMode];
    [runLoop addTimer:_dailyUpdateTimer forMode:NSRunLoopCommonModes];
    
    return YES;
}


@synthesize sharedSensorManager = _sharedSensorManager;

- (AWARESensorManager *) sharedSensorManager {
    AWAREStudy * study = [[AWAREStudy alloc] initWithReachability:YES];
    if(_sharedSensorManager == nil){
        _sharedSensorManager = [[AWARESensorManager alloc] initWithAWAREStudy:study];
    }
    return _sharedSensorManager;
}


void exceptionHandler(NSException *exception) {
    // http://www.yoheim.net/blog.php?q=20130113
//    NSLog(@"%@", exception.name);
//    NSLog(@"%@", exception.reason);
//    NSLog(@"%@", exception.callStackSymbols);
//    NSString * error = [NSString stringWithFormat:@"[%@] %@ , %@" , exception.name, exception.reason, exception.callStackSymbols];
    
    Debug * debugSensor = [[Debug alloc] initWithAwareStudy:nil];
    [debugSensor saveDebugEventWithText:exception.debugDescription type:DebugTypeCrash label:exception.name];
 }


- (void) powerStateDidChange:(id) sender {
    Debug * debugSensor = [[Debug alloc] initWithAwareStudy:awareStudy];
    if ([[NSProcessInfo processInfo] isLowPowerModeEnabled]) {
        // Low Power Mode is enabled. Start reducing activity to conserve energy.
        [debugSensor saveDebugEventWithText:@"[Low Power Mode] On" type:DebugTypeWarn label:@""];
        [AWAREUtils sendLocalNotificationForMessage:@"Please don't use **Low Power Mode** during a study!" soundFlag:YES];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"prefs:root=BATTERY_USAGE"]];
    } else {
        // Low Power Mode is not enabled.
        [debugSensor saveDebugEventWithText:@"[Low Power Mode] Off" type:DebugTypeWarn label:@""];
    };
}


/**
 * Start data sync with all sensors in the background when the device is started a battery charging.
 */
- (void) changedBatteryState:(id) sender {
    NSInteger batteryState = [UIDevice currentDevice].batteryState;
    if (batteryState == UIDeviceBatteryStateCharging || batteryState == UIDeviceBatteryStateFull) {
        Debug * debugSensor = [[Debug alloc] initWithAwareStudy:awareStudy];
        [debugSensor saveDebugEventWithText:@"[Uploader] The battery is charging. AWARE iOS start to upload sensor data." type:DebugTypeInfo label:@""];
        if (_sharedSensorManager != nil) {
            [_sharedSensorManager syncAllSensorsWithDBInBackground];
        }
        GoogleCalPush * cal = [[GoogleCalPush alloc] initWithSensorName:SENSOR_PLUGIN_GOOGLE_CAL_PUSH withAwareStudy:awareStudy];
        [cal checkCalendarEvents:nil];
        
        [_sharedSensorManager runBatteryStateChangeEvents];
    }
}


- (NSSet*) getNotificationCategories {
    // For text edit
    UIMutableUserNotificationAction *addLabelAction = [[UIMutableUserNotificationAction alloc] init];
    addLabelAction.title = @"Add Label";
    addLabelAction.activationMode = UIUserNotificationActivationModeBackground;
    addLabelAction.authenticationRequired = YES;
    addLabelAction.identifier = @"add_label_action";
    addLabelAction.behavior = UIUserNotificationActionBehaviorTextInput;
    
    UIMutableUserNotificationCategory *labelCategory = [[UIMutableUserNotificationCategory alloc] init];
    labelCategory.identifier = SENSOR_LABELS_TYPE_TEXT;
    [labelCategory setActions:@[addLabelAction] forContext:UIUserNotificationActionContextMinimal];
    
    // For label yes/no
    UIMutableUserNotificationAction *addTrueAction = [[UIMutableUserNotificationAction alloc] init];
    addTrueAction.title = @"YES";
    addTrueAction.activationMode = UIUserNotificationActivationModeBackground;
    addTrueAction.authenticationRequired = YES;
    addTrueAction.identifier = @"add_bool_action_yes";
    
    UIMutableUserNotificationAction *addFalseAction = [[UIMutableUserNotificationAction alloc] init];
    addFalseAction.title = @"NO";
    addFalseAction.activationMode = UIUserNotificationActivationModeBackground;
    addFalseAction.authenticationRequired = YES;
    addFalseAction.destructive = YES;
    addFalseAction.identifier = @"add_bool_action_no";
    
    UIMutableUserNotificationCategory *labelBooleanCategory = [[UIMutableUserNotificationCategory alloc] init];
    labelBooleanCategory.identifier = SENSOR_LABELS_TYPE_BOOLEAN;
    [labelBooleanCategory setActions:@[addTrueAction, addFalseAction] forContext:UIUserNotificationActionContextMinimal];
    
    // Upload date
    //            UIMutableUserNotificationAction *esmAction = [[UIMutableUserNotificationAction alloc] init];
    //            esmAction.title = @"Answer";
    //            esmAction.identifier = @"esm_action";
    //            esmAction.activationMode = UIUserNotificationActivationModeForeground;
    //            esmAction.authenticationRequired = YES;
    //            esmAction.destructive = NO;
    //
    //            UIMutableUserNotificationCategory *esmCategory = [[UIMutableUserNotificationCategory alloc] init];
    //            esmCategory.identifier = SENSOR_PLUGIN_CAMPUS;
    //            [esmCategory setActions:@[esmAction] forContext:UIUserNotificationActionContextMinimal];
    
    
    // Upload date
    UIMutableUserNotificationAction *updateCalendarAction = [[UIMutableUserNotificationAction alloc] init];
    updateCalendarAction.title = @"Update";
    updateCalendarAction.identifier = @"calendar_update_action";
    updateCalendarAction.activationMode = UIUserNotificationActivationModeBackground;
    updateCalendarAction.authenticationRequired = YES;
    updateCalendarAction.destructive = NO;
    
    UIMutableUserNotificationCategory *category = [[UIMutableUserNotificationCategory alloc] init];
    category.identifier = SENSOR_PLUGIN_GOOGLE_CAL_PUSH;
    [category setActions:@[updateCalendarAction] forContext:UIUserNotificationActionContextDefault];
    
    
    /** ---- ESM ---- **/
    // [For quick editing label]
    // make a action
    UIMutableUserNotificationAction *esmEditLabelAction = [[UIMutableUserNotificationAction alloc] init];
    esmEditLabelAction.title = @"Edit";
    esmEditLabelAction.activationMode = UIUserNotificationActivationModeBackground;
    esmEditLabelAction.authenticationRequired = YES;
    esmEditLabelAction.identifier = @"edit_label_action";
    esmEditLabelAction.behavior = UIUserNotificationActionBehaviorTextInput;
    // make a notification category
    UIMutableUserNotificationCategory *esmEditLabelCategory = [[UIMutableUserNotificationCategory alloc] init];
    esmEditLabelCategory.identifier = SENSOR_PLUGIN_CAMPUS_ESM_NOTIFICATION_LABEL;
    [esmEditLabelCategory setActions:@[esmEditLabelAction] forContext:UIUserNotificationActionContextMinimal];
    
    
    // [For quick YES/NO question]
    // make a action
    UIMutableUserNotificationAction *esmAnswerYesAction = [[UIMutableUserNotificationAction alloc] init];
    esmAnswerYesAction.title = @"YES";
    esmAnswerYesAction.activationMode = UIUserNotificationActivationModeBackground;
    esmAnswerYesAction.authenticationRequired = YES;
    esmAnswerYesAction.identifier = @"esm_answer_yes_action";
    // make a action
    UIMutableUserNotificationAction *esmAnswerNoAction = [[UIMutableUserNotificationAction alloc] init];
    esmAnswerNoAction.title = @"NO";
    esmAnswerNoAction.activationMode = UIUserNotificationActivationModeBackground;
    esmAnswerNoAction.authenticationRequired = YES;
    esmAnswerNoAction.destructive = YES;
    esmAnswerNoAction.identifier = @"esm_answer_no_action";
    // make a notification category
    UIMutableUserNotificationCategory *esmAnswerBoolQuestionCategory = [[UIMutableUserNotificationCategory alloc] init];
    esmAnswerBoolQuestionCategory.identifier = SENSOR_PLUGIN_CAMPUS_ESM_NOTIFICATION_BOOLEAN;
    [esmAnswerBoolQuestionCategory setActions:@[esmAnswerNoAction, esmAnswerYesAction] forContext:UIUserNotificationActionContextMinimal];
    
    return [NSSet setWithObjects: category,labelCategory, labelBooleanCategory, esmEditLabelCategory, esmAnswerBoolQuestionCategory, nil];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
//    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
//    [defaults setBool:NO forKey:@"APP_STATE"];
//    NSLog(@"Go to background 1");
//    [AWAREUtils setAppState:NO];
    
//    NSLog(@"Turn 'ON' the auto sleep mode on this app");
//    [UIApplication sharedApplication].idleTimerDisabled = NO;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
//    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
//    [defaults setBool:NO forKey:@"APP_STATE"];
//    NSLog(@"Go to background 2");
//    [AWAREUtils setAppState:NO];
    
    NSLog(@"Turn 'ON' the auto sleep mode on this app");
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    
    [ESM setAppearedState:NO];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
//    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
//    [defaults setBool:YES forKey:@"APP_STATE"];
//    NSLog(@"Go to fourground");
//    [AWAREUtils setAppState:YES];
    
    NSLog(@"Turn 'OFF' the auto sleep mode on this app");
    [UIApplication sharedApplication].idleTimerDisabled = YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    //    http://d.hatena.ne.jp/glass-_-onion/20120405/1333611664
//    [defaults setBool:YES forKey:@"APP_STATE"];
//    NSLog(@"Go to fourground");
//    [AWAREUtils setAppState:YES];
    
    NSLog(@"Turn 'OFF' the auto sleep mode on this app");
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:-1];
}




- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
//    [self saveContext];
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    if (notification){
        notification.repeatInterval = 0;
        notification.alertBody = @"Application is stoped! Please reboot this app for logging your acitivties.";
        notification.alertAction = @"Reboot";
        notification.soundName = UILocalNotificationDefaultSoundName;
        notification.applicationIconBadgeNumber = 1;
        [[UIApplication sharedApplication] scheduleLocalNotification:notification];
        
        
        Debug * debugSensor = [[Debug alloc] initWithAwareStudy:awareStudy];
        [debugSensor saveDebugEventWithText:notification.alertBody type:DebugTypeWarn label:@"stop"];
        [debugSensor syncAwareDB];
    }
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES forKey:KEY_APP_TERMINATED];

    NSLog(@"Stop background task of AWARE....");
    NSLog(@"Turn 'ON' the auto sleep mode on this app");
    [UIApplication sharedApplication].idleTimerDisabled = NO;
}


////////////////////////////////
///   Backgroud Fetch
///
/// https://mobiforge.com/design-development/using-background-fetch-ios
///
///////////////////////////////

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    /// NOTE: A background fetch method can work for 30 second. Also, the method is called randomly by OS.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        NSLog(@"Start a background fetch ...");
        
        // Send a survival signal to the AWARE server
        [observer sendSurvivalSignal];
        
        // Upload debug messagaes in the background (Wi-Fi is required for this upload process.)
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
        NSString *formattedDateString = [dateFormatter stringFromDate:[NSDate new]];
        
        Debug * debug = [[Debug alloc] initWithAwareStudy:awareStudy];
        [debug saveDebugEventWithText:@"This is a background fetch" type:DebugTypeInfo label:formattedDateString];
        bool result = [debug syncAwareDBInForeground];
        
        NSString * debugMessage = @"";
        if (result) {
            debugMessage = @"Sucess to upload debug message in the background fetch.";
        }else{
            debugMessage = @"Faile to upload debug message in the background fetch.";
        }
        [debug saveDebugEventWithText:debugMessage type:DebugTypeInfo label:formattedDateString];
        //    [AWAREUtils sendLocalNotificationForMessage:debugMessage soundFlag:YES];
        
        if (result) {
            completionHandler(UIBackgroundFetchResultNewData);
        }else{
            completionHandler(UIBackgroundFetchResultFailed);
        }
        
        debug = nil;
        
        NSLog(@"... Finish a background fetch");
    });
}


// This method is called then iOS receieved data by BackgroundFetch
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    NSLog(@"pushInfo in Background: %@", [userInfo description]);
    completionHandler(UIBackgroundFetchResultNoData);
}


- (void)application:(UIApplication *)application
handleEventsForBackgroundURLSession:(NSString *)identifier
  completionHandler:(void (^)())completionHandler {
    NSLog(@"Background OK");
    completionHandler();
    /*
     Store the completion handler. The completion handler is invoked by the view            
     controller's checkForAllDownloadsHavingCompleted method (if all the download tasks have been            
     completed).
     */
//    self.backgroundSessionCompletionHandler = completionHandler;
}

/////////////////////////////////////////
/////////////////////////////////////////



///////////////////////////////////////
//  For Push Notification
///////////////////////////////////////

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    
    NSString *token = deviceToken.description;
    
    token = [token stringByReplacingOccurrencesOfString:@"<" withString:@""];
    token = [token stringByReplacingOccurrencesOfString:@">" withString:@""];
    token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSLog(@"%@", token);
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:token forKey:KEY_APNS_TOKEN];
    [defaults synchronize];
    NSLog(@"deviceToken: %@", token);
}

// Faile to get a DeviceToken
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"deviceToken error: %@", [error description]);
}


// Get normal push alert
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    NSLog(@"pushInfo: %@", [userInfo description]);
}



////////////////////////////
///////////////////////////

/**
 * Location Notification Event
 * If you receive local push notification, every time this method is called.
 * Also, each notification has their category ID. You can do some operation after get the notification.
 */
- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification{
    // Calendar and ESM plugin use this method
    if ([notification.category isEqualToString:SENSOR_PLUGIN_CAMPUS]) {
        Scheduler * scheduler = [[Scheduler alloc] initWithSensorName:SENSOR_PLUGIN_SCHEDULER withAwareStudy:awareStudy];
        [scheduler setESMWithUserInfo:notification.userInfo];
    } else if ([notification.category isEqualToString:SENSOR_PLUGIN_GOOGLE_CAL_PUSH]){
        GoogleCalPush * balancedCampusJournal = [[GoogleCalPush alloc] initWithSensorName:SENSOR_PLUGIN_GOOGLE_CAL_PUSH withAwareStudy:awareStudy];
        [balancedCampusJournal makePrepopulateEvetnsWith:[NSDate new]];
    }
}




/**
 * Actions of LocalNotification.
 * After using the button on a notification in the lock or notifications screen, this method is called.
 */
- (void)application:(UIApplication *)application
handleActionWithIdentifier:(NSString *)identifier
forLocalNotification:(UILocalNotification *)notification
   withResponseInfo:(NSDictionary *)responseInfo
  completionHandler:(void (^)())completionHandler{
    // Calendar and ESM plugin use this method

    NSDictionary *userInfo = [(UILocalNotification*)notification userInfo];
    
    if ([identifier isEqualToString:@"calendar_update_action"]) {
        GoogleCalPush * balancedCampusJournal = [[GoogleCalPush alloc] initWithSensorName:SENSOR_PLUGIN_GOOGLE_CAL_PUSH withAwareStudy:awareStudy];
        [balancedCampusJournal makePrepopulateEvetnsWith:[NSDate new]];
    } else if ([identifier isEqualToString:@"add_label_action"]) {
        NSString * inputText = [responseInfo objectForKey:UIUserNotificationActionResponseTypedTextKey];
        Labels * labelSensor = [[Labels alloc] initWithSensorName:SENSOR_LABELS withAwareStudy:awareStudy];
        [labelSensor saveLabel:inputText
                       withKey:[userInfo objectForKey:@"key"]
                          type:identifier
                          body:notification.alertBody
                   triggerTime:notification.fireDate
                  answeredTime:[NSDate new]];
    } else if ([identifier isEqualToString:@"add_bool_action_yes"]){
        Labels * labelSensor = [[Labels alloc] initWithSensorName:SENSOR_LABELS withAwareStudy:awareStudy];
        [labelSensor saveLabel:@"1"
                       withKey:[userInfo objectForKey:@"key"]
                          type:identifier
                          body:notification.alertBody
                   triggerTime:notification.fireDate
                  answeredTime:[NSDate new]];
    } else if ([identifier isEqualToString:@"add_bool_action_no"]){
        Labels * labelSensor = [[Labels alloc] initWithSensorName:SENSOR_LABELS withAwareStudy:awareStudy];
        [labelSensor saveLabel:@"0"
                       withKey:[userInfo objectForKey:@"key"]
                          type:identifier
                          body:notification.alertBody
                   triggerTime:notification.fireDate
                  answeredTime:[NSDate new]];
    } else if ([identifier isEqualToString:@"edit_label_action"]){
        NSString * inputText = [responseInfo objectForKey:UIUserNotificationActionResponseTypedTextKey];
        ESM * esm = [[ESM alloc] initWithSensorName:SENSOR_ESMS withAwareStudy:awareStudy];
        NSMutableDictionary *dic =  [AWAREEsmUtils getEsmFormatDictionary:(NSMutableDictionary *)notification.userInfo
                                                    withTimesmap:[AWAREUtils getUnixTimestamp:notification.fireDate]
                                                         devieId:[awareStudy getDeviceId]];
        //        [dic setObject:unixtime forKey:@"timestamp"];
        [dic setObject:[AWAREUtils getUnixTimestamp:[NSDate new]] forKey:KEY_ESM_USER_ANSWER_TIMESTAMP];
        [dic setObject:[awareStudy getDeviceId] forKey:@"device_id"];
        [dic setObject:@2 forKey:KEY_ESM_STATUS];
        [dic setObject:inputText forKey:KEY_ESM_USER_ANSWER];
        [esm saveData:dic];
    } else if ([identifier isEqualToString:@"esm_answer_yes_action"]){
        ESM * esm = [[ESM alloc] initWithSensorName:SENSOR_ESMS withAwareStudy:awareStudy];
        NSMutableDictionary *dic =  [AWAREEsmUtils getEsmFormatDictionary:(NSMutableDictionary *)notification.userInfo
                                                             withTimesmap:[AWAREUtils getUnixTimestamp:notification.fireDate]
                                                                  devieId:[awareStudy getDeviceId]];
        //        [dic setObject:unixtime forKey:@"timestamp"];
        [dic setObject:[AWAREUtils getUnixTimestamp:[NSDate new]] forKey:KEY_ESM_USER_ANSWER_TIMESTAMP];
        [dic setObject:[awareStudy getDeviceId] forKey:@"device_id"];
        [dic setObject:@2 forKey:KEY_ESM_STATUS];
        [dic setObject:@"YES" forKey:KEY_ESM_USER_ANSWER];
        [esm saveData:dic];
    } else if ([identifier isEqualToString:@"esm_answer_no_action"]){
        ESM * esm = [[ESM alloc] initWithSensorName:SENSOR_ESMS withAwareStudy:awareStudy];
        NSMutableDictionary *dic =  [AWAREEsmUtils getEsmFormatDictionary:(NSMutableDictionary *)notification.userInfo
                                                             withTimesmap:[AWAREUtils getUnixTimestamp:notification.fireDate]
                                                                  devieId:[awareStudy getDeviceId]];
        //        [dic setObject:unixtime forKey:@"timestamp"];
        [dic setObject:[AWAREUtils getUnixTimestamp:[NSDate new]] forKey:KEY_ESM_USER_ANSWER_TIMESTAMP];
        [dic setObject:[awareStudy getDeviceId] forKey:@"device_id"];
        [dic setObject:@2 forKey:KEY_ESM_STATUS];
        [dic setObject:@"NO" forKey:KEY_ESM_USER_ANSWER];
        [esm saveData:dic];
    }
    
    
//    }else if([identifier isEqualToString:@"esm_action"]){
//        Scheduler * scheduler = [[Scheduler alloc] initWithSensorName:SENSOR_PLUGIN_SCHEDULER withAwareStudy:awareStudy];
//        [scheduler setESMWithUserInfo:notification];
//    }
    
    // Must be called when finished
    completionHandler();
}



///////////////////////////
//// For Google Login
///////////////////////////
- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    
    return [[GIDSignIn sharedInstance] handleURL:url
                               sourceApplication:sourceApplication
                                      annotation:annotation];
}

- (void)signIn:(GIDSignIn *)signIn
didSignInForUser:(GIDGoogleUser *)user
     withError:(NSError *)error {
    // Perform any operations on signed in user here.
    NSString *userId = user.userID;                  // For client-side use only!
    NSString *idToken = user.authentication.idToken; // Safe to send to the server
    NSString *name = user.profile.name;
    NSString *email = user.profile.email;

//    NSLog(@"user id is %@", userId);
//    NSLog(@"name is %@", name);
//    NSLog(@"email is %@", email);
//    NSLog(@"idToken is %@", idToken);
    
    if (name != nil ) {
        NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:userId forKey:@"GOOGLE_ID"];
        [defaults setObject:name forKey:@"GOOGLE_NAME"];
        [defaults setObject:email forKey:@"GOOGLE_EMAIL"];
        [defaults setObject:idToken forKey:@"GOOGLE_ID_TOKEN"];
        
        NSString* phoneNumber = [defaults objectForKey:@"GOOGLE_PHONE"];
        
        // Get Phone Number by using a notification with text field.
        UIAlertView *av = [[UIAlertView alloc]initWithTitle:@"Please write your phonenumber"
                                                    message:nil
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"OK", nil];
        av.alertViewStyle = UIAlertViewStylePlainTextInput;
        [av textFieldAtIndex:0].delegate = self;
        if (phoneNumber != nil) {
            [av textFieldAtIndex:0].text = phoneNumber;
        }
        UITextField* tf = [av textFieldAtIndex:0];
        tf.keyboardType = UIKeyboardTypeNumberPad;
        [av show];
        

    }

}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    NSLog(@"%@",[alertView textFieldAtIndex:0].text);
    if (buttonIndex != 0) {
        NSString * phonenumber = [alertView textFieldAtIndex:0].text;
        GoogleLogin * googleLogin = [[GoogleLogin alloc] initWithSensorName:SENSOR_PLUGIN_GOOGLE_LOGIN withAwareStudy:nil];
        NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
//        NSString *userId = [defaults objectForKey:@"GOOGLE_ID"];                  // For client-side use only!
//        NSString *idToken = [defaults objectForKey:@"GOOGLE_ID_TOKEN"]; // Safe to send to the server
        NSString *name = [defaults objectForKey:@"GOOGLE_NAME"];
        NSString *email = [defaults objectForKey:@"GOOGLE_EMAIL"];
        [defaults setObject:phonenumber forKey:@"GOOGLE_PHONE"];
        
        // Save the google account information to google login plugin
        [googleLogin saveName:name withEmail:email phoneNumber:phonenumber];
        
        // Show go back alert
        UIAlertView *av = [[UIAlertView alloc]initWithTitle:@"Success"
                                                    message:@"Please go back to the toppage"
                                                   delegate:self
                                          cancelButtonTitle:nil
                                          otherButtonTitles:@"OK", nil];
        [av show];
    }
}

- (void)signIn:(GIDSignIn *)signIn
didDisconnectWithUser:(GIDGoogleUser *)user
     withError:(NSError *)error {
    // Perform any operations when the user disconnects from app here.
    // ...
    NSLog(@"Google login error..");
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void (^)())completionHandler {
    if ([identifier isEqualToString:NotificationActionOneIdent]) {
//        NSLog(@"You chose action 1.");
    }
    else if ([identifier isEqualToString:NotificationActionTwoIdent]) {
//        NSLog(@"You chose action 2.");
    }
    if (completionHandler) {
        completionHandler();
    }
}


//////////////
/////////////


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
        _homeLocationManager.distanceFilter = 200; // meters
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
        Debug * debugSensor = [[Debug alloc] initWithAwareStudy:nil];
        [debugSensor saveDebugEventWithText:message type:DebugTypeInfo label:@""];
        [userDefaults setBool:NO forKey:KEY_APP_TERMINATED];
    }else{
        //        [self sendLocalNotificationForMessage:@"" soundFlag:YES];
    }
}

@end
