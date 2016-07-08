//
//  AWAREUploader.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 6/4/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWAREUploader.h"
#import "AWAREStudy.h"
#import "Debug.h"

@implementation AWAREUploader{
    // study
    AWAREStudy * awareStudy;
    NSString *sensorName;
    // debug
    Debug * debugSensor;
    // settings
    BOOL isDebug;
    BOOL isSyncWithOnlyBatteryCharging;
    BOOL isWifiOnly;
    BOOL isUploading;
    BOOL isLock;
    
    // for CoreData
    int fetchLimit;
    int batchSize;
    int bufferSize;
}

- (instancetype) initWithAwareStudy:(AWAREStudy *)study sensorName:(NSString *)name{
    self = [self init];
    if(self != nil){
        awareStudy = study;
        sensorName = name;
        
        fetchLimit = (int)[study getMaxFetchSize];
        batchSize = 0;
        bufferSize = 0;
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        isDebug = [userDefaults boolForKey:SETTING_DEBUG_STATE];
        isSyncWithOnlyBatteryCharging  = [userDefaults boolForKey:SETTING_SYNC_BATTERY_CHARGING_ONLY];
        isWifiOnly = [userDefaults boolForKey:SETTING_SYNC_WIFI_ONLY];
        
    }
    return self;
}


////////////////////////////////////////////////////////////////
/**
 * Settings
 */
- (bool) isUploading { return isUploading; }

- (void) setUploadingState:(bool)state{ isUploading = state; }

/////////////
- (void) lockBackgroundUpload{ isLock = YES; }

- (void) unlockBackgroundUpload{ isLock = NO; }

/////////
- (void) allowsCellularAccess{ isWifiOnly = NO; }

- (void) forbidCellularAccess{ isWifiOnly = YES; }

////////
- (void) allowsDateUploadWithoutBatteryCharging{ isSyncWithOnlyBatteryCharging = NO; }

- (void) forbidDatauploadWithoutBatteryCharging{ isSyncWithOnlyBatteryCharging = YES; }

//////////////////////////////////////////////////
- (bool) isDebug { return isDebug; }

- (bool) isSyncWithOnlyWifi {return isWifiOnly;}

- (bool) isSyncWithOnlyBatteryCharging { return isSyncWithOnlyBatteryCharging;}

///////////////////////////////////////////////////////////////////

- (void) setBufferSize:(int)size{bufferSize=size;}

- (void)setFetchLimit:(int)limit{ fetchLimit = limit; }

- (void)setFetchBatchSize:(int)size{ batchSize = size; }

- (int) getBufferSize{return bufferSize;}

- (int) getFetchLimit{ return fetchLimit; }

- (int) getFetchBatchSize{ return batchSize; }


- (bool) saveDataToDB{
    NSLog(@"[NOTE] Please overwrite this method (-saveDataToDB)");
    return NO;
}

//////////////////////////////////

- (void) syncAwareDBInBackground{
    NSLog(@"[NOTE] Please overwrite this method (-syncAwareDBInBackground)");
}

- (void) syncAwareDBInBackgroundWithSensorName:(NSString*) name{
    NSLog(@"[NOTE] Please overwrite this method (-syncAwareDBInBackgroundWithSensorName:)");
}


- (void) postSensorDataWithSensorName:(NSString*) name session:(NSURLSession *)oursession{
    NSLog(@"[NOTE] Please overwrite this method (-postSensorDataWithSensorName:session)");
}

////////////////////////////////////////////////////////////////////

- (BOOL) syncAwareDBInForeground{
    return [self syncAwareDBInForegroundWithSensorName:sensorName];
}

- (BOOL) syncAwareDBInForegroundWithSensorName:(NSString*) name{
    return NO;
}

- (BOOL) syncAwareDBWithData:(NSDictionary *) dictionary{
     NSLog(@"[NOTE] Please overwrite this method (-syncAwareDBWithData:)");
    return NO;
}


////////////////////////////////////////////////////////////////////////
- (NSString *) getSyncProgressAsText{
    return @"";
}

- (NSString *) getSyncProgressAsText:(NSString *)sensorName{
    return @"";
}


////////////////////////////////////////////////////////////////////////

- (void) createTable:(NSString*) query{
    [self createTable:query withTableName:sensorName];
}

- (void) createTable:(NSString *)query withTableName:(NSString*) tableName{
    NSLog(@"[NOTE] Please overwrite this method (createTable:query:withTableName)");
}

- (BOOL) clearTable{
    NSLog(@"[NOTE] Please overwrite this method (createTable)");
    return NO;
}


/**
 * Return current network condition with a text
 */
- (NSString *) getNetworkReachabilityAsText{
    return [awareStudy getNetworkReachabilityAsText];
}


/** /////////////////////////////////////////////////////////
 * makers
 * /////////////////////////////////////////////////////////
 */
- (NSString *)getWebserviceUrl{
    NSString* url = [awareStudy getWebserviceServer];
    if (url == NULL || [url isEqualToString:@""]) {
        NSLog(@"[Error] You did not have a StudyID. Please check your study configuration.");
        return @"";
    }
    return url;
}

- (NSString *)getDeviceId{
    //    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    //    NSString* deviceId = [userDefaults objectForKey:KEY_MQTT_USERNAME];
    NSString * deviceId = [awareStudy getDeviceId];
    return deviceId;
}

- (NSString *)getInsertUrl:(NSString *)name{
    //    - insert: insert new data to the table
    return [NSString stringWithFormat:@"%@/%@/insert", [self getWebserviceUrl], name];
}


- (NSString *)getLatestDataUrl:(NSString *)name{
    //    - latest: returns the latest timestamp on the server, for synching what’s new on the phone
    return [NSString stringWithFormat:@"%@/%@/latest", [self getWebserviceUrl], name];
}


- (NSString *)getCreateTableUrl:(NSString *)name{
    //    - create_table: creates a table if it doesn’t exist already
    return [NSString stringWithFormat:@"%@/%@/create_table", [self getWebserviceUrl], name];
}


- (NSString *)getClearTableUrl:(NSString *)name{
    //    - clear_table: remove a specific device ID data from the database table
    return [NSString stringWithFormat:@"%@/%@/clear_table", [self getWebserviceUrl], name];
}


/** ////////////////////////////////////////////////////
 * Set Debug Sensor
 * //////////////////////////////////////////////////////
 */
- (void) trackDebugEventsWithDebugSensor:(Debug *)debug {
    debugSensor = debug;
}


/* //////////////////////////////////////////////////////////////
 * A wrapper method for debug sensor
 * //////////////////////////////////////////////////////////////
 */

- (bool)saveDebugEventWithText:(NSString *)eventText type:(NSInteger)type label:(NSString *)label{
    if (debugSensor != nil) {
        [debugSensor saveDebugEventWithText:eventText type:type label:label];
        return  YES;
    }
    return NO;
}


/**
 * /////////////////////////////////////////////////////////
 *  Broadcast CoreData(insert/fetch/delete) and data upload events
 * /////////////////////////////////////////////////////////
 */
- (void) broadcastDBSyncEventWithProgress:(NSNumber *)progress
                                 isFinish:(BOOL)finish
                                isSuccess:(BOOL)success
                               sensorName:(NSString *)name{
    NSMutableDictionary * userInfo = [[NSMutableDictionary alloc] init];
    [userInfo setObject:progress forKey:@"KEY_UPLOAD_PROGRESS_STR"];
    [userInfo setObject:@(finish) forKey:@"KEY_UPLOAD_FIN"];
    [userInfo setObject:@(success) forKey:@"KEY_UPLOAD_SUCCESS"];
    [userInfo setObject:name forKey:@"KEY_UPLOAD_SENSOR_NAME"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ACTION_AWARE_DATA_UPLOAD_PROGRESS"
                                                        object:nil
                                                      userInfo:userInfo];
    
}


@end
