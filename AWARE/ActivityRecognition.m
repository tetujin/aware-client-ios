//
//  ActivityRecognition.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/26/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "ActivityRecognition.h"

@implementation ActivityRecognition
{
    CMMotionActivityManager *motionActivityManager;
    NSTimer * uploadTimer;
}

- (instancetype)initWithSensorName:(NSString *)sensorName{
    self = [super initWithSensorName:sensorName];
    if (self) {
        [super setSensorName:sensorName];
        motionActivityManager = [[CMMotionActivityManager alloc] init];
    }
    return self;
}

/**
 * [CoreMotion API]
 * https://developer.apple.com/library/ios/documentation/EventHandling/Conceptual/EventHandlingiPhoneOS/motion_event_basics/motion_event_basics.html
 *
 * [CMDeviceMotion API]
 * https://developer.apple.com/library/ios/documentation/CoreMotion/Reference/CMDeviceMotion_Class/index.html#//apple_ref/occ/cl/CMDeviceMotion
 */


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

//- (BOOL)startSensor:(double)interval withUploadInterval:(double)upInterval{
- (BOOL)startSensor:(double)upInterval withSettings:(NSArray *)settings{
    NSLog(@"Start Motion Activity Manager! ");
    [self createTable];

    uploadTimer = [NSTimer scheduledTimerWithTimeInterval:upInterval target:self selector:@selector(syncAwareDB) userInfo:nil repeats:YES];
    /** motion activity */
    if([CMMotionActivityManager isActivityAvailable]){
        motionActivityManager = [CMMotionActivityManager new];
        [motionActivityManager startActivityUpdatesToQueue:[NSOperationQueue new]
                                                withHandler:^(CMMotionActivity *activity) {
                                                    if (activity.confidence  == CMMotionActivityConfidenceHigh){
                                                        [self addMotionActivity:activity];
                                                    }
                                                }];
    }
    return YES;
}


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
    //        NSDate *started = motionActivity.startDate;
    if (motionActivity.stationary){
        motionName = @"still";
//        NSLog(@"still");
        motionType = @3;
    } else if (motionActivity.running){
        motionName = @"running";
//        NSLog(@"running");
        motionType = @8;
    } else if (motionActivity.automotive){
        motionName = @"in_vehicle";
        motionType = @1;
//        NSLog(@"in_vehicle");
    } else if (motionActivity.walking){
        motionName = @"walking";
        motionType = @7;
//        NSLog(@"walking");
    } else if (motionActivity.cycling){
        motionName = @"on_bicycle";
        motionType = @1;
//        NSLog(@"on_bicycle");
    } else if (motionActivity.unknown){
        motionName = @"unknown";
        motionType = @4;
//        NSLog(@"unknown");
    } else {
        motionName = @"unknown";
        motionType = @4;
//        NSLog(@"unknown");
    }
    
    //    NSLog(@"Discovered characteristic %@", characteristic);
    NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
    NSNumber* unixtime = [NSNumber numberWithDouble:timeStamp];
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



- (BOOL)stopSensor{
    [uploadTimer invalidate];
//    [motionManager stopDeviceMotionUpdates];
    [self stopWriteableTimer];
    return YES;
}

//- (void)uploadSensorData{
//    [self syncAwareDB];
////    NSString * jsonStr = [self getData:SENSOR_PLUGIING_GOOGLE_ACTIVITY_RECOGNITION withJsonArrayFormat:YES];
////    [self insertSensorData:jsonStr withDeviceId:[self getDeviceId] url:[self getInsertUrl:SENSOR_PLUGIING_GOOGLE_ACTIVITY_RECOGNITION]];
//}

@end
