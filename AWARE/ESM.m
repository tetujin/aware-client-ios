//
//  ESM.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 12/16/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "ESM.h"

@implementation ESM

- (instancetype)initWithSensorName:(NSString *)sensorName withAwareStudy:(AWAREStudy *)study{
    self = [super initWithSensorName:@"esms" withAwareStudy:study];
    if (self) {
    }
    return self;
}


- (void) createTable {
    NSLog(@"[%@] Create Table", [self getSensorName]);
    NSString *query = [[NSString alloc] init];
    query =
    @"_id integer primary key autoincrement,"
    "timestamp real default 0,"
    "device_id text default '',"
    "esm_type integer default 0,"
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
    "double_esm_user_answer_timestamp real default 0,"
    "esm_user_answer text default '',"
    "esm_trigger text default '',"
    "esm_scale_min integer default 0,"
    "esm_scale_max integer default 0,"
    "esm_scale_start integer default 0,"
    "esm_scale_max_label text default '',"
    "esm_scale_min_label text default '',"
    "esm_scale_step integer default 0";
    [super createTable:query];
}


- (BOOL) syncAwareDBWithData:(NSDictionary *)dictionary {
    return [super syncAwareDBWithData:dictionary];
}

- (BOOL)startSensor:(double)upInterval withSettings:(NSArray *)settings{
//    NSLog(@"[%@] Start ESM uploader", [self getSensorName]);
    return YES;
}

- (BOOL) stopSensor {
    return YES;
}

@end
