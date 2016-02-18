//
//  Debug.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 2/4/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//
//  NOTE: Don't make an instance in a AWARESensor's constructer. The operation make infinity roop.
//

#import "Debug.h"
#import "AWAREKeys.h"

@implementation Debug {
    NSString * KEY_DEBUG_TIMESTAMP;
    NSString * KEY_DEBUG_DEVICE_ID;
    NSString * KEY_DEBUG_EVENT;
    NSString * KEY_DEBUG_TYPE;
    NSString * KEY_DEBUG_NETWORK;
    NSString * KEY_DEBUG_DEVICE;
    NSString * KEY_DEBUG_OS;
    NSString * KEY_DEBUG_APP_VERSION;
    NSString * KEY_DEBUG_LABEL;
    NSString * KEY_DEBUG_BATTERY;
    NSString * KEY_DEBUG_BATTERY_STATE;
    
    NSString* KEY_APP_VERSION;
    NSString* KEY_OS_VERSION;
    NSString* KEY_APP_INSTALL;
    
    NSTimer * timer;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *) study {
    self = [super initWithSensorName:@"aware_debug" withAwareStudy:study];
    if (self) {
        KEY_DEBUG_TIMESTAMP = @"timestamp";
        KEY_DEBUG_DEVICE_ID = @"device_id";
        KEY_DEBUG_EVENT = @"event";
        KEY_DEBUG_TYPE = @"type";
        KEY_DEBUG_LABEL= @"label";
        KEY_DEBUG_NETWORK = @"network";
        KEY_DEBUG_DEVICE = @"device";
        KEY_DEBUG_OS = @"os";
        KEY_DEBUG_APP_VERSION = @"app_version";
        KEY_DEBUG_BATTERY = @"battery";
        KEY_DEBUG_BATTERY_STATE = @"battery_state";
        
        
        KEY_APP_VERSION = @"key_application_history_app_version";
        KEY_OS_VERSION = @"key_application_history_os_version";
        KEY_APP_INSTALL = @"key_application_history_app_install";
    }
    return self;
}


- (void) createTable{
    NSMutableString *query = [[NSMutableString alloc] init];
    [query appendString:@"_id integer primary key autoincrement,"];
    [query appendString:[NSString stringWithFormat:@"%@ real default 0,", KEY_DEBUG_TIMESTAMP]];
    [query appendString:[NSString stringWithFormat:@"%@ text default '',", KEY_DEBUG_DEVICE_ID]];
    [query appendString:[NSString stringWithFormat:@"%@ text default '',", KEY_DEBUG_EVENT]];
    [query appendString:[NSString stringWithFormat:@"%@ integer default 0,", KEY_DEBUG_TYPE]];
    [query appendString:[NSString stringWithFormat:@"%@ text default '',", KEY_DEBUG_LABEL]];
    [query appendString:[NSString stringWithFormat:@"%@ text default '',", KEY_DEBUG_NETWORK]];
    [query appendString:[NSString stringWithFormat:@"%@ text default '',",KEY_DEBUG_APP_VERSION]];
    [query appendString:[NSString stringWithFormat:@"%@ text default '',",KEY_DEBUG_DEVICE]];
    [query appendString:[NSString stringWithFormat:@"%@ text default '',",KEY_DEBUG_OS]];
    [query appendString:[NSString stringWithFormat:@"%@ integer default 0,", KEY_DEBUG_BATTERY]];
    [query appendString:[NSString stringWithFormat:@"%@ integer default 0,", KEY_DEBUG_BATTERY_STATE]];
    [query appendString:@"UNIQUE (timestamp,device_id)"];
    [super createTable:query];
}


- (BOOL)startSensor:(double)upInterval withSettings:(NSArray *)settings{
    // Send a create table query
    NSLog(@"[%@] CreateTable!", [self getSensorName]);
    [self createTable];
    
    // Start a data upload timer
    NSLog(@"[%@] Start Sensor!", [self getSensorName]);
    timer = [NSTimer scheduledTimerWithTimeInterval:upInterval
                                             target:self
                                           selector:@selector(syncAwareDB)
                                           userInfo:nil
                                            repeats:YES];
    
    // Set a buffer for reducing file access
    [self setBufferSize:10];
    
    // Software Update Event
    NSString* currentVersion = [NSString stringWithFormat:@"%@",[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    // OS Update Event
    NSString* currentOsVersion = [[UIDevice currentDevice] systemVersion];
    
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    
    // App Install event
    if (![defaults boolForKey:KEY_APP_INSTALL]) {
        if ([self getDebugState]) {
            NSString* message = [NSString stringWithFormat:@"AWARE iOS is installed"];
            [AWAREUtils sendLocalNotificationForMessage:message soundFlag:YES];
        }
        NSString *updateInformation = [NSString stringWithFormat:@"[SOFTWARE INSTALL] %@", currentVersion];
        [self saveDebugEventWithText:updateInformation type:DebugTypeInfo label:@""];
    }else{
        // Application update event
        NSString* oldVersion = @"";
        if ([defaults stringForKey:KEY_APP_VERSION]) {
            oldVersion = [defaults stringForKey:KEY_APP_VERSION];
        }
        [defaults setObject:currentVersion forKey:KEY_APP_VERSION];
        
        if (![currentVersion isEqualToString:oldVersion]) {
            if ([self getDebugState]) {
                NSString* message = [NSString stringWithFormat:@"AWARE iOS is updated to %@", currentVersion];
                [AWAREUtils sendLocalNotificationForMessage:message soundFlag:YES];
            }
            NSString *updateInformation = [NSString stringWithFormat:@"[SOFTWARE UPDATE] %@", currentVersion];
            [self saveDebugEventWithText:updateInformation type:DebugTypeInfo label:@""];
        }
        
        // OS update event
        NSString* storedOsVersion = @"";
        if ([defaults stringForKey:KEY_OS_VERSION]) {
            storedOsVersion = [defaults stringForKey:KEY_OS_VERSION];
        }
        [defaults setObject:currentOsVersion forKey:KEY_OS_VERSION];
        
        if (![currentOsVersion isEqualToString:storedOsVersion]) {
            if ([self getDebugState]) {
                NSString* message = [NSString stringWithFormat:@"OS is updated to %@", currentOsVersion];
                [AWAREUtils sendLocalNotificationForMessage:message soundFlag:YES];
            }
            NSString *updateInformation = [NSString stringWithFormat:@"[OS UPDATE] %@", currentOsVersion];
            [self saveDebugEventWithText:updateInformation type:DebugTypeInfo label:@""];
        }
    }
    [defaults setBool:YES forKey:KEY_APP_INSTALL];
    [defaults setObject:currentVersion forKey:KEY_APP_VERSION];
    [defaults setObject:currentOsVersion forKey:KEY_OS_VERSION];
    
    return YES;
}

- (BOOL) stopSensor{
    if (timer != nil) {
        [timer invalidate];
        timer = nil;
    }
    return NO;
}



//////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////



- (void) saveDebugEventWithText:(NSString *)eventText type:(NSInteger)type label:(NSString *) label {
    if (eventText == nil) eventText = @"";
    if (label == nil) eventText = @"";
    
    NSString * osVersion = [[UIDevice currentDevice] systemVersion];
    NSString * deviceName = [AWAREUtils deviceName];
    NSString * appVersion = [NSString stringWithFormat:@"%@",[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    NSNumber * battery = [NSNumber numberWithInt:[[UIDevice currentDevice] batteryLevel] * 100];
    NSNumber * batterySate = [NSNumber numberWithInteger:[UIDevice currentDevice].batteryState];
    NSString * deviceId = [self getDeviceId];
    if (deviceId == nil || [deviceId isEqualToString:@""]) {
        deviceId = [AWAREUtils getSystemUUID];
    }
    
    NSMutableDictionary* dic = [[NSMutableDictionary alloc] init];
    [dic setObject:[AWAREUtils getUnixTimestamp:[NSDate new]] forKey:KEY_DEBUG_DEVICE_ID];
    [dic setObject:deviceId forKey:KEY_DEBUG_DEVICE_ID];
    [dic setObject:[AWAREUtils getUnixTimestamp:[NSDate new]] forKey:KEY_DEBUG_TIMESTAMP];
    [dic setObject:eventText forKey:KEY_DEBUG_EVENT];
    [dic setObject:[NSNumber numberWithInteger:type] forKey:KEY_DEBUG_TYPE];
    [dic setObject:label forKey:KEY_DEBUG_LABEL];
    [dic setObject:[self getNetworkReachabilityAsText] forKey:KEY_DEBUG_NETWORK];
    [dic setObject:appVersion forKey:KEY_DEBUG_APP_VERSION];
    [dic setObject:deviceName forKey:KEY_DEBUG_DEVICE];
    [dic setObject:osVersion forKey:KEY_DEBUG_OS];
    [dic setObject:battery forKey:KEY_DEBUG_BATTERY];
    [dic setObject:batterySate forKey:KEY_DEBUG_BATTERY_STATE];
    
    // Set latest sensor data
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setDateFormat:@"MM-dd HH:mm"];
    NSString * dateStr = [timeFormat stringFromDate:[NSDate new]];
    NSString * latestEvent = [NSString stringWithFormat:@"[%@] %@", dateStr, eventText];
    [super setLatestValue: latestEvent];
    
    // Save a call event
    [super saveData:dic];
}


/**
 * ===========
 * For CoreData
 * ===========
 */
//#pragma mark - Core Data stack
//
//@synthesize managedObjectContext = _managedObjectContext;
//@synthesize managedObjectModel = _managedObjectModel;
//@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
//
//- (NSURL *)applicationDocumentsDirectory {
//    // The directory the application uses to store the Core Data store file. This code uses a directory named "jp.ac.keio.sfc.ht.tetujin.AWARE" in the application's documents directory.
//    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
//}
//
//- (NSManagedObjectModel *)managedObjectModel {
//    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
//    if (_managedObjectModel != nil) {
//        return _managedObjectModel;
//    }
//    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Debug" withExtension:@"momd"];
//    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
//    return _managedObjectModel;
//}
//
//- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
//    // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it.
//    if (_persistentStoreCoordinator != nil) {
//        return _persistentStoreCoordinator;
//    }
//
//    // Create the coordinator and store
//
//    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
//    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Debug.sqlite"];
//    NSError *error = nil;
//    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
//    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
//        // Report any error we got.
//        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
//        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
//        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
//        dict[NSUnderlyingErrorKey] = error;
//        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
//        // Replace this with code to handle the error appropriately.
//        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
//        abort();
//    }
//
//    return _persistentStoreCoordinator;
//}
//
//
//- (NSManagedObjectContext *)managedObjectContext {
//    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
//    if (_managedObjectContext != nil) {
//        return _managedObjectContext;
//    }
//
//    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
//    if (!coordinator) {
//        return nil;
//    }
//    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
//    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
//    return _managedObjectContext;
//}
//
//#pragma mark - Core Data Saving support
//
//- (void)saveContext {
//    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
//    if (managedObjectContext != nil) {
//        NSError *error = nil;
//        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
//            // Replace this implementation with code to handle the error appropriately.
//            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
//            abort();
//        }
//    }
//}


@end
