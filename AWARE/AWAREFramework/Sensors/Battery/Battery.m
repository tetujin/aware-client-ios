//
//  Battery.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/20/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//
//http://stackoverflow.com/questions/9515479/monitor-and-detect-if-the-iphone-is-plugged-in-and-charging-wifi-connected-when
//https://developer.apple.com/library/ios/samplecode/BatteryStatus/Introduction/Intro.html
//

#import "Battery.h"
#import "AppDelegate.h"

#import "EntityBattery.h"
#import "EntityBatteryCharge.h"
#import "EntityBatteryDischarge.h"

@implementation Battery {
    NSString* BATTERY_DISCHARGERES;
    NSString* BATTERY_CHARGERES;
    
    NSString* KEY_LAST_BATTERY_EVENT;
    NSString* KEY_LAST_BATTERY_EVENT_TIMESTAMP;
    NSString* KEY_LAST_BATTERY_LEVEL;
    
    // A battery charge sensor
    AWARESensor * batteryChargeSensor;
    // A battery discharge sensor
    AWARESensor * batteryDischargeSensor;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study{
    self = [super initWithAwareStudy:study
                          sensorName:SENSOR_BATTERY
                        dbEntityName:NSStringFromClass([EntityBattery class])
                              dbType:AwareDBTypeCoreData];
    if (self) {
        BATTERY_DISCHARGERES = @"battery_discharges";
        BATTERY_CHARGERES = @"battery_charges";
        
        // keys for local storage
        KEY_LAST_BATTERY_EVENT = @"key_last_battery_event";
        KEY_LAST_BATTERY_EVENT_TIMESTAMP = @"key_last_battery_event_timestamp";
        KEY_LAST_BATTERY_LEVEL = @"key_last_battery_level";
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        if (![userDefaults integerForKey:KEY_LAST_BATTERY_EVENT_TIMESTAMP]) {
            [userDefaults setInteger:UIDeviceBatteryStateUnknown forKey:KEY_LAST_BATTERY_EVENT];
            [userDefaults setObject:[AWAREUtils getUnixTimestamp:[NSDate new]] forKey:KEY_LAST_BATTERY_EVENT_TIMESTAMP];
            [userDefaults setInteger:[UIDevice currentDevice].batteryLevel*100 forKey:KEY_LAST_BATTERY_LEVEL];
        }
        // Get default information from local storage
        batteryChargeSensor = [[AWARESensor alloc] initWithAwareStudy:study
                                                           sensorName:BATTERY_CHARGERES
                                                         dbEntityName:NSStringFromClass([EntityBatteryCharge class])
                                                               dbType:AwareDBTypeCoreData];
        
        batteryDischargeSensor = [[AWARESensor alloc] initWithAwareStudy:study
                                                              sensorName:BATTERY_DISCHARGERES
                                                            dbEntityName:NSStringFromClass([EntityBatteryDischarge class])
                                                                  dbType:AwareDBTypeCoreData];
        [batteryChargeSensor trackDebugEvents];
        [batteryDischargeSensor trackDebugEvents];
    }
    return self;
}


- (void) createTable{
    // Send a create table queries (battery_level, battery_charging, and battery_discharging)
    [self createBatteryTable];
    [self createCargeTable];
    [self createDichargeTable];
}

- (void) createBatteryTable{
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

- (BOOL)startSensorWithSettings:(NSArray *)settings{

    // Set a battery level change event to a notification center
    [UIDevice currentDevice].batteryMonitoringEnabled = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(batteryLevelChanged:)
                                                 name:UIDeviceBatteryLevelDidChangeNotification object:nil];
    
    // Set a battery state change event to a notification center
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(batteryStateChanged:)
                                                 name:UIDeviceBatteryStateDidChangeNotification object:nil];
    
    return YES;
}


- (BOOL)stopSensor{
    [NSNotificationCenter.defaultCenter removeObserver:self name:UIDeviceBatteryLevelDidChangeNotification object:nil];
    [NSNotificationCenter.defaultCenter removeObserver:self name:UIDeviceBatteryStateDidChangeNotification object:nil];
//    [UIDevice currentDevice].batteryMonitoringEnabled = NO;
    return YES;
}

- (bool)isUploading{
    if([super isUploading] || [batteryChargeSensor isUploading] || [batteryDischargeSensor isUploading]){
        return YES;
    }else{
        return NO;
    }
}


//////////////////////////////
//////////////////////////////

-(BOOL)syncAwareDBInForeground{
    if(![super syncAwareDBInForeground]){
        return NO;
    }
    
    if(![batteryChargeSensor syncAwareDBInForeground]){
        return NO;
    }
    
    if(![batteryDischargeSensor syncAwareDBInForeground]){
        return NO;
    }
    return YES;
}

- (void) syncAwareDB {
    [super syncAwareDB];
    [batteryChargeSensor syncAwareDB];
    [batteryDischargeSensor syncAwareDB];
}


/////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////

//- (void)syncAwareDBWithAllBatterySensor:(id) sendar {
//    [self syncAwareDB];
//    [batteryChargeSensor syncAwareDB];
//    [batteryDischargeSensor syncAwareDB];
//}


- (void)batteryLevelChanged:(NSNotification *)notification {
    //    NSLog(@"battery status: %d",state); // 0 unknown, 1 unplegged, 2 charging, 3 full
    UIDevice *myDevice = [UIDevice currentDevice];
    [myDevice setBatteryMonitoringEnabled:YES];
    int state = [myDevice batteryState];
    int batLeft = [myDevice batteryLevel] * 100;
    
    AppDelegate *delegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    EntityBattery* batteryData = (EntityBattery *)[NSEntityDescription
                                        insertNewObjectForEntityForName:[self getEntityName]
                                                 inManagedObjectContext:delegate.managedObjectContext];
    
    batteryData.device_id = [self getDeviceId];
    batteryData.timestamp = [AWAREUtils getUnixTimestamp:[NSDate new]];
    batteryData.battery_status = [NSNumber numberWithInt:state];
    batteryData.battery_level = [NSNumber numberWithInt:batLeft];
    batteryData.battery_scale = @100;
    batteryData.battery_voltage = @-1;
    batteryData.battery_temperature = @-1;
    batteryData.battery_adaptor = @-1;
    batteryData.battery_health = @-1;
    batteryData.battery_technology = @"";
 
    [self setLatestValue:[NSString stringWithFormat:@"%d", batLeft]];
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:batteryData
                                                         forKey:EXTRA_DATA];
    [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_BATTERY_CHANGED
                                                        object:nil
                                                      userInfo:userInfo];
    
    NSError * error = nil;
    [delegate.managedObjectContext save:&error];
    if (error) {
        NSLog(@"%@", error.description);
    }
    
//    NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
//    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
//    [dic setObject:unixtime forKey:@"timestamp"];
//    [dic setObject:[self getDeviceId] forKey:@"device_id"];
//    [dic setObject:[NSNumber numberWithInt:state] forKey:@"battery_status"];
//    [dic setObject:[NSNumber numberWithInt:batLeft] forKey:@"battery_level"];
//    [dic setObject:@100 forKey:@"battery_scale"];
//    [dic setObject:@0 forKey:@"battery_voltage"];
//    [dic setObject:@0 forKey:@"battery_temperature"];
//    [dic setObject:@0 forKey:@"battery_adaptor"];
//    [dic setObject:@0 forKey:@"battery_health"];
//    [dic setObject:@"" forKey:@"battery_technology"];
//    [self setLatestValue:[NSString stringWithFormat:@"%d", batLeft]];
//    [self saveData:dic toLocalFile:SENSOR_BATTERY];
}


- (void)batteryStateChanged:(NSNotification *)notification {
    // Get current values
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSInteger lastBatteryEvent = [userDefaults integerForKey:KEY_LAST_BATTERY_EVENT];
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
            [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_BATTERY_CHARGING
                                                                object:nil
                                                              userInfo:nil];
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
    
    NSNumber * currentTime = [AWAREUtils getUnixTimestamp:[NSDate new]];
    int battery = [UIDevice currentDevice].batteryLevel * 100;
    NSNumber * currentBatteryLevel = [NSNumber numberWithInt:battery];

    // discharge event
    if (lastBatteryEvent == UIDeviceBatteryStateUnplugged &&
        currentBatteryEvent == UIDeviceBatteryStateCharging) {
//        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
//        [dic setObject:lastBatteryEventTimestamp forKey:@"timestamp"];
//        [dic setObject:[self getDeviceId] forKey:@"device_id"];
//        [dic setObject:lastBatteryLevel forKey:@"battery_start"];
//        [dic setObject:currentBatteryLevel forKey:@"battery_end"];
//        [dic setObject:currentTime forKey:@"double_end_timestamp"];
//        [batteryDischargeSensor saveData:dic];
        [userDefaults setObject:currentBatteryLevel forKey:KEY_LAST_BATTERY_LEVEL];
        [userDefaults setObject:currentTime forKey:KEY_LAST_BATTERY_EVENT_TIMESTAMP];
    
        AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
        EntityBatteryDischarge* batteryDischargeData = (EntityBatteryDischarge *)[NSEntityDescription
                                                       insertNewObjectForEntityForName:NSStringFromClass([EntityBatteryDischarge class])
                                                       inManagedObjectContext:delegate.managedObjectContext];
        batteryDischargeData.device_id = [self getDeviceId];
        batteryDischargeData.timestamp = lastBatteryEventTimestamp;
        batteryDischargeData.battery_start = lastBatteryLevel;
        batteryDischargeData.battery_end = currentBatteryLevel;
        batteryDischargeData.double_end_timestamp = currentTime;
        
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:batteryDischargeData
                                                             forKey:EXTRA_DATA];
        [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_BATTERY_DISCHARGING
                                                            object:nil
                                                          userInfo:userInfo];
        
        NSError * error = nil;
        [delegate.managedObjectContext save:&error];
        if (error) {
            NSLog(@"%@", error.description);
        }
        [delegate.managedObjectContext reset];
        
        // charge event
    }else if(lastBatteryEvent == UIDeviceBatteryStateCharging &&
             currentBatteryEvent == UIDeviceBatteryStateUnplugged ){
//        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
//        [dic setObject:lastBatteryEventTimestamp forKey:@"timestamp"];
//        [dic setObject:[self getDeviceId] forKey:@"device_id"];
//        [dic setObject:lastBatteryLevel forKey:@"battery_start"];
//        [dic setObject:currentBatteryLevel forKey:@"battery_end"];
//        [dic setObject:currentTime forKey:@"double_end_timestamp"];
//        [batteryChargeSensor saveData:dic];
        [userDefaults setObject:currentBatteryLevel forKey:KEY_LAST_BATTERY_LEVEL];
        [userDefaults setObject:currentTime forKey:KEY_LAST_BATTERY_EVENT_TIMESTAMP];
        
        AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
        EntityBatteryCharge* batteryChargeData = (EntityBatteryCharge *)[NSEntityDescription
                                                                                     insertNewObjectForEntityForName:NSStringFromClass([EntityBatteryCharge class])
                                                                                     inManagedObjectContext:delegate.managedObjectContext];
        batteryChargeData.device_id = [self getDeviceId];
        batteryChargeData.timestamp = lastBatteryEventTimestamp;
        batteryChargeData.battery_start = lastBatteryLevel;
        batteryChargeData.battery_end = currentBatteryLevel;
        batteryChargeData.double_end_timestamp = currentTime;
        
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:batteryChargeData
                                                             forKey:EXTRA_DATA];
        [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_BATTERY_CHARGING
                                                            object:nil
                                                          userInfo:userInfo];
        
        NSError * error = nil;
        [delegate.managedObjectContext save:&error];
        if (error) {
            NSLog(@"%@", error.description);
        }

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


@end
