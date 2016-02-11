//
//  AWAREStudy.m
//  AWARE for OSX
//
//  Created by Yuuki Nishiyama on 12/5/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWAREStudy.h"
#import "AWAREKeys.h"
#import "SSLManager.h"
#import "AWAREUtils.h"

@implementation AWAREStudy {
    NSString *mqttPassword;
    NSString *mqttUsername;
    NSString *studyId;
    NSString *mqttServer;
    NSString *webserviceServer;
    int mqttPort;
    int mqttKeepAlive;
    int mqttQos;
    bool readingState;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _getSettingIdentifier = @"set_setting_identifier";
        _addDeviceTableIdentifier = @"add_device_table_identifier";
        _makeDeviceTableIdentifier = @"make_device_table_identifier";
        
        mqttPassword = @"";
        mqttUsername = @"";
        studyId = @"";
        mqttServer = @"";
        webserviceServer = @"";
        mqttPort = 1883;
        mqttKeepAlive = 600;
        mqttQos = 2;
        readingState = YES;
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSString* tempUserName = [userDefaults objectForKey:KEY_MQTT_USERNAME];
        if(tempUserName != nil){
            mqttServer = [userDefaults objectForKey:KEY_MQTT_SERVER];
            mqttUsername = [userDefaults objectForKey:KEY_MQTT_USERNAME];
            mqttPassword =  [userDefaults objectForKey:KEY_MQTT_PASS];
            mqttPort =  [[userDefaults objectForKey:KEY_MQTT_PORT] intValue];
            mqttKeepAlive = [[userDefaults objectForKey:KEY_MQTT_KEEP_ALIVE] intValue];
            mqttQos = [[userDefaults objectForKey:KEY_MQTT_QOS] intValue];
            studyId = [userDefaults objectForKey:KEY_STUDY_ID];
            webserviceServer = [userDefaults objectForKey:KEY_WEBSERVICE_SERVER];
        }
    }
    return self;
}


/**
 * This method downloads and sets a study configuration by using study URL. (NOTE: This URL can get from a study QRCode.)
 *
 * @param url An study URL (e.g., https://r2d2.hcii.cs.cmu.edu/aware/dashboard/index.php/webservice/index/41/4LtzPxcAIrdi)
 * @return The result of download and set a study configuration
 */
- (BOOL) setStudyInformationWithURL:(NSString*)url {
    if (url != nil) {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setObject:url forKey:KEY_STUDY_QR_CODE];
    }
    NSString * deviceId = [AWAREUtils getSystemUUID];
    return [self setStudyInformation:url withDeviceId:deviceId];
}

- (bool) setStudyInformation:(NSString *)url withDeviceId:(NSString *) uuid {
    __weak NSURLSession *session = nil;
    // Set session configuration
    NSURLSessionConfiguration *sessionConfig = nil;
    double unxtime = [[NSDate new] timeIntervalSince1970];
    _getSettingIdentifier = [NSString stringWithFormat:@"%@%f", _getSettingIdentifier, unxtime];
    
    NSString *post = [NSString stringWithFormat:@"device_id=%@", uuid];
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%ld", [postData length]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:postData];

    // A process in the foreground
    if ( [AWAREUtils isForeground] ) {
        NSURLSession *session = [NSURLSession sharedSession];
        [[session dataTaskWithRequest: request  completionHandler: ^(NSData *data, NSURLResponse *response, NSError *error) {
            [session finishTasksAndInvalidate];
            [session invalidateAndCancel];
            // Success
            if (response && ! error) {
                NSString *responseString = [[NSString alloc] initWithData: data  encoding: NSUTF8StringEncoding];
                NSLog(@"Success: %@", responseString);
                [self setStudySettings:data];
            // Error
            } else {
                NSLog(@"Error: %@", error);
                NSLog(@"ERROR: %@ %ld", error.debugDescription , error.code);
                if (error.code == -1202) {
                    /**
                     * If the error code is -1202, this device needs .crt for SSL(secure) connection.
                     */
                    // Install CRT file for SSL
                    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                    NSString* url = [userDefaults objectForKey:KEY_STUDY_QR_CODE];
                    SSLManager *sslManager = [[SSLManager alloc] init];
                    [sslManager installCRTWithTextOfQRCode:url];
                }
            }
        }] resume];
    // A process in the background
    }else{
        sessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:_getSettingIdentifier];
        sessionConfig.timeoutIntervalForRequest = 120.0;
        sessionConfig.HTTPMaximumConnectionsPerHost = 60;
        sessionConfig.timeoutIntervalForResource = 60; //60*60*24; // 1 day
        sessionConfig.allowsCellularAccess = YES;
        sessionConfig.discretionary = YES;
        
        NSLog(@"--- This is background task ----");
        session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];
        NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request];
        [dataTask resume];
    }
    return YES;
}


- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
    int responseCode = (int)[httpResponse statusCode];
    NSLog(@"%d",responseCode);
    [session finishTasksAndInvalidate];
    [session invalidateAndCancel];
    completionHandler(NSURLSessionResponseAllow);
}


-(void)URLSession:(NSURLSession *)session
         dataTask:(NSURLSessionDataTask *)dataTask
   didReceiveData:(NSData *)data {

    [self setStudySettings:data];
    [session finishTasksAndInvalidate];
    [session invalidateAndCancel];
}


- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error != nil) {
        NSLog(@"ERROR: %@ %ld", error.debugDescription , error.code);
        if (error.code == -1202) {
            /**
             * If the error code is -1202, this device needs .crt for SSL(secure) connection.
             */
            // Install CRT file for SSL
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            NSString* url = [userDefaults objectForKey:KEY_STUDY_QR_CODE];
            SSLManager *sslManager = [[SSLManager alloc] init];
            [sslManager installCRTWithTextOfQRCode:url];
        }
    }
    [session finishTasksAndInvalidate];
    [session invalidateAndCancel];
}




/**
 * This method sets downloaded study configurations.
 *
 * @param resData A response (study configurations) from the aware server
 */
- (void) setStudySettings:(NSData *) resData {
    NSArray *mqttArray = [NSJSONSerialization JSONObjectWithData:resData options:NSJSONReadingMutableContainers error:nil];
    id obj = [NSJSONSerialization JSONObjectWithData:resData options:NSJSONReadingMutableContainers error:nil];
    NSData *data = [NSJSONSerialization dataWithJSONObject:obj options:0 error:nil];
    NSLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    
    //    if(responseCode == 200){
    NSLog(@"GET Study Information");
    NSArray * array = [[mqttArray objectAtIndex:0] objectForKey:@"sensors"];
    NSArray * plugins = [[mqttArray objectAtIndex:0] objectForKey:KEY_PLUGINS];
    for (int i=0; i<[array count]; i++) {
        NSDictionary *settingElement = [array objectAtIndex:i];
        NSString *setting = [settingElement objectForKey:@"setting"];
        NSString *value = [settingElement objectForKey:@"value"];
        if([setting isEqualToString:@"mqtt_password"]){
            mqttPassword = value;
        }else if([setting isEqualToString:@"mqtt_username"]){
            mqttUsername = value;
        }else if([setting isEqualToString:@"mqtt_server"]){
            mqttServer = value;
        }else if([setting isEqualToString:@"mqtt_server"]){
            mqttServer = value;
        }else if([setting isEqualToString:@"mqtt_port"]){
            mqttPort = [value intValue];
        }else if([setting isEqualToString:@"mqtt_keep_alive"]){
            mqttKeepAlive = [value intValue];
        }else if([setting isEqualToString:@"mqtt_qos"]){
            mqttQos = [value intValue];
        }else if([setting isEqualToString:@"study_id"]){
            studyId = value;
        }else if([setting isEqualToString:@"webservice_server"]){
            webserviceServer = value;
        }
    }
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString * oldStudyId = [userDefaults objectForKey:KEY_STUDY_ID];
    if(![oldStudyId isEqualToString:studyId]){
        NSLog(@"Add new device ID to the AWARE server.");
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSString* url =  [userDefaults objectForKey:KEY_STUDY_QR_CODE];
        NSString * uuid = [AWAREUtils getSystemUUID];
        [self addNewDeviceToAwareServer:url withDeviceId:uuid];
    }else{
        NSLog(@"This device ID is already regited to the AWARE server.");
    }
    [userDefaults setObject:mqttServer forKey:KEY_MQTT_SERVER];
    [userDefaults setObject:mqttPassword forKey:KEY_MQTT_PASS];
    [userDefaults setObject:mqttUsername forKey:KEY_MQTT_USERNAME];
    [userDefaults setObject:[NSNumber numberWithInt:mqttPort] forKey:KEY_MQTT_PORT];
    [userDefaults setObject:[NSNumber numberWithInt:mqttKeepAlive] forKey:KEY_MQTT_KEEP_ALIVE];
    [userDefaults setObject:[NSNumber numberWithInt:mqttQos] forKey:KEY_MQTT_QOS];
    [userDefaults setObject:studyId forKey:KEY_STUDY_ID];
    [userDefaults setObject:webserviceServer forKey:KEY_WEBSERVICE_SERVER];
    [userDefaults synchronize];
    
    [userDefaults setObject:array forKey:KEY_SENSORS];
    [userDefaults setObject:plugins forKey:KEY_PLUGINS];
    
    readingState = YES;
}



/**
 * This method sets downloaded study configurations.
 *
 * @param resData A response (study configurations) from the aware server
 */
- (bool) addNewDeviceToAwareServer:(NSString *)url withDeviceId:(NSString *) uuid {
    NSLog(@"Create an aware_device table on the aware server");
    [self createTable:url withDeviceId:uuid];
    
    // preparing for insert device information
    url = [NSString stringWithFormat:@"%@/aware_device/insert", url];
    NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
    struct utsname systemInfo;
    uname(&systemInfo);
    
    NSString* machine =  [NSString stringWithCString:systemInfo.machine  encoding:NSUTF8StringEncoding]; // ok
    NSString* nodeName = [NSString stringWithCString:systemInfo.nodename encoding:NSUTF8StringEncoding]; // ok
    NSString* release =  [NSString stringWithCString:systemInfo.release  encoding:NSUTF8StringEncoding]; // ok
    NSString* systemName = [NSString stringWithCString:systemInfo.sysname encoding:NSUTF8StringEncoding];// ok
    NSString* version = [NSString stringWithCString:systemInfo.version encoding:NSUTF8StringEncoding];
    NSString *name = [[UIDevice currentDevice] name];//ok
    NSString *systemVersion = [[UIDevice currentDevice] systemVersion];//ok
    NSString *localizeModel = [[UIDevice currentDevice] localizedModel];//
    NSString *model = [[UIDevice currentDevice] model]; //ok
    NSString *manufacturer = @"Apple";//ok
    
    
    //    [[UIDevice currentDevice] platformType]   // ex: UIDevice4GiPhone
    //    [[UIDevice currentDevice] platformString] // ex: @"iPhone 4G"
//    @property(nonatomic,readonly,strong) NSString    *name;              // e.g. "My iPhone"
//    @property(nonatomic,readonly,strong) NSString    *model;             // e.g. @"iPhone", @"iPod touch"
//    @property(nonatomic,readonly,strong) NSString    *localizedModel;    // localized version of model
//    @property(nonatomic,readonly,strong) NSString    *systemName;        // e.g. @"iOS"
//    @property(nonatomic,readonly,strong) NSString    *systemVersion;     // e.g. @"4.0"
    
    NSMutableDictionary *jsonQuery = [[NSMutableDictionary alloc] init];
    [jsonQuery setValue:uuid            forKey:@"device_id"];
    [jsonQuery setValue:unixtime        forKey:@"timestamp"];
    [jsonQuery setValue:manufacturer    forKey:@"board"];
    [jsonQuery setValue:model           forKey:@"brand"];
    [jsonQuery setValue:[AWAREUtils deviceName] forKey:@"device"];
    [jsonQuery setValue:version         forKey:@"build_id"];
    [jsonQuery setValue:machine         forKey:@"hardware"];
    [jsonQuery setValue:manufacturer    forKey:@"manufacturer"];
    [jsonQuery setValue:model           forKey:@"model"];
    [jsonQuery setValue:[AWAREUtils deviceName]    forKey:@"product"];
    [jsonQuery setValue:version         forKey:@"serial"];
    [jsonQuery setValue:release         forKey:@"release"];
    [jsonQuery setValue:localizeModel        forKey:@"release_type"];
    [jsonQuery setValue:systemVersion   forKey:@"sdk"];
    [jsonQuery setValue:name            forKey:@"label"];
    
    NSMutableArray *a = [[NSMutableArray alloc] init];
    [a addObject:jsonQuery];
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:a
                                                       options:NSJSONWritingPrettyPrinted // Pass 0 if you don't care about the readability of the generated string
                                                         error:&error];
    NSString *jsonString = @"";
    if (! jsonData) {
        NSLog(@"Got an error: %@", error);
    } else {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        NSLog(@"%@",jsonString);
    }
    NSString *post = [NSString stringWithFormat:@"data=%@&device_id=%@", jsonString,uuid];
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%ld", [postData length]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    //[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    
    //    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSError *error = nil;
        NSHTTPURLResponse *response = nil;
        NSData *resData = [NSURLConnection sendSynchronousRequest:request
                                                returningResponse:&response error:&error];
        int responseCode = (int)[response statusCode];
        dispatch_async(dispatch_get_main_queue(), ^{
            if(responseCode == 200){
                NSLog(@"UPLOADED SENSOR DATA TO A SERVER");
            }else{
                NSLog(@"ERROR");
            }
        });
    });
    return true;
}



/**
 * Create an aware_device table with an url and an uuid
 * @param url An url for create aware_device table on aware database
 * @param uuid An uuid for create aware_device table on aware database
 * @return A result of creating a table of the aware_deivce table
 */
- (bool) createTable:(NSString *)url withDeviceId:(NSString *) uuid{
        // preparing for insert device information
        url = [NSString stringWithFormat:@"%@/aware_device/create_table", url];
    NSString *query = [[NSString alloc] init];
    query = @"_id integer primary key autoincrement,"
    "timestamp real default 0,"
    "device_id text default '',"
    
    "board text default '',"
    "brand text default '',"
    "device text default '',"
    "build_id text default '',"
    "hardware text default '',"
    "manufacturer text default '',"
    "model text default '',"
    "product text default '',"
    "serial text default '',"
    "release text default '',"
    "release_type text default '',"
    "sdk text default '',"
    "label text default '',"
    "UNIQUE (timestamp,device_id)";
  
    NSString *post = [NSString stringWithFormat:@"device_id=%@&fields=%@", uuid, query];
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%ld", [postData length]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    //[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    
    //    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
    NSError *error = nil;
    NSHTTPURLResponse *response = nil;
    NSData *resData = [NSURLConnection sendSynchronousRequest:request
                                            returningResponse:&response error:&error];
    NSString * resultDate = [[NSString alloc] initWithData:resData encoding:NSUTF8StringEncoding];
    NSLog(@"==> %@", resultDate);
    int responseCode = (int)[response statusCode];
    if(responseCode == 200){
        NSLog(@"UPLOADED SENSOR DATA TO A SERVER");
        return YES;
    }else{
        NSLog(@"ERROR");
        return NO;
    }
    return NO;
}



- (BOOL) isFirstAccess:(NSString*) url withDeviceId:(NSString *) uuid {
    // check latest record
    // https://api.awareframework.com/index.php/webservice/index/STUDYID/APIKEY/accelerometer/latest
    NSString * latestDataURL = [NSString stringWithFormat:@"%@/aware_device/latest", url];
    NSLog(@"%@", latestDataURL);
    
    NSString *post = [NSString stringWithFormat:@"device_id=%@", uuid];
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%ld", [postData length]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:latestDataURL]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    //[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    
    NSError *error = nil;
    NSHTTPURLResponse *response = nil;
    NSData *resData = [NSURLConnection sendSynchronousRequest:request
                                            returningResponse:&response error:&error];
    int responseCode = (int)[response statusCode];
    if(responseCode == 200){
        NSString* resultString = [[NSString alloc] initWithData:resData encoding:NSUTF8StringEncoding];
        //        NSLog(@"UPLOADED SENSOR DATA TO A SERVER");
        NSLog(@"Result: %@", resultString);
        if ([resultString isEqualToString:@"[]"]) {
            return YES;
        }
        return NO;
    }else{
        NSLog(@"ERROR");
        return NO;
    }
}


- (BOOL) isAvailable {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSArray * sensors = [userDefaults objectForKey:KEY_SENSORS];
    if(sensors){
        return YES;
    }else{
        return NO;
    }
}


- (BOOL)refreshStudy {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *url = [userDefaults objectForKey:KEY_STUDY_QR_CODE];
    if (url != nil) {
        [self setStudyInformationWithURL:url];
        return YES;
    }
    return NO;
}


- (NSString *)getDeviceId {
    if ([mqttUsername isEqualToString:@""] || mqttUsername == nil) {
        return [AWAREUtils getSystemUUID];
    }
    return mqttUsername;
}

// MQTT Information
- (NSString* ) getMqttServer{
    return mqttServer;
}

- (NSString* ) getMqttUserName{
    return mqttUsername;
}

- (NSString* ) getMqttPassowrd{
    return mqttPassword;
}

- (NSNumber* ) getMqttPort{
    return [NSNumber numberWithInt:mqttPort];
}

- (NSNumber* ) getMqttKeepAlive{
    return [NSNumber numberWithInt:mqttKeepAlive];
}

- (NSNumber* ) getMqttQos{
    return [NSNumber numberWithInt:mqttKeepAlive];
}

// Study Information
- (NSString* ) getStudyId{
    return studyId;}


- (NSString* ) getWebserviceServer{
    return webserviceServer;
}


- (NSArray *) getSensors {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults objectForKey:KEY_SENSORS];
}

- (NSArray *) getPlugins{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults objectForKey:KEY_PLUGINS];
}

- (BOOL) clearAllSetting {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults removeObjectForKey:KEY_MQTT_SERVER];
    [userDefaults removeObjectForKey:KEY_MQTT_USERNAME];
    [userDefaults removeObjectForKey:KEY_MQTT_PASS];
    [userDefaults removeObjectForKey:KEY_MQTT_PORT];
    [userDefaults removeObjectForKey:KEY_MQTT_KEEP_ALIVE];
    [userDefaults removeObjectForKey:KEY_MQTT_QOS];
    [userDefaults removeObjectForKey:KEY_STUDY_ID];
    [userDefaults removeObjectForKey:KEY_WEBSERVICE_SERVER];
    [userDefaults removeObjectForKey:KEY_SENSORS];
    [userDefaults removeObjectForKey:KEY_PLUGINS];
    return YES;
}


@end
