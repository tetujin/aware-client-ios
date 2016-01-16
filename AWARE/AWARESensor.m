//
//  AWARESensorViewController.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/19/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//


#import "AWARESensor.h"
#import "AWAREKeys.h"
#import "SCNetworkReachability.h"

@interface AWARESensor () {
    
    int bufferLimit;
    int lostedTextLength;
    int lineCount;
    int marker;
    int errorPosts;
    int postThreads;
    
    BOOL previusUploadingState;
    bool wifiState;
    bool writeAble;
    bool blancerState;
    
    NSString * awareSensorName;
    NSString *latestSensorValue;
    
    NSMutableString *tempData;
    NSMutableString *bufferStr;
    
    NSTimer* writeAbleTimer;

    SCNetworkReachability* reachability;
}

@end

@implementation AWARESensor

- (instancetype) initWithSensorName:(NSString *)sensorName {
    if (self = [super init]) {
        NSLog(@"[%@] Initialize an AWARESensor as '%@' ", sensorName, sensorName);
        _syncDataQueryIdentifier = [NSString stringWithFormat:@"sync_data_query_identifier_%@", sensorName];
        _createTableQueryIdentifier = [NSString stringWithFormat:@"create_table_query_identifier_%@",  sensorName];
        awareSensorName = sensorName;
        bufferLimit = 0;
        lostedTextLength = 0;
        previusUploadingState = NO;
        blancerState = NO;
        awareSensorName = sensorName;
        latestSensorValue = @"";
        errorPosts = 0;
        postThreads = 0;
        tempData = [[NSMutableString alloc] init];
        bufferStr = [[NSMutableString alloc] init];
        reachability = [[SCNetworkReachability alloc] initWithHost:@"www.google.com"];
        [reachability observeReachability:^(SCNetworkStatus status){
             switch (status){
                 case SCNetworkStatusReachableViaWiFi:
                     NSLog(@"[%@] Reachable via WiFi", [self getSensorName]);
                     wifiState = YES;
                     break;
                 case SCNetworkStatusReachableViaCellular:
                     NSLog(@"[%@] Reachable via Cellular", [self getSensorName]);
                     wifiState = NO;
                     break;
                 case SCNetworkStatusNotReachable:
                     NSLog(@"[%@] Not Reachable", [self getSensorName]);
                     wifiState = NO;
                     break;
             }
         }];
        
        // Make new file
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString * path = [documentsDirectory stringByAppendingPathComponent:sensorName];
        NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:[NSString stringWithFormat:@"%@.dat",path]];
        if (!fh) { // no
            NSLog(@"[%@] You don't have a file for %@, then system recreated new file!", sensorName, sensorName);
            NSFileManager *manager = [NSFileManager defaultManager];
            if (![manager fileExistsAtPath:path]) { // yes
                BOOL result = [manager createFileAtPath:path
                                               contents:[NSData data] attributes:nil];
                if (!result) {
                    NSLog(@"[%@] Error to create the file", sensorName);
                }else{
                    NSLog(@"[%@] Sucess to create the file", sensorName);
                }
            }
        }
        writeAble = YES;
    }
    return self;
}


- (void) setWriteableYES{
    writeAble = YES;
}

- (void) setWriteableNO{
    writeAble = NO;
}

- (void) startWriteAbleTimer{
    writeAbleTimer =  [NSTimer scheduledTimerWithTimeInterval:1.0f
                                                       target:self
                                                     selector:@selector(setWriteableYES)
                                                     userInfo:nil repeats:YES];
    [writeAbleTimer fire];
    blancerState = YES;
    
}

- (void) stopWriteableTimer{
    if (!writeAbleTimer) {
        [writeAbleTimer invalidate];
        blancerState = NO;
    }
}

- (void) setBufferLimit:(int)limit{
    bufferLimit = limit;
}

- (void) setLatestValue:(NSString *) valueStr{
    latestSensorValue = valueStr;
}

- (NSString *)getLatestValue {
    return latestSensorValue;
}

- (void) setSensorName:(NSString *)sensorName{
    awareSensorName = sensorName;
    wifiState = NO;
}

- (NSString *)getSensorName{
    return awareSensorName;
}

-(BOOL)startSensor:(double)upInterval withSettings:(NSArray *)settings{
    return NO;
}

- (BOOL)stopSensor{
    [writeAbleTimer invalidate];
    return NO;
}


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


- (NSString *)getInsertUrl:(NSString *)sensorName{
    //    - insert: insert new data to the table
    return [NSString stringWithFormat:@"%@/%@/insert", [self getWebserviceUrl], sensorName];
}


- (NSString *)getLatestDataUrl:(NSString *)sensorName{
    //    - latest: returns the latest timestamp on the server, for synching what’s new on the phone
    return [NSString stringWithFormat:@"%@/%@/latest", [self getWebserviceUrl], sensorName];
}


- (NSString *)getCreateTableUrl:(NSString *)sensorName{
    //    - create_table: creates a table if it doesn’t exist already
    return [NSString stringWithFormat:@"%@/%@/create_table", [self getWebserviceUrl], sensorName];
}


- (NSString *)getClearTableUrl:(NSString *)sensorName{
    //    - clear_table: remove a specific device ID data from the database table
    return [NSString stringWithFormat:@"%@/%@/clear_table", [self getWebserviceUrl], sensorName];
}


- (NSString *)getWebserviceUrl{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString* url = [userDefaults objectForKey:KEY_WEBSERVICE_SERVER];
    if (url == NULL) {
        NSLog(@"[Error] You did not have a StudyID. Please check your study configuration.");
        return @"";
    }
    return url;
}


- (NSString *)getDeviceId{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString* deviceId = [userDefaults objectForKey:KEY_MQTT_USERNAME];
    if (deviceId == NULL) {
        NSLog(@"[Error] You did not have a StudyID. Please check your study configuration.");
        return @"";
    }
    return deviceId;
}



- (bool) saveData:(NSDictionary *)data{
    return [self saveData:data toLocalFile:[self getSensorName]];
}
            

- (bool) saveData:(NSDictionary *)data toLocalFile:(NSString *)fileName{
    NSError*error=nil;
    NSData*d=[NSJSONSerialization dataWithJSONObject:data options:2 error:&error];
    NSString* jsonstr = [[NSString alloc] init];
    // TODO: error hundling of nill in NSDictionary.
    if (!error) {
        jsonstr = [[NSString alloc]initWithData:d encoding:NSUTF8StringEncoding];
    } else {
        NSString * errorStr = [NSString stringWithFormat:@"[%@] %@", [self getSensorName], [error localizedDescription]];
        [self sendLocalNotificationForMessage:errorStr soundFlag:YES];
        return NO;
        //Do additional data manipulation or handling work here.
    }
    [bufferStr appendString:jsonstr];
    [bufferStr appendFormat:@","];
    
    if ( writeAble || !blancerState ) {
        [self appendLine:bufferStr path:fileName];
        [bufferStr setString:@""];
        [self setWriteableNO];
    }else{
        if (!blancerState) {
            NSLog(@"[%@] writable time is false.", [self getSensorName]);
        }
    }
    return YES;
}

- (bool) saveDataWithArray:(NSArray*) array {
    NSError*error=nil;
    for (NSDictionary *dic in array) {
        NSLog(@"%@", [dic objectForKey:@"timestamp"]);
        NSData*d=[NSJSONSerialization dataWithJSONObject:dic options:2 error:&error];
        NSString* jsonstr = [[NSString alloc] init];
        // TODO: error hundling of nill in NSDictionary.
        if (!error) {
            jsonstr = [[NSString alloc]initWithData:d encoding:NSUTF8StringEncoding];
        } else {
            NSString * errorStr = [NSString stringWithFormat:@"[%@] %@", [self getSensorName], [error localizedDescription]];
            [self sendLocalNotificationForMessage:errorStr soundFlag:YES];
            return NO;
            //Do additional data manipulation or handling work here.
        }
        [bufferStr appendString:jsonstr];
        [bufferStr appendFormat:@","];
    }
    if (writeAble) {
        [self appendLine:bufferStr path:[self getSensorName]];
        [bufferStr setString:@""];
        [self setWriteableNO];
        return YES;
    } else {
        return YES;
    }
}


- (BOOL) appendLine:(NSString *)line path:(NSString*) fileName {
    if (!line) {
        NSLog(@"[%@] Line is null", [self getSensorName] );
        return NO;
    }
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString * path = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.dat",fileName]];
    if(previusUploadingState){
        [tempData appendFormat:@"%@", line];
        return YES;
    }else{
        NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:path];
        if (fh == nil) { // no
            NSLog(@"[%@] ERROR: AWARE can not handle the file.", fileName);
            [self createNewFile:fileName];
            return NO;
        }else{
            [fh seekToEndOfFile];
            if (![tempData isEqualToString:@""]) {
                NSData * tempdataLine = [tempData dataUsingEncoding:NSUTF8StringEncoding];
                [fh writeData:tempdataLine]; //write temp data to the main file
                [tempData setString:@""];
                NSLog(@"[%@] Add the sensor data to temp variable.", fileName);
            }
            NSString * oneLine = [[NSString alloc] initWithString:[NSString stringWithFormat:@"%@", line]];
            NSData *data = [oneLine dataUsingEncoding:NSUTF8StringEncoding];
            [fh writeData:data];
            [fh synchronizeFile];
            [fh closeFile];
            return YES;
        }
    }
    return YES;
}


/** create new file */
-(void)createNewFile:(NSString*) fileName {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString * path = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.dat",fileName]];
    NSFileManager *manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:path]) { // yes
        BOOL result = [manager createFileAtPath:path
                                       contents:[NSData data]
                                     attributes:nil];
        if (!result) {
            NSLog(@"[%@] Failed to create the file.", fileName);
            return;
        }else{
            NSLog(@"[%@] Create the file.", fileName);
        }
    }
}

/** clear file */
- (bool) removeFile:(NSString *) fileName {
    NSFileManager *manager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString * path = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.dat",fileName]];
    if ([manager fileExistsAtPath:path]) { // yes
        bool result = [@"" writeToFile:path atomically:NO encoding:NSUTF8StringEncoding error:nil];
        if (result) {
            NSLog(@"[%@] Correct to clear sensor data.", fileName);
        }else{
            NSLog(@"[%@] Error to clear sensor data.", fileName);
        }
    }else{
        NSLog(@"[%@] The file is not exist.", fileName);
        [self createNewFile:fileName];
        return YES;
    }
    return NO;
}

- (NSMutableString *) getSensorDataForPost {

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSInteger length = [userDefaults integerForKey:KEY_MAX_DATA_SIZE];
    NSUInteger seek = marker * length;

//    // init variables
//    NSString *post = nil;
//    NSData *postData = nil;
//    NSMutableURLRequest *request = nil;
//    __weak NSURLSession *session = nil;
//    NSString *postLength = nil;
    lineCount = 0;
    
    // get sensor data from file
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString * path = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.dat",[self getSensorName]]];
    NSMutableString *data = nil;
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:path];
    if (!fileHandle) {
        NSLog(@"[%@] AWARE can not handle the file.", [self getSensorName]);
        [self createNewFile:[self getSensorName]];
        previusUploadingState = NO;
        return Nil;
    }
    NSLog(@"--> %ld", seek);
    if (seek > lostedTextLength) {
        [fileHandle seekToFileOffset:seek-(NSInteger)lostedTextLength];
    }else{
        [fileHandle seekToFileOffset:seek];
    }
    NSData *clipedData = [fileHandle readDataOfLength:length];
    [fileHandle closeFile];
    
    data = [[NSMutableString alloc] initWithData:clipedData encoding:NSUTF8StringEncoding];
    lineCount = (int)data.length;
    NSLog(@"[%@] Line lenght is %ld", [self getSensorName], (unsigned long)data.length);
    if (data.length == 0) {
        marker = 0;
        [self dataSyncIsFinishedCorrectoly];
        return Nil;
    }
    
    if ( data.length < length ) {
        marker = 0;
        [self dataSyncIsFinishedCorrectoly];
    } else {
        marker += 1;
    }
    return data;
}



- (void) syncAwareDB {
    [self syncAwareDBWithSensorName:[self getSensorName]];
}

/** Sync with AWARE database */
// This is main syncmethod from AWARESensor thread
- (void) syncAwareDBWithSensorName:(NSString*) sensorName {
    
    if(previusUploadingState){
        NSLog(@"[%@] Now sendsor data is uploading.", [self getSensorName]);
        return;
    }
    
    if (!wifiState) {
        NSLog(@"[%@] Wifi is not availabe.", [self getSensorName]);
        return;
    }
    
    previusUploadingState = YES;
    
    postThreads++;
    NSLog(@"Post Threads: %d", postThreads);
    
    [self postSensorDataWithSensorName:sensorName session:nil];
}

- (void) postSensorDataWithSensorName:(NSString* )sensorName session:(NSURLSession *)oursession {
    
    NSString *deviceId = [self getDeviceId];
    NSString *url = [self getInsertUrl:sensorName];
    
    NSMutableString* sensorData = [self getSensorDataForPost];
    NSString* formatedSensorData = [self fixJsonFormat:sensorData];
    
    // Set session configuration
    NSURLSessionConfiguration *sessionConfig = nil;
    double unxtime = [[NSDate new] timeIntervalSince1970];
    _syncDataQueryIdentifier = [NSString stringWithFormat:@"%@%f", _syncDataQueryIdentifier, unxtime];
    sessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:_syncDataQueryIdentifier];
    sessionConfig.timeoutIntervalForRequest = 60 * 5;
    sessionConfig.HTTPMaximumConnectionsPerHost = 60;
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
    
    NSLog(@"[%@] This is background task for upload sensor data", [self getSensorName]);
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

}



- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    
    
    [session finishTasksAndInvalidate];
    [session invalidateAndCancel];
    completionHandler(NSURLSessionResponseAllow);
    
    if ([session.configuration.identifier isEqualToString:_syncDataQueryIdentifier]) {
        NSLog(@"[%@] Get response from the server.", [self getSensorName]);
        [self receivedResponseFromServer:dataTask.response withData:nil error:nil];
        
    } else if ( [session.configuration.identifier isEqualToString:_createTableQueryIdentifier] ){
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
        int responseCode = (int)[httpResponse statusCode];
        if (responseCode == 200) {
            NSLog(@"[%@] Sucess to create new table on AWARE server.", [self getSensorName]);
        }
    } else {
        
    }
}


-(void)URLSession:(NSURLSession *)session
         dataTask:(NSURLSessionDataTask *)dataTask
   didReceiveData:(NSData *)data {
    
    if ([session.configuration.identifier isEqualToString:_syncDataQueryIdentifier]) {
        // If the data is null, this method is not called.
        NSString * result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"[%@] Data is coming! => %@", [self getSensorName], result);
    } else if ([session.configuration.identifier isEqualToString:_createTableQueryIdentifier]){
        NSString* newStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"[%@] %@",[self getSensorName], newStr);
    }
    
//    [session finishTasksAndInvalidate];
//    [session invalidateAndCancel];

}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    
    [session finishTasksAndInvalidate];
    [session invalidateAndCancel];

    if ([session.configuration.identifier isEqualToString:_syncDataQueryIdentifier]) {
        if (error) {
            NSLog(@"[%@] Session task is finished with error. %@", [self getSensorName], error.debugDescription);
            if ( marker > 0 ) {
                marker = marker - 1;
            }
            errorPosts++;
            NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
            bool debugState = [defaults boolForKey:SETTING_DEBUG_STATE];
            if (debugState) {
                [self sendLocalNotificationForMessage:[NSString stringWithFormat:
                                                       @"[%@] Retry - %d (%d): %@",
                                                       [self getSensorName],
                                                       marker,
                                                       errorPosts,
                                                       error.debugDescription]
                                            soundFlag:NO];
            }
            if (errorPosts < 3) { //TODO
                [self postSensorDataWithSensorName:[self getSensorName] session:session];
//                [task resume];
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
    } else if ([session.configuration.identifier isEqualToString:_createTableQueryIdentifier]){
        
    }
}

- (void) dataSyncIsFinishedCorrectoly {
    postThreads = postThreads - 1;
    previusUploadingState = NO;
    NSLog(@"[%@] Session task finished correctly.", [self getSensorName]);
    errorPosts = 0;
}

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error{
    if (error != nil) {
        NSLog(@"[%@] the session did become invaild with error: %@", [self getSensorName], error.debugDescription);
        [self sendLocalNotificationForMessage:error.debugDescription soundFlag:NO];
    }
    [session invalidateAndCancel];
    [session finishTasksAndInvalidate];
}




- (NSMutableString *) fixJsonFormat:(NSMutableString *) clipedText {
    // head
    if ([clipedText hasPrefix:@"{"]) {
    }else{
        NSRange rangeOfExtraText = [clipedText rangeOfString:@"{"];
        if (rangeOfExtraText.location == NSNotFound) {
//             NSLog(@"[HEAD] There is no extra text");
        }else{
//            NSLog(@"[HEAD] There is some extra text!");
            NSRange deleteRange = NSMakeRange(0, rangeOfExtraText.location);
            [clipedText deleteCharactersInRange:deleteRange];
        }
    }
    
    // tail
    if ([clipedText hasSuffix:@"}"]){
    }else{
        NSRange rangeOfExtraText = [clipedText rangeOfString:@"}" options:NSBackwardsSearch];
        if (rangeOfExtraText.location == NSNotFound) {
//             NSLog(@"[TAIL] There is no extra text");
            lostedTextLength = 0;
        }else{
//             NSLog(@"[TAIL] There is some extra text!");
            NSRange deleteRange = NSMakeRange(rangeOfExtraText.location+1, clipedText.length-rangeOfExtraText.location-1);
            [clipedText deleteCharactersInRange:deleteRange];
            lostedTextLength = (int)deleteRange.length;
        }
    }
    [clipedText insertString:@"[" atIndex:0];
    [clipedText appendString:@"]"];
    
    return clipedText;
}


//NSError * _Nullable error
- (void)receivedResponseFromServer:(NSURLResponse *)response
                          withData:(NSData *)data
                             error:(NSError *)error{
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
    int responseCode = (int)[httpResponse statusCode];
    NSString* newStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"[%@] %d  Response =====> %@",[self getSensorName], responseCode, newStr);
    if ( responseCode == 200 ) {
        NSString *bytes = @"";
        if (lineCount >= 1000*1000) { //MB
            bytes = [NSString stringWithFormat:@"%.2f MB", (double)lineCount/(double)(1000*1000)];
        } else if (lineCount >= 1000) { //KB
            bytes = [NSString stringWithFormat:@"%.2f KB", (double)lineCount/(double)1000];
        } else if (lineCount < 1000) {
            bytes = [NSString stringWithFormat:@"%d Bytes", lineCount];
        } else {
            bytes = [NSString stringWithFormat:@"%d Bytes", lineCount];
        }
        NSString *message = [NSString stringWithFormat:@"[%@] Sucess to upload sensor data to AWARE server with %@ - %d", [self getSensorName], bytes, marker ];
        NSLog(@"%@", message);
        // send notification
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        bool debugState = [userDefaults boolForKey:SETTING_DEBUG_STATE];
        if (debugState) {
            [self sendLocalNotificationForMessage:message soundFlag:NO];
        }
    }
    
    data = nil;
    response = nil;
    error = nil;
    httpResponse = nil;
//    dispatch_async(dispatch_get_main_queue(), ^{
        if (marker != 0) {
//            [self syncAwareDB];
            [self postSensorDataWithSensorName:[self getSensorName] session:nil];
        }else{
            if(responseCode == 200){
                [self removeFile:[self getSensorName]];
            }
        }
//    });
}




/** Sync with AWARE database */
- (BOOL) syncAwareDBWithData:(NSDictionary *) dictionary {
    // init variables
    NSString *deviceId = [self getDeviceId];
    NSError *error = nil;
    NSData*d=[NSJSONSerialization dataWithJSONObject:dictionary options:2 error:&error];
    NSString* jsonstr = [[NSString alloc] init];
    if (!error) {
        jsonstr = [[NSString alloc]initWithData:d encoding:NSUTF8StringEncoding];
    } else {
        NSString * errorStr = [NSString stringWithFormat:@"[%@] %@", [self getSensorName], [error localizedDescription]];
        [self sendLocalNotificationForMessage:errorStr soundFlag:YES];
        return NO;
    }

    NSString *post = [NSString stringWithFormat:@"device_id=%@&data=%@", deviceId, jsonstr];
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%ld", [postData length]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    NSString *url = [self getInsertUrl:[self getSensorName]];
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


- (bool) isFirstAccess {
    NSString * url = [self getLatestDataUrl:[self getSensorName]];
    NSString * value = [self getLatestSensorData:[self getSensorName] withUrl:url];
    if ([value isEqualToString:@"[]"] || value == nil) {
        return YES;
    }else{
        return  NO;
    }
}


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


- (BOOL)clearTable{
    return NO;
}

- (void) createTable:(NSString*) query {
    [self createTable:query withTableName:[self getSensorName]];
}


- (void) createTable:(NSString *)query withTableName:(NSString*) tableName {
//    NSLog(@"%@",[self getCreateTableUrl:tableName]);
    // create table
    NSString *post = nil;
    NSData *postData = nil;
    NSMutableURLRequest *request = nil;
    __weak NSURLSession *session = nil;
    NSString *postLength = nil;
    post = [NSString stringWithFormat:@"device_id=%@&fields=%@", [self getDeviceId], query];
//            NSLog(@"%@", post);
    postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    postLength = [NSString stringWithFormat:@"%ld", [postData length]];
    request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:[self getCreateTableUrl:tableName]]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:postData];
    
    
    NSURLSessionConfiguration *sessionConfig = nil;
    sessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:_createTableQueryIdentifier];
    sessionConfig.timeoutIntervalForRequest = 120.0;
    sessionConfig.HTTPMaximumConnectionsPerHost = 60;
    sessionConfig.timeoutIntervalForResource = 60; //60*60*24; // 1 day
    sessionConfig.allowsCellularAccess = NO;
    sessionConfig.discretionary = YES;

    NSLog(@"--- [%@] This is background task for create table ----", [self getSensorName]);
    session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];
    NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request];
    [dataTask resume];
}


- (void)uploadSensorData{
    
}



- (double) convertMotionSensorFrequecyFromAndroid:(double)frequency{
    //        Android: Non-deterministic frequency in microseconds (dependent of the hardware sensor capabilities and resources), e.g., 200000 (normal), 60000 (UI), 20000 (game), 0 (fastest).
    //         iOS: https://developer.apple.com/library/ios/documentation/EventHandling/Conceptual/EventHandlingiPhoneOS/motion_event_basics/motion_event_basics.html
    //          e.g 10-20Hz, 30-60Hz, 70-100Hz
    double y1 = 0.01; //iOS 1 max
    double y2 = 0.1; //iOS 2 min
    double x1 = 0; //Android 1 max
    double x2 = 200000; // Android 2 min
    
    // y1 = a * x1 + b;
    // y2 = a * x2 + b;
    double a = (y1-y2)/(x1-x2);
    double b = y1 - x1*a;
//    y =a * x + b;
//    NSLog(@"%f", a *frequency + b);
    return a *frequency + b;
}


/**
 Local push notification method
 @param message text message for notification
 @param sound type of sound for notification
 */
- (void)sendLocalNotificationForMessage:(NSString *)message soundFlag:(BOOL)soundFlag {
    UILocalNotification *localNotification = [UILocalNotification new];
    localNotification.alertBody = message;
    //    localNotification.fireDate = [NSDate date];
    localNotification.repeatInterval = 0;
    if(soundFlag) {
        localNotification.soundName = UILocalNotificationDefaultSoundName;
    }
    localNotification.hasAction = YES;
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}


@end
