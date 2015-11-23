//
//  Wifi.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/20/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "Wifi.h"



@implementation Wifi{
    NSTimer * uploadTimer;
    NSTimer * sensingTimer;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        //        manager = [[CMMotionManager alloc] init];
    }
    return self;
}

- (instancetype)initWithSensorName:(NSString *)sensorName{
    self = [super initWithSensorName:sensorName];
    if (self) {
        //        manager = [[CMMotionManager alloc] init];
        [super setSensorName:sensorName];
    }
    return self;
}

//- (BOOL)startSensor:(double)interval withUploadInterval:(double)upInterval{
- (BOOL)startSensor:(double)upInterval withSettings:(NSArray *)settings{
    NSLog(@"Start Wifi sensing!");
    double interval = 1.0f;
    
    //sensing interval
//    [self setBufferLimit:10000];
    double frequency = [self getSensorSetting:settings withKey:@"frequency_wifi"];
    if(frequency != -1){
        NSLog(@"Location sensing requency is %f ", frequency);
        interval = frequency;
    }
    
    uploadTimer = [NSTimer scheduledTimerWithTimeInterval:upInterval target:self selector:@selector(uploadSensorData) userInfo:nil repeats:YES];
    sensingTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(getSensorData) userInfo:nil repeats:YES];
    return YES;
}

- (void) getSensorData{
    // Get wifi information
    NSString *bssid = @"";
    NSString *ssid = @"";
    
    
    //http://www.heapoverflow.me/question-how-to-get-wifi-ssid-in-ios9-after-captivenetwork-is-depracted-and-calls-for-wif-31555640
//    NSArray * networkInterfaces = [NEHotspotHelper supportedNetworkInterfaces];
//    NSLog(@"Networks %@",networkInterfaces);
//    for(NEHotspotNetwork *hotspotNetwork in [NEHotspotHelper supportedNetworkInterfaces]) {
//        NSString *ssid = hotspotNetwork.SSID;
//        NSString *bssid = hotspotNetwork.BSSID;
//        BOOL secure = hotspotNetwork.secure;
//        BOOL autoJoined = hotspotNetwork.autoJoined;
//        double signalStrength = hotspotNetwork.signalStrength;
//    }
    
    NSArray *ifs = (__bridge_transfer id)CNCopySupportedInterfaces();
    for (NSString *ifnam in ifs) {
        NSDictionary *info = (__bridge_transfer id)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
//        NSLog(@"info:%@",info);
        if (info[@"BSSID"]) {
            bssid = info[@"BSSID"];
        }
        if(info[@"SSID"]){
            ssid = info[@"SSID"];
        }
    }
    

    
    NSMutableString *finalBSSID = [[NSMutableString alloc] init];
    NSArray *arrayOfBssid = [bssid componentsSeparatedByString:@":"];
    for(int i=0; i<arrayOfBssid.count; i++){
        NSString *element = [arrayOfBssid objectAtIndex:i];
        if(element.length == 1){
            [finalBSSID appendString:[NSString stringWithFormat:@"0%@:",element]];
        }else if(element.length == 2){
            [finalBSSID appendString:[NSString stringWithFormat:@"%@:",element]];
        }else{
            NSLog(@"error");
        }
    }
    if (finalBSSID.length > 0) {
//        NSLog(@"%@",finalBSSID);
        [finalBSSID deleteCharactersInRange:NSMakeRange([finalBSSID length]-1, 1)];
    } else{
//        NSLog(@"error");
    }
    
    
    // Save sensor data to the local database.
    NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
    NSNumber* unixtime = [NSNumber numberWithDouble:timeStamp];
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setObject:unixtime forKey:@"timestamp"];
    [dic setObject:[self getDeviceId] forKey:@"device_id"];
    [dic setObject:finalBSSID forKey:@"bssid"]; //text
    [dic setObject:ssid forKey:@"ssid"]; //text
    [dic setObject:@"" forKey:@"security"]; //text
    [dic setObject:@0 forKey:@"frequency"];//int
    [dic setObject:@0 forKey:@"rssi"]; //int
    [dic setObject:@"" forKey:@"label"]; //text
    [self setLatestValue:[NSString stringWithFormat:@"%@ (%@)",ssid, finalBSSID]];
    [self saveData:dic toLocalFile:SENSOR_WIFI];
}




- (BOOL)stopSensor{
    [sensingTimer invalidate];
    [uploadTimer invalidate];
    return YES;
}

- (void)uploadSensorData{
    NSString * jsonStr = [self getData:SENSOR_WIFI withJsonArrayFormat:YES];
    [self insertSensorData:jsonStr withDeviceId:[self getDeviceId] url:[self getInsertUrl:SENSOR_WIFI]];
}

@end
