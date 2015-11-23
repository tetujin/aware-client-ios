//
//  AWARESensorViewController.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/19/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"
#import "AWAREStudyManager.h"
#import "SCNetworkReachability.h"


@interface AWARESensor (){
    int bufferLimit;
    BOOL previusUploadingState;
    BOOL fileClearState;
    NSString * awareSensorName;
    NSString *latestSensorValue;
    int lineCount;
    SCNetworkReachability* reachability;
    NSMutableString *tempData;
    NSMutableString *bufferStr;
    bool wifiState;
}


@end

@implementation AWARESensor


- (instancetype)init
{
    self = [super init];
    if (self) {

    }
    return self;
}


- (instancetype) initWithSensorName:(NSString *)sensorName {
    if (self = [super init]) {
        NSLog(@"Initialize an AWARESensor as '%@' ", sensorName);
        awareSensorName = sensorName;
        bufferLimit = 0;
        previusUploadingState = NO;
        fileClearState = NO;
        awareSensorName = @"";
        latestSensorValue = @"";
        tempData = [[NSMutableString alloc] init];
        bufferStr = [[NSMutableString alloc] init];
    }
    return self;
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
    // network check
    wifiState = NO;
    
    reachability = [[SCNetworkReachability alloc] initWithHost:@"www.google.com"];
    [reachability observeReachability:^(SCNetworkStatus status)
    {
        switch (status)
        {
            case SCNetworkStatusReachableViaWiFi:
                NSLog(@"Reachable via WiFi at %@", [self getSensorName]);
                wifiState = YES;
                break;
                
            case SCNetworkStatusReachableViaCellular:
                NSLog(@"Reachable via Cellular at %@", [self getSensorName]);
                wifiState = NO;
                break;
                
            case SCNetworkStatusNotReachable:
                NSLog(@"Not Reachable at %@", [self getSensorName]);
                wifiState = NO;
                break;
        }
    }];
}

- (NSString *)getSensorName{
    return awareSensorName;
}

//- (BOOL)startSensor:(double) interval withUploadInterval:(double)upInterval{
//    return NO;
//}

-(BOOL)startSensor:(double)upInterval withSettings:(NSArray *)settings{
    return NO;
}

- (BOOL)stopSensor{
    return NO;
}


- (NSString *)saveData:(NSDictionary *)data toLocalFile:(NSString *)fileName{
    NSError*error=nil;
    NSData*d=[NSJSONSerialization dataWithJSONObject:data options:2 error:&error];
    NSString*jsonstr=[[NSString alloc]initWithData:d encoding:NSUTF8StringEncoding];
    
//    if ([fileName isEqualToString:SENSOR_ACCELEROMETER]) {
//        NSLog(@"%ld", bufferStr.length);
//    }
    
//    if(jsonstr == nil) return @"";
    if (bufferStr.length < bufferLimit) {
        [bufferStr appendString:jsonstr];
        [bufferStr appendFormat:@"\n"];
        return @"";
    }else{
        // append sensor data the file
        [bufferStr appendString:jsonstr];
        [self appendLine:bufferStr path:fileName];
        [bufferStr setString:@""];
        return @"";
    }
    
//    [self appendLine:jsonstr path:fileName];
    return @"";
}

- (BOOL) appendLine:(NSString *)line path:(NSString*) fileName {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString * path = [documentsDirectory stringByAppendingPathComponent:fileName];
    
    // file initialization and data clear:
    if(fileClearState){
        [self removeFile:fileName];
        fileClearState = NO;
    }
    
    if(previusUploadingState){
        [tempData appendFormat:@"%@\n", line];
        return YES;
    }else{
        NSData * tempdataLine = [tempData dataUsingEncoding:NSUTF8StringEncoding];
        NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:path];
        if (!fh) { // no
//            NSLog(@"You don't have a file for %@, then system recreated new file!", fileName);
            [self createNewFile:path];
            fh = [NSFileHandle fileHandleForWritingAtPath:path];
        }
        [fh seekToEndOfFile];
        if (![tempData isEqualToString:@""]) {
            [fh writeData:tempdataLine]; //write temp data to the main file
//            _tempData = [[NSMutableString alloc] init];// init
            [tempData setString:@""];
            NSLog(@"Add sensor data to the temp variable! @ %@", fileName);
        }
        line = [NSString stringWithFormat:@"%@\n", line];
        NSData *data = [line dataUsingEncoding:NSUTF8StringEncoding];
        [fh writeData:data];
        [fh synchronizeFile];
        [fh closeFile];
        return YES;
    }
//    return YES;
}

-(void)createNewFile:(NSString*) path
{
    NSFileManager *manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:path]) { // yes
        BOOL result = [manager createFileAtPath:path
                                       contents:[NSData data] attributes:nil];
        if (!result) {
            NSLog(@"Failed to create the file at %@", path);
            return;
        }else{
            NSLog(@"Create the file at %@", path);
        }
    }
    NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:path];
    if (!fh) {
        NSLog(@"Failed to handle the file at %@", path);
        return;
    }
    [fh closeFile];
}

- (bool) removeFile:(NSString *) fileName {
    NSFileManager *manager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString * path = [documentsDirectory stringByAppendingPathComponent:fileName];
    if ([manager fileExistsAtPath:path]) { // yes
//        NSLog(@"%@",path);
//        BOOL result = [manager createFileAtPath:path
//                                       contents:[NSData data] attributes:nil];
        bool result = [manager removeItemAtPath:path error:nil];
        if (!result) {
            NSLog(@"Failed to remove the file at %@", fileName);
            return NO;
        }else{
            NSLog(@"Sucsess to remove the file at %@", fileName);
            [self createNewFile:path];
            return YES;
        }
    }else{
        NSLog(@"File (%@) is not exist.", fileName);
        return YES;
    }
    return NO;
}


- (NSString*) getData:(NSString *)fileName withJsonArrayFormat:(bool)jsonArrayFormat{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString * path = [documentsDirectory stringByAppendingPathComponent:fileName];
    NSMutableString *data = nil;
    
//    @autoreleasepool {
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:path];
        if (!fileHandle) {
            NSLog(@"AWARE can not find the file of %@.", fileName);
            return @"[]";
        }
        NSString *str = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
        [fileHandle closeFile];
        
        lineCount = 0;
        data = [[NSMutableString alloc] initWithString:@"["];
        [str enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
            lineCount++;
            [data appendString:[NSString stringWithFormat:@"%@,", line]];
        }];
        [data deleteCharactersInRange:NSMakeRange([data length]-1, 1)];
        [data appendString:@"]"];
        NSLog(@"[%@] You got %d lines of sensor data", [self getSensorName], lineCount);
//        NSLog(@"%@", data);
//    }
    return [NSString stringWithString:data];
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
    return [NSString stringWithFormat:@"%@/%@/create_tablet", [self getWebserviceUrl], sensorName];
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

- (BOOL)insertSensorData:(NSString *)data withDeviceId:(NSString *)deviceId url:(NSString *)url{
    NSString *post = nil;
    NSData *postData = nil;
    NSMutableURLRequest *request = nil;
    __weak NSURLSession *session = nil;
    NSString *postLength = nil;
//    NSLog(@"Wifi network state is %d", wifiState);
    if (!wifiState) {
        NSLog(@"You need wifi network to upload sensor data.");
        return NO;
    }
    
    previusUploadingState = YES; //file lock
    
    // Set settion configu and HTTP/POST body.
    NSURLSessionConfiguration *sessionConfig =
    [NSURLSessionConfiguration defaultSessionConfiguration];
//        sessionConfig.allowsCellularAccess = NO;
//        [sessionConfig setHTTPAdditionalHeaders:
//         @{@"Accept": @"application/json"}];
    sessionConfig.timeoutIntervalForRequest = 180.0;
    sessionConfig.timeoutIntervalForResource = 300.0;
    sessionConfig.HTTPMaximumConnectionsPerHost = 30;
    
    post = [NSString stringWithFormat:@"device_id=%@&data=%@", deviceId, data];
//        NSLog(@"%@", post);
    postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    postLength = [NSString stringWithFormat:@"%ld", [postData length]];
    request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:postData];
    
    
    // Check application condition: "foreground(YES)" or "background(NO)"
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    bool foreground = [defaults objectForKey:@"APP_STATE"];
    
//    foreground = NO;
    // HTTP/POST with each application condition
    if (foreground) { // foreground
        session = [NSURLSession sessionWithConfiguration:sessionConfig];
        [[session dataTaskWithRequest:request
                   completionHandler:^(NSData * _Nullable data,
                                       NSURLResponse * _Nullable response,
                                       NSError * _Nullable error) {
                        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
                        int responseCode = (int)[httpResponse statusCode];
                       
                       NSString* newStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                       NSLog(@"%@: Response=> %@", [self getSensorName],newStr);
                       
                        if(responseCode == 200){
                            NSString *message = [NSString stringWithFormat:@"Sucess to upload sensor data (%@) to AWARE server in the fourground.", [self getSensorName]];
                            NSLog(@"%@", message);
                            [self sendLocalNotificationForMessage:message soundFlag:NO];
                            fileClearState = YES;
                        }
                       previusUploadingState = NO;
                       data = nil;
                       response = nil;
                       error = nil;
                       httpResponse = nil;
                       dispatch_async(dispatch_get_main_queue(), ^{
                                [session finishTasksAndInvalidate];
                                [session invalidateAndCancel];
                       });
        }] resume];
    }else{ // background
        NSError *error = nil;
        NSHTTPURLResponse *response = nil;
        NSData *resData = [NSURLConnection sendSynchronousRequest:request
                                                returningResponse:&response error:&error];
        NSString* newStr = [[NSString alloc] initWithData:resData encoding:NSUTF8StringEncoding];
        NSLog(@"%@: Response=> %@", [self getSensorName],newStr);
        int responseCode = (int)[response statusCode];
        if(responseCode == 200){
            NSString *message = [NSString stringWithFormat:@"Sucess to upload sensor data (%@) to AWARE server in the background", [self getSensorName]];
            NSLog(@"%@", message);
            fileClearState = YES;
            [self sendLocalNotificationForMessage:message soundFlag:NO];
        }else{
            return NO;
        }
        previusUploadingState = NO;
        data = nil;
        response = nil;
        error = nil;
    }
    return YES;
}

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error{
    
}

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler{
    
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session{
    
}

//- URLSession:didBecomeInvalidWithErr
//- URLSession:didReceiveChallenge:completionHandler:
//- URLSessionDidFinishEventsForBackgroundURLSession:



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



- (BOOL)createTable:(NSString *)data withDeviceId:(NSString *)deviceId withUrl:(NSString *)url{
    return NO;
}

- (BOOL)clearTable:(NSString *)data withDeviceId:(NSString *)deviceId withUrl:(NSString *)url{
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
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}


// Using SQLite

//- (NSString *)saveData:(NSDictionary *)data toLocalFile:(NSString *)fileName{
//    NSError*error=nil;
//    NSData*d=[NSJSONSerialization dataWithJSONObject:data options:2 error:&error];
//    NSString*jsonstr=[[NSString alloc]initWithData:d encoding:NSUTF8StringEncoding];
//    //    [self appendLine:jsonstr path:fileName];
//    // update to SQLite.
//    NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
//    NSNumber* unixtime = [NSNumber numberWithDouble:timeStamp];
//    NSString* sql = [NSString stringWithFormat:@"insert into data (timestamp, data) values (%f, '%@')", unixtime.doubleValue, jsonstr];
//    //     _db = [FMDatabase databaseWithPath:dbPath];
//    if (![_db open]) NSLog(@"%@ dabase was not opened.", dbPath);
//    bool result = [_db executeStatements:sql];
//    if(result){
//        //        NSLog(@"sucess!");
//    }else{
//        NSLog(@"failure...");
//    }
//    [_db close];
//    return @"";
//}
//
//
//-  (NSString*) getData:(NSString *)fileName withJsonArrayFormat:(bool)jsonArrayFormat{
//    // 1. Get sensor data.
//    // 1.1 Open the database
//    NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
//    NSNumber* unixtime = [NSNumber numberWithDouble:timeStamp];
//    NSString* sql = [NSString stringWithFormat:@"select * from data where timestamp < %f", unixtime.doubleValue];
//    if (![_db open]) {
//        NSLog(@"%@ dabase was not opened.", dbPath);
//        return @"";
//    }
//    int count = 0;
//    FMResultSet *s = [_db executeQuery:sql];
//    [_db close];
//    
//    NSMutableString *data = [[NSMutableString alloc] initWithString:@"["];
//    while ([s next]) {
//        NSString *value = nil;
//        @autoreleasepool{
//            count++;
//            value = [s objectForColumnName:@"data"];
//            [data appendString:[NSString stringWithFormat:@"%@,", value]];
//        }
//    }
//    NSLog(@"You got %d records",count);
//    [s close];
//    if([data length] > 1) [data deleteCharactersInRange:NSMakeRange([data length]-1, 1)];
//    [data appendString:@"]"];
//    // 2. Remove old sensor data.
//    
//    sql = [NSString stringWithFormat:@"delete from data where timestamp < %f", unixtime.doubleValue];
//    bool result = [_db executeStatements:sql];
//    //    [db close];
//    if (result) {
//        NSLog(@"deleted");
//    }else{
//        NSLog(@"error!");
//    }
//    
//    // 3. Return sensor data sa a NSString.
//    return data;
//}





//- (BOOL) appendLine:(NSString *)line path:(NSString*) fileName {
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *documentsDirectory = [paths objectAtIndex:0];
//    NSString * path = [documentsDirectory stringByAppendingPathComponent:fileName];
//    if(previusUploadingState){
//        [tempData appendFormat:@"%@\n", line];
//        return YES;
//    }else{
//        NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:path];
//        if (!fh) { // no
//            NSLog(@"Re-create the file! ");
//            [self createNewFile:path];
//            fh = [NSFileHandle fileHandleForWritingAtPath:path];
//        }
//        [fh seekToEndOfFile];
//        if (![tempData isEqualToString:@""]) {
//            [fh writeData:[tempData dataUsingEncoding:NSUTF8StringEncoding]]; //write temp data to the main file
//            tempData = [[NSMutableString alloc] init];// init
//            NSLog(@"----> add temp data to the file!!!! ");
//        }
//        line = [NSString stringWithFormat:@"%@\n", line];
//        NSData *data = [line dataUsingEncoding:NSUTF8StringEncoding];
//        [fh writeData:data];
//        [fh synchronizeFile];
//        [fh closeFile];
//        return YES;
//    }
//}

//-(void)createNewFile:(NSString*) path
//{
//    NSFileManager *manager = [NSFileManager defaultManager];
//    if (![manager fileExistsAtPath:path]) { // yes
//        BOOL result = [manager createFileAtPath:path
//                                       contents:[NSData data] attributes:nil];
//        if (!result) {
//            NSLog(@"ファイルの作成に失敗");
//            return;
//        }else{
//            NSLog(@"Created a file");
//        }
//    }
//    NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:path];
//    if (!fh) {
//        NSLog(@"ファイルハンドルの作成に失敗");
//        return;
//    }
//    [fh closeFile];
//}


//- (NSString*) getData:(NSString *)fileName withJsonArrayFormat:(bool)jsonArrayFormat{
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *documentsDirectory = [paths objectAtIndex:0];
//    NSString * path = [documentsDirectory stringByAppendingPathComponent:fileName];
//    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:path];
//    if (!fileHandle) {
//        NSLog(@"ファイルがありません．");
//        return @"[]";
//    }
//    NSString *str = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
//    [fileHandle closeFile];
//
//    NSMutableString *data = nil;
//    @autoreleasepool {
//        data = [[NSMutableString alloc] initWithString:@"["];
//        [str enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
//            [data appendString:[NSString stringWithFormat:@"%@,", line]];
//        }];
//        [data deleteCharactersInRange:NSMakeRange([data length]-1, 1)];
//        [data appendString:@"]"];
//    }
//    return [NSString stringWithString:data];
//}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
