//
//  AWARESensorViewController.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/19/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//


/**
 * 2/16/2016 by Yuuki NISHIYAMA
 * 
 * The AWARESensor class is the super class of aware sensors, and wraps to access
 * local storages(LocalFileStorageHelper) and to upload sensor data to
 * an AWARE server(AWAREDataUploader).
 *
 * LocalFileStorageHelper:
 * LocalFileStoragehelper is a text file based local storage. And also, a developer can store 
 * a sensor data with a NSDictionary Object using -(bool)saveData:(NSDictionary *)data;.
 * [WIP] Now I'm making a CoreData based storage for more stable data management.
 *
 * AWAREDataUploader:
 * This class supports data upload in the background/foreground. You can upload data by using -(void)syncAwareDB; 
 * or -(BOOL)syncAwareDBInForeground;. AWAREDataUploader obtains uploading sensor data from LocalFileStorageHelper
 * by -(NSMutableString *)getSensorDataForPost;
 *
 */


#import "AWARESensor.h"
#import "AWAREKeys.h"
#import "AWAREStudy.h"

#import "SCNetworkReachability.h"
#import "LocalFileStorageHelper.h"
#import "AWAREDataUploader.h"
#import "Debug.h"

@interface AWARESensor () {
    /** aware sensor name */
    NSString * awareSensorName;
    /** latest Sensor Value */
    NSString * latestSensorValue;

    /** debug state */
    bool debug;
    /** network state */
    NSInteger networkState;
    
    /** debug sensor*/
    Debug * debugSensor;
    /** aware study*/
    AWAREStudy * awareStudy;
    /** aware local storage (text) */
    LocalFileStorageHelper * localStorage;
    /** sensor data uploader */
    AWAREDataUploader *uploader;
}

@end

@implementation AWARESensor

- (instancetype) initWithSensorName:(NSString *)sensorName withAwareStudy:(AWAREStudy *)study {
    if (self = [super init]) {
        NSLog(@"[%@] Initialize an AWARESensor as '%@' ", sensorName, sensorName);
        // Get debug state
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        debug = [userDefaults boolForKey:SETTING_DEBUG_STATE];
        
        if(study == nil){
            // If the study object is nil(null), the initializer gnerates a new AWAREStudy object.
            awareStudy = [[AWAREStudy alloc] initWithReachability:NO];
        }else{
            awareStudy = study;
        }
        // Save sensorName instance to awareSensorName
        awareSensorName = sensorName;
        // Initialize the latest sensor value with an empty object (@"").
        latestSensorValue = @"";
        
        
        // Make a local storage with sensor name
        localStorage = [[LocalFileStorageHelper alloc] initWithStorageName:sensorName];
        // Make an uploader instance with the local storage and an aware study instance.
        uploader = [[AWAREDataUploader alloc] initWithLocalStorage:localStorage withAwareStudy:awareStudy];
    }
    return self;
}


//////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////

/// All subclass of AWARESensor have to implemtn following
/// three methods based on the AWARESensorDelegate:
/// -(BOOL)clearTable;
/// -(BOOL)startSensor:(double)upInterval withSettings:(NSArray *)settings;
/// -(BOOL)stopSensor;


/**
 * DEFAULT:
 *
 */
- (BOOL)clearTable{
    return NO;
}


/**
 * DEFAULT:
 *
 */
-(BOOL)startSensor:(double)upInterval withSettings:(NSArray *)settings{
    return NO;
}


/**
 * DEFAULT:
 */
- (BOOL)stopSensor{
    return NO;
}



//////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////

/**
 * Set the latest sensor data
 *
 * @param   NSString    The latest sensor value as a NSString value
 */

- (void) setLatestValue:(NSString *)valueStr{
    latestSensorValue = valueStr;
}

/**
 * Set buffer size of sensor data
 * NOTE: If you use high sampling rate sensor (such as an accelerometer, gyroscope, and magnetic-field),
 * you shold use to set buffer value.
 * @param int A buffer size
 */
- (void) setBufferSize:(int) size{
    [localStorage setBufferSize:size];
}


//////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////

/**
 * Get the latest sensor value as a NSString
 *
 * @return The latest sensor data as a NSString
 */
- (NSString *)getLatestValue{
    return latestSensorValue;
}

/**
 * Get a device_id
 * @return A device_id
 */
- (NSString *) getDeviceId {
    return [awareStudy getDeviceId];
}

/**
 * Get a sensor name of this sensor
 * @return A sensor name of this AWARESensor
 */
- (NSString *) getSensorName{
    return awareSensorName;
}




//////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////

- (void) createTable {
    
}

/**
 * Send a query for creating a table of this sensor on an AWARE Server (MySQL).
 * @param   NSString    A query for creating a database table
 */
- (void) createTable:(NSString *) query {
    [uploader createTable:query];
}

/**
 * Send a query for creating a table of this sensor on an AWARE Server (MySQL) with a sensor name.
 * @param   NSString    A query for creating a database table
 */
- (void) createTable:(NSString *)query withTableName:(NSString *)tableName{
    [uploader createTable:query withTableName:tableName];
}



//////////////////////////////////////////
////////////////////////////////////////

//// save data
- (bool) saveDataWithArray:(NSArray*) array {
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




//////////////////////////////////////////
////////////////////////////////////////

//////////////////////////////////////////
////////////////////////////////////////
/**
 * Background sync method
 */

- (void) syncAwareDB{
    [uploader syncAwareDB];
}


//////////////////////////////////////////
////////////////////////////////////////
/**
 * Fourground sync method
 */
- (BOOL) syncAwareDBInForeground{
    return [uploader syncAwareDBInForeground];
}


- (BOOL) syncAwareDBWithData:(NSDictionary *) dictionary{
    return [uploader syncAwareDBWithData:dictionary];
}

- (void) sensorLock{
    [localStorage dbLock];
    [uploader lockBackgroundUpload];
}

- (void) sensorUnLock{
    [localStorage dbUnlock];
    [uploader unlockBackgroundUpload];
}


//////////////////////////////////////////
////////////////////////////////////////

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
 * A wrapper method for saving debug message
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

/// Utils

/**
 * Get a sensor setting(such as a sensing frequency) from settings with Key
 *
 * @param NSArray   Settings
 * @param NSString  A key for the target setting
 * @return A double value of the setting.
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


/**
 * Convert an iOS motion sensor frequency from an Androind frequency.
 *
 * @param   double  A sensing frequency for Andrind
 * @return  double  A sensing frequency for iOS
 */
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

/// For debug
/**
 Local push notification method
 @param message text message for notification
 @param sound type of sound for notification
 */
- (void)sendLocalNotificationForMessage:(NSString *)message soundFlag:(BOOL)soundFlag {
    [AWAREUtils sendLocalNotificationForMessage:message soundFlag:soundFlag];
}


/**
 * Start a debug event tracker
 */
- (void) trackDebugEvents {
    debugSensor = [[Debug alloc] initWithAwareStudy:awareStudy];
    [localStorage trackDebugEventsWithDebugSensor:debugSensor];
    [uploader trackDebugEventsWithDebugSensor:debugSensor];
}

/**
 * Get a debug sensor state
 */
- (bool) isDebug{
    return debug;
}

- (NSString *) getWebserviceUrl{
    return [uploader getWebserviceUrl];
}

- (NSString *) getInsertUrl:(NSString *)sensorName{
    return [uploader getInsertUrl:sensorName];
}

- (NSString *) getLatestDataUrl:(NSString *)sensorName{
    return [uploader getLatestDataUrl:sensorName];
}

- (NSString *) getCreateTableUrl:(NSString *)sensorName{
    return [uploader getCreateTableUrl:sensorName];
}

- (NSString *) getClearTableUrl:(NSString *)sensorName{
    return [uploader getCreateTableUrl:sensorName];
}

@end
