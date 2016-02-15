//
//  AWARESensorViewController.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/19/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//


#import "AWARESensor.h"
#import "AWAREKeys.h"
#import "AWAREStudy.h"

#import "SCNetworkReachability.h"
#import "LocalFileStorageHelper.h"
#import "AWAREDataUploader.h"
#import "Debug.h"

@interface AWARESensor () {
    
    NSString * awareSensorName;
    NSString * latestSensorValue;
    
    NSMutableString *tempData;
    NSMutableString *bufferStr;
    
    // timer
    NSTimer* writeAbleTimer;

    bool debug;
    NSInteger networkState;
    
    Debug * debugSensor;
    AWAREStudy * awareStudy;
    LocalFileStorageHelper * localStorage;
    AWAREDataUploader *uploader;
}

@end

@implementation AWARESensor

- (instancetype) initWithSensorName:(NSString *)sensorName withAwareStudy:(AWAREStudy *)study {
    if (self = [super init]) {
        NSLog(@"[%@] Initialize an AWARESensor as '%@' ", sensorName, sensorName);
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        debug = [userDefaults boolForKey:SETTING_DEBUG_STATE];
        
        localStorage = [[LocalFileStorageHelper alloc] initWithStorageName:sensorName];
        
        if(study == nil){
            awareStudy = [[AWAREStudy alloc] init];
        }else{
            awareStudy = study;
        }
        
        awareSensorName = sensorName;
        latestSensorValue = @"";
        uploader = [[AWAREDataUploader alloc] initWithLocalStorage:localStorage withAwareStudy:awareStudy];
    }
    return self;
}


- (void) setLatestValue:(NSString *)valueStr{
    latestSensorValue = valueStr;
}
- (NSString *)getLatestValue{
    return latestSensorValue;
}


- (NSString *) getDeviceId {
    return [awareStudy getDeviceId];
}

- (NSString *) getSensorName{
    return awareSensorName;
}

- (void)createTable:(NSString *)query{
    [uploader createTable:query];
}

- (void) createTable:(NSString *)query withTableName:(NSString *)tableName{
    [uploader createTable:query withTableName:tableName];
}

- (BOOL)clearTable{
    return NO;
}

/**
 * DEFUALT: a start sensor method
 */
-(BOOL)startSensor:(double)upInterval withSettings:(NSArray *)settings{
    return NO;
}

/**
 * DEFUALT: a stop sensor method
 */
- (BOOL)stopSensor{
    [writeAbleTimer invalidate];
    writeAbleTimer = nil;
    return NO;
}


//// save data
- (bool) saveDataWithArray:(NSArray*) array{
    return [localStorage saveDataWithArray:array];
}

// save data
- (bool) saveData:(NSDictionary *)data{
    return [localStorage saveData:data];
}

// save data with local file
- (bool) saveData:(NSDictionary *)data toLocalFile:(NSString *)fileName{
    return [localStorage saveData:data toLocalFile:fileName];
}

- (void) setBufferSize:(int) size{
    [localStorage setBufferSize:size];
}


//////////////////////////////////////////
////////////////////////////////////////


/**
 * Background sync method
 */

- (void) syncAwareDB{
    [uploader syncAwareDB];
}

- (void) sensorLock{
    [localStorage dbLock];
    [uploader lockBackgroundUpload];
}

- (void) sensorUnLock{
    [localStorage dbUnlock];
    [uploader unlockBackgroundUpload];
}

/**
 * Fourground sync method
 */
- (BOOL) syncAwareDBInForeground{
    return [uploader syncAwareDBInForeground];
}


- (BOOL) syncAwareDBWithData:(NSDictionary *) dictionary{
    return [uploader syncAwareDBWithData:dictionary];
}

- (NSString *)getSyncProgressAsText{
    return [uploader getSyncProgressAsText];
}

- (NSString *) getSyncProgressAsText:(NSString *)sensorName{
    return [uploader getSyncProgressAsText:sensorName];
}

- (NSString *) getNetworkReachabilityAsText{
    return [uploader getNetworkReachabilityAsText];
}

- (bool)isUploading{
    return [uploader isUploading];
}

//////////////////////////////////////////
/////////////////////////////////////////




/**
 * A wrapper method for debug sensor
 */

- (bool)saveDebugEventWithText:(NSString *)eventText type:(NSInteger)type label:(NSString *)label{
    if (debugSensor != nil) {
        [debugSensor saveDebugEventWithText:eventText type:type label:label];
        return  YES;
    }
    return NO;
}


///////////////////////////////////
///////////////////////////////////



/**
 * Setting Conveters
 */
- (double)getSensorSetting:(NSArray *)settings withKey:(NSString *)key{
    if (settings != nil) {
        for (NSDictionary * setting in settings) {
            if ([[setting objectForKey:@"setting"] isEqualToString:key]) {
                double value = [[setting objectForKey:@"value"] doubleValue];
                return value;
            }
        }
    }
    return -1;
}


- (double) convertMotionSensorFrequecyFromAndroid:(double)frequency{
    //  Android: Non-deterministic frequency in microseconds
    // (dependent of the hardware sensor capabilities and resources),
    // e.g., 200000 (normal), 60000 (UI), 20000 (game), 0 (fastest).
    //  iOS: https://developer.apple.com/library/ios/documentation/EventHandling/Conceptual/EventHandlingiPhoneOS/motion_event_basics/motion_event_basics.html
    //  e.g 10-20Hz, 30-60Hz, 70-100Hz
    double y1 = 0.01;   //iOS 1 max
    double y2 = 0.1;    //iOS 2 min
    double x1 = 0;      //Android 1 max
    double x2 = 200000; //Android 2 min
    
    // y1 = a * x1 + b;
    // y2 = a * x2 + b;
    double a = (y1-y2)/(x1-x2);
    double b = y1 - x1*a;
//    y =a * x + b;
//    NSLog(@"%f", a *frequency + b);
    return a *frequency + b;
}

///////////////////////////////////////////////////////
///////////////////////////////////////////////////////


- (void)sendLocalNotificationForMessage:(NSString *)message soundFlag:(BOOL)soundFlag {
    [AWAREUtils sendLocalNotificationForMessage:message soundFlag:soundFlag];
}


/**
 * Set Debug Sensor
 */
- (void) trackDebugEvents {
    debugSensor = [[Debug alloc] initWithAwareStudy:awareStudy];
    [localStorage trackDebugEventsWithDebugSensor:debugSensor];
    [uploader trackDebugEventsWithDebugSensor:debugSensor];
}


- (bool) getDebugState {
    return debugSensor;
}


@end
