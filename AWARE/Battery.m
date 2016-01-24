//
//  Battery.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/20/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "Battery.h"

@implementation Battery{
    NSTimer *uploadTimer;
//    NSTimer *sensingTimer;
    
    NSString* BATTERY_DISCHARGERES;
    NSString* BATTERY_CHARGERES;
    
    NSString* KEY_LAST_BATTERY_EVENT;
    NSString* KEY_LAST_BATTERY_EVENT_TIMESTAMP;
    NSString* KEY_LAST_BATTERY_LEVEL;
    
    AWARESensor * batteryChargeSensor;
    AWARESensor * batteryDischargeSensor;
    
//    NSInteger lastBatteryEvent;
//    NSNumber *lastBatteryEventTimestamp;
//    int lastBatteryLevel;
}

- (instancetype)initWithSensorName:(NSString *)sensorName{
    self = [super initWithSensorName:sensorName];
    if (self) {
        [super setSensorName:sensorName];
        BATTERY_DISCHARGERES = @"battery_discharges";
        BATTERY_CHARGERES = @"battery_charges";
        
        // keys for local storage
        KEY_LAST_BATTERY_EVENT = @"key_last_battery_event";
        KEY_LAST_BATTERY_EVENT_TIMESTAMP = @"key_last_battery_event_timestamp";
        KEY_LAST_BATTERY_LEVEL = @"key_last_battery_level";
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        if (![userDefaults integerForKey:KEY_LAST_BATTERY_EVENT_TIMESTAMP]) {
            // lastBatteryEvent = UIDeviceBatteryStateUnknown;
            [userDefaults setInteger:UIDeviceBatteryStateUnknown forKey:KEY_LAST_BATTERY_EVENT];
            // lastBatteryEventTimestamp = [self getUnixtimeWithNSDate:[NSDate new]];
            [userDefaults setObject:[AWAREUtils getUnixTimestamp:[NSDate new]] forKey:KEY_LAST_BATTERY_EVENT_TIMESTAMP];
            // lastBatteryEvent = [UIDevice currentDevice].batteryLevel * 100;
            [userDefaults setInteger:[UIDevice currentDevice].batteryLevel*100 forKey:KEY_LAST_BATTERY_LEVEL];
        }
        // Get default information from local storage
        
        batteryChargeSensor = [[AWARESensor alloc] initWithSensorName:BATTERY_CHARGERES];
        batteryDischargeSensor = [[AWARESensor alloc] initWithSensorName:BATTERY_DISCHARGERES];
    }
    return self;
}

//http://stackoverflow.com/questions/9515479/monitor-and-detect-if-the-iphone-is-plugged-in-and-charging-wifi-connected-when

//https://developer.apple.com/library/ios/samplecode/BatteryStatus/Introduction/Intro.html

- (void) createTable{
    NSString *query = [[NSString alloc] init];
    query = @"_id integer primary key autoincrement,"
    "timestamp real default 0,"
    "device_id text default '',"
    "battery_status integer default 0,"
    "battery_level integer default 0,"
    "battery_scale integer default 0,"
    "battery_voltage integer default 0,"
    "battery_temperature integer default 0,"
    "battery_adaptor integer default 0,"
    "battery_health integer default 0,"
    "battery_technology text default '',"
    "UNIQUE (timestamp,device_id)";
    [super createTable:query];
}

- (void) createDichargeTable {
    NSString *query = [[NSString alloc] init];
    query = @"_id integer primary key autoincrement,"
    "timestamp real default 0,"
    "device_id text default '',"
    "battery_start integer default 0,"
    "battery_end integer default 0,"
    "double_end_timestamp real default 0,"
    "UNIQUE (timestamp,device_id)";
    [batteryDischargeSensor createTable:query];
}


- (void) createCargeTable {
    NSString *query = [[NSString alloc] init];
    query = @"_id integer primary key autoincrement,"
    "timestamp real default 0,"
    "device_id text default '',"
    "battery_start integer default 0,"
    "battery_end integer default 0,"
    "double_end_timestamp real default 0,"
    "UNIQUE (timestamp,device_id)";
    [batteryChargeSensor createTable:query];
}

- (BOOL)startSensor:(double)upInterval withSettings:(NSArray *)settings{
    [self createTable];
    [self createCargeTable];
    [self createDichargeTable];
    
    [UIDevice currentDevice].batteryMonitoringEnabled = YES;
    
    NSLog(@"upload interval is %f.", upInterval);
    uploadTimer = [NSTimer scheduledTimerWithTimeInterval:upInterval target:self selector:@selector(syncAwareDBWithAllBatterySensor:) userInfo:nil repeats:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(batteryLevelChanged:)
                                                 name:UIDeviceBatteryLevelDidChangeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(batteryStateChanged:)
                                                 name:UIDeviceBatteryStateDidChangeNotification object:nil];
    return YES;
}


- (void)batteryLevelChanged:(NSNotification *)notification {
    UIDevice *myDevice = [UIDevice currentDevice];
    [myDevice setBatteryMonitoringEnabled:YES];
    int state = [myDevice batteryState];
    //    NSLog(@"battery status: %d",state); // 0 unknown, 1 unplegged, 2 charging, 3 full
    int batLeft = [myDevice batteryLevel] * 100;
    
//    double timeStamp = [[NSDate date] timeIntervalSince1970] * 1000;
//    NSNumber* unixtime = [NSNumber numberWithLong:timeStamp];
    NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setObject:unixtime forKey:@"timestamp"];
    [dic setObject:[self getDeviceId] forKey:@"device_id"];
    [dic setObject:[NSNumber numberWithInt:state] forKey:@"battery_status"];
    [dic setObject:[NSNumber numberWithInt:batLeft] forKey:@"battery_level"];
    [dic setObject:@100 forKey:@"battery_scale"];
    [dic setObject:@0 forKey:@"battery_voltage"];
    [dic setObject:@0 forKey:@"battery_temperature"];
    [dic setObject:@0 forKey:@"battery_adaptor"];
    [dic setObject:@0 forKey:@"battery_health"];
    [dic setObject:@"" forKey:@"battery_technology"];
    [self setLatestValue:[NSString stringWithFormat:@"%d", batLeft]];
    [self saveData:dic toLocalFile:SENSOR_BATTERY];
}


- (void)batteryStateChanged:(NSNotification *)notification {
    // Get current values
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSInteger lastBatteryEvent = [userDefaults integerForKey:KEY_LAST_BATTERY_EVENT];
    // lastBatteryEventTimestamp = [self getUnixtimeWithNSDate:[NSDate new]];
    NSNumber * lastBatteryEventTimestamp = [userDefaults objectForKey:KEY_LAST_BATTERY_EVENT_TIMESTAMP];
    // lastBatteryEvent = [UIDevice currentDevice].batteryLevel * 100;
    NSNumber* lastBatteryLevel = [userDefaults objectForKey:KEY_LAST_BATTERY_LEVEL];
    
    
    NSInteger currentBatteryEvent = UIDeviceBatteryStateUnknown;
    switch ([UIDevice currentDevice].batteryState) {
        case UIDeviceBatteryStateCharging:
            currentBatteryEvent = UIDeviceBatteryStateCharging;
//            [self sendLocalNotificationForMessage:@"Battery Charging Event" soundFlag:NO];
            break;
        case UIDeviceBatteryStateFull:
            currentBatteryEvent = UIDeviceBatteryStateFull;
//            [self sendLocalNotificationForMessage:@"Battery Full Event" soundFlag:NO];
            break;
        case UIDeviceBatteryStateUnknown:
            currentBatteryEvent = UIDeviceBatteryStateUnknown;
//            [self sendLocalNotificationForMessage:@"Battery Unknown Event" soundFlag:NO];
            break;
        case UIDeviceBatteryStateUnplugged:
            currentBatteryEvent = UIDeviceBatteryStateUnplugged;
//            [self sendLocalNotificationForMessage:@"Battery Unplugged Event" soundFlag:NO];
            break;
        default:
            currentBatteryEvent = UIDeviceBatteryStateUnknown;
//            [self sendLocalNotificationForMessage:@"Battery Unknown Event" soundFlag:NO];
            break;
    };
    
//    NSNumber * currentTime = [self getUnixtimeWithNSDate:[NSDate new]];
    NSNumber * currentTime = [AWAREUtils getUnixTimestamp:[NSDate new]];
    int battery = [UIDevice currentDevice].batteryLevel * 100;
    NSNumber * currentBatteryLevel = [NSNumber numberWithInt:battery];

    // discharge event
    if (lastBatteryEvent == UIDeviceBatteryStateUnplugged &&
        currentBatteryEvent == UIDeviceBatteryStateCharging) {
//        [self sendLocalNotificationForMessage:@"Save Discharge Event" soundFlag:NO];
        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
        [dic setObject:lastBatteryEventTimestamp forKey:@"timestamp"];
        [dic setObject:[self getDeviceId] forKey:@"device_id"];
        [dic setObject:lastBatteryLevel forKey:@"battery_start"];
        [dic setObject:currentBatteryLevel forKey:@"battery_end"];
        [dic setObject:currentTime forKey:@"double_end_timestamp"];
        [batteryDischargeSensor saveData:dic];
        // save the last event information
//        lastBatteryEventTimestamp = currentTime;
//        lastBatteryLevel = battery;
        [userDefaults setObject:currentBatteryLevel forKey:KEY_LAST_BATTERY_LEVEL];
        [userDefaults setObject:currentTime forKey:KEY_LAST_BATTERY_EVENT_TIMESTAMP];
    // charge event
    }else if(lastBatteryEvent == UIDeviceBatteryStateCharging &&
             currentBatteryEvent == UIDeviceBatteryStateUnplugged ){
//        [self sendLocalNotificationForMessage:@"Save Charge Event" soundFlag:NO];
        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
        [dic setObject:lastBatteryEventTimestamp forKey:@"timestamp"];
        [dic setObject:[self getDeviceId] forKey:@"device_id"];
        [dic setObject:lastBatteryLevel forKey:@"battery_start"];
        [dic setObject:currentBatteryLevel forKey:@"battery_end"];
        [dic setObject:currentTime forKey:@"double_end_timestamp"];
        [batteryChargeSensor saveData:dic];
        // save the last event information
//        lastBatteryEventTimestamp = currentTime;
//        lastBatteryLevel = battery;
        [userDefaults setObject:currentBatteryLevel forKey:KEY_LAST_BATTERY_LEVEL];
        [userDefaults setObject:currentTime forKey:KEY_LAST_BATTERY_EVENT_TIMESTAMP];
    }
    
    
    switch (currentBatteryEvent) {
        case UIDeviceBatteryStateCharging:
//            lastBatteryEvent = currentBatteryEvent;
            [userDefaults setInteger:UIDeviceBatteryStateCharging forKey:KEY_LAST_BATTERY_EVENT];
            break;
        case UIDeviceBatteryStateUnplugged:
//            currentBatteryEvent = UIDeviceBatteryStateUnplugged;
//            lastBatteryEvent = currentBatteryEvent;
            [userDefaults setInteger:UIDeviceBatteryStateUnplugged forKey:KEY_LAST_BATTERY_EVENT];
            break;
        default:
            break;
    }
    [userDefaults synchronize];
}

- (void)syncAwareDBWithAllBatterySensor:(id) sendar {
    [self syncAwareDB];
    [batteryChargeSensor syncAwareDB];
    [batteryDischargeSensor syncAwareDB];
}



- (BOOL)stopSensor{
    [uploadTimer invalidate];
    [UIDevice currentDevice].batteryMonitoringEnabled = NO;
    return YES;
}


//- (NSNumber *) getUnixtimeWithNSDate:(NSDate *) date {
//    double timeStamp = [date timeIntervalSince1970] * 1000;
//    NSNumber* unixtime = [NSNumber numberWithLong:timeStamp];
//    return unixtime;
//}



@end
