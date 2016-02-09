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
#import "LocalFileStorageHelper.h"
#import "Debug.h"

@interface AWARESensor () {
    
    int bufferLimit;
//    int lostedTextLength;
    int lineCount;
//    int marker;
    int errorPosts;
    int postThreads;
    uint64_t fileSize;
    
    BOOL previusUploadingState;
    bool wifiState;
    bool writeAble;
    bool blancerState;
    bool isLocked;
    
    NSString * awareSensorName;
    NSString * latestSensorValue;
    NSString * KEY_SENSOR_UPLOAD_MARK;
    NSString * KEY_SENSOR_UPLOAD_LOSTED_TEXT_LENGTH;
    
    NSMutableString *tempData;
    NSMutableString *bufferStr;
    
    NSTimer* writeAbleTimer;

    SCNetworkReachability* reachability;
    
    double httpStart;
    
    bool debug;
    
    Debug * debugSensor;
    NSInteger networkState;
}

@end

@implementation AWARESensor

- (instancetype) initWithSensorName:(NSString *)sensorName {
    if (self = [super init]) {
        NSLog(@"[%@] Initialize an AWARESensor as '%@' ", sensorName, sensorName);
        _syncDataQueryIdentifier = [NSString stringWithFormat:@"sync_data_query_identifier_%@", sensorName];
        _createTableQueryIdentifier = [NSString stringWithFormat:@"create_table_query_identifier_%@",  sensorName];
        KEY_SENSOR_UPLOAD_MARK = [NSString stringWithFormat:@"key_sensor_upload_mark_%@", sensorName];
        KEY_SENSOR_UPLOAD_LOSTED_TEXT_LENGTH = [NSString stringWithFormat:@"key_sensor_upload_losted_text_length_%@", sensorName];
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        debug = [userDefaults boolForKey:SETTING_DEBUG_STATE];
        if ([self getMarker] >= 1) {
            [self setMarker:([self getMarker] - 1)];
        }
//        [self sendLocalNotificationForMessage:[NSString stringWithFormat:@"%d", [self getMarker]] soundFlag:NO];
        
        awareSensorName = sensorName;
        httpStart = 0;
        bufferLimit = 0;
//        lostedTextLength = 0;
        fileSize = 0;
        previusUploadingState = NO;
        blancerState = NO;
        awareSensorName = sensorName;
        latestSensorValue = @"";
        errorPosts = 0;
        postThreads = 0;
        isLocked = NO;
        tempData = [[NSMutableString alloc] init];
        bufferStr = [[NSMutableString alloc] init];
//        debugSensor = [[Debug alloc] init];
        reachability = [[SCNetworkReachability alloc] initWithHost:@"www.google.com"];
        [reachability observeReachability:^(SCNetworkStatus status){
            networkState = status;
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
        path = [NSString stringWithFormat:@"%@.dat",path];
        NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:path];
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

- (int) getMarker {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSNumber * number = [NSNumber numberWithInteger:[userDefaults integerForKey:KEY_SENSOR_UPLOAD_MARK]];
    return number.intValue;
}

- (void) setMarker:(int) intMarker {
    NSNumber * number = [NSNumber numberWithInt:intMarker];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:number.integerValue forKey:KEY_SENSOR_UPLOAD_MARK];
}

- (int) getLostedTextLength{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSNumber * number = [NSNumber numberWithInteger:[userDefaults integerForKey:KEY_SENSOR_UPLOAD_LOSTED_TEXT_LENGTH]];
    return number.intValue;
}

- (void) setLostedTextLength:(int)lostedTextLength {
    NSNumber * number = [NSNumber numberWithInt:lostedTextLength];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:number.integerValue forKey:KEY_SENSOR_UPLOAD_LOSTED_TEXT_LENGTH];
}


- (bool)saveDebugEventWithText:(NSString *)eventText type:(NSInteger)type label:(NSString *)label{
    if (debugSensor != nil) {
        [debugSensor saveDebugEventWithText:eventText type:type label:label];
        return  YES;
    }
    return NO;
}

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

- (void) trackDebugEvents {
    debugSensor = [[Debug alloc] init];
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

- (bool) getDebugState {
    return debug;
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
            return YES;
        }else{
            NSLog(@"[%@] Error to clear sensor data.", fileName);
            return NO;
        }
    }else{
        NSLog(@"[%@] The file is not exist.", fileName);
        [self createNewFile:fileName];
        return NO;
    }
    return NO;
}

- (NSMutableString *) getSensorDataForPost {

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSInteger length = [userDefaults integerForKey:KEY_MAX_DATA_SIZE];
//    NSUInteger seek = marker * length;
    NSUInteger seek = [self getMarker] * length;

    lineCount = 0;
    
    // get sensor data from file
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString * path = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.dat",[self getSensorName]]];
    NSMutableString *data = nil;
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:path];
    if (!fileHandle) {
        NSString * message = [NSString stringWithFormat:@"[%@] AWARE can not handle the file.", [self getSensorName]];
        NSLog(@"%@", message);
        if(debugSensor != nil) [debugSensor saveDebugEventWithText:message type:DebugTypeError label:@""];
        [self createNewFile:[self getSensorName]];
        previusUploadingState = NO;
        return Nil;
    }
    NSLog(@"--> %ld", seek);
    if (seek > [self getLostedTextLength]) {
        [fileHandle seekToFileOffset:seek-(NSInteger)[self getLostedTextLength]];
    }else{
        [fileHandle seekToFileOffset:seek];
    }
    
//    uint64_t fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:_filePath error:nil] fileSize];
    fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil] fileSize];
    
    NSData *clipedData = [fileHandle readDataOfLength:length];
    [fileHandle closeFile];
    
    data = [[NSMutableString alloc] initWithData:clipedData encoding:NSUTF8StringEncoding];
    lineCount = (int)data.length;
    NSLog(@"[%@] Line lenght is %ld", [self getSensorName], (unsigned long)data.length);
    if (data.length == 0) {
//        marker = 0;
        [self setMarker:0];
        [self dataSyncIsFinishedCorrectoly];
        return Nil;
    }
    
    if ( data.length < length ) {
//        marker = 0;
        [self setMarker:0];
        [self dataSyncIsFinishedCorrectoly];
    } else {
//        marker += 1;
        [self setMarker:([self getMarker]+1)];
    }
    return data;
}

- (bool) isUploading {
    return previusUploadingState;
}

- (void) lockSensor:(bool) status{
    isLocked = status;
}

- (void) syncAwareDB {
    [self syncAwareDBWithSensorName:[self getSensorName]];
}

/** Sync with AWARE database */
// This is main syncmethod from AWARESensor thread
- (void) syncAwareDBWithSensorName:(NSString*) sensorName {
    if(previusUploadingState){
        NSString * message= [NSString stringWithFormat:@"[%@] Now sendsor data is uploading.", [self getSensorName]];
        NSLog(@"%@", message);
        if (debugSensor != nil) [debugSensor saveDebugEventWithText:message type:DebugTypeInfo  label:@""];
        return;
    }
    
    if (!wifiState) {
        NSString * message = [NSString stringWithFormat:@"[%@] Wifi is not availabe.", [self getSensorName]];
        NSLog(@"%@", message);
        if (debugSensor != nil) [debugSensor saveDebugEventWithText:message type:DebugTypeInfo  label:@""];
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
    
    if (sensorData.length == 0) {
        NSString * message = [NSString stringWithFormat:@"[%@] Data length is zero => %ld", [self getSensorName], sensorData.length];
        NSLog(@"%@", message);
        if (debugSensor != nil) [debugSensor saveDebugEventWithText:message type:DebugTypeInfo  label:@""];
        return;
    }
    
    // Set session configuration
    NSURLSessionConfiguration *sessionConfig = nil;
    double unxtime = [[NSDate new] timeIntervalSince1970];
    _syncDataQueryIdentifier = [NSString stringWithFormat:@"%@%f", _syncDataQueryIdentifier, unxtime];
    sessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:_syncDataQueryIdentifier];
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
    
    NSString * logMessage = [NSString stringWithFormat:@"[%@] This is background task for upload sensor data", [self getSensorName]];
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
    
    if (debugSensor != nil) [debugSensor saveDebugEventWithText:logMessage type:DebugTypeInfo  label:_syncDataQueryIdentifier];
}



- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    // test: httpend
    double serverPerformace = [[NSDate new] timeIntervalSince1970] - httpStart;
    NSLog(@"[%@] %f", [self getSensorName], serverPerformace);
    
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
            NSString * log = [NSString stringWithFormat:@"[%@] Session task is finished with error (%d). %@", [self getSensorName], [self getMarker], error.debugDescription];
            NSLog(@"%@",log);
            if (debugSensor != nil) [debugSensor saveDebugEventWithText:log type:DebugTypeError label:_syncDataQueryIdentifier];
//            if ( marker > 0 ) {
//                marker = marker - 1;
//            }
            if ( [self getMarker] > 0 ) {
                [self setMarker:([self getMarker] - 1)];
            }
            errorPosts++;
            NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
            bool debugState = [defaults boolForKey:SETTING_DEBUG_STATE];
            if (debugState) {
                [self sendLocalNotificationForMessage:[NSString stringWithFormat:
                                                       @"[%@] Retry - %d (%d): %@",
                                                       [self getSensorName],
                                                       [self getMarker],
                                                       errorPosts,
                                                       error.debugDescription]
                                            soundFlag:NO];
            }
            if (errorPosts < 3) { //TODO
                [self postSensorDataWithSensorName:[self getSensorName] session:nil];
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
//            lostedTextLength = 0;
            [self setLostedTextLength:0];
        }else{
//             NSLog(@"[TAIL] There is some extra text!");
            NSRange deleteRange = NSMakeRange(rangeOfExtraText.location+1, clipedText.length-rangeOfExtraText.location-1);
            [clipedText deleteCharactersInRange:deleteRange];
//            lostedTextLength = (int)deleteRange.length;
            [self setLostedTextLength:(int) deleteRange.length];
        }
    }
    [clipedText insertString:@"[" atIndex:0];
    [clipedText appendString:@"]"];
//    NSLog(@"%@", clipedText);
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
        NSString *message = @"";
        if( [self getMarker] == 0 ){
            message = [NSString stringWithFormat:@"[%@] Sucess to upload sensor data to AWARE server with %@", [self getSensorName], bytes];
        }else{
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            NSInteger length = [userDefaults integerForKey:KEY_MAX_DATA_SIZE];
            long denominator = (long)fileSize/(long)length;
            message = [NSString stringWithFormat:@"[%@] Sucess to upload sensor data to AWARE server with %@ - %d/%ld", [self getSensorName], bytes, [self getMarker], denominator];
        }
        NSLog(@"%@", message);
        if (debugSensor != nil) [debugSensor saveDebugEventWithText:message type:DebugTypeInfo label:_syncDataQueryIdentifier];
        // send notification
        if ([self getDebugState]) {
            [self sendLocalNotificationForMessage:message soundFlag:NO];
        }
    }
    
    data = nil;
    response = nil;
    error = nil;
    httpResponse = nil;
//    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self getMarker] != 0) {
//            [self syncAwareDB];
            if (debugSensor != nil) [debugSensor saveDebugEventWithText:[NSString stringWithFormat:@"[%@] Upload stored data again", [self getSensorName]]
                                           type:DebugTypeInfo
                                          label:_syncDataQueryIdentifier];
            [self postSensorDataWithSensorName:[self getSensorName] session:nil];
        }else{
            if(responseCode == 200){
                if (debugSensor != nil) [debugSensor saveDebugEventWithText:[NSString stringWithFormat:@"[%@] Remove stored data", [self getSensorName]]
                                               type:DebugTypeInfo
                                              label:_syncDataQueryIdentifier];
                [self removeFile:[self getSensorName]];
            }
        }
//    });
}


- (BOOL) syncAwareDBInForeground{
    return [self syncAwareDBInForegroundWithSensorName:[self getSensorName]];
}


- (BOOL) syncAwareDBInForegroundWithSensorName:(NSString*) sensorName {
    
    // init variables
    NSString *deviceId = [self getDeviceId];
    NSString *url = [self getInsertUrl:sensorName];
    NSError *error = nil;
    
    // Get sensor data
    NSMutableString* sensorData = [self getSensorDataForPost];
    NSString* formatedSensorData = [self fixJsonFormat:sensorData];
    
    if (sensorData.length == 0) {
        NSString * message = [NSString stringWithFormat:@"[%@] Data length is zero => %ld", [self getSensorName], sensorData.length ];
        NSLog(@"%@", message);
        if (debugSensor != nil) [debugSensor saveDebugEventWithText:message
                                       type:DebugTypeInfo
                                      label:@""];
        return YES;
    }
    NSString * message = [NSString stringWithFormat:@"[%@] Start sensor data upload in the foreground => %ld", [self getSensorName], sensorData.length ];
    NSLog(@"%@", message);
    if (debugSensor != nil) [debugSensor saveDebugEventWithText:message
                                   type:DebugTypeInfo
                                  label:@""];
    
    NSString *post = [NSString stringWithFormat:@"device_id=%@&data=%@", deviceId, formatedSensorData];
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
    NSString* newStr = [[NSString alloc] initWithData:resData encoding:NSUTF8StringEncoding];
    int responseCode = (int)[response statusCode];
    if(responseCode == 200){
        NSLog(@"Success to upload the data: %@", newStr);
        if([self getMarker] == 0){
//            marker = 0;
//            if(responseCode == 200){
            bool isRemoved = [self removeFile:sensorName];
            if (debugSensor != nil){
                if (isRemoved) {
                    [debugSensor saveDebugEventWithText:[NSString stringWithFormat:@"[%@] Sucessed to remove stored data in the foreground", [self getSensorName]]
                                                                           type:DebugTypeInfo
                                                                          label:@""];
                }else{
                    [debugSensor saveDebugEventWithText:[NSString stringWithFormat:@"[%@] Failed to remove stored data in the foreground", [self getSensorName]]
                                                                           type:DebugTypeError
                                                                          label:@""];
                }
            }
//            }
        }else{
            if (debugSensor != nil) [debugSensor saveDebugEventWithText:[NSString stringWithFormat:@"[%@] Upload stored data in the foreground again", [self getSensorName]]
                                           type:DebugTypeInfo
                                          label:@""];
//            marker ++;
            [self syncAwareDBInForegroundWithSensorName:sensorName];
        }
    }else{
        NSLog(@"Error");
        if (debugSensor != nil) [debugSensor saveDebugEventWithText:[NSString stringWithFormat:@"[%@] Failed to upload sensor data in the foreground", [self getSensorName]]
                                       type:DebugTypeError
                                      label:@""];
        if ([self getMarker] > 0) {
            [self setMarker:[self getMarker]-1];
        }
        return NO;
    }
    return YES;
}







- (NSString *)  getSyncProgressAsText {
    return [self getSyncProgressAsText:[self getSensorName]];
}

- (NSString *) getSyncProgressAsText:(NSString *)sensorName {

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString * path = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.dat",sensorName]];
    fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil] fileSize];
    NSString *bytes = @"";
    if (fileSize >= 1000*1000) { //MB
        bytes = [NSString stringWithFormat:@"%.2f MB", (double)fileSize /(double)(1000*1000)];
    } else if (fileSize >= 1000) { //KB
        bytes = [NSString stringWithFormat:@"%.2f KB", (double)fileSize /(double)1000];
    } else if (fileSize < 1000) {
        bytes = [NSString stringWithFormat:@"%llu Bytes", fileSize ];
    } else {
        bytes = [NSString stringWithFormat:@"%llu Bytes", fileSize ];
    }
    return [NSString stringWithFormat:@"(%@)",bytes];
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
    
    double unxtime = [[NSDate new] timeIntervalSince1970];
    _createTableQueryIdentifier = [NSString stringWithFormat:@"%@%f", _createTableQueryIdentifier, unxtime];
    sessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:_createTableQueryIdentifier];
    sessionConfig.timeoutIntervalForRequest = 180.0;
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
