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
    [self appendLine:jsonstr path:fileName];
    return @"";
}

- (BOOL) appendLine:(NSString *)line path:(NSString*) fileName {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString * path = [documentsDirectory stringByAppendingPathComponent:fileName];
//    NSLog(@"--> %@", path);
    if(previusUploadingState){
        [tempData appendFormat:@"%@\n", line];
        return YES;
    }else{
        NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:path];
        if (!fh) { // no
            NSLog(@"Re-create the file! ");
            [self createNewFile:path];
            fh = [NSFileHandle fileHandleForWritingAtPath:path];
        }
        [fh seekToEndOfFile];
        //if tempdata has some data
        if (![tempData isEqualToString:@""]) {
            [fh writeData:[tempData dataUsingEncoding:NSUTF8StringEncoding]]; //write temp data to the main file
            tempData = [[NSMutableString alloc] init];// init
            NSLog(@"----> add temp data to the file!!!! ");
        }
        line = [NSString stringWithFormat:@"%@\n", line];
        NSData *data = [line dataUsingEncoding:NSUTF8StringEncoding];
        [fh writeData:data];
        [fh synchronizeFile];
        [fh closeFile];
        return YES;
    }
}

-(void)createNewFile:(NSString*) path
{
    NSFileManager *manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:path]) { // yes
        BOOL result = [manager createFileAtPath:path
                                       contents:[NSData data] attributes:nil];
        if (!result) {
            NSLog(@"ファイルの作成に失敗");
            return;
        }else{
            NSLog(@"Created a file");
        }
    }
    NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:path];
    if (!fh) {
        NSLog(@"ファイルハンドルの作成に失敗");
        return;
    }
    [fh closeFile];
}


- (NSString*) getData:(NSString *)fileName withJsonArrayFormat:(bool)jsonArrayFormat{
    // ファイルハンドルを作成する
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString * path = [documentsDirectory stringByAppendingPathComponent:fileName];
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:path];
    if (!fileHandle) {
        NSLog(@"ファイルがありません．");
        return @"[]";
    }
    // ファイルの末尾まで読み込む
    NSString *str = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    [fileHandle closeFile];
    
    NSMutableString *data = [[NSMutableString alloc] initWithString:@"["];
    // 1行ずつ文字列を列挙
    [str enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
        [data appendString:[NSString stringWithFormat:@"%@,", line]];
    }];
    [data deleteCharactersInRange:NSMakeRange([data length]-1, 1)];
    [data appendString:@"]"];
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
    previusUploadingState = YES; //file lock
    NSString *post = [NSString stringWithFormat:@"device_id=%@&data=%@", deviceId, data];
    NSLog(@"%@", post);
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%ld", [postData length]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    //    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    
    //    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSError *error = nil;
        NSHTTPURLResponse *response = nil;
        NSData *resData = [NSURLConnection sendSynchronousRequest:request
                                                returningResponse:&response error:&error];
        NSString* newStr = [[NSString alloc] initWithData:resData encoding:NSUTF8StringEncoding];
        NSLog(@"%@", newStr);
        //                    NSArray *mqttArray = [NSJSONSerialization JSONObjectWithData:resData options:NSJSONReadingMutableContainers error:nil];
        //        id obj = [NSJSONSerialization JSONObjectWithData:resData options:NSJSONReadingMutableContainers error:nil];
        //        NSData *data = [NSJSONSerialization dataWithJSONObject:obj options:0 error:nil];
        //        NSLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        int responseCode = (int)[response statusCode];
        dispatch_async(dispatch_get_main_queue(), ^{
            if(responseCode == 200){
                NSLog(@"UPLOADED SENSOR DATA TO A SERVER");
            }
            previusUploadingState = NO; //file unlock
        });
    });
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
    NSLog(@"%@", newStr);
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

- (void)uploadSensorData {
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
