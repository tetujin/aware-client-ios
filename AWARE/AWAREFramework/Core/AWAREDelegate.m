//
//  AWAREDelegate.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 6/2/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWAREDelegate.h"
#import "AWAREKeys.h"
#import "AWAREEsmUtils.h"
#import "AWARECore.h"

// Sensors
#import "Debug.h"
#import "PushNotification.h"
#import "BalacnedCampusESMScheduler.h"
// #import "ESM.h"
#import "IOSESM.h"
#import "WebESM.h"
#import "Labels.h"
#import "GoogleCalPush.h"
#import "GoogleLogin.h"
#import "Observer.h"

#import "NXOAuth2.h"
#import "Fitbit.h"

@implementation AWAREDelegate{
    // AWARECoreDataMigrationManager * migrationManager;
}

/////////////////////////////////////////////////////

@synthesize sharedAWARECore = _sharedAWARECore;
- (AWARECore *) sharedAWARECoreManager {
    if(_sharedAWARECore == nil){
        _sharedAWARECore = [[AWARECore alloc] init];
    }
    return _sharedAWARECore;
}

////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    // [self setNotification:application];
    
    // Set background fetch for updating debug information
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];

    // Google Login Plugin
//    NSError* configureError;
//    [[GGLContext sharedInstance] configureWithError: &configureError];
//    NSAssert(!configureError, @"Error configuring Google services: %@", configureError);
//    [GIDSignIn sharedInstance].delegate = self;
    [GIDSignIn sharedInstance].clientID = GOOGLE_LOGIN_CLIENT_ID;
    [GIDSignIn sharedInstance].delegate = self;
    
    NSLog(@"Turn 'OFF' the auto sleep mode on this app");
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    // Error Tacking
    NSSetUncaughtExceptionHandler(&exceptionHandler);
    
    
    _sharedAWARECore = [[AWARECore alloc] init];
    [_sharedAWARECore activate];
    
    return YES;
}



- (void) setNotification:(UIApplication *)application {
    // [application unregisterForRemoteNotifications];
    
    if ([AWAREUtils getCurrentOSVersionAsFloat] >= 8.0) {
        // Set remote notifications
        [application registerForRemoteNotifications];
        // [application registerForRemoteNotificationTypes:(UIRemoteNotificationTypeNewsstandContentAvailability | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound)];
        
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
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    NSLog(@"Turn 'ON' the auto sleep mode on this app");
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    
    //[ESM setAppearedState:NO];
    [IOSESM setAppearedState:NO];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    
    NSLog(@"Turn 'OFF' the auto sleep mode on this app");
    [UIApplication sharedApplication].idleTimerDisabled = YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    NSLog(@"Turn 'OFF' the auto sleep mode on this app");
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:-1];
}


////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    //    [self saveContext];
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    if (notification){
        notification.repeatInterval = 0;
        notification.alertBody = @"Application is stopped! Please reboot this app for logging your acitivties.";
        notification.alertAction = @"Reboot";
        notification.soundName = UILocalNotificationDefaultSoundName;
        notification.applicationIconBadgeNumber = 1;
        [[UIApplication sharedApplication] scheduleLocalNotification:notification];
        
        
        Debug * debugSensor = [[Debug alloc] initWithAwareStudy:_sharedAWARECore.sharedAwareStudy dbType:AwareDBTypeTextFile];
        [debugSensor saveDebugEventWithText:notification.alertBody type:DebugTypeWarn label:@"stop"];
        [debugSensor syncAwareDB];
    }
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES forKey:KEY_APP_TERMINATED];
    
    NSLog(@"Stop background task of AWARE....");
    NSLog(@"Turn 'ON' the auto sleep mode on this app");
    [UIApplication sharedApplication].idleTimerDisabled = NO;
}

////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////
// https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIApplicationShortcutIcon_Class/#//apple_ref/c/tdef/UIApplicationShortcutIconType
// https://developer.apple.com/library/ios/documentation/General/Reference/InfoPlistKeyReference/Articles/iPhoneOSKeys.html#//apple_ref/doc/uid/TP40009252-SW36
// https://developer.apple.com/library/ios/documentation/UserExperience/Conceptual/Adopting3DTouchOniPhone/

- (void)application:(UIApplication *)application
performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem
  completionHandler:(void (^)(BOOL))completionHandler{
    if([shortcutItem.type isEqualToString:@"com.awareframework.aware-client-ios.shortcut.manualupload"]){
        [_sharedAWARECore.sharedSensorManager syncAllSensorsWithDBInForeground];
    }
}



//////////////////////////////////////////////////////////////////////////
///   Backgroud Fetch
/// https://mobiforge.com/design-development/using-background-fetch-ios
///////////////////////////////////////////////////////////////////////////
- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    /// NOTE: A background fetch method can work for 30 second. Also, the method is called randomly by OS.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        NSLog(@"Start a background fetch ...");
        
        // Send a survival signal to the AWARE server
        // [observer sendSurvivalSignal];
        
        // Upload debug messagaes in the background (Wi-Fi is required for this upload process.)
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
        NSString *formattedDateString = [dateFormatter stringFromDate:[NSDate new]];
        
        Debug * debug = [[Debug alloc] initWithAwareStudy:_sharedAWARECore.sharedAwareStudy dbType:AwareDBTypeTextFile];
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


///////////////////////////////////////
//  For Push Notification
///////////////////////////////////////

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    
    NSString *token = deviceToken.description;
    
    if([[NSUserDefaults standardUserDefaults] boolForKey:SETTING_DEBUG_STATE]){
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"deviceToken: %@", token);
            [AWAREUtils sendLocalNotificationForMessage:token soundFlag:YES];
        });
    }
    
    token = [token stringByReplacingOccurrencesOfString:@"<" withString:@""];
    token = [token stringByReplacingOccurrencesOfString:@">" withString:@""];
    token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
        
    PushNotification * pushNotification = [[PushNotification alloc] initWithAwareStudy:_sharedAWARECore.sharedAwareStudy dbType:AwareDBTypeCoreData];
    [pushNotification savePushNotificationDeviceToken:token];
    [pushNotification allowsCellularAccess];
    [pushNotification allowsDateUploadWithoutBatteryCharging];
    [pushNotification performSelector:@selector(syncAwareDBInForeground) withObject:nil afterDelay:3];
    
    NSLog(@"deviceToken: %@", token);
}

// Faile to get a DeviceToken
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"deviceToken error: %@", [error description]);
    
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
    AWAREStudy * awareStudy = _sharedAWARECore.sharedAwareStudy;
    if ([notification.category isEqualToString:SENSOR_PLUGIN_CAMPUS]) {
        BalacnedCampusESMScheduler * scheduler = [[BalacnedCampusESMScheduler alloc] initWithAwareStudy:awareStudy dbType:AwareDBTypeTextFile];
        [scheduler setESMWithUserInfo:notification.userInfo];
    } else if ([notification.category isEqualToString:SENSOR_PLUGIN_GOOGLE_CAL_PUSH]){
        GoogleCalPush * balancedCampusJournal = [[GoogleCalPush alloc] initWithAwareStudy:awareStudy dbType:AwareDBTypeTextFile];
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
    AWAREStudy * awareStudy = _sharedAWARECore.sharedAwareStudy;
    if ([identifier isEqualToString:@"calendar_update_action"]) {
        GoogleCalPush * balancedCampusJournal = [[GoogleCalPush alloc] initWithAwareStudy:awareStudy dbType:AwareDBTypeTextFile];
        [balancedCampusJournal makePrepopulateEvetnsWith:[NSDate new]];
    } else if ([identifier isEqualToString:@"add_label_action"]) {
        NSString * inputText = [responseInfo objectForKey:UIUserNotificationActionResponseTypedTextKey];
        Labels * labelSensor = [[Labels alloc] initWithAwareStudy:awareStudy dbType:AwareDBTypeTextFile];
        [labelSensor saveLabel:inputText
                       withKey:[userInfo objectForKey:@"key"]
                          type:identifier
                          body:notification.alertBody
                   triggerTime:notification.fireDate
                  answeredTime:[NSDate new]];
    } else if ([identifier isEqualToString:@"add_bool_action_yes"]){
        Labels * labelSensor = [[Labels alloc] initWithAwareStudy:awareStudy dbType:AwareDBTypeTextFile];
        [labelSensor saveLabel:@"1"
                       withKey:[userInfo objectForKey:@"key"]
                          type:identifier
                          body:notification.alertBody
                   triggerTime:notification.fireDate
                  answeredTime:[NSDate new]];
    } else if ([identifier isEqualToString:@"add_bool_action_no"]){
        Labels * labelSensor = [[Labels alloc] initWithAwareStudy:awareStudy dbType:AwareDBTypeTextFile];
        [labelSensor saveLabel:@"0"
                       withKey:[userInfo objectForKey:@"key"]
                          type:identifier
                          body:notification.alertBody
                   triggerTime:notification.fireDate
                  answeredTime:[NSDate new]];
    } else if ([identifier isEqualToString:@"edit_label_action"]){
//        NSString * inputText = [responseInfo objectForKey:UIUserNotificationActionResponseTypedTextKey];
//        ESM * esm = [[ESM alloc] initWithAwareStudy:awareStudy dbType:AwareDBTypeTextFile];
//        NSMutableDictionary *dic =  [AWAREEsmUtils getEsmFormatDictionary:(NSMutableDictionary *)notification.userInfo
//                                                             withTimesmap:[AWAREUtils getUnixTimestamp:notification.fireDate]
//                                                                  devieId:[awareStudy getDeviceId]];
//        //        [dic setObject:unixtime forKey:@"timestamp"];
//        [dic setObject:[AWAREUtils getUnixTimestamp:[NSDate new]] forKey:KEY_ESM_USER_ANSWER_TIMESTAMP];
//        [dic setObject:[awareStudy getDeviceId] forKey:@"device_id"];
//        [dic setObject:@2 forKey:KEY_ESM_STATUS];
//        [dic setObject:inputText forKey:KEY_ESM_USER_ANSWER];
//        [esm saveData:dic];
    } else if ([identifier isEqualToString:@"esm_answer_yes_action"]){
//        ESM * esm = [[ESM alloc] initWithAwareStudy:awareStudy dbType:AwareDBTypeTextFile];
//        NSMutableDictionary *dic =  [AWAREEsmUtils getEsmFormatDictionary:(NSMutableDictionary *)notification.userInfo
//                                                             withTimesmap:[AWAREUtils getUnixTimestamp:notification.fireDate]
//                                                                  devieId:[awareStudy getDeviceId]];
//        //        [dic setObject:unixtime forKey:@"timestamp"];
//        [dic setObject:[AWAREUtils getUnixTimestamp:[NSDate new]] forKey:KEY_ESM_USER_ANSWER_TIMESTAMP];
//        [dic setObject:[awareStudy getDeviceId] forKey:@"device_id"];
//        [dic setObject:@2 forKey:KEY_ESM_STATUS];
//        [dic setObject:@"YES" forKey:KEY_ESM_USER_ANSWER];
//        [esm saveData:dic];
    } else if ([identifier isEqualToString:@"esm_answer_no_action"]){
//        ESM * esm = [[ESM alloc] initWithAwareStudy:awareStudy dbType:AwareDBTypeTextFile];
//        NSMutableDictionary *dic =  [AWAREEsmUtils getEsmFormatDictionary:(NSMutableDictionary *)notification.userInfo
//                                                             withTimesmap:[AWAREUtils getUnixTimestamp:notification.fireDate]
//                                                                  devieId:[awareStudy getDeviceId]];
//        //        [dic setObject:unixtime forKey:@"timestamp"];
//        [dic setObject:[AWAREUtils getUnixTimestamp:[NSDate new]] forKey:KEY_ESM_USER_ANSWER_TIMESTAMP];
//        [dic setObject:[awareStudy getDeviceId] forKey:@"device_id"];
//        [dic setObject:@2 forKey:KEY_ESM_STATUS];
//        [dic setObject:@"NO" forKey:KEY_ESM_USER_ANSWER];
//        [esm saveData:dic];
    }
    
    
    //    }else if([identifier isEqualToString:@"esm_action"]){
    //        Scheduler * scheduler = [[Scheduler alloc] initWithSensorName:SENSOR_PLUGIN_SCHEDULER withAwareStudy:awareStudy];
    //        [scheduler setESMWithUserInfo:notification];
    //    }
    
    // Must be called when finished
    completionHandler();
}


/////////////////////////////////////////////////////////////////////////////
///// remote push notification

// This method is called then iOS receieved data by BackgroundFetch
- (void)application:(UIApplication *)application
didReceiveRemoteNotification:(NSDictionary *)userInfo
fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    NSLog(@"pushInfo in Background: %@", [userInfo description]);
    
    NSDictionary * awareAps= [userInfo objectForKey:@"aware-aps"];
    if(awareAps != nil){
        Observer * observer = [[Observer alloc] initWithAwareStudy:_sharedAWARECore.sharedAwareStudy dbType:AwareDBTypeTextFile];
        NSString *awareCategory = [awareAps objectForKey:@"category"];
        /////////////// refresh /////////////////
        if([awareCategory isEqualToString:@"refresh"]){
            [_sharedAWARECore.sharedAwareStudy refreshStudy];
            [observer sendSurvivalSignalWithCategory:awareCategory message:@"try"];
        /////////////// forcibly upload /////////////////
        }else if([awareCategory isEqualToString:@"upload"]){
            [_sharedAWARECore.sharedSensorManager syncAllSensorsWithDBInForeground];
            [observer sendSurvivalSignalWithCategory:awareCategory message:@"try"];
        /////////////// compliance check /////////////////
        }else if([awareCategory isEqualToString:@"compliance"]){
            // [WIP] New function
            [_sharedAWARECore checkCompliance];
            [observer sendComplianceState];
        /////////////// ping ///////////////////////
        }else if([awareCategory isEqualToString:@"ping"]){
            // [WIP] New function
            [observer sendSurvivalSignalWithCategory:awareCategory message:@"ping"];
            /////////////// ios_esm ///////////////////////
        }else if ([awareCategory isEqualToString:@"ios_esm"]){
            NSString * trigger = [userInfo objectForKey:@"trigger"];
            NSString * title = [userInfo objectForKey:@"title"];
            NSNumber * firedTimestamp = [AWAREUtils getUnixTimestamp:[NSDate new]];
            NSNumber * scheduledTimestamp = [userInfo objectForKey:@"schedule"];
            
            if([trigger isEqual:[NSNull null]] || trigger == nil){
                trigger = @"";
            }
            if([title  isEqual:[NSNull null]] || title == nil){
                title = @"";
            }
            if([scheduledTimestamp isEqual:[NSNull null]] || scheduledTimestamp == nil){
                scheduledTimestamp = [AWAREUtils getUnixTimestamp:[NSDate new]];
            }
            if(userInfo == NULL){
                userInfo = [[NSDictionary alloc] init];
            }
            
            IOSESM * iOSESM = [[IOSESM alloc] initWithAwareStudy:_sharedAWARECore.sharedAwareStudy dbType:AwareDBTypeCoreData];
            [iOSESM saveESMAnswerWithTimestamp:scheduledTimestamp
                                      deviceId:[_sharedAWARECore.sharedAwareStudy getDeviceId]
                                       esmJson:[iOSESM convertNSArraytoJsonStr:@[userInfo]]
                                    esmTrigger:trigger
                        esmExpirationThreshold:@0
                        esmUserAnswerTimestamp:firedTimestamp
                                 esmUserAnswer:title
                                     esmStatus:@0];
            
            // [WIP] New function
            [observer sendSurvivalSignalWithCategory:awareCategory message:@"recived a notification for iOS EMS."];
        /////////////// version check ///////////////////////
        }else if([awareCategory isEqualToString:@"version"]){
            NSString* version = [NSString stringWithFormat:@"%@",[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
            NSString *build = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
            if(build != nil){
                version = [version stringByAppendingFormat:@"(%@)", build];
            }
            [observer sendSurvivalSignalWithCategory:awareCategory message:version];
        /////////////// wifi ///////////////////////
        }else if([awareCategory isEqualToString:@"only_wifi"]){
            NSNumber * state = [awareAps objectForKey:@"value"];
            if(state != nil){
                if(state.intValue == 0){
                    [_sharedAWARECore.sharedAwareStudy setDataUploadStateInWifi:NO];
                }else{
                    [_sharedAWARECore.sharedAwareStudy setDataUploadStateInWifi:YES];
                }
                [observer sendSurvivalSignalWithCategory:awareCategory message:state.stringValue];
            }else{
                [observer sendSurvivalSignalWithCategory:awareCategory message:@"-1"];
            }
        /////////////// battery ///////////////////////
        }else if([awareCategory isEqualToString:@"only_battery"]){
            NSNumber * state = [awareAps objectForKey:@"value"];
            if(state != nil){
                if(state.intValue == 0){
                    [_sharedAWARECore.sharedAwareStudy setDataUploadStateWithOnlyBatterChargning:NO];
                }else{
                    [_sharedAWARECore.sharedAwareStudy setDataUploadStateWithOnlyBatterChargning:YES];
                }
                [observer sendSurvivalSignalWithCategory:awareCategory message:state.stringValue];
            }else{
                [observer sendSurvivalSignalWithCategory:awareCategory message:@"-1"];
            }
        /////////////// max upload length ///////////////////////
        }else if([awareCategory isEqualToString:@"max_upload_length"]){
            NSNumber * length = [awareAps objectForKey:@"value"];
            if(length != nil){
                [_sharedAWARECore.sharedAwareStudy setMaximumByteSizeForDataUpload:length.intValue];
                [observer sendSurvivalSignalWithCategory:awareCategory message:length.stringValue];
                [_sharedAWARECore.sharedSensorManager startAllSensors];
            }else{
                [observer sendSurvivalSignalWithCategory:awareCategory message:@"-1"];
            }
        ////////////// sync interval //////////////
        }else if([awareCategory isEqualToString:@"sync_interval_min"]){
            NSNumber * interval = [awareAps objectForKey:@"value"];
            if(interval != nil){
                [_sharedAWARECore.sharedAwareStudy setUploadIntervalWithMinutue:interval.intValue];
                int uploadInterval = [_sharedAWARECore.sharedAwareStudy getUploadIntervalAsSecond];
                [_sharedAWARECore.sharedSensorManager startUploadTimerWithInterval:uploadInterval];
                [observer sendSurvivalSignalWithCategory:awareCategory message:interval.stringValue];
            }else{
                [observer sendSurvivalSignalWithCategory:awareCategory message:@"-1"];
            }
        }
        
        if (awareCategory == nil) {
            awareCategory = @"unknown";
        }
        Debug * debugSensor = [[Debug alloc] initWithAwareStudy:[[AWAREStudy alloc] initWithReachability:YES] dbType:AwareDBTypeTextFile];
        [debugSensor saveDebugEventWithText:@"[notification] received a push notification" type:DebugTypeInfo label:awareCategory];
        
    }
    
    completionHandler(UIBackgroundFetchResultNoData);
}


/**
 * Notification handler for remote push notification
 */
- (void)application:(UIApplication *)application
handleActionWithIdentifier:(NSString *)identifier
forRemoteNotification:(NSDictionary *)userInfo
  completionHandler:(void (^)())completionHandler {
    
    // Get notification information from a userInfo variable
    
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



////////////////////////////////////////////
////////////////////////////////////////////

void exceptionHandler(NSException *exception) {
    // http://www.yoheim.net/blog.php?q=20130113
    //    NSLog(@"%@", exception.name);
    //    NSLog(@"%@", exception.reason);
    //    NSLog(@"%@", exception.callStackSymbols);
    //    NSString * error = [NSString stringWithFormat:@"[%@] %@ , %@" , exception.name, exception.reason, exception.callStackSymbols];
    
    Debug * debugSensor = [[Debug alloc] initWithAwareStudy:[[AWAREStudy alloc] initWithReachability:YES] dbType:AwareDBTypeTextFile];
    [debugSensor saveDebugEventWithText:exception.debugDescription type:DebugTypeCrash label:exception.name];
    [debugSensor syncAwareDB];
}



////////////////////////////////////////////////////////////////////////////////
//// For Google Login
///////////////////////////////////////////////////////////////////////////////


- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {

    if([[url scheme] isEqualToString:@"aware-client"] || [[url scheme] isEqualToString:@"aware"]){
        if([[url host] isEqualToString:@"com.aware.ios.study.settings"]){
            NSDictionary *dict = [AWAREUtils getDictionaryFromURLParameter:url];
            if (dict != nil) {
                NSString * studyURL = [dict objectForKey:@"study_url"];
                if(studyURL != nil){
                    [_sharedAWARECore.sharedAwareStudy setStudyInformationWithURL:studyURL];
                }
            }
        }else if([[url host] isEqualToString:@"com.aware.ios.oauth2"]){
            
            // return [Fitbit handleURL:url sourceApplication:sourceApplication annotation:annotation];
            
        }
        return YES;
    }else if([[url scheme] isEqualToString:@"fitbit"]){
        if([[url host] isEqualToString:@"logincallback"]){
            NSLog(@"Get a login call back");
            dispatch_async(dispatch_get_main_queue(), ^{
                // [Fitbit handleURL:url sourceApplication:sourceApplication annotation:annotation];
                Fitbit * fitbit = [[Fitbit alloc] initWithAwareStudy:_sharedAWARECore.sharedAwareStudy dbType:AwareDBTypeTextFile];
                [fitbit handleURL:url sourceApplication:sourceApplication annotation:annotation];
            });
            return YES;
        }else{
            NSLog(@"This is not a Get a login call back");
        }
        return YES;
    }else{
        return [[GIDSignIn sharedInstance] handleURL:url
                                   sourceApplication:sourceApplication
                                          annotation:annotation];
    }
    
}

- (void)signIn:(GIDSignIn *)signIn
didSignInForUser:(GIDGoogleUser *)user
     withError:(NSError *)error {
    // Perform any operations on signed in user here.
    NSString *userId = user.userID;                  // For client-side use only!
    // NSString *idToken = user.authentication.idToken; // Safe to send to the server
    NSString *name = user.profile.name;
    NSString *email = user.profile.email;
    
    if (name != nil ) {
        GoogleLogin * googleLogin = [[GoogleLogin alloc] initWithAwareStudy:_sharedAWARECore.sharedAwareStudy dbType:AwareDBTypeCoreData];
        [googleLogin setGoogleAccountWithUserId:userId name:name email:email];
    }
}


- (void)signIn:(GIDSignIn *)signIn
didDisconnectWithUser:(GIDGoogleUser *)user
     withError:(NSError *)error {
    // Perform any operations when the user disconnects from app here.
    // ...
    NSLog(@"Google login error..");
}


//////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////
///////////////////////////////////////////
////////////////////////////////////////////


#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory {
    // NSLog(@"%@",[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory  inDomains:NSUserDomainMask] lastObject]);
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"AWARE" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"AWARE.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    
    
    /*********** options  ***********/
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
                             nil];
    
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
//        abort();
    }
    
    return _persistentStoreCoordinator;
}


- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            // abort();
        }
    }
}

//- (BOOL)isRequiredMigration {
//    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"AWARE.sqlite"];
//    NSError* error = nil;
//    
//    NSDictionary* sourceMetaData = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:NSSQLiteStoreType
//                                                                                              URL:storeURL
//                                                                                            error:&error];
//    if (sourceMetaData == nil) {
//        return NO;
//    } else if (error) {
//        NSLog(@"Checking migration was failed (%@, %@)", error, [error userInfo]);
//        abort();
//    }
//    
//    BOOL isCompatible = [self.managedObjectModel isConfiguration:nil
//                                     compatibleWithStoreMetadata:sourceMetaData];
//    
//    return !isCompatible;
//}
//
//- (BOOL) doMigration {
//    NSLog(@"--- doMigration ---");
//    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"AWARE.sqlite"];
//    
//    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
//                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
//                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
//                             nil];
//    NSError *error = nil;
//    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
//    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error])
//    {
//        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
//        // abort();
//        return NO;
//    }
//    
//    return YES;//_persistentStoreCoordinator;
//}
//

@end
