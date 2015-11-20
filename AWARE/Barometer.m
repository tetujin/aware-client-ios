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


- (instancetype)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (instancetype)initWithSensorName:(NSString *)sensorName{
    self = [super init];
    if (self) {
        [super setSensorName:sensorName];
    }
    return self;
}

- (BOOL)startSensor:(double)interval withUploadInterval:(double)upInterval{
    NSLog(@"Start Gyroscope!");
    uploadTimer = [NSTimer scheduledTimerWithTimeInterval:upInterval target:self selector:@selector(uploadSensorData) userInfo:nil repeats:YES];
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
                                               NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
                                               NSNumber* unixtime = [NSNumber numberWithDouble:timeStamp];
                                               NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
                                               [dic setObject:unixtime forKey:@"timestamp"];
                                               [dic setObject:[self getDeviceId] forKey:@"device_id"];
                                               [dic setObject:[NSNumber numberWithDouble:pressure_f*10.0f] forKey:@"double_values_0"];
                                               [dic setObject:@0 forKey:@"accuracy"];
                                               [dic setObject:@"" forKey:@"label"];
                                               [self setLatestValue:[NSString stringWithFormat:@"%f", pressure_f*10.0f]];
                                               [self saveData:dic toLocalFile:SENSOR_BAROMETER];
                                           }];
    }
    
    
    
    
    return YES;
}

- (BOOL)stopSensor{
    [altitude stopRelativeAltitudeUpdates];
    [uploadTimer invalidate];
    return YES;
}

- (void)uploadSensorData{
    NSString * jsonStr = [self getData:SENSOR_BAROMETER withJsonArrayFormat:YES];
    [self insertSensorData:jsonStr withDeviceId:[self getDeviceId] url:[self getInsertUrl:SENSOR_BAROMETER]];
}


@end
