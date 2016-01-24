//
//  DeviceUsage.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 12/14/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "DeviceUsage.h"
#import "notify.h"

@implementation DeviceUsage {
    NSTimer * uploadTimer;
    double lastTime;
    int _notifyTokenForDidChangeDisplayStatus;
}

- (instancetype)initWithSensorName:(NSString *)sensorName{
    self = [super initWithSensorName:sensorName];
    if (self) {
        [super setSensorName:sensorName];
    }
    return self;
}

- (void) createTable{
    NSString *query = [[NSString alloc] init];
    query = @"_id integer primary key autoincrement,"
    "timestamp real default 0,"
    "device_id text default '',"
    "elapsed_device_on real default 0,"
    "elapsed_device_off real default 0,"
    "UNIQUE (timestamp,device_id)";
    [super createTable:query];
}


- (BOOL)startSensor:(double)upInterval withSettings:(NSArray *)settings{
    NSLog(@"[%@] Create Table", [self getSensorName]);
    [self createTable];
    
    NSLog(@"[%@] Start Device Usage Sensor", [self getSensorName]);
//    [self registerAppforDetectLockState];
    lastTime = [[[NSDate alloc] init] timeIntervalSince1970];
    
    [self registerAppforDetectDisplayStatus];
    
    uploadTimer = [NSTimer scheduledTimerWithTimeInterval:upInterval target:self selector:@selector(syncAwareDB) userInfo:nil repeats:YES];
    return YES;
}

- (BOOL)stopSensor{
    [self unregisterAppforDetectDisplayStatus];
    [uploadTimer invalidate];
    return YES;
}

- (void) registerAppforDetectDisplayStatus {
//    int notify_token;
    notify_register_dispatch("com.apple.iokit.hid.displayStatus", &_notifyTokenForDidChangeDisplayStatus,dispatch_get_main_queue(), ^(int token) {
        
//        double timeStamp = [[NSDate date] timeIntervalSince1970] * 1000;
//        NSNumber* unixtime = [NSNumber numberWithLong:timeStamp];
        NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
        [dic setObject:unixtime forKey:@"timestamp"];
        [dic setObject:[self getDeviceId] forKey:@"device_id"];
        
        int awareScreenState = 0;
        double currentTime = [[NSDate date] timeIntervalSince1970];
        double elapsedTime = currentTime - lastTime;
        lastTime = currentTime;
        
        uint64_t state = UINT64_MAX;
        notify_get_state(token, &state);
        if(state == 0) {
            NSLog(@"screen off");
            awareScreenState = 0;
            [dic setObject:[NSNumber numberWithDouble:elapsedTime] forKey:@"elapsed_device_on"]; // real
            [dic setObject:@0 forKey:@"elapsed_device_off"]; // real
        } else {
            NSLog(@"screen on");
            awareScreenState = 1;
            [dic setObject:@0 forKey:@"elapsed_device_on"]; // real
            [dic setObject:[NSNumber numberWithDouble:elapsedTime] forKey:@"elapsed_device_off"]; // real
        }
        
        [self setLatestValue:[NSString stringWithFormat:@"[%d] %f", awareScreenState, elapsedTime ]];
        [self saveData:dic];
        
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




//-(void)registerAppforDetectLockState {
//    int notify_token;
//    notify_register_dispatch("com.apple.springboard.lockstate", &notify_token,dispatch_get_main_queue(), ^(int token) {
//        
//        uint64_t state = UINT64_MAX;
//        notify_get_state(token, &state);
//        
//        int awareScreenState = 0;
//        
//        if(state == 0) {
//            NSLog(@"unlock device");
//            awareScreenState = 3;
//        } else {
//            NSLog(@"lock device");
//            awareScreenState = 2;
//        }
//        
//        NSLog(@"com.apple.springboard.lockstate = %llu", state);
//        
//        NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
//        NSNumber* unixtime = [NSNumber numberWithDouble:timeStamp];
//        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
//        [dic setObject:unixtime forKey:@"timestamp"];
//        [dic setObject:[self getDeviceId] forKey:@"device_id"];
//        [dic setObject:[NSNumber numberWithInt:awareScreenState] forKey:@"screen_status"]; // int
//        [self setLatestValue:[NSString stringWithFormat:@"%@", [NSNumber numberWithInt:awareScreenState]]];
//        [self saveData:dic];
//    });
//}



@end
