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
#import "EntityDebug.h"
#import "AppDelegate.h"

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
    AWAREStudy * awareStudy;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *) study {
    
    return self = [self initWithAwareStudy:study
                  sensorName:@"aware_debug"
                dbEntityName:NSStringFromClass([EntityDebug class])
                      dbType:AwareDBTypeTextFile];
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study
                        sensorName:(NSString *)sensorName
                      dbEntityName:(NSString *)entityName
                            dbType:(AwareDBType)dbType{
    self = [super initWithAwareStudy:study
                          sensorName:sensorName
                        dbEntityName:entityName
                              dbType:dbType];
    if (self) {
        awareStudy = study;
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
    
    NSLog(@"[%@] CreateTable!", [self getSensorName]);
    
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


- (BOOL)startSensorWithSettings:(NSArray *)settings{
    
    // Start a data upload timer
    NSLog(@"[%@] Start Sensor!", [self getSensorName]);
    
    // Set a buffer for reducing file access
    [self setBufferSize:10];
    
    // Software Update Event
    NSString* currentVersion = [NSString stringWithFormat:@"%@",[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    // OS Update Event
    NSString* currentOsVersion = [[UIDevice currentDevice] systemVersion];
    
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    
    // App Install event
    if (![defaults boolForKey:KEY_APP_INSTALL]) {
        if ([self isDebug]) {
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
            if ([self isDebug]) {
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
            if ([self isDebug]) {
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
    return YES;
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
    
    if([self getDBType] == AwareDBTypeTextFile){
        NSMutableDictionary* dic = [[NSMutableDictionary alloc] init];
        [dic setObject:[AWAREUtils getUnixTimestamp:[NSDate new]] forKey:KEY_DEBUG_DEVICE_ID];
        [dic setObject:deviceId forKey:KEY_DEBUG_DEVICE_ID];
        [dic setObject:[AWAREUtils getUnixTimestamp:[NSDate new]] forKey:KEY_DEBUG_TIMESTAMP];
        [dic setObject:eventText forKey:KEY_DEBUG_EVENT];
        [dic setObject:[NSNumber numberWithInteger:type] forKey:KEY_DEBUG_TYPE];
        [dic setObject:label forKey:KEY_DEBUG_LABEL];
        [dic setObject:[awareStudy getNetworkReachabilityAsText] forKey:KEY_DEBUG_NETWORK];
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
        // Save a call event (if this class is using TextFile based database)
        [super saveData:dic];
    }else if([self getDBType] == AwareDBTypeCoreData){
        AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
        EntityDebug* debugData = (EntityDebug *)[NSEntityDescription
                                                             insertNewObjectForEntityForName:NSStringFromClass([EntityDebug class])
                                                             inManagedObjectContext:delegate.managedObjectContext];
        debugData.device_id = [self getDeviceId];
        debugData.timestamp = [AWAREUtils getUnixTimestamp:[NSDate new]];
        debugData.app_version = appVersion;
        debugData.battery = battery;
        debugData.battery_state = batterySate;
        debugData.device = deviceName;
        debugData.event = eventText;
        debugData.label = label;
        debugData.network = [awareStudy getNetworkReachabilityAsText];
        debugData.os = osVersion;
        debugData.type = @(type);
    
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:debugData
                                                             forKey:EXTRA_DATA];
        [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_DEBUG
                                                            object:nil
                                                          userInfo:userInfo];
        
        NSError * error = nil;
        [delegate.managedObjectContext save:&error];
        if (error) {
            NSLog(@"%@", error.description);
        }
    }
}

- (void)syncAwareDB{
    [super syncAwareDB];
}

@end
