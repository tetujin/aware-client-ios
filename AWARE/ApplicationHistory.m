//
//  ApplicationHistory.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 1/27/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "ApplicationHistory.h"
#import "AWAREKeys.h"

@implementation ApplicationHistory {
    NSTimer *timer;
    NSString* KEY_TIMESTAMP;// = @"timestamp";
    NSString* KEY_DEVICE_ID;// = @"device_id";
    NSString* KEY_PACKAGE_NAME;
    NSString* KEY_APPLICATION_NAME;
    NSString* KEY_PROCESS_IMPORTANCE;
    NSString* KEY_PROCESS_ID;
    NSString* KEY_DOUBLE_END_TIMESTAMP;
    NSString* KEY_IS_SYSTEM_APP;
    
    NSString* KEY_APP_VERSION;
    NSString* KEY_OS_VERSION;
    NSString* KEY_APP_INSTALL;
    bool isTest;
}

- (instancetype)initWithSensorName:(NSString *)sensorName{
    self = [super initWithSensorName: SENSOR_APPLICATION_HISTORY];
    if (self) {
//        [super setSensorName:sensorName];
        KEY_TIMESTAMP = @"timestamp";
        KEY_DEVICE_ID = @"device_id";
        KEY_PACKAGE_NAME = @"package_name";
        KEY_APPLICATION_NAME = @"application_name";
        KEY_PROCESS_IMPORTANCE = @"process_importance";
        KEY_PROCESS_ID = @"process_id";
        KEY_DOUBLE_END_TIMESTAMP = @"double_end_timestamp";
        KEY_IS_SYSTEM_APP = @"is_system_app";
        KEY_APP_VERSION = @"key_application_history_app_version";
        KEY_OS_VERSION = @"key_application_history_os_version";
        KEY_APP_INSTALL = @"key_application_history_app_install";
        isTest = NO;
        if (isTest) {
            NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
            [defaults removeObjectForKey:KEY_APP_VERSION];
            [defaults removeObjectForKey:KEY_OS_VERSION];
            [defaults removeObjectForKey:KEY_APP_INSTALL];
            
            [defaults setObject:@"hoge" forKey:KEY_OS_VERSION];
            [defaults setObject:@"hello" forKey:KEY_APP_VERSION];
        }
    }
    return self;
}


- (void) createTable{
    NSMutableString *query = [[NSMutableString alloc] init];
    [query appendString:@"_id integer primary key autoincrement,"];
    [query appendString:[NSString stringWithFormat:@"%@ real default 0,", KEY_TIMESTAMP]];
    [query appendString:[NSString stringWithFormat:@"%@ text default '',", KEY_DEVICE_ID]];
    [query appendString:[NSString stringWithFormat:@"%@ text default '',", KEY_PACKAGE_NAME]];
    [query appendString:[NSString stringWithFormat:@"%@ text default '',", KEY_APPLICATION_NAME]];
    [query appendString:[NSString stringWithFormat:@"%@ integer default 0,", KEY_PROCESS_IMPORTANCE]];
    [query appendString:[NSString stringWithFormat:@"%@ integer default 0,", KEY_PROCESS_ID]];
    [query appendString:[NSString stringWithFormat:@"%@ real default 0,", KEY_DOUBLE_END_TIMESTAMP]];
    [query appendString:[NSString stringWithFormat:@"%@ integer default 0,", KEY_IS_SYSTEM_APP]];
    [query appendString:@"UNIQUE (timestamp,device_id)"];
    
    [super createTable:query];
}


-(BOOL)startSensor:(double)upInterval withSettings:(NSArray *)settings{
    NSLog(@"[%@] Create Table", [self getSensorName]);
    [self createTable];
    
    NSLog(@"[%@] Start Sensor!", [self getSensorName]);
    timer = [NSTimer scheduledTimerWithTimeInterval:upInterval
                                             target:self selector:@selector(syncAwareDB) userInfo:nil repeats:YES];
    
    // Software Update Event
    NSString* currentVersion = [NSString stringWithFormat:@"%@",[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    // OS Update Event
    NSString* currentOsVersion = [[UIDevice currentDevice] systemVersion];
    
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    
    // App Install event
    if (![defaults boolForKey:KEY_APP_INSTALL]) {
        if ([self getDebugState]) {
            NSString* message = [NSString stringWithFormat:@"AWARE iOS is installed"];
            [self sendLocalNotificationForMessage:message soundFlag:YES];
        }
        NSString *updateInformation = [NSString stringWithFormat:@"[SOFTWARE INSTALL] %@", currentVersion];
        [self storeApplicationEvent:updateInformation];
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
                [self sendLocalNotificationForMessage:message soundFlag:YES];
            }
            NSString *updateInformation = [NSString stringWithFormat:@"[SOFTWARE UPDATE] %@", currentVersion];
            [self storeApplicationEvent:updateInformation];
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
                [self sendLocalNotificationForMessage:message soundFlag:YES];
            }
            NSString *updateInformation = [NSString stringWithFormat:@"[OS UPDATE] %@", currentOsVersion];
            [self storeApplicationEvent:updateInformation];
        }
    }
    [defaults setBool:YES forKey:KEY_APP_INSTALL];
    [defaults setObject:currentVersion forKey:KEY_APP_VERSION];
    [defaults setObject:currentOsVersion forKey:KEY_OS_VERSION];
    
    return YES;
}

- (bool) storeApplicationEvent:(NSString*) event {
    NSString *deviceId = [AWAREUtils getSystemUUID];
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    NSNumber * updateDate = [AWAREUtils getUnixTimestamp:[NSDate new]];
    [dic setObject:updateDate forKey:KEY_TIMESTAMP];
    [dic setObject:deviceId forKey:KEY_DEVICE_ID];
    [dic setObject:@"AWARE iOS" forKey:KEY_PACKAGE_NAME];
    [dic setObject:event forKey:KEY_APPLICATION_NAME];
    [dic setObject:@0 forKey:KEY_PROCESS_IMPORTANCE];
    [dic setObject:@0 forKey:KEY_PROCESS_ID];
    [dic setObject:updateDate forKey:KEY_DOUBLE_END_TIMESTAMP];
    [dic setObject:@0 forKey:KEY_IS_SYSTEM_APP];
    [self saveData:dic];
    return YES;
}

-(BOOL) stopSensor{
    if (timer != nil) {
        [timer invalidate];
        timer = nil;
    }

    return YES;
}
@end
