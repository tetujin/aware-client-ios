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
#import "AWARECoreDataManager.h"
#import "AWAREDataUploader.h"
#import "AWAREUploader.h"

#import "SCNetworkReachability.h"
#import "LocalFileStorageHelper.h"
#import "Debug.h"

@interface AWARESensor () {
    /** aware sensor name */
    NSString * awareSensorName;
    /** entity name */
    NSString * dbEntityName;
    /** latest Sensor Value */
    NSString * latestSensorValue;
    /** buffer size */
    int bufferSize;

    /** debug state */
    bool debug;
    /** network state */
    NSInteger networkState;
    
    /** debug sensor*/
    Debug * debugSensor;
    /** aware study*/
    AWAREStudy * awareStudy;

    
    AwareDBType awareDBType;
    
    /// Base Uploader
    AWAREUploader * baseDataUploader;

    ///////////// text file based database ////////////////
    /** aware local storage (text) */
    LocalFileStorageHelper * localStorage;
    /** sensor data uploader */
//    AWAREDataUploader *uploader;
    
    ////////////// CoroData //////////////////////////////
//    AWARECoreDataManager * coreDataManager;

    BOOL sensorStatus;
}

@end

@implementation AWARESensor

- (instancetype) initWithAwareStudy:(AWAREStudy *)study{
    return [self initWithAwareStudy:study sensorName:@"---" dbEntityName:@"---"];
}


- (instancetype) initWithAwareStudy:(AWAREStudy *)study
                         sensorName:(NSString *)sensorName
                       dbEntityName:(NSString *)entityName {
    return [self initWithAwareStudy:study sensorName:sensorName dbEntityName:entityName dbType:AwareDBTypeCoreData];
}

- (instancetype) initWithAwareStudy:(AWAREStudy *)study
                         sensorName:(NSString *)sensorName
                       dbEntityName:(NSString *)entityName
                             dbType:(AwareDBType)dbType{
    return [self initWithAwareStudy:study sensorName:sensorName dbEntityName:entityName dbType:dbType bufferSize:0];
}

- (instancetype) initWithAwareStudy:(AWAREStudy *)study
                         sensorName:(NSString *)sensorName
                       dbEntityName:(NSString *)entityName
                             dbType:(AwareDBType)dbType
                         bufferSize:(int)buffer{
    if (self = [super init]) {
        
        sensorStatus = NO;
        
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
        
        // Set db entity name
        dbEntityName = entityName;
        
        // Initialize the latest sensor value with an empty object (@"").
        latestSensorValue = @"";
        
        // init buffer size
        bufferSize = buffer;
        
        // AWARE DB setting
        awareDBType = dbType;
        
        switch (dbType) {
            case AwareDBTypeCoreData:
                 baseDataUploader = [[AWARECoreDataManager alloc] initWithAwareStudy:awareStudy sensorName:sensorName dbEntityName:dbEntityName];
                NSLog(@"[%@] Initialize an AWARESensor as '%@' with CoreData (EntityName=%@,BufferSize=%d)", sensorName, sensorName, dbEntityName, bufferSize);
                break;
            case AwareDBTypeTextFile:
                // Make a local storage with sensor name
                localStorage = [[LocalFileStorageHelper alloc] initWithStorageName:sensorName];
                // Make an uploader instance with the local storage and an aware study instance.
                 baseDataUploader = [[AWAREDataUploader alloc] initWithLocalStorage:localStorage withAwareStudy:awareStudy];
                NSLog(@"[%@] Initialize an AWARESensor as '%@' with TextFile (DBName=%@,BufferSize=%d)", sensorName, sensorName, sensorName, bufferSize);
                break;
            default:
                break;
        }
    }
    return self;
}


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
-(BOOL)startSensorWithSettings:(NSArray *)settings{
    return [self startSensor];
}

- (BOOL) startSensor {
    sensorStatus = YES;
    return NO;
}

/**
 * DEFAULT:
 */
- (BOOL)stopSensor{
    sensorStatus = NO;
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
    bufferSize = size;
    if (localStorage != nil) {
        [localStorage setBufferSize:size];
    }
    if (baseDataUploader != nil){
        [baseDataUploader setBufferSize:size];
    }
}


- (void)setFetchLimit:(int)limit{ [baseDataUploader setFetchLimit:limit]; }

- (void)setFetchBatchSize:(int)size{ [baseDataUploader setFetchBatchSize:size]; }

- (int) getFetchLimit{ return [baseDataUploader getFetchLimit]; }

- (int) getFetchBatchSize{ return [baseDataUploader getFetchBatchSize]; }

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

- (NSString *)getEntityName{
    return dbEntityName;
}

- (int) getBufferSize{
    return bufferSize;
    
}

- (NSInteger) getDBType{
    return awareDBType;
}

///////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////

- (void) changedBatteryState{
    
}

- (void) calledBackgroundFetch{
    
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
    [baseDataUploader createTable:query];
}

/**
 * Send a query for creating a table of this sensor on an AWARE Server (MySQL) with a sensor name.
 * @param   NSString    A query for creating a database table
 */
- (void) createTable:(NSString *)query withTableName:(NSString *)tableName{
    [baseDataUploader createTable:query withTableName:tableName];
}



//////////////////////////////////////////
////////////////////////////////////////

//// save data
- (bool) saveDataWithArray:(NSArray*) array {
    if(localStorage != nil){
        return [localStorage saveDataWithArray:array];
    }else{
        NSLog(@"local storage variable is nil");
        return NO;
    }
}

// save data
- (bool) saveData:(NSDictionary *)data{
    if(localStorage != nil){
        return [localStorage saveData:data];
    }else{
        NSLog(@"local storage variable is nil");
        return NO;
    }
}

// save data with local file
- (bool) saveData:(NSDictionary *)data toLocalFile:(NSString *)fileName{
    if(localStorage != nil){
        return [localStorage saveData:data toLocalFile:fileName];
    }else{
        return NO;
    }
}



- (BOOL) syncAwareDBWithData:(NSDictionary *) dictionary{
    [baseDataUploader syncAwareDBWithData:dictionary];
    return NO;
}


- (bool) saveDataToDB{
    return [baseDataUploader saveDataToDB];
}

//////////////////////////////////////////
////////////////////////////////////////

//////////////////////////////////////////
////////////////////////////////////////
/**
 * Background sync method
 */

- (void) syncAwareDB {
    [baseDataUploader syncAwareDBInBackground];
}


//////////////////////////////////////////
////////////////////////////////////////
/**
 * Fourground sync method
 */
- (BOOL) syncAwareDBInForeground{
    return [baseDataUploader syncAwareDBInForeground];
}

- (void) lockDB{
    [baseDataUploader lockDB];
    // [localStorage dbLock];
    // [baseDataUploader lockBackgroundUpload];
}

- (void) unlockDB{
    [baseDataUploader unlockDB];
    // [localStorage dbUnlock];
    // [baseDataUploader unlockBackgroundUpload];
}

- (BOOL) isDBLock {
    return [baseDataUploader isDBLock];
}

/////////////////////////////////////////////
/////////////////////////////////////////////
/**
 * Sync options
 */
- (void)allowsCellularAccess{
    [baseDataUploader allowsCellularAccess];
}

- (void)forbidCellularAccess{
    [baseDataUploader forbidCellularAccess];
}


- (void) allowsDateUploadWithoutBatteryCharging{
    [baseDataUploader allowsDateUploadWithoutBatteryCharging];
}

- (void) forbidDatauploadWithoutBatteryCharging{
    [baseDataUploader forbidDatauploadWithoutBatteryCharging];
}


//////////////////////////////////////////
////////////////////////////////////////

- (NSString *)getSyncProgressAsText{
    return [baseDataUploader getSyncProgressAsText];
}

- (NSString *) getSyncProgressAsText:(NSString *)sensorName{
    return [baseDataUploader getSyncProgressAsText:sensorName];
}

- (NSString *) getNetworkReachabilityAsText{
    return [baseDataUploader getNetworkReachabilityAsText];
}

- (bool)isUploading{
    return [baseDataUploader isUploading];
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
    [baseDataUploader trackDebugEventsWithDebugSensor:debugSensor];
}

/**
 * Get a debug sensor state
 */
- (bool) isDebug{
    return debug;
}

- (NSString *) getWebserviceUrl{
    return [baseDataUploader getWebserviceUrl];
}

- (NSString *) getInsertUrl:(NSString *)sensorName{
    return [baseDataUploader getInsertUrl:sensorName];
}

- (NSString *) getLatestDataUrl:(NSString *)sensorName{
    return [baseDataUploader getLatestDataUrl:sensorName];
}

- (NSString *) getCreateTableUrl:(NSString *)sensorName{
    return [baseDataUploader getCreateTableUrl:sensorName];
}

- (NSString *) getClearTableUrl:(NSString *)sensorName{
    return [baseDataUploader getCreateTableUrl:sensorName];
}

- (NSManagedObjectContext *)getSensorManagedObjectContext{
    // return baseDataUploader.mainQueueManagedObjectContext;
    // return baseDataUploader.writeQueueManagedObjectContext;
     AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
    return delegate.managedObjectContext;
}

@end
