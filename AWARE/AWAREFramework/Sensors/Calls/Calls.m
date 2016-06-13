//
//  Telephony.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 1/19/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//
//  http://www.awareframework.com/communication/
//  https://developer.apple.com/library/ios/documentation/ContactData/Conceptual/AddressBookProgrammingGuideforiPhone/Chapters/QuickStart.html#//apple_ref/doc/uid/TP40007744-CH2-SW1
//

#import "Calls.h"
#import "AWAREUtils.h"
#import "EntityCall.h"
#import "AppDelegate.h"

NSString* const KEY_CALLS_TIMESTAMP = @"timestamp";
NSString* const KEY_CALLS_DEVICEID = @"device_id";
NSString* const KEY_CALLS_CALL_TYPE = @"call_type";
NSString* const KEY_CALLS_CALL_DURATION = @"call_duration";
NSString* const KEY_CALLS_TRACE = @"trace";

@implementation Calls {
    NSDate * start;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study{
    self = [super initWithAwareStudy:study
                          sensorName:@"calls"
                        dbEntityName:NSStringFromClass([EntityCall class])
                              dbType:AwareDBTypeCoreData];
    if (self) {
    }
    return self;
}

- (void)syncAwareDB{
    [super syncAwareDB];
}

- (void) createTable{
    
    NSLog(@"[%@] Create Telephony Sensor Table", [self getSensorName]);
    
    NSMutableString *query = [[NSMutableString alloc] init];
    [query appendString:@"_id integer primary key autoincrement,"];
    [query appendString:[NSString stringWithFormat:@"%@ real default 0,", KEY_CALLS_TIMESTAMP]];
    [query appendString:[NSString stringWithFormat:@"%@ text default '',", KEY_CALLS_DEVICEID]];
    [query appendString:[NSString stringWithFormat:@"%@ integer default 0,", KEY_CALLS_CALL_TYPE]];
    [query appendString:[NSString stringWithFormat:@"%@ integer default 0,", KEY_CALLS_CALL_DURATION]];
    [query appendString:[NSString stringWithFormat:@"%@ text default '',", KEY_CALLS_TRACE ]];
    [query appendString:@"UNIQUE (timestamp,device_id)"];
    [super createTable:query];
}


-(BOOL)startSensorWithSettings:(NSArray *)settings{
    // Set and start a call sensor
    _callCenter = [[CTCallCenter alloc] init];
    _callCenter.callEventHandler = ^(CTCall* call){
        NSString * callId = call.callID;
        NSNumber * callType = @0;
        NSString * callTypeStr = @"Unknown";
        int duration = 0;
        if (start == nil) start = [NSDate new];
        
        // one of the Android’s call types (1 – incoming, 2 – outgoing, 3 – missed)
        if (call.callState == CTCallStateIncoming) {
            // start
            callType = @1;
            start = [NSDate new];
            callTypeStr = @"Incoming";
        } else if (call.callState == CTCallStateConnected){
            callType = @2;
            duration = [[NSDate new] timeIntervalSinceDate:start];
            start = [NSDate new];
            callTypeStr = @"Connected";
        } else if (call.callState == CTCallStateDialing){
            // start
            callType = @3;
            start = [NSDate new];
            callTypeStr = @"Dialing";
        } else if (call.callState == CTCallStateDisconnected){
            // fin
            callType = @4;
            callTypeStr = @"Disconnected";
            duration = [[NSDate new] timeIntervalSinceDate:start];
            start = [NSDate new];
        }
        
        
        NSLog(@"[%@] Call Duration is %d seconds @ [%@]", [super getSensorName], duration, callTypeStr);
        NSNumber *durationValue = [NSNumber numberWithInt:duration];
//        NSMutableDictionary* dic = [[NSMutableDictionary alloc] init];
//        [dic setObject:[AWAREUtils getUnixTimestamp:[NSDate new]] forKey:KEY_CALLS_TIMESTAMP];
//        [dic setObject:[super getDeviceId] forKey:KEY_CALLS_DEVICEID];
//        [dic setObject:callType forKey:KEY_CALLS_CALL_TYPE];
//        [dic setObject:durationValue forKey:KEY_CALLS_CALL_DURATION];
//        [dic setObject:callId forKey:KEY_CALLS_TRACE];
        
        AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
        EntityCall* callData = (EntityCall *)[NSEntityDescription
                                        insertNewObjectForEntityForName:NSStringFromClass([EntityCall class])
                                        inManagedObjectContext:delegate.managedObjectContext];
        callData.device_id = [super getDeviceId];
        callData.timestamp = [AWAREUtils getUnixTimestamp:[NSDate new]];
        callData.call_type = callType;
        callData.call_duration = @(duration);
        callData.trace = callId;
        
        NSError * error = nil;
        [delegate.managedObjectContext save:&error];
        if (error) {
            NSLog(@"%@", error.description);
        }
        [delegate.managedObjectContext reset];
        
        // Set latest sensor data
        NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
        [timeFormat setDateFormat:@"YYYY-MM-dd HH:mm"];
        NSString * dateStr = [timeFormat stringFromDate:[NSDate new]];
        NSString * latestData = [NSString stringWithFormat:@"%@ [%@] %d seconds",dateStr, callTypeStr, duration];
        [super setLatestValue: latestData];
        

        // Broadcast a notification
        // http://www.awareframework.com/communication/
        // [NOTE] On the Andoind AWARE client, when the ACTION_AWARE_USER_NOT_IN_CALL and ACTION_AWARE_USER_IN_CALL are called?
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:callData forKey:EXTRA_DATA];
        if (call.callState == CTCallStateIncoming) {
            [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_CALL_RINGING
                                                                object:nil
                                                              userInfo:userInfo];
        } else if (call.callState == CTCallStateConnected){
            [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_CALL_ACCEPTED
                                                                object:nil
                                                              userInfo:userInfo];
            [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_USER_IN_CALL
                                                                object:nil
                                                              userInfo:userInfo];
        } else if (call.callState == CTCallStateDialing){
            [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_CALL_MADE
                                                                object:nil
                                                              userInfo:userInfo];
        } else if (call.callState == CTCallStateDisconnected){
            [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_CALL_MISSED
                                                                object:nil
                                                              userInfo:userInfo];
            [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_USER_NOT_IN_CALL
                                                                object:nil
                                                              userInfo:userInfo];
        }
        
        // Save a call event (, this sensor using TextFile based DB.)
        // [super saveData:dic];
    };
    
    return YES;
}

-(BOOL) stopSensor{
    _callCenter.callEventHandler = nil;
    return YES;
}


////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////



- (void) sendLocalNotificationWithCallId : (NSString *) callId
                                 soundFlag : (BOOL) soundFlag {
    UILocalNotification *localNotification = [UILocalNotification new];
    CGFloat currentVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    NSLog(@"OS:%f", currentVersion);
    if (currentVersion >= 9.0){
        localNotification.alertBody = @"Call from/to who?";
    } else {
        localNotification.alertBody = @"Call from/to who?";
    }
    localNotification.fireDate = [NSDate new];
    localNotification.timeZone = [NSTimeZone localTimeZone];
    localNotification.category = callId;
    if(soundFlag) {
        localNotification.soundName = UILocalNotificationDefaultSoundName;
    }
    localNotification.applicationIconBadgeNumber = 1;
    localNotification.hasAction = YES;
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}

@end
