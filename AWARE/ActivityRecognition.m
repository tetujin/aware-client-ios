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
    NSString * KEY_TIMESTAMP_OF_LAST_UPDATE;
    NSTimer * timer;
}

- (instancetype)initWithSensorName:(NSString *)sensorName withAwareStudy:(AWAREStudy *)study{
    self = [super initWithSensorName:sensorName withAwareStudy:study];
    if (self) {
        motionActivityManager = [[CMMotionActivityManager alloc] init];
        KEY_TIMESTAMP_OF_LAST_UPDATE = @"key_plugin_sensor_activity_recognition_last_update_timestamp";
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
    [self setBufferSize:10];
    [self getMotionActivity:nil];

    
    /** motion activity */
    if([CMMotionActivityManager isActivityAvailable]){
        motionActivityManager = [CMMotionActivityManager new];
        [motionActivityManager startActivityUpdatesToQueue:[NSOperationQueue new]
                                                withHandler:^(CMMotionActivity *activity) {
                                                    dispatch_async(dispatch_get_main_queue(), ^{
                                                        [self addMotionActivity:activity];
                                                    });
                                                }];
    }
    return YES;
}


- (BOOL)stopSensor{
    // Stop and remove a motion sensor
    [motionActivityManager stopActivityUpdates];
    motionActivityManager = nil;
    if (timer != nil) {
        [timer invalidate];
        timer = nil;
    }
    return YES;
}

- (void)changedBatteryState{
//    [self getMotionActivity:nil];
}


//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

- (void) getMotionActivity:(id)sender{
    
    NSOperationQueue *operationQueueUpdate = [NSOperationQueue mainQueue];
    if([CMMotionActivityManager isActivityAvailable]){
        // from data
        NSDate * fromDate = [self getLastUpdate];
        // to date
        NSDate * toDate = [NSDate new];
        motionActivityManager = [CMMotionActivityManager new];
        [motionActivityManager queryActivityStartingFromDate:fromDate toDate:toDate toQueue:operationQueueUpdate withHandler:^(NSArray<CMMotionActivity *> * _Nullable activities, NSError * _Nullable error) {
            if (activities!=nil && error==nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([self isDebug]) {
                        NSString * message = [NSString stringWithFormat:@"Activity Recognition Sensor is called by a timer. (%ld activites)" ,activities.count];
                        [AWAREUtils sendLocalNotificationForMessage:message soundFlag:YES];
                        
                    }
                    for (CMMotionActivity * activity in activities) {
                        [self addMotionActivity:activity];
                    }
                    [self setLastUpdateWithDate:toDate];
                });
            }
        }];
    }
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
    NSString *motionName = @"unknown";
    NSNumber *motionType = @4;
    NSMutableArray * activities = [[NSMutableArray alloc] init];
//    NSLog(@"Quite probably a new activity.");
    
    if (motionActivity.unknown){
        motionName = @"unknown";
        motionType = @4;
        [activities addObject:[self getActivityDicWithName:motionName confidence:motionConfidence]];
    }
    
    if (motionActivity.stationary){
        motionName = @"still";
        motionType = @3;
        [activities addObject:[self getActivityDicWithName:motionName confidence:motionConfidence]];
    }
    
    if (motionActivity.running){
        motionName = @"running";
        motionType = @8;
        [activities addObject:[self getActivityDicWithName:motionName confidence:motionConfidence]];
    }
    
    if (motionActivity.walking){
        motionName = @"walking";
        motionType = @7;
        [activities addObject:[self getActivityDicWithName:motionName confidence:motionConfidence]];
    }
    
    if (motionActivity.automotive){
        motionName = @"in_vehicle";
        motionType = @1;
        [activities addObject:[self getActivityDicWithName:motionName confidence:motionConfidence]];
    }
    
    if (motionActivity.cycling){
        motionName = @"on_bicycle";
        motionType = @1;
        [activities addObject:[self getActivityDicWithName:motionName confidence:motionConfidence]];
    }
    
    NSString * activitiesStr = @"";
    if (activities != nil && activities.count > 0) {
        if([NSJSONSerialization isValidJSONObject:activities]){
            NSError * error = nil;
            NSData *json = [NSJSONSerialization dataWithJSONObject:activities
                                                           options:0
                                                             error:&error];
            if (error == nil) {
                activitiesStr = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
            }
        }
    }

    
    NSLog(@"[%@] %@ %ld", motionActivity.startDate, motionName, motionActivity.confidence);
    
    NSNumber * unixtime = [AWAREUtils getUnixTimestamp:motionActivity.startDate];
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setObject:unixtime forKey:@"timestamp"];
    [dic setObject:[self getDeviceId] forKey:@"device_id"];
    [dic setObject:motionName forKey:@"activity_name"]; //varchar
    [dic setObject:motionType forKey:@"activity_type"]; //text
    [dic setObject:motionConfidence forKey:@"confidence"]; //int
    [dic setObject:@"" forKey:@"activities"]; //text
    [self setLatestValue:[NSString stringWithFormat:@"%@, %@, %@", motionName, motionType, motionConfidence]];
    [self saveData:dic toLocalFile:SENSOR_PLUGIN_GOOGLE_ACTIVITY_RECOGNITION];
    
    
//    AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
//    PluginActivityRecognition * activity = [NSEntityDescription insertNewObjectForEntityForName:@"ActivityRecognition" inManagedObjectContext:delegate.managedObjectContext];
//    activity.device_id = [self getDeviceId];
//    activity.timestamp = unixtime;
//    activity.confidence = motionConfidence;
//    activity.activities = activitiesStr;
//    activity.activity_name = motionName;
//    activity.activity_type = [motionType stringValue];
//    
//    NSError * error = nil;
//    [delegate.managedObjectContext save:&error];
//    if (error) {
//        NSLog(@"%@", error.description);
//    }
    
    [self setLatestValue:[NSString stringWithFormat:@"%@, %@, %@", motionName, motionType, motionConfidence]];
}

-(NSString*)timestamp2date:(NSDate*)date{
    //[timeStampString stringByAppendingString:@"000"];   //convert to ms
    NSDateFormatter *_formatter=[[NSDateFormatter alloc]init];
    [_formatter setDateFormat:@"dd/MM/yy hh/mm/ss"];
    return [_formatter stringFromDate:date];
}

- (NSDictionary *) getActivityDicWithName:(NSString*) activityName confidence:(NSNumber *) confidence  {
    NSMutableDictionary * dic = [[NSMutableDictionary alloc] init];
    [dic setObject:activityName forKey:@"activity"];
    [dic setObject:confidence forKey:@"confidence"];
    return dic;
}

- (void) setLastUpdateWithDate:(NSDate *)date{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:date forKey:KEY_TIMESTAMP_OF_LAST_UPDATE];
}

- (NSDate *) getLastUpdate{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDate * date = [defaults objectForKey:KEY_TIMESTAMP_OF_LAST_UPDATE];
    if (date != nil) {
        return date;
    }else{
        return [NSDate new];
    }
}

@end
