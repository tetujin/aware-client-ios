//
//  DeviceUsage.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 12/14/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "DeviceUsage.h"
#import "notify.h"
#import "AppDelegate.h"
#import "EntityDeviceUsage.h"

@implementation DeviceUsage {
    double lastTime;
    int _notifyTokenForDidChangeDisplayStatus;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study{
    self = [super initWithAwareStudy:study
                          sensorName:SENSOR_PLUGIN_DEVICE_USAGE
                        dbEntityName:NSStringFromClass([EntityDeviceUsage class])
                              dbType:AwareDBTypeCoreData];
    if (self) {
    }
    return self;
}

- (void) createTable{
    NSLog(@"[%@] Create Table", [self getSensorName]);
    NSString *query = [[NSString alloc] init];
    query = @"_id integer primary key autoincrement,"
    "timestamp real default 0,"
    "device_id text default '',"
    "elapsed_device_on real default 0,"
    "elapsed_device_off real default 0,"
    "UNIQUE (timestamp,device_id)";
    [super createTable:query];
}


- (BOOL)startSensorWithSettings:(NSArray *)settings{
    NSLog(@"[%@] Start Device Usage Sensor", [self getSensorName]);
    lastTime = [[[NSDate alloc] init] timeIntervalSince1970];
    
    [self registerAppforDetectDisplayStatus];
    
    return YES;
}

- (BOOL)stopSensor{
    [self unregisterAppforDetectDisplayStatus];
    return YES;
}


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


- (void) registerAppforDetectDisplayStatus {
//    int notify_token;
    notify_register_dispatch("com.apple.iokit.hid.displayStatus", &_notifyTokenForDidChangeDisplayStatus,dispatch_get_main_queue(), ^(int token) {
        
        //        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
//        [dic setObject:unixtime forKey:@"timestamp"];
//        [dic setObject:[self getDeviceId] forKey:@"device_id"];

        AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
        EntityDeviceUsage * deviceUsage = (EntityDeviceUsage *)[NSEntityDescription insertNewObjectForEntityForName:[self getEntityName]
                                                                                                inManagedObjectContext:delegate.managedObjectContext];
        NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
        deviceUsage.timestamp = unixtime;
        deviceUsage.device_id = [self getDeviceId];
        
        
        int awareScreenState = 0;
        double currentTime = [[NSDate date] timeIntervalSince1970];
        double elapsedTime = currentTime - lastTime;
        lastTime = currentTime;
        
        uint64_t state = UINT64_MAX;
        notify_get_state(token, &state);
        if(state == 0) {
            NSLog(@"screen off");
            awareScreenState = 0;
            deviceUsage.elapsed_device_on = @(elapsedTime);
            deviceUsage.elapsed_device_off = @0;
//            [dic setObject:[NSNumber numberWithDouble:elapsedTime] forKey:@"elapsed_device_on"]; // real
//            [dic setObject:@0 forKey:@"elapsed_device_off"]; // real
        } else {
            NSLog(@"screen on");
            awareScreenState = 1;
            deviceUsage.elapsed_device_on = @0;
            deviceUsage.elapsed_device_off = @(elapsedTime);
//            [dic setObject:@0 forKey:@"elapsed_device_on"]; // real
//            [dic setObject:[NSNumber numberWithDouble:elapsedTime] forKey:@"elapsed_device_off"]; // real
        }
        
        [self setLatestValue:[NSString stringWithFormat:@"[%d] %f", awareScreenState, elapsedTime ]];
        [self saveDataToDB];
//        [self saveData:dic];
        
    });
}

- (void) unregisterAppforDetectDisplayStatus {
    //    notify_suspend(_notifyTokenForDidChangeDisplayStatus);
    uint32_t result = notify_cancel(_notifyTokenForDidChangeDisplayStatus);
    if (result == NOTIFY_STATUS_OK) {
        NSLog(@"[screen] OK ==> %d", result);
    } else {
        NSLog(@"[screen] NO ==> %d", result);
    }
}

@end
