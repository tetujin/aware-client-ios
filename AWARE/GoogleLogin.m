//
//  GoogleLogin.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 1/6/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "GoogleLogin.h"
#import "AWAREKeys.h"

@implementation GoogleLogin {
    NSTimer * uploadTimer;
    NSString* KEY_GOOGLE_NAME;
    NSString* KEY_GOOGLE_EMAIL;
    NSString* KEY_GOOGLE_BLOB_PICTURE;
    NSString* KEY_GOOGLE_PHONENUMBER;
}

- (instancetype)initWithSensorName:(NSString *)sensorName {
    self = [super initWithSensorName:SENSOR_PLUGIN_GOOGLE_LOGIN];
    if (self) {
        KEY_GOOGLE_NAME = @"name";
        KEY_GOOGLE_EMAIL = @"email";
        KEY_GOOGLE_BLOB_PICTURE = @"blob_picture";
        KEY_GOOGLE_PHONENUMBER = @"phonenumber";
    }
    return self;
}

- (void) createTable {
    NSMutableString* query = [[NSMutableString alloc] init];
    [query appendFormat:@"_id integer primary key autoincrement,"];
    [query appendFormat:@"timestamp real default 0,"];
    [query appendFormat:@"device_id text default '',"];
    
    [query appendFormat:@"%@ text default '',", KEY_GOOGLE_NAME];
    [query appendFormat:@"%@ text default '',", KEY_GOOGLE_EMAIL];
    [query appendFormat:@"%@ text default '',", KEY_GOOGLE_PHONENUMBER];
    [query appendFormat:@"%@ blob ", KEY_GOOGLE_BLOB_PICTURE];
    
    [query appendString:@"UNIQUE (timestamp,device_id)"];
    
    [super createTable:query];
}

- (BOOL)startSensor:(double)upInterval withSettings:(NSArray *)settings{
    // Create table
    [self createTable];
    NSLog(@"[%@] Crate table.", [self getSensorName]);
    
    uploadTimer = [NSTimer timerWithTimeInterval:upInterval
                                          target:self
                                        selector:@selector(syncAwareDB)
                                        userInfo:nil
                                         repeats:YES];
    return NO;
}

- (void) saveName:(NSString* )name
        withEmail:(NSString *)email
      phoneNumber:(NSString*) phonenumber {

    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    
    double timeStamp = [[NSDate date] timeIntervalSince1970] * 1000;
    NSNumber* unixtime = [NSNumber numberWithLong:timeStamp];
    [dic setObject:unixtime forKey:@"timestamp"];
    [dic setObject:[self getDeviceId] forKey:@"device_id"];
    [dic setObject:name forKey:KEY_GOOGLE_NAME];
    [dic setObject:email forKey:KEY_GOOGLE_EMAIL];
    [dic setObject:phonenumber forKey:KEY_GOOGLE_PHONENUMBER];
    [dic setObject:[NSNull null] forKey:KEY_GOOGLE_BLOB_PICTURE];
    [self saveData:dic];
    [self performSelector:@selector(syncAwareDB) withObject:0 afterDelay:5];
//    [self syncAwareDB];
}

- (BOOL)stopSensor {
    [uploadTimer invalidate];
    return YES;
}


@end
