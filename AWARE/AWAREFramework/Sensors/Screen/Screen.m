//
//  Screen.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 12/14/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//


/**
 * I referenced following source code for detecting screen lock/unlock events. Thank you very much!
 * http://stackoverflow.com/questions/706344/lock-unlock-events-iphone
 * http://stackoverflow.com/questions/6114677/detect-if-iphone-screen-is-on-off
 */

#import "Screen.h"
#import "notify.h"

@implementation Screen {
    int _notifyTokenForDidChangeLockStatus;
    int _notifyTokenForDidChangeDisplayStatus;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study{
    self = [super initWithAwareStudy:study
                          sensorName:SENSOR_SCREEN
                        dbEntityName:nil
                              dbType:AwareDBTypeTextFile];
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
    "screen_status integer default 0,"
    "UNIQUE (timestamp,device_id)";
    [super createTable:query];
}


- (BOOL)startSensorWithSettings:(NSArray *)settings{
    NSLog(@"[%@] Start Screen Sensor", [self getSensorName]);
    [self registerAppforDetectLockState];
    [self registerAppforDetectDisplayStatus];
    return YES;
}

- (BOOL) stopSensor {
    // Stop a sync timer
    [self unregisterAppforDetectDisplayStatus];
    [self unregisterAppforDetectLockState];
    return YES;
}


/////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////



-(void)registerAppforDetectLockState {
    notify_register_dispatch("com.apple.springboard.lockstate", &_notifyTokenForDidChangeLockStatus,dispatch_get_main_queue(), ^(int token) {
        
        uint64_t state = UINT64_MAX;
        notify_get_state(token, &state);
        
        int awareScreenState = 0;
        
        if(state == 0) {
            NSLog(@"unlock device");
            awareScreenState = 3;
        } else {
            NSLog(@"lock device");
            awareScreenState = 2;
        }
        
        NSLog(@"com.apple.springboard.lockstate = %llu", state);

        NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
        [dic setObject:unixtime forKey:@"timestamp"];
        [dic setObject:[self getDeviceId] forKey:@"device_id"];
        [dic setObject:[NSNumber numberWithInt:awareScreenState] forKey:@"screen_status"]; // int
        [self setLatestValue:[NSString stringWithFormat:@"%@", [NSNumber numberWithInt:awareScreenState]]];
        [self saveData:dic];
    });
}


- (void) registerAppforDetectDisplayStatus {
    notify_register_dispatch("com.apple.iokit.hid.displayStatus", &_notifyTokenForDidChangeDisplayStatus,dispatch_get_main_queue(), ^(int token) {
        
        uint64_t state = UINT64_MAX;
        notify_get_state(token, &state);
        
        int awareScreenState = 0;
        
        if(state == 0) {
            NSLog(@"screen off");
            awareScreenState = 0;
        } else {
            NSLog(@"screen on");
            awareScreenState = 1;
        }
        
        NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
        [dic setObject:unixtime forKey:@"timestamp"];
        [dic setObject:[self getDeviceId] forKey:@"device_id"];
        [dic setObject:[NSNumber numberWithInt:awareScreenState] forKey:@"screen_status"]; // int
        [self setLatestValue:[NSString stringWithFormat:@"%@", [NSNumber numberWithInt:awareScreenState]]];
        [self saveData:dic];
        
    });
}


-(void) unregisterAppforDetectLockState {
    //    notify_suspend(_notifyTokenForDidChangeLockStatus);
    uint32_t result = notify_cancel(_notifyTokenForDidChangeLockStatus);

    if (result == NOTIFY_STATUS_OK) {
        NSLog(@"[screen] OK --> %d", result);
    } else {
        NSLog(@"[screen] NO --> %d", result);
    }
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
