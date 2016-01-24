//
//  Barometer.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/20/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "Barometer.h"

@implementation Barometer{
    NSTimer *uploadTimer;
    CMAltimeter* altitude;
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
    "double_values_0 real default 0,"
    "accuracy integer default 0,"
    "label text default '',"
    "UNIQUE (timestamp,device_id)";
    [super createTable:query];
}


//- (BOOL)startSensor:(double)interval withUploadInterval:(double)upInterval{
- (BOOL)startSensor:(double)upInterval withSettings:(NSArray *)settings{
    NSLog(@"[%@] Create Table", [self getSensorName]);
    [self createTable];
    
    
//    double frequency = [self getSensorSetting:settings withKey:@"frequency_barometer"];
//    if(frequency != -1){
//        frequency = 200000/100000;
//    }else{
//        
//    }
    
    NSLog(@"[%@] Start Barometer Sensor", [self getSensorName]);
    uploadTimer = [NSTimer scheduledTimerWithTimeInterval:upInterval target:self selector:@selector(syncAwareDB) userInfo:nil repeats:YES];
    if (![CMAltimeter isRelativeAltitudeAvailable]) {
        NSLog(@"This device doesen't support CMAltimeter.");
    } else {
        altitude = [[CMAltimeter alloc] init];
        [altitude startRelativeAltitudeUpdatesToQueue:[NSOperationQueue mainQueue]
                                           withHandler:^(CMAltitudeData *altitudeData, NSError *error) {
//                                               NSNumber *altitude_value = altitudeData.relativeAltitude;
//                                               double altitude_f = [altitude_value doubleValue];
//                                               self.altitudeLabel.text = [NSString stringWithFormat:@"%.2f [m]", altitude_f];
                                               NSNumber *pressure_value = altitudeData.pressure;
                                               double pressure_f = [pressure_value doubleValue];
//                                               self.pressureLabel.text = [NSString stringWithFormat:@"%.2f [hPa]", pressure_f*10];
//                                               double timeStamp = [[NSDate date] timeIntervalSince1970] * 1000;
//                                               NSNumber* unixtime = [NSNumber numberWithLong:timeStamp];
                                               NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
                                               NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
                                               [dic setObject:unixtime forKey:@"timestamp"];
                                               [dic setObject:[self getDeviceId] forKey:@"device_id"];
                                               [dic setObject:[NSNumber numberWithDouble:pressure_f*10.0f] forKey:@"double_values_0"];
                                               [dic setObject:@0 forKey:@"accuracy"];
                                               [dic setObject:@"" forKey:@"label"];
                                               [self setLatestValue:[NSString stringWithFormat:@"%f", pressure_f*10.0f]];
                                               [self saveData:dic];
                                           }];
    }
    
    
    
    
    return YES;
}

- (BOOL)stopSensor{
    [altitude stopRelativeAltitudeUpdates];
    [uploadTimer invalidate];
    return YES;
}


@end
