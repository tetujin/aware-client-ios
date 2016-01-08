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
#import "GoogleLogin.h"
#import "DeployGateSDK/DeployGateSDK.h"

//#define NSLog DGSLog

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    //[defaults setInteger:[[self.fps text] integerValue] forKey:KEY_FPS];
    [defaults setBool:YES forKey:@"APP_STATE"];
    
    [application unregisterForRemoteNotifications];
    
    // Get OS version
    CGFloat currentVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    NSLog(@"OS:%f", currentVersion);
    if (currentVersion >= 8.0) {
        [application registerForRemoteNotifications];
        
        // For Push Notification and Background Fetch
        UIUserNotificationType types =
        UIUserNotificationTypeBadge|
        UIUserNotificationTypeSound|
        UIUserNotificationTypeNone|
        UIUserNotificationTypeAlert;
        UIUserNotificationSettings *mySettings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
        [application registerUserNotificationSettings:mySettings];
        [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    }else{
        UIRemoteNotificationType remoteNotificationType =
        UIRemoteNotificationTypeBadge|
        UIRemoteNotificationTypeSound|
        UIRemoteNotificationTypeAlert;
        //   |UIRemoteNotificationTypeNewsstandContentAvailability;
        [application registerForRemoteNotificationTypes:remoteNotificationType];
    }
    
    // For Google Auth API
    NSError* configureError;
    [[GGLContext sharedInstance] configureWithError: &configureError];
    NSAssert(!configureError, @"Error configuring Google services: %@", configureError);
    [GIDSignIn sharedInstance].delegate = self;
    
    
    [[DeployGateSDK sharedInstance] launchApplicationWithAuthor:@"tetujin" key:@"b268f60ae48ecfca7352c0a01918c86a7bd4bc74"];
    
    
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:NO forKey:@"APP_STATE"];
    
    NSLog(@"Go to background 1");
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:NO forKey:@"APP_STATE"];
    NSLog(@"Go to background 2");
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES forKey:@"APP_STATE"];
    NSLog(@"Go to fourground");
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    //    http://d.hatena.ne.jp/glass-_-onion/20120405/1333611664
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    //[defaults setInteger:[[self.fps text] integerValue] forKey:KEY_FPS];
    [defaults setBool:YES forKey:@"APP_STATE"];
    NSLog(@"Go to fourground");
    
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:-1];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
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
    
    [defaults setBool:NO forKey:@"APP_STATE"];
    NSLog(@"Stop background task of AWARE....");
}

// for DeplyGate
//- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
//    return [[DeployGateSDK sharedInstance] handleOpenUrl:url sourceApplication:sourceApplication annotation:annotation];
//}

// for Google Auth
- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    
    return [[GIDSignIn sharedInstance] handleURL:url
                               sourceApplication:sourceApplication
                                      annotation:annotation];
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    NSLog(@"This is background fetch result!");
    completionHandler(UIBackgroundFetchResultNewData);
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
     Store the completion handler. The completion handler is invoked by the view            controller's checkForAllDownloadsHavingCompleted method (if all the download tasks have been            completed).
     */
//    self.backgroundSessionCompletionHandler = completionHandler;
}


// Success to get a DeviceToken
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



- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    if (notification != nil) {
        NSLog(@"Nofication was selected!!: %@", notification.category);
//        NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
//        [defaults setObject:notification.category forKey:@"schedule_id"];
        // Get category id -> "category id is schdule_id"
//        NSString * scheduleId = notification.category;
//        AWAREScheduleManager *scheduleManager = [[AWAREScheduleManager alloc] init];
//        AWARESchedule *schedule = [scheduleManager getScheduleByScheduleId:scheduleId];
//        NSLog(@"--> %@", schedule.title);
//        [scheduleManager addEsmObject:schedule.esmObject];
    } else {
        NSLog(@"-------");
    }
    
//    NSLog(@"Stop background task of AWARE....");
//    AppDelegate *appDelegate;
//    appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
//    singleView.text = appDelegate.singleString;
    
}

#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "jp.ac.keio.sfc.ht.tetujin.AWARE" in the application's documents directory.
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
    // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"AWARE.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
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
    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
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
            abort();
        }
    }
}






- (void)signIn:(GIDSignIn *)signIn
didSignInForUser:(GIDGoogleUser *)user
     withError:(NSError *)error {
    // Perform any operations on signed in user here.
    NSString *userId = user.userID;                  // For client-side use only!
    NSString *idToken = user.authentication.idToken; // Safe to send to the server
    NSString *name = user.profile.name;
    NSString *email = user.profile.email;
    NSLog(@"user id is %@", userId);
    NSLog(@"name is %@", name);
    NSLog(@"email is %@", email);
    NSLog(@"idToken is %@", idToken);
    
    GoogleLogin * googleLogin = [[GoogleLogin alloc] initWithSensorName:SENSOR_PLUGIN_GOOGLE_LOGIN];
    if (name != nil ) {
        [googleLogin saveName:name withEmail:email];
        NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:userId forKey:@"GOOGLE_ID"];
        [defaults setObject:name forKey:@"GOOGLE_NAME"];
        [defaults setObject:email forKey:@"GOOGLE_EMAIL"];
        [defaults setObject:idToken forKey:@"GOOGLE_ID_TOKEN"];
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
        
        NSLog(@"You chose action 1.");
    }
    else if ([identifier isEqualToString:NotificationActionTwoIdent]) {
        
        NSLog(@"You chose action 2.");
    }
    if (completionHandler) {
        
        completionHandler();
    }
}

@end
