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
    BOOL previusUploadingState;
    NSString * awareSensorName;
    NSString *latestSensorValue;
    int lineCount;
    SCNetworkReachability* reachability;
    NSMutableString *tempData;
    NSMutableString *bufferStr;
    bool wifiState;
    NSTimer* writeAbleTimer;
    bool writeAble;
    int marker;
    int errorPosts;
}

@end

@implementation AWARESensor

- (instancetype) initWithSensorName:(NSString *)sensorName {
    if (self = [super init]) {
        NSLog(@"[%@] Initialize an AWARESensor as '%@' ", sensorName, sensorName);
        awareSensorName = sensorName;
        bufferLimit = 0;
        previusUploadingState = NO;
        awareSensorName = sensorName;
        latestSensorValue = @"";
        errorPosts = 0;
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
}

- (void) stopWriteableTimer{
    if (!writeAbleTimer) {
        [writeAbleTimer invalidate];
    }
}

- (void) setBufferLimit:(int)limit{
    bufferLimit = limit;
}

- (void) setLatestValue:(NSString *) valueStr{
    latestSensorValue = valueStr;
}

- (NSString *)getLatestValue{
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
    if (writeAble) {
        [self appendLine:bufferStr path:fileName];
        [bufferStr setString:@""];
        [self setWriteableNO];
    }
    return YES;
}

- (bool) saveDataWithArray:(NSArray*) array {
    NSError*error=nil;
    for (NSDictionary *dic in array) {
        NSLog(@"%f", [dic objectForKey:@"timestamp"]);
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



/** Sync with AWARE database */
- (void) syncAwareDB {
    if (!wifiState) {
        NSLog(@"You need wifi network to upload sensor data.");
        return;
    }
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
//    NSInteger marker = [userDefaults integerForKey:KEY_MARK];
    NSInteger length = [userDefaults integerForKey:KEY_MAX_DATA_SIZE];
//    NSUInteger length = 1000 * 1000 * 5; //5MB
    NSUInteger seek = marker * length;
    
    previusUploadingState = YES;
    
    // init variables
    NSString *post = nil;
    NSData *postData = nil;
    NSMutableURLRequest *request = nil;
    __weak NSURLSession *session = nil;
    NSString *postLength = nil;
    NSString *sensorName = [self getSensorName];
    NSString *deviceId = [self getDeviceId];
    NSString *url = [self getInsertUrl:sensorName];
    lineCount = 0;
    
    // get sensor data from file
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString * path = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.dat",sensorName]];
    NSMutableString *data = nil;
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:path];
    if (!fileHandle) {
        NSLog(@"[%@] AWARE can not handle the file.", sensorName);
        [self createNewFile:sensorName];
        previusUploadingState = NO;
        return;
    }
    [fileHandle seekToFileOffset:seek];
    NSData *clipedData = [fileHandle readDataOfLength:length];
    [fileHandle closeFile];
    
    data = [[NSMutableString alloc] initWithData:clipedData encoding:NSUTF8StringEncoding];
    lineCount = (int)data.length;
    NSLog(@"[%@] Line lenght is %ld", [self getSensorName], (unsigned long)data.length);
    if (data.length == 0) {
        previusUploadingState = NO;
        marker = 0;
        return;
    }
    
    if ( data.length < length ) {
        // more post = 0
        marker = 0;
    } else {
        // more post += 1
        marker += 1;
    }
    data = [self fixJsonFormat:data];

    // Set session configuration
    NSURLSessionConfiguration *sessionConfig = nil;
//    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
//    BOOL foreground = [defaults boolForKey:@"APP_STATE"];
//    foreground = NO;
//    
//    if (foreground) {
        // If the app in the foreground, we will make a default session
//        sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
//    } else {
//        // If the app in the background, we will make a background session with identifier.
        NSDate *now = [NSDate date];
        NSString* identifier = [NSString stringWithFormat:@"%@_%f", sensorName, [now timeIntervalSince1970]];
        sessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:identifier];
//    }
    sessionConfig.timeoutIntervalForRequest = 120.0;
    sessionConfig.HTTPMaximumConnectionsPerHost = 60;
    sessionConfig.timeoutIntervalForResource = 60; //60*60*24; // 1 day
    sessionConfig.allowsCellularAccess = NO;
    sessionConfig.discretionary = YES;
    //        [sessionConfig setHTTPAdditionalHeaders:
    //         @{@"Accept": @"application/json"}];
    //    sessionConfig.timeoutIntervalForResource = 300.0;

    // set HTTP/POST body information
    post = [NSString stringWithFormat:@"device_id=%@&data=%@", deviceId, data];
    postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    postLength = [NSString stringWithFormat:@"%ld", [postData length]];
    request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:postData];
    
//    if (foreground) {
//        NSLog(@"--- This is a foreground task----");
//        session = [NSURLSession sessionWithConfiguration:sessionConfig];
//        [[session dataTaskWithRequest:request
//                    completionHandler:^(NSData * _Nullable data,
//                                        NSURLResponse * _Nullable response,
//                                        NSError * _Nullable error) {
//                        
//                        [self receivedResponseFromServer:response withData:data error:error];
//                    }] resume];
//    }else {
        NSLog(@"--- This is background task ----");
        session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];
        NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request];
        [dataTask resume];
//    }
    
//    dispatch_async(dispatch_get_main_queue(), ^{
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"title" message:@"message" delegate:self cancelButtonTitle:@"cancel" otherButtonTitles:@"OK",@"hello",@"hoge",@"hoge", nil];
//        [alert show];
//        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Filename" message:@"Enter the file name:" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil];
//        alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
//        //    UITextField *passwordTextField = [alertView textFieldAtIndex:0];
//        [alertView show];
//    });
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    NSLog(@"[%@] Get response from the server.", [self getSensorName]);
    [self receivedResponseFromServer:dataTask.response withData:nil error:nil];
    completionHandler(NSURLSessionResponseAllow);
//    [session finishTasksAndInvalidate];
//    [session invalidateAndCancel];
}


-(void)URLSession:(NSURLSession *)session
         dataTask:(NSURLSessionDataTask *)dataTask
   didReceiveData:(NSData *)data {
    // If the data is null, this method is not called.
    NSLog(@"[%@] Data is coming!", [self getSensorName]);
    NSString * result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"[%@] response => %@", result);
    
    [session finishTasksAndInvalidate];
    [session invalidateAndCancel];
}


- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error) {
        NSLog(@"[%@] Session task finished with error. %@", [self getSensorName], error.debugDescription);
        if ( marker > 0 ) {
            marker = marker - 1;
        }
        errorPosts++;
        NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
        bool debugState = [defaults boolForKey:SETTING_DEBUG_STATE];
        if (debugState) {
            [self sendLocalNotificationForMessage:[NSString stringWithFormat:@"[%@] Retry - %d (%d)", [self getSensorName], marker, errorPosts] soundFlag:NO];
        }
//        [self downLimit];
        if (errorPosts < 3) { //TODO
            [self syncAwareDB];
        } else {
            errorPosts = 0;
        }
    } else {
        NSLog(@"[%@] Session task finished correctly.", [self getSensorName]);
//        [self upLimit];
        errorPosts = 0;
    }
    NSLog(@"%@", task.description);
    previusUploadingState = NO;
    [session finishTasksAndInvalidate];
    [session invalidateAndCancel];
//    completionHandler(NSURLSessionResponseAllow);
}


- (void) downLimit {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSInteger length = [defaults integerForKey:KEY_MAX_DATA_SIZE];
    // 1000 * 100; //100KB
    if( length > 1000*100 && lineCount == length ){
        length = length/5;
        [defaults setInteger:length forKey:KEY_MAX_DATA_SIZE];
    }
}

- (void) upLimit {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSInteger length = [defaults integerForKey:KEY_MAX_DATA_SIZE];
    // 1000 * 1000 * 5; //5MB
    if(length < 1000*1000*5 && lineCount == length ){
        length = length*5;
        [defaults setInteger:length forKey:KEY_MAX_DATA_SIZE];
    }
}


- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error{
//    NSLog(@"[%@] error.... then this session is canceled.: %@", [self getSensorName], error.debugDescription);
    previusUploadingState = NO;
    [session invalidateAndCancel];
    [session finishTasksAndInvalidate];
}


- (NSMutableString *) fixJsonFormat:(NSMutableString *) clipedText {
    // head
    if ([clipedText hasPrefix:@"{"]) {
//        NSLog(@"HEAD => correct!");
    }else{
        NSRange rangeOfExtraText = [clipedText rangeOfString:@"{"];
        if (rangeOfExtraText.location == NSNotFound) {
//            NSLog(@"[HEAD] There is no extra text");
        }else{
//            NSLog(@"[HEAD] There is some extra text!");
            NSRange deleteRange = NSMakeRange(0, rangeOfExtraText.location);
            [clipedText deleteCharactersInRange:deleteRange];
        }
    }
    
    // tail
    if ([clipedText hasSuffix:@"}"]){
//        NSLog(@"TAIL => correct!");
    }else{
        NSRange rangeOfExtraText = [clipedText rangeOfString:@"}" options:NSBackwardsSearch];
        if (rangeOfExtraText.location == NSNotFound) {
//            NSLog(@"[TAIL] There is no extra text");
        }else{
//            NSLog(@"[TAIL] There is some extra text!");
            NSRange deleteRange = NSMakeRange(rangeOfExtraText.location+1, clipedText.length-rangeOfExtraText.location-1);
            //                NSLog(@"%@", clipedText);
            [clipedText deleteCharactersInRange:deleteRange];
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
    if(responseCode == 200){
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
//        debugState = YES;
        if (debugState) {
            [self sendLocalNotificationForMessage:message soundFlag:NO];
        }
    }
    
    previusUploadingState = NO;
    
    data = nil;
    response = nil;
    error = nil;
    httpResponse = nil;
    dispatch_async(dispatch_get_main_queue(), ^{
        CGFloat currentVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
        if (currentVersion >= 9.0) {
//            [session finishTasksAndInvalidate];
//            [session invalidateAndCancel];
        }
        if (marker != 0) {
            [self syncAwareDB];
        }else{
            if(responseCode == 200){
                [self removeFile:[self getSensorName]];
                //                                NSLog(@"[%@] File is removed.", [self getSensorName]);
            }
            //                            previusUploadingState = NO;
        }
    });
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
//    NSLog(@"%@", newStr);
    int responseCode = (int)[response statusCode];
    if(responseCode == 200){
        NSLog(@"UPLOADED SENSOR DATA TO A SERVER");
        return newStr;
    }
    return @"";
}



- (void) createTable:(NSString *)query{
    
    NSLog(@"%@",[self getCreateTableUrl:[self getSensorName]]);
    
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
    [request setURL:[NSURL URLWithString:[self getCreateTableUrl:[self getSensorName]]]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:postData];
    
    NSURLSessionConfiguration *sessionConfig =
    [NSURLSessionConfiguration defaultSessionConfiguration];
    //        sessionConfig.allowsCellularAccess = NO;
    //        [sessionConfig setHTTPAdditionalHeaders:
    //         @{@"Accept": @"application/json"}];
    sessionConfig.timeoutIntervalForRequest = 180.0;
    sessionConfig.timeoutIntervalForResource = 300.0;
    sessionConfig.HTTPMaximumConnectionsPerHost = 30;

    session = [NSURLSession sessionWithConfiguration:sessionConfig];
    [[session dataTaskWithRequest:request
                completionHandler:^(NSData * _Nullable data,
                                    NSURLResponse * _Nullable response,
                                    NSError * _Nullable error) {
                    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
                    int responseCode = (int)[httpResponse statusCode];
                    
                    NSString* newStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    NSLog(@"[%@] Response----> %d, %@", [self getSensorName],responseCode, newStr);
                    
                    if(responseCode == 200){
//                        [self removeFile:[self getSensorName]];
//                        //                            [self createNewFile:[self getSensorName]];
                        NSString *message = [NSString stringWithFormat:@"[%@] Sucess to create new table on AWARE server.", [self getSensorName]];
                        NSLog(@"%@", message);
//                        [self sendLocalNotificationForMessage:message soundFlag:NO];
                    }
//                    previusUploadingState = NO;
                    data = nil;
                    response = nil;
                    error = nil;
                    httpResponse = nil;
//                    dispatch_async(dispatch_get_main_queue(), ^{
//                        [session finishTasksAndInvalidate];
//                        [session invalidateAndCancel];
//                    });
                }] resume];
}

- (BOOL) clearTable
{
    NSLog(@"%@",[self getCreateTableUrl:[self getSensorName]]);
    NSString *post = nil;
    NSData *postData = nil;
    NSMutableURLRequest *request = nil;
    __weak NSURLSession *session = nil;
    NSString *postLength = nil;
    post = [NSString stringWithFormat:@"device_id=%@", [self getDeviceId]];
    NSLog(@"%@", post);
    postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    postLength = [NSString stringWithFormat:@"%ld", [postData length]];
    request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:[self getClearTableUrl:[self getSensorName]]]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:postData];
    
    NSURLSessionConfiguration *sessionConfig =
    [NSURLSessionConfiguration defaultSessionConfiguration];
    //        sessionConfig.allowsCellularAccess = NO;
    //        [sessionConfig setHTTPAdditionalHeaders:
    //         @{@"Accept": @"application/json"}];
    sessionConfig.timeoutIntervalForRequest = 180.0;
    sessionConfig.timeoutIntervalForResource = 300.0;
    sessionConfig.HTTPMaximumConnectionsPerHost = 30;
    
    session = [NSURLSession sessionWithConfiguration:sessionConfig];
    [[session dataTaskWithRequest:request
                completionHandler:^(NSData * _Nullable data,
                                    NSURLResponse * _Nullable response,
                                    NSError * _Nullable error) {
                    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
                    int responseCode = (int)[httpResponse statusCode];
                    
                    NSString* newStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    NSLog(@"[%@] Response----> %d, %@", [self getSensorName],responseCode, newStr);
                    
                    if(responseCode == 200){
                        //                        [self removeFile:[self getSensorName]];
                        //                        //                            [self createNewFile:[self getSensorName]];
                        NSString *message = [NSString stringWithFormat:@"[%@] Sucess to clear table on AWARE server.", [self getSensorName]];
                        NSLog(@"%@", message);
                        //                        [self sendLocalNotificationForMessage:message soundFlag:NO];
                    }
                    //                    previusUploadingState = NO;
                    data = nil;
                    response = nil;
                    error = nil;
                    httpResponse = nil;
                    //                    dispatch_async(dispatch_get_main_queue(), ^{
                    //                        [session finishTasksAndInvalidate];
                    //                        [session invalidateAndCancel];
                    //                    });
                }] resume];
    return NO;
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
//    localNotification.alertAction = @"hoge";
//    [self registerForNotification];
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}



- (void)registerForNotification {
    
    UIMutableUserNotificationAction *action1;
    action1 = [[UIMutableUserNotificationAction alloc] init];
    [action1 setActivationMode:UIUserNotificationActivationModeBackground];
    [action1 setTitle:@"Action 1"];
    [action1 setIdentifier:NotificationActionOneIdent];
    [action1 setDestructive:NO];
    [action1 setAuthenticationRequired:NO];
    
    UIMutableUserNotificationAction *action2;
    action2 = [[UIMutableUserNotificationAction alloc] init];
    [action2 setActivationMode:UIUserNotificationActivationModeBackground];
    [action2 setTitle:@"Action 2"];
    [action2 setIdentifier:NotificationActionTwoIdent];
    [action2 setDestructive:NO];
    [action2 setAuthenticationRequired:NO];
    
    UIMutableUserNotificationCategory *actionCategory;
    actionCategory = [[UIMutableUserNotificationCategory alloc] init];
    [actionCategory setIdentifier:NotificationCategoryIdent];
    [actionCategory setActions:@[action1, action2]
                    forContext:UIUserNotificationActionContextDefault];
    
    NSSet *categories = [NSSet setWithObject:actionCategory];
    UIUserNotificationType types = (UIUserNotificationTypeAlert|
                                    UIUserNotificationTypeSound|
                                    UIUserNotificationTypeBadge);
    
    UIUserNotificationSettings *settings;
    settings = [UIUserNotificationSettings settingsForTypes:types
                                                 categories:categories];
    
    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
}



- (void)connection:(NSURLConnection *)connection
didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    NSLog(@"-------------------");
    if ([[[challenge protectionSpace] authenticationMethod] isEqualToString: NSURLAuthenticationMethodServerTrust]){
        
        do {
            SecTrustRef serverTrust = [[challenge protectionSpace] serverTrust];
            if (serverTrust == nil)
                break; // failed
            
            SecTrustResultType trustResult;
            OSStatus status = SecTrustEvaluate(serverTrust, &trustResult);
            if (!(errSecSuccess == status))
                break; // fatal error in trust evaluation -> failed
            
            if (!((trustResult == kSecTrustResultProceed)
                  || (trustResult == kSecTrustResultUnspecified)))
            {
                break; // see "Certificate, Key, and Trust Services Reference"
                // for explanation of result codes.
            }
            
            SecCertificateRef serverCertificate = SecTrustGetCertificateAtIndex(serverTrust, 0);
            if (serverCertificate == nil)
                break; // failed
            
            CFDataRef serverCertificateData = SecCertificateCopyData(serverCertificate);
            if (serverCertificateData == nil)
                break; // failed
            
            const UInt8* const data = CFDataGetBytePtr(serverCertificateData);
            const CFIndex size = CFDataGetLength(serverCertificateData);
            NSData* server_cert = [NSData dataWithBytes:data length:(NSUInteger)size];
            CFRelease(serverCertificateData);
            
            NSString* file = [[NSBundle mainBundle] pathForResource:@"awareframework"
                                                             ofType:@"der"];
            NSData* my_cert = [NSData dataWithContentsOfFile:file];
            
            if (server_cert == nil || my_cert == nil)
                break; // failed
            
            const BOOL equal = [server_cert isEqualToData:my_cert];
            if (!equal)
                break; // failed
            
            // Athentication succeeded:
            return [[challenge sender] useCredential:[NSURLCredential credentialForTrust:serverTrust]
                          forAuthenticationChallenge:challenge];
        } while (0);
        
        // Authentication failed:
        return [[challenge sender] cancelAuthenticationChallenge:challenge];
    }
}

@end
