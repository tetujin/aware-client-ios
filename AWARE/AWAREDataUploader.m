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
    
    // for network test
    double httpStart;
    
    SCNetworkReachability* reachability;
    NSInteger networkState;
    BOOL wifiReachable;
    
    BOOL isDebug;
    
    Debug * debugSensor;
}


- (instancetype)initWithLocalStorage:(LocalFileStorageHelper *)localStorage{
    if (self = [super init]) {
        sensorName = [localStorage getSensorName];
        awareStudy = [[AWAREStudy alloc] init];
        awareLocalStorage = localStorage;
        isUploading = false;
        if ([awareLocalStorage getMarker] >= 1) {
            [awareLocalStorage setMarker:([localStorage getMarker] - 1)];
        }
        syncDataQueryIdentifier = [NSString stringWithFormat:@"sync_data_query_identifier_%@", sensorName];
        createTableQueryIdentifier = [NSString stringWithFormat:@"create_table_query_identifier_%@",  sensorName];
        
        reachability = [[SCNetworkReachability alloc] initWithHost:@"www.google.com"];
        [reachability observeReachability:^(SCNetworkStatus status){
            networkState = status;
            switch (status){
                case SCNetworkStatusReachableViaWiFi:
                    NSLog(@"[%@] Reachable via WiFi", sensorName);
                    wifiReachable = YES;
                    break;
                case SCNetworkStatusReachableViaCellular:
                    NSLog(@"[%@] Reachable via Cellular", sensorName);
                    wifiReachable = NO;
                    break;
                case SCNetworkStatusNotReachable:
                    NSLog(@"[%@] Not Reachable", sensorName);
                    wifiReachable = NO;
                    break;
            }
        }];
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        isDebug = [userDefaults boolForKey:SETTING_DEBUG_STATE];
    }
    return self;
}


/**
 * Sensor data uploading state
 */
- (bool) isUploading {
    return isUploading;
}

- (void) setUploadingState:(bool)state{
    isUploading = state;
}

/////////////////////////////////
/////////////////////////////////



/**
 * Background data post
 */



- (void) syncAwareDB {
    [self syncAwareDBWithSensorName:sensorName];
}

/** Sync with AWARE database */
- (void) syncAwareDBWithSensorName:(NSString*) name {
    if(isUploading){
        NSString * message= [NSString stringWithFormat:@"[%@] Now sendsor data is uploading.", name];
        NSLog(@"%@", message);
        [self saveDebugEventWithText:message type:DebugTypeInfo  label:@""];
        return;
    }
    
    if (!wifiReachable) {
        NSString * message = [NSString stringWithFormat:@"[%@] Wifi is not availabe.", name];
        NSLog(@"%@", message);
        [self saveDebugEventWithText:message type:DebugTypeInfo  label:@""];
        return;
    }
    isUploading = YES;
    [self postSensorDataWithSensorName:sensorName session:nil];
}


/**
 * Core Date Upload method
 */
- (void) postSensorDataWithSensorName:(NSString* )name session:(NSURLSession *)oursession {
    
    NSString *deviceId = [self getDeviceId];
    NSString *url = [self getInsertUrl:name];
    
    NSMutableString* sensorData = [awareLocalStorage getSensorDataForPost];
    NSString* formatedSensorData = [awareLocalStorage fixJsonFormat:sensorData];
    
    if (sensorData.length == 0) {
        NSString * message = [NSString stringWithFormat:@"[%@] Data length is zero => %ld", sensorName, sensorData.length];
        NSLog(@"%@", message);
        [self saveDebugEventWithText:message type:DebugTypeInfo  label:@""];
        return;
    }
    
    // Set session configuration
    NSURLSessionConfiguration *sessionConfig = nil;
    double unxtime = [[NSDate new] timeIntervalSince1970];
    syncDataQueryIdentifier = [NSString stringWithFormat:@"%@%f", syncDataQueryIdentifier, unxtime];
    sessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:syncDataQueryIdentifier];
    sessionConfig.timeoutIntervalForRequest = 60 * 5;
    sessionConfig.HTTPMaximumConnectionsPerHost = 60 * 5;
    sessionConfig.timeoutIntervalForResource = 300.0;
    sessionConfig.allowsCellularAccess = NO;
    
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
    
    [dataTask resume];
    // test
    httpStart = [[NSDate new] timeIntervalSince1970];
    [self saveDebugEventWithText:logMessage type:DebugTypeInfo  label:syncDataQueryIdentifier];
}



- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    // test: httpend
    double serverPerformace = [[NSDate new] timeIntervalSince1970] - httpStart;
    NSLog(@"[%@] %f", sensorName, serverPerformace);
    
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
    //    [session finishTasksAndInvalidate];
    //    [session invalidateAndCancel];
    
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
        
    }
}


- (void) dataSyncIsFinishedCorrectoly {
    isUploading = NO;
    NSLog(@"[%@] Session task finished correctly.", sensorName);
    errorPosts = 0;
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
    
    if ( responseCode == 200 ) {
        NSString *bytes = [self getFileStrSize:(double)[awareLocalStorage getFileSize]];
        NSString *message = @"";
        if( [awareLocalStorage getMarker] == 0 ){
            message = [NSString stringWithFormat:@"[%@] Sucess to upload sensor data to AWARE server with %@", sensorName, bytes];
        }else{
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            NSInteger length = [userDefaults integerForKey:KEY_MAX_DATA_SIZE];
            long denominator = (long)[awareLocalStorage getFileSize]/(long)length;
            message = [NSString stringWithFormat:@"[%@] Sucess to upload sensor data to AWARE server with %@ - %d/%ld", sensorName, bytes, [awareLocalStorage getMarker], denominator];
        }
        NSLog(@"%@", message);
        [self saveDebugEventWithText:message type:DebugTypeInfo label:syncDataQueryIdentifier];
        // send notification
        if ([self getDebugState]) {
            [AWAREUtils sendLocalNotificationForMessage:message soundFlag:NO];
        }
    }
    
    data = nil;
    response = nil;
    error = nil;
    httpResponse = nil;
    if ([awareLocalStorage getMarker] != 0) {
        [self saveDebugEventWithText:[NSString stringWithFormat:@"[%@] Upload stored data again", sensorName]
                                type:DebugTypeInfo
                               label:syncDataQueryIdentifier];
        [self postSensorDataWithSensorName:sensorName session:nil];
    }else{
        if(responseCode == 200){
            [self saveDebugEventWithText:[NSString stringWithFormat:@"[%@] Remove stored data", sensorName]
                                    type:DebugTypeInfo
                                   label:syncDataQueryIdentifier];
            [awareLocalStorage clearFile:sensorName];
        }
    }
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
//                [self foregroundSyncRequestWithSensorName:sensorName];
            }
        }else{
            NSLog(@"Error");
            [self saveDebugEventWithText:[NSString stringWithFormat:@"[%@] Failed to upload sensor data in the foreground", sensorName]
                                    type:DebugTypeError
                                   label:@""];
            if ([awareLocalStorage getMarker] == 0) {
                [awareLocalStorage setMarker:[awareLocalStorage getMarker] - 1];
            }
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
        
        if (sensorData.length == 0) {
            NSString * message = [NSString stringWithFormat:@"[%@] Data length is zero => %ld", name, sensorData.length ];
            NSLog(@"%@", message);
            [self saveDebugEventWithText:message type:DebugTypeInfo label:@""];
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
        [request setTimeoutInterval:60*60];
        [request setAllowsCellularAccess:NO];
        
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

- (NSString *) getSyncProgressAsText:(NSString *)sensorName {
    double fileSize = [awareLocalStorage getFileSize];
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
    sessionConfig.allowsCellularAccess = NO;
    sessionConfig.discretionary = YES;
    
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
    NSString * reachabilityText = @"";
    switch (networkState){
        case SCNetworkStatusReachableViaWiFi:
            reachabilityText = @"wifi";
            break;
        case SCNetworkStatusReachableViaCellular:
            reachabilityText = @"cellular";
            break;
        case SCNetworkStatusNotReachable:
            reachabilityText = @"no";
            break;
        default:
            reachabilityText = @"unknown";
            break;
    }
    return reachabilityText;
}


//////////////////////////////////////////////
/////////////////////////////////////////////

/**
 * Set Debug Sensor
 */
- (void) trackDebugEventsWithDebugSensor:(Debug *)debug {
    debugSensor = debug;
}


- (bool) getDebugState {
    return debugSensor;
}

@end
