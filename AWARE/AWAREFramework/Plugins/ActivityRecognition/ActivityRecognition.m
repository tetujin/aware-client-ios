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
#import "AppDelegate.h"
#import "EntityActivityRecognition.h"

@implementation ActivityRecognition {
    CMMotionActivityManager *motionActivityManager;
    NSString * KEY_TIMESTAMP_OF_LAST_UPDATE;
    NSTimer * timer;
    double defaultInterval;
    ActivityRecognitionMode sensingMode;
    CMMotionActivityConfidence confidenceFilter;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    self = [super initWithAwareStudy:study
                          sensorName:SENSOR_PLUGIN_GOOGLE_ACTIVITY_RECOGNITION
                        dbEntityName:NSStringFromClass([EntityActivityRecognition class])
                              dbType:dbType];

    
    if (self) {
        motionActivityManager = [[CMMotionActivityManager alloc] init];
        KEY_TIMESTAMP_OF_LAST_UPDATE = @"key_plugin_sensor_activity_recognition_last_update_timestamp";
        defaultInterval = 60*3; // 3 min
        sensingMode = ActivityRecognitionModeLive;
        confidenceFilter = CMMotionActivityConfidenceLow;
        [self setCSVHeader:@[@"timestamp",@"device_id",@"activity_name",@"activity_type",@"confidence",@"activities"]];
    }
    return self;
}

- (void) createTable{
    
    // creata original table 
    NSString *query = [[NSString alloc] init];
    
    query = @"_id integer primary key autoincrement,"
    "timestamp real default 0,"
    "device_id text default '',"
    "activity_name text default '',"
    "activity_type text default '',"
    "confidence int default 4,"
    "activities text default ''";
    //"UNIQUE (timestamp,device_id)";

    /*
    stationary
    walking
    running
    automotive
    cycling
    unknown
    */
     
    [super createTable:query];
}


- (BOOL)startSensorWithSettings:(NSArray *)settings{
    NSLog(@"Start Motion Activity Manager! ");
    

    double frequency = [self getSensorSetting:settings withKey:@"frequency_plugin_google_activity_recognition"];
    if (frequency < defaultInterval) {
        frequency = defaultInterval;
    }
    
    return [self startSensorWithConfidenceFilter:CMMotionActivityConfidenceLow mode:ActivityRecognitionModeHistory interval:frequency];
//    return [self startSensorWithConfidenceFilter:CMMotionActivityConfidenceLow mode:ActivityRecognitionModeLive interval:frequency];
}


- (BOOL) startSensorWithLiveMode:(CMMotionActivityConfidence) filterLevel{
    return [self startSensorWithConfidenceFilter:filterLevel mode:ActivityRecognitionModeLive interval:defaultInterval];
}

- (BOOL) startSensorWithHistoryMode:(CMMotionActivityConfidence)filterLevel interval:(double) interval{
    return [self startSensorWithConfidenceFilter:filterLevel mode:ActivityRecognitionModeHistory interval:interval];
}

- (BOOL) startSensorWithConfidenceFilter:(CMMotionActivityConfidence) filterLevel
                        mode:(ActivityRecognitionMode)mode
                    interval:(double) interval{
    
    confidenceFilter = filterLevel;
    sensingMode = mode;
    
    // history mode
    if( mode == ActivityRecognitionModeHistory){
        [self getMotionActivity:nil];
        timer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                 target:self
                                               selector:@selector(getMotionActivity:)
                                               userInfo:nil
                                                repeats:YES];
    // live mode
    }else if( mode == ActivityRecognitionModeLive ){
        /** motion activity */
        if([CMMotionActivityManager isActivityAvailable]){
            motionActivityManager = [CMMotionActivityManager new];
            [motionActivityManager startActivityUpdatesToQueue:[NSOperationQueue new]
                                                   withHandler:^(CMMotionActivity *activity) {
                                                       dispatch_async(dispatch_get_main_queue(), ^{
                                                           [self addMotionActivity:activity];
                                                       });
                                                   }];
        }else{
            return NO;
        }
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
    [self getMotionActivity:nil];
}


//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

- (void) getMotionActivity:(id)sender{
    
    NSOperationQueue *operationQueueUpdate = [NSOperationQueue mainQueue];
    if([CMMotionActivityManager isActivityAvailable]){
        // from data
        NSDate * fromDate = [self getLastUpdate];
//        NSDate * fromDate = [AWAREUtils getTargetNSDate:[NSDate new] hour:-7*24 nextDay:NO];
        // to date
        NSDate * toDate = [NSDate new];
        motionActivityManager = [CMMotionActivityManager new];
        [motionActivityManager queryActivityStartingFromDate:fromDate toDate:toDate toQueue:operationQueueUpdate withHandler:^(NSArray<CMMotionActivity *> * _Nullable activities, NSError * _Nullable error) {
            if (activities!=nil && error==nil) {
                // [[[NSOperationQueue alloc] init] addOperationWithBlock:^{
                if(activities.count > 1000){
                    [self setBufferSize:1000];
                }else if(activities.count > 100){
                    [self setBufferSize:100];
                }else if (activities.count > 50) {
                    [self setBufferSize:50];
                }else if(activities.count > 20){
                    [self setBufferSize:20];
                }else{
                    [self setBufferSize:0];
                }
                
                if (NSThread.isMainThread){
                    NSLog(@"[activity] sensor: main thread");
                }else{
                    NSLog(@"[activity] sensor: not main thread");
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    for (CMMotionActivity * activity in activities) {
                        [self addMotionActivity:activity];
                    }
                    [self setLastUpdateWithDate:toDate];
                    [self setBufferSize:0];
                    if ([self isDebug]) {
                        NSString * message = [NSString stringWithFormat:@"Activity Recognition Sensor is called by a timer (%ld activites)" ,activities.count];
                        [AWAREUtils sendLocalNotificationForMessage:message soundFlag:NO];
                    }
                });
            }
        }];
    }
}


////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////


- (void) addMotionActivity: (CMMotionActivity *) motionActivity{
    
    // NSLog(@"%ld", motionActivity.confidence);
    
    switch (confidenceFilter) {
        case CMMotionActivityConfidenceHigh:
            if(motionActivity.confidence == CMMotionActivityConfidenceMedium ||
               motionActivity.confidence == CMMotionActivityConfidenceLow){
                return;
            }
            break;
        case CMMotionActivityConfidenceMedium:
            if(motionActivity.confidence == CMMotionActivityConfidenceLow){
                return;
            }
            break;
        case CMMotionActivityConfidenceLow:
            break;
        default:
            break;
    }
    
    // NSLog(@"stored");
    
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
        motionType = @0;
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

    if([self getDBType] == AwareDBTypeTextFile){
        activitiesStr = @"";
    }
    
    if ([self isDebug]) {
        NSLog(@"[%@] %@ %ld", motionActivity.startDate, motionName, motionActivity.confidence);
    }
    
    // dispatch_async(dispatch_get_main_queue(), ^{
    NSNumber * unixtime = [AWAREUtils getUnixTimestamp:motionActivity.startDate];

    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:unixtime forKey:@"timestamp"];
    [dict setObject:[self getDeviceId] forKey:@"device_id"];
    [dict setObject:motionName forKey:@"activity_name"]; //varchar
    [dict setObject:[motionType stringValue] forKey:@"activity_type"]; //text
    [dict setObject:motionConfidence forKey:@"confidence"]; //int
    [dict setObject:activitiesStr forKey:@"activities"]; //text
    [self setLatestValue:[NSString stringWithFormat:@"%@, %@, %@", motionName, motionType, motionConfidence]];
    [self saveData:dict];
    [self setLatestData:dict];
    
    NSDictionary * userInfo = [NSDictionary dictionaryWithObject:dict
                                                          forKey:EXTRA_DATA];
    [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_GOOGLE_ACTIVITY_RECOGNITION
                                                            object:nil
                                                          userInfo:userInfo];
    // });
}

- (void)insertNewEntityWithData:(NSDictionary *)data
           managedObjectContext:(NSManagedObjectContext *)childContext
                     entityName:(NSString *)entity{
    
    EntityActivityRecognition * entityActivity = (EntityActivityRecognition *)[NSEntityDescription insertNewObjectForEntityForName:entity
                                                                                                  inManagedObjectContext:childContext];
    entityActivity.device_id = [data objectForKey:@"device_id"];
    entityActivity.timestamp = [data objectForKey:@"timestamp"];
    entityActivity.confidence = [data objectForKey:@"confidence"];
    entityActivity.activities =    [data objectForKey:@"activities"];
    entityActivity.activity_name = [data objectForKey:@"activity_name"];
    entityActivity.activity_type = [data objectForKey:@"activity_type"];
    
}


- (void)saveDummyData{
    NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:unixtime forKey:@"timestamp"];
    [dict setObject:[self getDeviceId] forKey:@"device_id"];
    [dict setObject:@"dummy" forKey:@"activity_name"]; //varchar
    [dict setObject:@"dummy" forKey:@"activity_type"]; //text
    [dict setObject:@0 forKey:@"confidence"]; //int
    [dict setObject:@"" forKey:@"activities"]; //text
    [self saveData:dict];
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

- (NSDate *) getLastUpdate {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDate * date = [defaults objectForKey:KEY_TIMESTAMP_OF_LAST_UPDATE];
    if (date != nil) {
        return date;
    }else{
        return [NSDate new];
    }
}

@end
