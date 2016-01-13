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
    NSTimer *sensingTimer;
}

- (instancetype)initWithSensorName:(NSString *)sensorName{
    self = [super initWithSensorName:sensorName];
    if (self) {
        [super setSensorName:sensorName];
    }
    return self;
}

//http://stackoverflow.com/questions/9515479/monitor-and-detect-if-the-iphone-is-plugged-in-and-charging-wifi-connected-when

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

//- (BOOL)startSensor:(double)interval withUploadInterval:(double)upInterval{
- (BOOL)startSensor:(double)upInterval withSettings:(NSArray *)settings{
    // create table
//    NSLog(@"[%@] Create Table");
    [self createTable];
    
    // start sensor
//    NSLog(@"[%@] Start Battery Sensor");
    double interval = 60.0f;
    NSLog(@"upload interval is %f.", upInterval);
    uploadTimer = [NSTimer scheduledTimerWithTimeInterval:upInterval target:self selector:@selector(syncAwareDB) userInfo:nil repeats:YES];
    sensingTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(getSensorData) userInfo:nil repeats:YES];
    return YES;
}

- (void) getSensorData{
    UIDevice *myDevice = [UIDevice currentDevice];
    [myDevice setBatteryMonitoringEnabled:YES];
    int state = [myDevice batteryState];
//    NSLog(@"battery status: %d",state); // 0 unknown, 1 unplegged, 2 charging, 3 full
    int batLeft = [myDevice batteryLevel] * 100;
//    NSLog(@"battery left: %ld", batLeft);
    
    double timeStamp = [[NSDate date] timeIntervalSince1970] * 1000;
    NSNumber* unixtime = [NSNumber numberWithLong:timeStamp];
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

- (BOOL)stopSensor{
    [sensingTimer invalidate];
    [uploadTimer invalidate];
    return YES;
}

//- (void)uploadSensorData{
//    [self syncAwareDB];
////    NSString * jsonStr = [self getData:SENSOR_BATTERY withJsonArrayFormat:YES];
////    [self insertSensorData:jsonStr withDeviceId:[self getDeviceId] url:[self getInsertUrl:SENSOR_BATTERY]];
//}

@end
