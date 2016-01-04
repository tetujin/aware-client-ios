//
//  ESM.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 12/16/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "ESM.h"

@implementation ESM
{
    NSTimer * uploadTimer;
}

- (instancetype)initWithSensorName:(NSString *)sensorName
{
    self = [super initWithSensorName:@"esms"];
    if (self) {
//        [super setSensorName:sensorName];
    }
    return self;
}

- (void) createTable
{
    NSString *query = [[NSString alloc] init];
    query =
    @"_id integer primary key autoincrement,"
    "timestamp real default 0,"
    "device_id text default '',"
    "esm_type integer default NULL,"
    "esm_title text default '',"
    "esm_submit text default '',"
    "esm_instructions text default '',"
    "esm_radios text default '',"
    "esm_checkboxes text default '',"
    "esm_likert_max integer default 0,"
    "esm_likert_max_label text default '',"
    "esm_likert_min_label text default '',"
    "esm_likert_step real default 0,"
    "esm_quick_answers text default '',"
    "esm_expiration_threshold integer default 0,"
    "esm_status integer default 0,"
    "double_esm_user_answer_timestamp default 0,"
    "esm_user_answer text default '',"
    "esm_trigger text defadult '',"
    "esm_scale_min integer default 0,"
    "esm_scale_max integer default 0,"
    "esm_scale_start integer default 0,"
    "esm_scale_max_label text default '',"
    "esm_scale_min_label text default '',"
    "esm_scale_step integer default 0,"
    "UNIQUE (timestamp,device_id)";
    [super createTable:query];
}

- (BOOL) syncAwareDBWithData:(NSDictionary *)dictionary {
    return [super syncAwareDBWithData:dictionary];
}

- (BOOL)startSensor:(double)upInterval withSettings:(NSArray *)settings{
    NSLog(@"[%@] Create Table", [self getSensorName]);
    [self createTable];
    
    NSLog(@"[%@] Start Device Usage Sensor", [self getSensorName]);
    
    // set sync timer
    uploadTimer = [NSTimer scheduledTimerWithTimeInterval:upInterval
                                                   target:self
                                                 selector:@selector(syncAwareDB)
                                                 userInfo:nil
                                                  repeats:YES];
    return YES;
}

//- (void) getTimezone {
//    [NSTimeZone localTimeZone];
//    NSLog(@"Timezone: %@", [[NSTimeZone localTimeZone] description]);
//    NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
//    NSNumber* unixtime = [NSNumber numberWithDouble:timeStamp];
//    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
//    [dic setObject:unixtime forKey:@"timestamp"];
//    [dic setObject:[self getDeviceId] forKey:@"device_id"];
//    [dic setObject:[[NSTimeZone localTimeZone] description] forKey:@"timezone"]; // real
//    [self setLatestValue:[NSString stringWithFormat:@"%@", [[NSTimeZone localTimeZone] description]]];
//    [self saveData:dic];
//}


- (BOOL) stopSensor {
    [uploadTimer invalidate];
    return YES;
}
@end
