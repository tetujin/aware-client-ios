//
//  AWAREDataUploader.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 2/7/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWAREDataUploader.h"
#import "SCNetworkReachability.h"
#import "AWAREKeys.h"
#import "AWAREStudy.h"

@implementation AWAREDataUploader{
    NSString * sensorName;
    bool isUploading;
    int errorPosts;
    LocalFileStorageHelper * awareLocalStorage;
    AWAREStudy * awareStudy;
    
    NSString * syncDataQueryIdentifier;
    NSString * createTableQueryIdentifier;
    
    double httpStart;
    double postLengthDouble;
    
    BOOL isDebug;
    BOOL isLock;
    BOOL isSyncWithOnlyBatteryCharging;
    
    BOOL isWifiOnly;
    
    Debug * debugSensor;
}


- (instancetype)initWithLocalStorage:(LocalFileStorageHelper *)localStorage withAwareStudy:(AWAREStudy *) study {
    if (self = [super init]) {
        sensorName = [localStorage getSensorName];
        awareStudy = study;
        awareLocalStorage = localStorage;
        isUploading = NO;
        syncDataQueryIdentifier = [NSString stringWithFormat:@"sync_data_query_identifier_%@", sensorName];
        createTableQueryIdentifier = [NSString stringWithFormat:@"create_table_query_identifier_%@",  sensorName];
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        isDebug = [userDefaults boolForKey:SETTING_DEBUG_STATE];
        isSyncWithOnlyBatteryCharging  = [userDefaults boolForKey:SETTING_SYNC_BATTERY_CHARGING_ONLY];
        isWifiOnly = [userDefaults boolForKey:SETTING_SYNC_WIFI_ONLY];
    }
    return self;
}


/////////////////////////////////
/////////////////////////////////
/**
 * Sensor data uploading state
 */
- (bool) isUploading {
    return isUploading;
}

- (void) setUploadingState:(bool)state{
    isUploading = state;
}

- (void) lockBackgroundUpload{
    isLock = YES;
}

- (void) unlockBackgroundUpload{
    isLock = NO;
}


- (void) allowsCellularAccess{
    isWifiOnly = NO;
}


- (void) forbidCellularAccess{
    isWifiOnly = YES;
}

/////////////////////////////////
/////////////////////////////////


/**
 * Background data sync
 */
- (void) syncAwareDB {
    [self syncAwareDBWithSensorName:sensorName];
}

/** 
 * Background data sync with database name
 * @param NSString  A sensor name
 */
- (void) syncAwareDBWithSensorName:(NSString*) name {
    // chekc wifi state
    if(isUploading){
        NSString * message= [NSString stringWithFormat:@"[%@] Now sendsor data is uploading.", name];
        NSLog(@"%@", message);
        [self saveDebugEventWithText:message type:DebugTypeInfo  label:@""];
        return;
    }
    
    // chekc wifi state
    if (![awareStudy isWifiReachable] && isWifiOnly) {
        NSString * message = [NSString stringWithFormat:@"[%@] Wifi is not availabe.", name];
        NSLog(@"%@", message);
        [self saveDebugEventWithText:message type:DebugTypeInfo  label:@""];
        return;
    }
    
    // check battery condition
    if (isSyncWithOnlyBatteryCharging) {
        NSInteger batteryState = [UIDevice currentDevice].batteryState;
        if ( batteryState == UIDeviceBatteryStateCharging || batteryState == UIDeviceBatteryStateFull) {
        }else{
            NSString * message = [NSString stringWithFormat:@"[%@] This device is not charginig battery now.", name];
            NSLog(@"%@", message);
            [self saveDebugEventWithText:message type:DebugTypeInfo  label:name];
            return;
        }
    }
    
    isUploading = YES;
    [self postSensorDataWithSensorName:sensorName session:nil];
}


/**
 * Upload method
 */
- (void) postSensorDataWithSensorName:(NSString* )name session:(NSURLSession *)oursession {
    
    NSString *deviceId = [self getDeviceId];
    NSString *url = [self getInsertUrl:name];
    
    NSMutableString* sensorData = [awareLocalStorage getSensorDataForPost];
    NSString* formatedSensorData = [awareLocalStorage fixJsonFormat:sensorData];
    
    if (sensorData.length == 0 || [sensorData isEqualToString:@"[]"]) {
        NSString * message = [NSString stringWithFormat:@"[%@] Data length is zero => %ld", sensorName, sensorData.length];
        NSLog(@"%@", message);
        [self saveDebugEventWithText:message type:DebugTypeInfo  label:@""];
        [self dataSyncIsFinishedCorrectoly];
        [awareLocalStorage restMark];
        return;
    }
    
    // Set session configuration
    NSURLSessionConfiguration *sessionConfig = nil;
    double unxtime = [[NSDate new] timeIntervalSince1970];
    syncDataQueryIdentifier = [NSString stringWithFormat:@"%@%f", syncDataQueryIdentifier, unxtime];
    sessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:syncDataQueryIdentifier];
    sessionConfig.timeoutIntervalForRequest = 60 * 3;
    sessionConfig.HTTPMaximumConnectionsPerHost = 60 * 3;
    sessionConfig.timeoutIntervalForResource = 60 * 3;
    if (isWifiOnly) {
        sessionConfig.allowsCellularAccess = NO;
    } else {
        sessionConfig.allowsCellularAccess = YES;
    }
    
    // set HTTP/POST body information
    NSString* post = [NSString stringWithFormat:@"device_id=%@&data=%@", deviceId, formatedSensorData];
    NSData* postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString* postLength = [NSString stringWithFormat:@"%ld", [postData length]];
    //    NSLog(@"Data Length: %@", postLength);
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:postData];
    
    NSString * logMessage = [NSString stringWithFormat:@"[%@] This is background task for upload sensor data", sensorName];
    NSLog(@"%@", logMessage);
    NSURLSession* session = oursession;
    if (session == nil) {
        session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];
    }
    NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request];
    
    [session getTasksWithCompletionHandler:^(NSArray* dataTasks, NSArray* uploadTasks, NSArray* downloadTasks){
        NSLog(@"Currently suspended tasks");
        for (NSURLSessionDownloadTask* task in dataTasks) {
            NSLog(@"Task: %@",[task description]);
        }
    }];
    
    httpStart = [[NSDate new] timeIntervalSince1970];
    postLengthDouble = [[NSNumber numberWithInteger:postData.length] doubleValue];
    [self saveDebugEventWithText:logMessage type:DebugTypeInfo  label:syncDataQueryIdentifier];
    
    [dataTask resume];
}



- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    
    // test: server peformance
    double diff = [[NSDate new] timeIntervalSince1970] - httpStart;
//    NSLog(@"[%@] %f", sensorName, diff);
    if (postLengthDouble > 0 && diff > 0) {
        NSString *networkPeformance = [NSString stringWithFormat:@"%0.2f KB/s",postLengthDouble/diff/1000.0f];
        NSLog(@"[%@] %@", sensorName, networkPeformance);
        [self saveDebugEventWithText:networkPeformance type:DebugTypeInfo label:sensorName];
    }
    
    
    [session finishTasksAndInvalidate];
    [session invalidateAndCancel];
    completionHandler(NSURLSessionResponseAllow);
    
    if ([session.configuration.identifier isEqualToString:syncDataQueryIdentifier]) {
        NSLog(@"[%@] Get response from the server.", sensorName);
        [self receivedResponseFromServer:dataTask.response withData:nil error:nil];
        
    } else if ( [session.configuration.identifier isEqualToString:createTableQueryIdentifier] ){
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
        int responseCode = (int)[httpResponse statusCode];
        if (responseCode == 200) {
            NSLog(@"[%@] Sucess to create new table on AWARE server.", sensorName);
        }
    } else {
        
    }
}


-(void)URLSession:(NSURLSession *)session
         dataTask:(NSURLSessionDataTask *)dataTask
   didReceiveData:(NSData *)data {
    
    if ([session.configuration.identifier isEqualToString:syncDataQueryIdentifier]) {
        // If the data is null, this method is not called.
        NSString * result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"[%@] Data is coming! => %@", sensorName, result);
    } else if ([session.configuration.identifier isEqualToString:createTableQueryIdentifier]){
        NSString* newStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"[%@] %@",sensorName, newStr);
    }
    [session finishTasksAndInvalidate];
    [session invalidateAndCancel];
    session = nil;
    dataTask = nil;
    data = nil;
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    
    [session finishTasksAndInvalidate];
    [session invalidateAndCancel];
    
    if ([session.configuration.identifier isEqualToString:syncDataQueryIdentifier]) {
        if (error) {
            NSString * log = [NSString stringWithFormat:@"[%@] Session task is finished with error (%d). %@", sensorName, [awareLocalStorage getMarker], error.debugDescription];
            NSLog(@"%@",log);
            [self  saveDebugEventWithText:log type:DebugTypeError label:syncDataQueryIdentifier];
            errorPosts++;
            if (isDebug) {
                [AWAREUtils sendLocalNotificationForMessage:[NSString stringWithFormat:
                                                             @"[%@] Retry - %d (%d): %@",
                                                             sensorName,
                                                             [awareLocalStorage getMarker],
                                                             errorPosts,
                                                             error.debugDescription]
                                                  soundFlag:NO];
            }
            if (errorPosts < 3) { //TODO
                [self postSensorDataWithSensorName:sensorName session:nil];
            } else {
                [self dataSyncIsFinishedCorrectoly];
            }
        } else {
            //            [self dataSyncIsFinishedCorrectoly];
        }
        NSLog(@"%@", task.description);
        //        NSLog(@"%@", error.debugDescription);
        return;
        //    completionHandler(NSURLSessionResponseAllow);
    } else if ([session.configuration.identifier isEqualToString:createTableQueryIdentifier]){
        session = nil;
        task = nil;
    }
}


- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error{
    if (error != nil) {
        NSLog(@"[%@] the session did become invaild with error: %@", sensorName, error.debugDescription);
        [AWAREUtils sendLocalNotificationForMessage:error.debugDescription soundFlag:NO];
    }
    [session invalidateAndCancel];
    [session finishTasksAndInvalidate];
}


- (void)receivedResponseFromServer:(NSURLResponse *)response
                          withData:(NSData *)data
                             error:(NSError *)error{
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
    int responseCode = (int)[httpResponse statusCode];
    NSString* newStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"[%@] %d  Response =====> %@",sensorName, responseCode, newStr);
    
    data = nil;
    response = nil;
    error = nil;
    httpResponse = nil;
    
    if ( responseCode == 200 ) {
        [awareLocalStorage setNextMark];
        NSString *bytes = [self getFileStrSize:(double)[awareLocalStorage getFileSize]];
        NSString *message = @"";
        
        NSLog(@"%d", [awareLocalStorage getMarker]);
        
        if( [awareLocalStorage getMarker] == 0 ){
            // success to upload data
            message = [NSString stringWithFormat:@"[%@] Sucess to upload sensor data to AWARE server with %@", sensorName, bytes];
            NSLog(@"%@", message);
            [self saveDebugEventWithText:message type:DebugTypeInfo label:syncDataQueryIdentifier];
            
            // send notification
            if (isDebug) [AWAREUtils sendLocalNotificationForMessage:message soundFlag:NO];
            
            // remove store data
            [awareLocalStorage clearFile:sensorName];
            [self saveDebugEventWithText:[NSString stringWithFormat:@"[%@] Remove stored data", sensorName]
                                    type:DebugTypeInfo
                                   label:syncDataQueryIdentifier];
            // init http/post condition
            [self dataSyncIsFinishedCorrectoly];
            
        } else {
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            NSInteger length = [userDefaults integerForKey:KEY_MAX_DATA_SIZE];
            long denominator = (long)[awareLocalStorage getFileSize]/(long)length;
            
            NSString* formatedLength = [self getFileStrSize:(double)length];
            
            message = [NSString stringWithFormat:@"[%@] Sucess to upload sensor data to AWARE server with %@ - %d/%ld", sensorName, formatedLength, [awareLocalStorage getMarker], denominator];
            NSLog(@"%@", message);
            [self saveDebugEventWithText:message type:DebugTypeInfo label:syncDataQueryIdentifier];
            
            // send notification
            if (isDebug) [AWAREUtils sendLocalNotificationForMessage:message soundFlag:NO];
            
            // upload sensor data again
            [self saveDebugEventWithText:[NSString stringWithFormat:@"[%@] Upload stored data again", sensorName]
                                    type:DebugTypeInfo
                                   label:syncDataQueryIdentifier];
            [self postSensorDataWithSensorName:sensorName session:nil];
        }
    }
}


- (void) dataSyncIsFinishedCorrectoly {
    isUploading = NO;
    NSLog(@"[%@] Session task finished correctly.", sensorName);
    errorPosts = 0;
}


/**
 * Foreground data upload
 */

- (BOOL) syncAwareDBInForeground{
    return [self syncAwareDBInForegroundWithSensorName:sensorName];
}

- (BOOL) syncAwareDBInForegroundWithSensorName:(NSString*) name {
    while(true){
        if([self foregroundSyncRequestWithSensorName:name]){
            NSLog(@"%d", [awareLocalStorage getMarker]);
            if([awareLocalStorage getMarker] == 0){
                bool isRemoved = [awareLocalStorage clearFile:sensorName];
                if (isRemoved) {
                    [self saveDebugEventWithText:[NSString stringWithFormat:@"[%@] Sucessed to remove stored data in the foreground", sensorName]
                                            type:DebugTypeInfo
                                           label:@""];
                }else{
                    [self saveDebugEventWithText:[NSString stringWithFormat:@"[%@] Failed to remove stored data in the foreground", sensorName]
                                            type:DebugTypeError
                                           label:@""];
                }
                break;
            }else{
                [self saveDebugEventWithText:[NSString stringWithFormat:@"[%@] Upload stored data in the foreground again", sensorName]
                                        type:DebugTypeInfo
                                       label:@""];
            }
        }else{
            NSLog(@"Error");
            [self saveDebugEventWithText:[NSString stringWithFormat:@"[%@] Failed to upload sensor data in the foreground", sensorName]
                                    type:DebugTypeError
                                   label:@""];
            return NO;
        }
    }
    return YES;
}

- (bool)foregroundSyncRequestWithSensorName:(NSString * )name{
    // init variables
    NSString *deviceId = [self getDeviceId];
    NSString *url = [self getInsertUrl:name];
    NSError *error = nil;
    int responseCode = 0;
    NSString* newStr = @"";
    
    @autoreleasepool {
        // Get sensor data
        NSMutableString* sensorData = [awareLocalStorage getSensorDataForPost];
        sensorData = [awareLocalStorage fixJsonFormat:sensorData];
//        NSLog(@"%@", sensorData);
        
        if (sensorData.length == 0 || sensorData.length == 2) {
            NSString * message = [NSString stringWithFormat:@"[%@] Data length is zero => %ld", name, sensorData.length ];
            NSLog(@"%@", message);
            [self saveDebugEventWithText:message type:DebugTypeInfo label:@""];
            [awareLocalStorage restMark];
            return YES;
        }
        NSString * message = [NSString stringWithFormat:@"[%@] Start sensor data upload in the foreground => %ld", name, sensorData.length ];
        NSLog(@"%@", message);
        [self saveDebugEventWithText:message type:DebugTypeInfo label:@""];
        
        NSString *post = [NSString stringWithFormat:@"device_id=%@&data=%@", deviceId, sensorData];
        NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
        NSString *postLength = [NSString stringWithFormat:@"%ld", [postData length]];
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
        [request setURL:[NSURL URLWithString:url]];
        [request setHTTPMethod:@"POST"];
        [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
        [request setHTTPBody:postData];
        [request setTimeoutInterval:60*3];
        if(isWifiOnly){
            [request setAllowsCellularAccess:NO];
        }else{
            [request setAllowsCellularAccess:YES];
        }
        
        NSHTTPURLResponse *response = nil;
        NSData *resData = [NSURLConnection sendSynchronousRequest:request
                                                returningResponse:&response error:&error];
        newStr = [[NSString alloc] initWithData:resData encoding:NSUTF8StringEncoding];
        responseCode = (int)[response statusCode];
        
        post = nil;
        postData = nil;
        postLength = nil;
        request = nil;
        response = nil;
        sensorData = nil;
    }

    if(responseCode == 200){
        NSLog(@"Success to upload the data: %@", newStr);
        [awareLocalStorage setNextMark];
        return YES;
    }else{
        return NO;
    }
}

////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////



/**
 * Sync with AWARE database
 */
- (BOOL) syncAwareDBWithData:(NSDictionary *) dictionary {
    // init variables
    NSString *deviceId = [self getDeviceId];
    NSError *error = nil;
    NSData*d=[NSJSONSerialization dataWithJSONObject:dictionary options:2 error:&error];
    NSString* jsonstr = [[NSString alloc] init];
    if (!error) {
        jsonstr = [[NSString alloc]initWithData:d encoding:NSUTF8StringEncoding];
    } else {
        NSString * errorStr = [NSString stringWithFormat:@"[%@] %@", sensorName, [error localizedDescription]];
        [AWAREUtils sendLocalNotificationForMessage:errorStr soundFlag:YES];
        return NO;
    }
    NSString *post = [NSString stringWithFormat:@"device_id=%@&data=%@", deviceId, jsonstr];
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%ld", [postData length]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    NSString *url = [self getInsertUrl:sensorName];
    [request setURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:postData];
    NSHTTPURLResponse *response = nil;
    NSData *resData = [NSURLConnection sendSynchronousRequest:request
                                            returningResponse:&response error:&error];
    NSString* newStr = [[NSString alloc] initWithData:resData encoding:NSUTF8StringEncoding];
    //    NSLog(@"%@", newStr);
    int responseCode = (int)[response statusCode];
    if(responseCode == 200){
        NSLog(@"Success to upload the data: %@", newStr);
        return YES;
    }else{
        return NO;
    }
}


/**
 * Get latest sensor data method
 */
- (NSString *)getLatestSensorData:(NSString *)deviceId withUrl:(NSString *)url{
    NSString *post = [NSString stringWithFormat:@"device_id=%@", deviceId];
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%ld", [postData length]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:postData];
    NSError *error = nil;
    NSHTTPURLResponse *response = nil;
    NSData *resData = [NSURLConnection sendSynchronousRequest:request
                                            returningResponse:&response error:&error];
    NSString* newStr = [[NSString alloc] initWithData:resData encoding:NSUTF8StringEncoding];
    int responseCode = (int)[response statusCode];
    if(responseCode == 200){
        NSLog(@"UPLOADED SENSOR DATA TO A SERVER");
        return newStr;
    }
    return @"";
}
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////




/**
 * Get progress
 */
- (NSString *)  getSyncProgressAsText {
    return [self getSyncProgressAsText:sensorName];
}

- (NSString *) getSyncProgressAsText:(NSString *)name {
    double fileSize = [awareLocalStorage getFileSizeWithName:name];
    NSString *bytes = [self getFileStrSize:fileSize];
    return [NSString stringWithFormat:@"(%@)",bytes];
}

- (NSString *) getFileStrSize:(double)size{
    NSString *bytes = @"";
    if (size >= 1000*1000) { //MB
        bytes = [NSString stringWithFormat:@"%.2f MB", size /(double)(1000*1000)];
    } else if (size >= 1000) { //KB
        bytes = [NSString stringWithFormat:@"%.2f KB", size /(double)1000];
    } else if (size < 1000) {
        bytes = [NSString stringWithFormat:@"%d Bytes", (int)size ];
    } else {
        bytes = [NSString stringWithFormat:@"%d Bytes", (int)size ];
    }
    return [NSString stringWithFormat:@"%@",bytes];
}


////////////////////////////////////////////
////////////////////////////////////////////



/**
 * Create Table Methods
 */

- (void) createTable:(NSString*) query {
    [self createTable:query withTableName:sensorName];
}

- (void) createTable:(NSString *)query withTableName:(NSString*) tableName {
    NSString *post = nil;
    NSData *postData = nil;
    NSMutableURLRequest *request = nil;
    __weak NSURLSession *session = nil;
//    NSURLSession *session = nil;
    NSString *postLength = nil;
    NSURLSessionConfiguration *sessionConfig = nil;
    
    // Make a post query for creating a table
    post = [NSString stringWithFormat:@"device_id=%@&fields=%@", [self getDeviceId], query];
    postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    postLength = [NSString stringWithFormat:@"%ld", [postData length]];
    
    request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:[self getCreateTableUrl:tableName]]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:postData];
    
    // Generate an unique identifier for background HTTP/POST on iOS
    double unxtime = [[NSDate new] timeIntervalSince1970];
    createTableQueryIdentifier = [NSString stringWithFormat:@"%@%f", createTableQueryIdentifier, unxtime];
    sessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:createTableQueryIdentifier];
    sessionConfig.timeoutIntervalForRequest = 180.0;
    sessionConfig.HTTPMaximumConnectionsPerHost = 60;
    sessionConfig.timeoutIntervalForResource = 60;
    sessionConfig.allowsCellularAccess = YES;
//    sessionConfig.discretionary = YES;
    
    NSString * debugMessage = [NSString stringWithFormat:@"[%@] Sent a query for creating a table in the background", sensorName];
    [self saveDebugEventWithText:debugMessage type:DebugTypeInfo label:@""];
    session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];
    NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request];
    [dataTask resume];
}



/**
 * WIP:
 */
- (BOOL)clearTable{
    return NO;
}


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



/**
 * AWARE URL makers
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


//////////////////////////////////////////////
/////////////////////////////////////////////


/**
 * Return current network condition with a text
 */
- (NSString *) getNetworkReachabilityAsText{
    return [awareStudy getNetworkReachabilityAsText];
}


//////////////////////////////////////////////
/////////////////////////////////////////////

/**
 * Set Debug Sensor
 */
- (void) trackDebugEventsWithDebugSensor:(Debug *)debug {
    debugSensor = debug;
}


@end
