//
//  ActivityRecognition.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/26/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//
//

/**
- [Document for CoreMotion API]( https://developer.apple.com/library/ios/documentation/EventHandling/Conceptual/EventHandlingiPhoneOS/motion_event_basics/motion_event_basics.html )
 
- [Document for CMDeviceMotion API] ( https://developer.apple.com/library/ios/documentation/CoreMotion/Reference/CMDeviceMotion_Class/index.html#//apple_ref/occ/cl/CMDeviceMotion )
 */


#import "ActivityRecognition.h"

@implementation ActivityRecognition {
    CMMotionActivityManager *motionActivityManager;
//    NSTimer * uploadTimer;
}

- (instancetype)initWithSensorName:(NSString *)sensorName withAwareStudy:(AWAREStudy *)study{
    self = [super initWithSensorName:sensorName withAwareStudy:study];
    if (self) {
        motionActivityManager = [[CMMotionActivityManager alloc] init];
    }
    return self;
}

- (void) createTable{
    NSString *query = [[NSString alloc] init];
    query = @"_id integer primary key autoincrement,"
    "timestamp real default 0,"
    "device_id text default '',"
    "activity_name text default '',"
    "activity_type text default '',"
    "confidence int default 4,"
    "activities text default '',"
    "UNIQUE (timestamp,device_id)";
    [super createTable:query];
}


- (BOOL)startSensor:(double)upInterval withSettings:(NSArray *)settings{
    NSLog(@"Start Motion Activity Manager! ");
    [self createTable];

    [self setBufferSize:10];
//    uploadTimer = [NSTimer scheduledTimerWithTimeInterval:upInterval target:self selector:@selector(syncAwareDB) userInfo:nil repeats:YES];
    /** motion activity */
    if([CMMotionActivityManager isActivityAvailable]){
        motionActivityManager = [CMMotionActivityManager new];
        [motionActivityManager startActivityUpdatesToQueue:[NSOperationQueue new]
                                                withHandler:^(CMMotionActivity *activity) {
                                                    [self addMotionActivity:activity];
                                                }];
    }
    return YES;
}


- (BOOL)stopSensor{
    // Stop a sync timer
//    if (uploadTimer != nil) {
//        [uploadTimer invalidate];
//        uploadTimer = nil;
//    }
    // Stop and remove a motion sensor
    [motionActivityManager stopActivityUpdates];
    motionActivityManager = nil;
    return YES;
}


////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////


- (void) addMotionActivity: (CMMotionActivity *) motionActivity{
    NSNumber *motionConfidence = [NSNumber numberWithInt:0];
    if (motionActivity.confidence  == CMMotionActivityConfidenceHigh){
        motionConfidence = [NSNumber numberWithInt:100];
    }else if(motionActivity.confidence == CMMotionActivityConfidenceMedium){
        motionConfidence = [NSNumber numberWithInt:50];
    }else if(motionActivity.confidence == CMMotionActivityConfidenceLow){
        motionConfidence = [NSNumber numberWithInt:0];
    }
    
    // Motion types are refere from Google Activity Recognition
    //https://developers.google.com/android/reference/com/google/android/gms/location/DetectedActivity
    NSString *motionName = @"";
    NSNumber *motionType = @4;
//    NSLog(@"Quite probably a new activity.");
    if (motionActivity.stationary){
        motionName = @"still";
        motionType = @3;
    } else if (motionActivity.running){
        motionName = @"running";
        motionType = @8;
    } else if (motionActivity.automotive){
        motionName = @"in_vehicle";
        motionType = @1;
    } else if (motionActivity.walking){
        motionName = @"walking";
        motionType = @7;
    } else if (motionActivity.cycling){
        motionName = @"on_bicycle";
        motionType = @1;
    } else if (motionActivity.unknown){
        motionName = @"unknown";
        motionType = @4;
    } else {
        motionName = @"unknown";
        motionType = @4;
    }
    
    NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setObject:unixtime forKey:@"timestamp"];
    [dic setObject:[self getDeviceId] forKey:@"device_id"];
    [dic setObject:motionName forKey:@"activity_name"]; //varchar
    [dic setObject:motionType forKey:@"activity_type"]; //text
    [dic setObject:motionConfidence forKey:@"confidence"]; //int
    [dic setObject:@"" forKey:@"activities"]; //text
    [self setLatestValue:[NSString stringWithFormat:@"%@, %@, %@", motionName, motionType, motionConfidence]];
    [self saveData:dic toLocalFile:SENSOR_PLUGIN_GOOGLE_ACTIVITY_RECOGNITION];
}



@end
