//
//  IOSActivityRecognition.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 9/19/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "IOSActivityRecognition.h"
#import "AppDelegate.h"
#import "EntityIOSActivityRecognition+CoreDataClass.h"

@implementation IOSActivityRecognition {
    CMMotionActivityManager *motionActivityManager;
    NSString * KEY_TIMESTAMP_OF_LAST_UPDATE;
    NSTimer * timer;
    double defaultInterval;
    IOSActivityRecognitionMode sensingMode;
    CMMotionActivityConfidence confidenceFilter;
    
    /* stationary,walking,running,automotive,cycling,unknown */
    NSString * ACTIVITY_NAME_STATIONARY;
    NSString * ACTIVITY_NAME_WALKING;
    NSString * ACTIVITY_NAME_RUNNING;
    NSString * ACTIVITY_NAME_AUTOMOTIVE;
    NSString * ACTIVITY_NAME_CYCLING;
    NSString * ACTIVITY_NAME_UNKNOWN;
    NSString * CONFIDENCE;
    NSString * ACTIVITIES;
    NSString * LABEL;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    ACTIVITIES = @"activities";
    CONFIDENCE = @"confidence";
    ACTIVITY_NAME_STATIONARY = @"stationary";
    ACTIVITY_NAME_WALKING    = @"walking";
    ACTIVITY_NAME_RUNNING    = @"running";
    ACTIVITY_NAME_AUTOMOTIVE = @"automotive";
    ACTIVITY_NAME_CYCLING    = @"cycling";
    ACTIVITY_NAME_UNKNOWN    = @"unknown";
    LABEL = @"label";
    
    self = [super initWithAwareStudy:study
                          sensorName:SENSOR_IOS_ACTIVITY_RECOGNITION
                        dbEntityName:NSStringFromClass([EntityIOSActivityRecognition class])
                              dbType:dbType];
    
    if (self) {
        motionActivityManager = [[CMMotionActivityManager alloc] init];
        KEY_TIMESTAMP_OF_LAST_UPDATE = @"key_sensor_ios_activity_recognition_last_update_timestamp";
        defaultInterval = 60*3; // 3 min
        sensingMode = IOSActivityRecognitionModeLive;
        confidenceFilter = CMMotionActivityConfidenceLow;
        [self setCSVHeader:@[@"timestamp",
                             @"device_id",
                             ACTIVITIES,
                             CONFIDENCE,
                             ACTIVITY_NAME_STATIONARY,
                             ACTIVITY_NAME_WALKING,
                             ACTIVITY_NAME_RUNNING,
                             ACTIVITY_NAME_AUTOMOTIVE,
                             ACTIVITY_NAME_CYCLING,
                             ACTIVITY_NAME_UNKNOWN,
                             LABEL]];
    }
    return self;
}

- (void) createTable{
    
    // creata original table
    NSString *query = [[NSString alloc] init];
    
    /*
    query = @"_id integer primary key autoincrement,"
    "timestamp real default 0,"
    "device_id text default '',"
    "activity_name text default '',"
    "activity_type text default '',"
    "confidence int default 4,"
    "activities text default ''";
    */
    
    // https://developer.apple.com/reference/coremotion/cmmotionactivity?language=objc
    TCQMaker * tcqMaker = [[TCQMaker alloc] init];
    [tcqMaker addColumn:ACTIVITIES               type:TCQTypeText    default:@"''"  ];   // e.g., stationary,cycling
    [tcqMaker addColumn:CONFIDENCE               type:TCQTypeInteger default:@"-1"];   // -1=Unknown; 0=Low(low); 1=Medium(good); 2=High(high)
    [tcqMaker addColumn:ACTIVITY_NAME_STATIONARY type:TCQTypeInteger default:@"0" ];   // 0 or 1
    [tcqMaker addColumn:ACTIVITY_NAME_WALKING    type:TCQTypeInteger default:@"0" ];   // 0 or 1
    [tcqMaker addColumn:ACTIVITY_NAME_RUNNING    type:TCQTypeInteger default:@"0" ];   // 0 or 1
    [tcqMaker addColumn:ACTIVITY_NAME_AUTOMOTIVE type:TCQTypeInteger default:@"0" ];   // 0 or 1
    [tcqMaker addColumn:ACTIVITY_NAME_CYCLING    type:TCQTypeInteger default:@"0" ];   // 0 or 1
    [tcqMaker addColumn:ACTIVITY_NAME_UNKNOWN    type:TCQTypeInteger default:@"0" ];   // 0 or 1
    [tcqMaker addColumn:LABEL                    type:TCQTypeText    default:@"''"  ];
    
    query = [tcqMaker getDefaudltTableCreateQuery];
    /* stationary,walking,running,automotive,cycling,unknown */
    
    [super createTable:query];
}


- (BOOL)startSensorWithSettings:(NSArray *)settings{
    NSLog(@"Start Motion Activity Manager! ");
    
    
    double frequency = [self getSensorSetting:settings withKey:@"frequency_plugin_ios_activity_recognition"];
    if (frequency < defaultInterval) {
        frequency = defaultInterval;
    }
    
    int liveMode = [self getSensorSetting:settings withKey:@"status_plugin_ios_activity_recognition_live"];
    
    if(liveMode){
        return [self startSensorWithConfidenceFilter:CMMotionActivityConfidenceLow mode:IOSActivityRecognitionModeLive interval:frequency];
    }else{
        return [self startSensorWithConfidenceFilter:CMMotionActivityConfidenceLow mode:IOSActivityRecognitionModeHistory interval:frequency];
    }
}


- (BOOL) startSensorWithLiveMode:(CMMotionActivityConfidence) filterLevel{
    return [self startSensorWithConfidenceFilter:filterLevel mode:IOSActivityRecognitionModeLive interval:defaultInterval];
}

- (BOOL) startSensorWithHistoryMode:(CMMotionActivityConfidence)filterLevel interval:(double) interval{
    return [self startSensorWithConfidenceFilter:filterLevel mode:IOSActivityRecognitionModeHistory interval:interval];
}

- (BOOL) startSensorWithConfidenceFilter:(CMMotionActivityConfidence) filterLevel
                                    mode:(IOSActivityRecognitionMode)mode
                                interval:(double) interval{
    
    confidenceFilter = filterLevel;
    sensingMode = mode;
    
    // history mode
    if( mode == IOSActivityRecognitionModeHistory){
        [self getMotionActivity:nil];
        timer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                 target:self
                                               selector:@selector(getMotionActivity:)
                                               userInfo:nil
                                                repeats:YES];
        // live mode
    }else if( mode == IOSActivityRecognitionModeLive ){
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
                [[[NSOperationQueue alloc] init] addOperationWithBlock:^{
                    
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
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        for (CMMotionActivity * activity in activities) {
                            [self addMotionActivity:activity];
                        }
                        [self setLastUpdateWithDate:toDate];
                        [self setBufferSize:0];
                    });
                }];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([self isDebug]) {
                        NSInteger count = activities.count;
                        NSString * message = [NSString stringWithFormat:@"Activity Recognition Sensor is called by a timer (%ld activites)" ,count];
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
    
    NSNumber *motionConfidence = @(-1);
    if (motionActivity.confidence  == CMMotionActivityConfidenceHigh){
        motionConfidence = @2;
    }else if(motionActivity.confidence == CMMotionActivityConfidenceMedium){
        motionConfidence = @1;
    }else if(motionActivity.confidence == CMMotionActivityConfidenceLow){
        motionConfidence = @0;
    }
    
    // Motion types are refere from Google Activity Recognition
    //https://developers.google.com/android/reference/com/google/android/gms/location/DetectedActivity
    NSMutableArray * activities = [[NSMutableArray alloc] init];
    
    if (motionActivity.unknown){
        [activities addObject:ACTIVITY_NAME_UNKNOWN];
    }
    
    if (motionActivity.stationary){
        [activities addObject:ACTIVITY_NAME_STATIONARY];
    }
    
    if (motionActivity.running){
        [activities addObject:ACTIVITY_NAME_RUNNING];
    }
    
    if (motionActivity.walking){
        [activities addObject:ACTIVITY_NAME_WALKING];
    }
    
    if (motionActivity.automotive){
        [activities addObject:ACTIVITY_NAME_AUTOMOTIVE];
    }
    
    if (motionActivity.cycling){
        [activities addObject:ACTIVITY_NAME_CYCLING];
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
    
    //if([self getDBType] == AwareDBTypeTextFile){
    //    activitiesStr = @"";
    //}
    
    if ([self isDebug]) {
        NSLog(@"[%@] %@ %ld", motionActivity.startDate, activitiesStr, motionActivity.confidence);
    }
    
    NSNumber * unixtime = [AWAREUtils getUnixTimestamp:motionActivity.startDate];
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:unixtime                     forKey:@"timestamp"];
    [dict setObject:[self getDeviceId]           forKey:@"device_id"];
    [dict setObject:activitiesStr                forKey:ACTIVITIES];
    [dict setObject:motionConfidence             forKey:CONFIDENCE];
    [dict setObject:@(motionActivity.stationary) forKey:ACTIVITY_NAME_STATIONARY];   // 0 or 1
    [dict setObject:@(motionActivity.walking)    forKey:ACTIVITY_NAME_WALKING];   // 0 or 1
    [dict setObject:@(motionActivity.running)    forKey:ACTIVITY_NAME_RUNNING];   // 0 or 1
    [dict setObject:@(motionActivity.automotive) forKey:ACTIVITY_NAME_AUTOMOTIVE];   // 0 or 1
    [dict setObject:@(motionActivity.cycling)    forKey:ACTIVITY_NAME_CYCLING];   // 0 or 1
    [dict setObject:@(motionActivity.unknown)    forKey:ACTIVITY_NAME_UNKNOWN];   // 0 or 1
    [dict setObject:@""                          forKey:LABEL];
    
    [self setLatestValue:[NSString stringWithFormat:@"%@ (%@)", activities, motionConfidence]];
    [self saveData:dict];
    [self setLatestData:dict];
    
    NSDictionary * userInfo = [NSDictionary dictionaryWithObject:dict
                                                          forKey:EXTRA_DATA];
    [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_IOS_ACTIVITY_RECOGNITION
                                                        object:nil
                                                      userInfo:userInfo];
}


- (void)insertNewEntityWithData:(NSDictionary *)data
           managedObjectContext:(NSManagedObjectContext *)childContext
                     entityName:(NSString *)entity{
    
    EntityIOSActivityRecognition * entityActivity = (EntityIOSActivityRecognition *)[NSEntityDescription insertNewObjectForEntityForName:entity
                                                                                                            inManagedObjectContext:childContext];
    entityActivity.device_id  = [data objectForKey:@"device_id"];
    entityActivity.timestamp  = [data objectForKey:@"timestamp"];
    entityActivity.confidence = [data objectForKey:CONFIDENCE];
    entityActivity.activities = [data objectForKey:ACTIVITIES];
    entityActivity.label      = [data objectForKey:LABEL];
    entityActivity.stationary = [data objectForKey:ACTIVITY_NAME_STATIONARY];
    entityActivity.walking    = [data objectForKey:ACTIVITY_NAME_WALKING];
    entityActivity.running    = [data objectForKey:ACTIVITY_NAME_RUNNING];
    entityActivity.automotive = [data objectForKey:ACTIVITY_NAME_AUTOMOTIVE];
    entityActivity.cycling    = [data objectForKey:ACTIVITY_NAME_CYCLING];
    entityActivity.unknown    = [data objectForKey:ACTIVITY_NAME_UNKNOWN];
    
}


- (void)saveDummyData{
    NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:unixtime            forKey:@"timestamp"];
    [dict setObject:[self getDeviceId]  forKey:@"device_id"];
    [dict setObject:@"test activites"   forKey:ACTIVITIES];
    [dict setObject:@(-1)   forKey:CONFIDENCE];
    [dict setObject:@0      forKey:ACTIVITY_NAME_STATIONARY];   // 0 or 1
    [dict setObject:@0      forKey:ACTIVITY_NAME_WALKING];   // 0 or 1
    [dict setObject:@0      forKey:ACTIVITY_NAME_RUNNING];   // 0 or 1
    [dict setObject:@0      forKey:ACTIVITY_NAME_AUTOMOTIVE];   // 0 or 1
    [dict setObject:@0      forKey:ACTIVITY_NAME_CYCLING];   // 0 or 1
    [dict setObject:@0      forKey:ACTIVITY_NAME_UNKNOWN];   // 0 or 1
    [dict setObject:@"test" forKey:LABEL];
    
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
