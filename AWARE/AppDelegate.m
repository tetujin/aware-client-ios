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


@implementation AppDelegate{
    AWAREStudy * awareStudy;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    awareStudy = [[AWAREStudy alloc] init];
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES forKey:@"APP_STATE"];
    
    [application unregisterForRemoteNotifications];
    
    if ([AWAREUtils getCurrentOSVersionAsFloat] >= 8.0) {
        // Set Notifications
        [application registerForRemoteNotifications];
        UIUserNotificationType types = UIUserNotificationTypeBadge|
                                       UIUserNotificationTypeSound|
                                       UIUserNotificationTypeNone|
                                       UIUserNotificationTypeAlert;
        UIUserNotificationSettings *mySettings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
        [application registerUserNotificationSettings:mySettings];
        [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    }
    
    // DeployGate SDK
    [[DeployGateSDK sharedInstance] launchApplicationWithAuthor:@"[user name]" key:@"[api key]"];
    
    // WIP: Set background fetch
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    
    // Google Login Plugin
    NSError* configureError;
    [[GGLContext sharedInstance] configureWithError: &configureError];
    NSAssert(!configureError, @"Error configuring Google services: %@", configureError);
    [GIDSignIn sharedInstance].delegate = self;
    
    // Microsoft Band Plugin
//    AWAREStudy * awareStudy = [[AWAREStudy alloc] init];
//    MSBand * awareSensor = [[MSBand alloc] initWithPluginName:SENSOR_PLUGIN_MSBAND awareStudy:awareStudy];
//    [awareSensor startSensor:60*15 withSettings:[awareStudy getPlugins]];
//    [awareSensor trackDebugEvents];
    
    
    NSLog(@"Turn 'OFF' the auto sleep mode on this app");
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    // Error Tacking
    NSSetUncaughtExceptionHandler(&exceptionHandler);
    
    // Battery Save Mode
    if([AWAREUtils getCurrentOSVersionAsFloat] >= 9.0){
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(powerStateDidChange:)
                                                     name:NSProcessInfoPowerStateDidChangeNotification
                                                   object:nil];
    }
    return YES;
}


void exceptionHandler(NSException *exception) {
    // http://www.yoheim.net/blog.php?q=20130113
    NSLog(@"%@", exception.name);
    NSLog(@"%@", exception.reason);
    NSLog(@"%@", exception.callStackSymbols);
    
    NSString * error = [NSString stringWithFormat:@"[%@] %@ , %@" , exception.name, exception.reason, exception.callStackSymbols];
    
    Debug * debugSensor = [[Debug alloc] initWithAwareStudy:nil];
    [debugSensor saveDebugEventWithText:error type:DebugTypeCrash label:exception.name];
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


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
//    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
//    [defaults setBool:NO forKey:@"APP_STATE"];
//    NSLog(@"Go to background 1");
    [AWAREUtils setAppState:NO];
    
//    NSLog(@"Turn 'ON' the auto sleep mode on this app");
//    [UIApplication sharedApplication].idleTimerDisabled = NO;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
//    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
//    [defaults setBool:NO forKey:@"APP_STATE"];
//    NSLog(@"Go to background 2");
    [AWAREUtils setAppState:NO];
    
    NSLog(@"Turn 'ON' the auto sleep mode on this app");
    [UIApplication sharedApplication].idleTimerDisabled = NO;
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
//    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
//    [defaults setBool:YES forKey:@"APP_STATE"];
//    NSLog(@"Go to fourground");
    [AWAREUtils setAppState:YES];
    
    NSLog(@"Turn 'OFF' the auto sleep mode on this app");
    [UIApplication sharedApplication].idleTimerDisabled = YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    //    http://d.hatena.ne.jp/glass-_-onion/20120405/1333611664
//    [defaults setBool:YES forKey:@"APP_STATE"];
//    NSLog(@"Go to fourground");
    [AWAREUtils setAppState:YES];
    
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
        //        notification.timeZone = [NSTimeZone defaultTimeZone];
        notification.repeatInterval = 0;
        notification.alertBody = @"Application is stoped! Please reboot this app for logging your acitivties.";
        notification.alertAction = @"Reboot";
        notification.soundName = UILocalNotificationDefaultSoundName;
        notification.applicationIconBadgeNumber = 1;
        [[UIApplication sharedApplication] scheduleLocalNotification:notification];
    }
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES forKey:KEY_APP_TERMINATED];
    
//    [defaults setBool:NO forKey:@"APP_STATE"];
    [AWAREUtils setAppState:NO];
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
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        NSLog(@"Start a background fetch ...");
        /// for 30 sec
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

@end
