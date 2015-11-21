//
//  AWARESensorViewController.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/19/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"
#import "AWAREStudyManager.h"


@interface AWARESensor (){
    NSMutableString *tempData;
    BOOL previusUploadingState;
    NSString * awareSensorName;
    NSString *latestSensorValue;
//    FMDatabase *db;
    NSString *dbPath;
}
@end

@implementation AWARESensor

- (instancetype)init
{
    self = [super init];
    if (self) {
        tempData = [[NSMutableString alloc] init];
        previusUploadingState = NO;
        awareSensorName = @"";
        latestSensorValue = @"";
    }
    return self;
}


- (instancetype) initWithSensorName:(NSString *)sensorName {
    if (self = [super init]) {
        awareSensorName = sensorName;
    }
    return self;
}

- (void) setLatestValue:(NSString *) valueStr{
    latestSensorValue = valueStr;
}

- (NSString *)getLatestValue{
    return latestSensorValue;
}

- (void) setSensorName:(NSString *)sensorName{
    awareSensorName = sensorName;
    //        FMDatabase *db = [FMDatabase databaseWithPath:@"/tmp/tmp.db"];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *dbName = [NSString stringWithFormat:@"%@.db",sensorName];
    dbPath = [documentsDirectory stringByAppendingPathComponent:dbName];
    _db = [FMDatabase databaseWithPath:dbPath];
    if (![_db open]) {
        NSLog(@"%@ dabase was not opened. Please check path of database of configuration.", sensorName);
        _db = nil;
    }else{
        NSLog(@"%@ dabase was created!!", sensorName);
    }
//    [_db executeStatements:@"drop table data;"];
    NSString *sql = @"create table data (id integer primary key autoincrement, timestamp double, data text);";
    if(![_db executeStatements:sql]){
        NSLog(@"Error: You could not make %@ table.", sensorName);
    }else{
        NSLog(@"%@ table was created!", sensorName);
    }
    [_db close];
}

- (NSString *)getSensorName{
    return awareSensorName;
}

- (BOOL)startSensor:(double) interval withUploadInterval:(double)upInterval{
    return NO;
}

- (BOOL)stopSensor{
    return NO;
}

- (NSString *)saveData:(NSDictionary *)data toLocalFile:(NSString *)fileName{
    NSError*error=nil;
    NSData*d=[NSJSONSerialization dataWithJSONObject:data options:2 error:&error];
    NSString*jsonstr=[[NSString alloc]initWithData:d encoding:NSUTF8StringEncoding];
//    [self appendLine:jsonstr path:fileName];
    // update to SQLite.
    NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
    NSNumber* unixtime = [NSNumber numberWithDouble:timeStamp];
    NSString* sql = [NSString stringWithFormat:@"insert into data (timestamp, data) values (%f, '%@')", unixtime.doubleValue, jsonstr];
//     _db = [FMDatabase databaseWithPath:dbPath];
    if (![_db open]) NSLog(@"%@ dabase was not opened.", dbPath);
    bool result = [_db executeStatements:sql];
    if(result){
//        NSLog(@"sucess!");
    }else{
        NSLog(@"failure...");
    }
    [_db close];
    return @"";
}


-  (NSString*) getData:(NSString *)fileName withJsonArrayFormat:(bool)jsonArrayFormat{
    // 1. Get sensor data.
    // 1.1 Open the database
    NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
    NSNumber* unixtime = [NSNumber numberWithDouble:timeStamp];
    NSString* sql = [NSString stringWithFormat:@"select * from data where timestamp < %f", unixtime.doubleValue];
    if (![_db open]) {
        NSLog(@"%@ dabase was not opened.", dbPath);
        return @"";
    }
    int count = 0;
    FMResultSet *s = [_db executeQuery:sql];
    [_db close];
    
    NSMutableString *data = [[NSMutableString alloc] initWithString:@"["];
    while ([s next]) {
        NSString *value = nil;
        @autoreleasepool{
            count++;
            value = [s objectForColumnName:@"data"];
            [data appendString:[NSString stringWithFormat:@"%@,", value]];
        }
    }
    NSLog(@"You got %d records",count);
    [s close];
    if([data length] > 1) [data deleteCharactersInRange:NSMakeRange([data length]-1, 1)];
    [data appendString:@"]"];
    // 2. Remove old sensor data.

    sql = [NSString stringWithFormat:@"delete from data where timestamp < %f", unixtime.doubleValue];
    bool result = [_db executeStatements:sql];
//    [db close];
    if (result) {
        NSLog(@"deleted");
    }else{
        NSLog(@"error!");
    }

    // 3. Return sensor data sa a NSString.
    return data;
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
    NSURLSession *session = nil;
    @autoreleasepool {
        previusUploadingState = YES; //file lock
//        NSLog(@"%@", data);
        post = [NSString stringWithFormat:@"device_id=%@&data=%@", deviceId, data];
        postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
        NSString *postLength = [NSString stringWithFormat:@"%ld", [postData length]];
        request = [[NSMutableURLRequest alloc] init];
        [request setURL:[NSURL URLWithString:url]];
        [request setHTTPMethod:@"POST"];
        [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
        //    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        [request setHTTPBody:postData];

        @autoreleasepool {
            session = [NSURLSession sharedSession];
            [[session dataTaskWithRequest:request
                       completionHandler:^(NSData * _Nullable data,
                                           NSURLResponse * _Nullable response,
                                           NSError * _Nullable error) {
                            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
                            int responseCode = (int)[httpResponse statusCode];
                            if(responseCode == 200){
                                NSLog(@"UPLOADED SENSOR DATA TO A SERVER");
                            }
                            previusUploadingState = NO;
                           dispatch_async(dispatch_get_main_queue(), ^{
                               [session finishTasksAndInvalidate];
                               [session invalidateAndCancel];
                               
                           });
            }] resume];
        }
    }
    return YES;
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



- (BOOL)createTable:(NSString *)data withDeviceId:(NSString *)deviceId withUrl:(NSString *)url{
    return NO;
}

- (BOOL)clearTable:(NSString *)data withDeviceId:(NSString *)deviceId withUrl:(NSString *)url{
    return NO;
}

- (void)uploadSensorData{
    
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
