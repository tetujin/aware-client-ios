//
//  Fitbit.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 2017/01/15.
//  Copyright © 2017 Yuuki NISHIYAMA. All rights reserved.
//

#import "Fitbit.h"
#import "FitbitData.h"
#import "FitbitDevice.h"
#import "AWAREUtils.h"

@implementation Fitbit{
    FitbitData * fitbitData;
    FitbitDevice * fitbitDevice;
    NSString * baseOAuth2URL;
    NSString * redirectURI;
    NSNumber * expiresIn;
    NSTimer * updateTimer;
    
    NSMutableData * profileData;
    NSMutableData * refreshTokenData;
    NSMutableData * tokens;
    
    NSString * identificationForFitbitProfile;
    NSString * identificationForFitbitRefreshToken;
    NSString * identificationForFitbitTokens;
    
    NSDateFormatter * hourFormat;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study
                            dbType:(AwareDBType)dbType{
    
    self = [super initWithAwareStudy:study
                          sensorName:SENSOR_PLUGIN_FITBIT
                        dbEntityName:nil
                              dbType:AwareDBTypeTextFile];
    if(self != nil){
        fitbitData = [[FitbitData alloc] initWithAwareStudy:study dbType:dbType];
        fitbitDevice = [[FitbitDevice alloc] initWithAwareStudy:study dbType:dbType];
        baseOAuth2URL = @"https://www.fitbit.com/oauth2/authorize";
        redirectURI = @"fitbit://logincallback";
        expiresIn = @( 1000L*60L*60L*24L); // 1day  //*365L ); // 1 Year
        
        profileData = [[NSMutableData alloc] init];
        refreshTokenData = [[NSMutableData alloc] init];
        tokens = [[NSMutableData alloc] init];
        
        identificationForFitbitProfile = @"action.aware.plugin.fitbit.api.get.profile";
        identificationForFitbitRefreshToken = @"action.aware.plugin.fitbit.api.get.refresh_token";
        identificationForFitbitTokens = @"action.aware.plugin.fitbit.api.get.tokens";
        
        hourFormat = [[NSDateFormatter alloc] init];
        [hourFormat setDateFormat:@"yyyy-MM-dd HH"];
        
        [self setTypeAsPlugin];
        
//        NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
//        NSString * clientId = [defaults objectForKey:@"api_key_plugin_fitbit"];
//        NSString * apiSecret = [defaults objectForKey:@"api_secret_plugin_fitbit"];
//        if(clientId == nil) clientId = @"";
//        if(apiSecret == nil) apiSecret = @"";
        
        [self addDefaultSettingWithBool:@NO key:@"status_plugin_fitbit" desc:@"(boolean) activate/deactivate plugin"];
        [self addDefaultSettingWithString:@"metric" key:@"units_plugin_fitbit" desc:@"(String) one of metric/imperial"];
        [self addDefaultSettingWithNumber:@15 key:@"plugin_fitbit_frequency" desc:@"(integer) interval in which to check for new data on Fitbit. Fitbit has a hard-limit of 150 data checks, per hour, per device."];
        [self addDefaultSettingWithString:@"1min" key:@"fitbit_granularity" desc:@"(String) intraday granularity. One of 1d/15min/1min for daily summary, 15 minutes and 1 minute, respectively."];
        [self addDefaultSettingWithString:@"1min" key:@"fitbit_hr_granularity" desc:@"(String) intraday granularity. One of 1min/1sec for 1 minute, and 5 second interval respectively (setting is 1sec but returns every 5sec)."];
        [self addDefaultSettingWithString:@"" key:@"api_key_plugin_fitbit" desc:@"(String) Fitbit Client Key"];
        [self addDefaultSettingWithString:@"" key:@"api_secret_plugin_fitbit" desc:@"(String) Fitbit Client Secret"];
    }
    
    return self;
}

- (void)createTable{
    [fitbitData createTable];
    [fitbitDevice createTable];
    [super createTable];
}

- (void)syncAwareDBInBackground{
    [fitbitData syncAwareDBInBackground];
    [fitbitDevice syncAwareDBInBackground];
    [super syncAwareDBInBackground];
}

- (void) syncAwareDB{
    [fitbitData syncAwareDB];
    [fitbitDevice syncAwareDB];
    [super syncAwareDB];
}

- (BOOL)syncAwareDBInForeground{
    [fitbitData syncAwareDBInForeground];
    [fitbitDevice syncAwareDBInForeground];
    return [super syncAwareDBInForeground];
}



- (BOOL)startSensorWithSettings:(NSArray *)settings{

    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:settings forKey:@"aware.plugn.fitbit.settings"];
    
    NSString * clientId = [self getSettingAsStringFromSttings:settings withKey:@"api_key_plugin_fitbit"];
    NSString * apiSecret = [self getSettingAsStringFromSttings:settings withKey:@"api_secret_plugin_fitbit"];
    
    if([clientId isEqualToString:@""] && [apiSecret isEqualToString:@""]){
        // clientId = [defaults objectForKey:@"api_key_plugin_fitbit"];
        // apiSecret = [defaults objectForKey:@"api_secret_plugin_fitbit"];
        clientId = [Fitbit getFitbitClientId];
        apiSecret = [Fitbit getFitbitApiSecret];
    }
    
    double intervalMin = [self getSensorSetting:settings withKey:@"plugin_fitbit_frequency"];
    if(intervalMin<0){
        intervalMin = 15;
    }
    
    [Fitbit setFitbitClientId:clientId];
    [Fitbit setFitbitApiSecret:apiSecret];
    
    if(![Fitbit getFitbitAccessToken] &&
       ![clientId isEqualToString:@""] &&
       ![apiSecret isEqualToString:@""]) {
        if( clientId != nil && apiSecret != nil){
            [self loginWithOAuth2WithClientId:clientId apiSecret:apiSecret];
        }
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(getData:)
                                                 name:@"action.aware.plugin.fitbit.get.activity.sleep"
                                               object:[[NSDictionary alloc] initWithObjects:@[@"sleep"] forKeys:@[@"type"]]];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(getData:)
                                                 name:@"action.aware.plugin.fitbit.get.activity.steps"
                                               object:[[NSDictionary alloc] initWithObjects:@[@"steps"] forKeys:@[@"type"]]];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(getData:)
                                                 name:@"action.aware.plugin.fitbit.get.activity.calories"
                                               object:[[NSDictionary alloc] initWithObjects:@[@"calories"] forKeys:@[@"type"]]];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(getData:)
                                                 name:@"action.aware.plugin.fitbit.get.activity.heartrate"
                                               object:[[NSDictionary alloc] initWithObjects:@[@"heartrate"] forKeys:@[@"type"]]];

    
    updateTimer = [NSTimer scheduledTimerWithTimeInterval:intervalMin*60
                                             target:self
                                                 selector:@selector(getData:)
                                           userInfo:[[NSDictionary alloc] initWithObjects:@[@"all"] forKeys:@[@"type"]]
                                            repeats:YES];
    [updateTimer fire];
    
    return YES;
}

- (BOOL)stopSensor{
    if(updateTimer != nil){
        [updateTimer invalidate];
        updateTimer = nil;
    }
    
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"action.aware.plugin.fitbit.get.activity.sleep" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"action.aware.plugin.fitbit.get.activity.steps" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"action.aware.plugin.fitbit.get.activity.calories" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"action.aware.plugin.fitbit.get.activity.heartrate" object:nil];

    return YES;
}

- (BOOL)quitSensor{
    NSUserDefaults * userDefualt = [NSUserDefaults standardUserDefaults];
    [userDefualt removeObjectForKey:@"fitbit.setting.access_token"];
    [userDefualt removeObjectForKey:@"fitbit.setting.user_id"];
    [userDefualt removeObjectForKey:@"fitbit.setting.token_type"];
    [userDefualt removeObjectForKey:@"api_key_plugin_fitbit"];
    [userDefualt removeObjectForKey:@"api_secret_plugin_fitbit"];
    [userDefualt synchronize];
    return YES;
}


- (void) getData:(id)sender{
    
     NSDictionary * userInfo = [sender userInfo] ;
     NSString * type = [userInfo objectForKey:@"type"];
    
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSArray * settings = [defaults objectForKey:@"aware.plugn.fitbit.settings"];
    
    if(settings != nil){
        [self getProfile];
        
        [fitbitDevice getDeviceInfo];
        
        // Get setting from settings variable
        NSString * activityDetailLevel = [self getSettingAsStringFromSttings:settings withKey:@"fitbit_granularity"]; //1d/15min/1min
        if([activityDetailLevel isEqualToString:@""] || activityDetailLevel == nil ){
            activityDetailLevel = @"1d";
        }
        
        NSString * hrDetailLevel = [self getSettingAsStringFromSttings:settings withKey:@"fitbit_hr_granularity"];//1min/1sec
        if( [hrDetailLevel isEqualToString:@""] || hrDetailLevel == nil){
            hrDetailLevel = @"1min";
        }
        
        
        double intervalMin = [self getSensorSetting:settings withKey:@"plugin_fitbit_frequency"];
        if(intervalMin<0){
            intervalMin = 15;
        }
        double intervalSec = intervalMin * 60.0f;
        
        // 1d/15min/1min
        int granuTimeActivity = 60*60*24;
        if([activityDetailLevel isEqualToString:@"15min"]) {
            granuTimeActivity = 60*15;
        }else if([activityDetailLevel isEqualToString:@"1min"]){
            granuTimeActivity = 60;
        }
        
        // 1min/1sec
        int granuTimeHr = 60;
        if ([hrDetailLevel isEqualToString:@"1sec"]) {
            granuTimeHr = 1;
        }
        
        NSDate * start = nil;
        NSDate * end = [NSDate new];
        
        /// test ///
//        if([type isEqualToString:@"all"] || [type isEqualToString:@"steps"]){
//            // start = [FitbitData getLastSyncSteps];
//            start = [[NSDate alloc] initWithTimeInterval:-60*60*24 sinceDate:end];
//            NSDate * tempEnd = [[NSDate alloc] initWithTimeInterval:-1 sinceDate:end];
//            
//            [fitbitData getStepsWithStart:start
//                                      end:tempEnd
//                                   period:nil
//                              detailLevel:activityDetailLevel];
//        }
        
        ///////////////// Step/Cal /////////////////////
        if([type isEqualToString:@"all"] || [type isEqualToString:@"steps"]){
            start = [self smoothDateWithHour:[FitbitData getLastSyncSteps]];

            if(start == nil) start = [self smoothDateWithHour:[[NSDate alloc] initWithTimeInterval:(-60*60*24)+1 sinceDate:end]];
            
            if(([end timeIntervalSince1970] - [start timeIntervalSince1970]) > 60*60*24-1){
                NSDate * tempEnd = [NSDate dateWithTimeInterval:60*60*24-1 sinceDate:start];
                [fitbitData getStepsWithStart:start end:tempEnd period:nil detailLevel:activityDetailLevel];
            }else if(([end timeIntervalSince1970] - [start timeIntervalSince1970]) > intervalSec){
                [fitbitData getStepsWithStart:start end:end period:nil detailLevel:activityDetailLevel];
            }else{
                NSLog(@"[step] Overtime Request: %@ %@", start, end);
            }
        }
        
        if([type isEqualToString:@"all"] || [type isEqualToString:@"calories"]){
            start = [self smoothDateWithHour:[FitbitData getLastSyncCalories]];
            
            if(start == nil) start = [self smoothDateWithHour:[[NSDate alloc] initWithTimeInterval:(-60*60*24)+1 sinceDate:end]];
            
            if(([end timeIntervalSince1970] - [start timeIntervalSince1970]) > 60*60*24-1){
                // end = [NSDate dateWithTimeInterval:60*60*24-1 sinceDate:start];
                NSDate * tempEnd = [NSDate dateWithTimeInterval:60*60*24-1 sinceDate:start];
                [fitbitData getCaloriesWithStart:start end:tempEnd period:nil detailLevel:activityDetailLevel];
            }else if(([end timeIntervalSince1970] - [start timeIntervalSince1970]) > intervalSec){
                [fitbitData getCaloriesWithStart:start end:end period:nil detailLevel:activityDetailLevel];
            }else{
                NSLog(@"[cal] Overtime Request: %@ %@", start, end);
            }
        }
        
        
        ///////////////// Heartrate ////////////////////
        if([type isEqualToString:@"all"] || [type isEqualToString:@"heartrate"]){
            start = [self smoothDateWithHour:[FitbitData getLastSyncHeartrate]];
            if(start == nil) start = [self smoothDateWithHour:[[NSDate alloc] initWithTimeInterval:(-60*60*24)+1 sinceDate:end]];
            if(([end timeIntervalSince1970] - [start timeIntervalSince1970]) > 60*60*24-1){
                // end = [NSDate dateWithTimeInterval:60*60*24-1 sinceDate:start];
                NSDate * tempEnd = [NSDate dateWithTimeInterval:60*60*24-1 sinceDate:start];
                [fitbitData getHeartrateWithStart:start end:tempEnd period:nil detailLevel:hrDetailLevel];
            }else if(([end timeIntervalSince1970] - [start timeIntervalSince1970]) > intervalSec){
                [fitbitData getHeartrateWithStart:start end:end period:nil detailLevel:hrDetailLevel];
            }else{
                NSLog(@"[heartrate] Overtime Request: %@ %@", start, end);
            }
        }
        
        
        ///////////////// Sleep  /////////////////////
        if([type isEqualToString:@"all"] || [type isEqualToString:@"sleep"]){
            start = [FitbitData getLastSyncSleep];
            if(start == nil) start = [self smoothDateWithHour:[[NSDate alloc] initWithTimeInterval:(-60*60*24)+1 sinceDate:end]];
            
            if(([end timeIntervalSince1970] - [start timeIntervalSince1970]) > 60*60*24-1){
                //NSDate * tempEnd = [NSDate dateWithTimeInterval:60*60*24-1 sinceDate:start];
                [fitbitData getSleepWithStart:start end:end period:nil detailLevel:hrDetailLevel];
            }else{
                NSLog(@"[sleep] Overtime Request: %@ %@", start, end);
            }
        }
    }
}


////////////////////////////////////////////////////////////////////////////////////////

- (void) loginWithOAuth2WithClientId:(NSString *)clientId apiSecret:(NSString *)apiSecret {
    
    NSMutableString * url = [[NSMutableString alloc] initWithString:baseOAuth2URL];

    //[url appendFormat:@"?response_type=token&client_id=%@",clientId];
    [url appendFormat:@"?response_type=code&client_id=%@",clientId];
    // [url appendFormat:@"&redirect_uri=%@", [AWAREUtils stringByAddingPercentEncoding:@"aware-client://com.aware.ios.oauth2" unreserved:@"-."]];
    [url appendFormat:@"&redirect_uri=%@", [AWAREUtils stringByAddingPercentEncoding:redirectURI unreserved:@"-."]];
    [url appendFormat:@"&scope=%@", [AWAREUtils stringByAddingPercentEncoding:@"activity heartrate location nutrition profile settings sleep social weight"]];
    [url appendFormat:@"&expires_in=%@", expiresIn.stringValue];
    
    // NSLog(@"%@", url);
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}

///////////////////////////////////////////////////////////////////

- (NSDate *) smoothDateWithHour:(NSDate *) date{
    NSString * smoothedData = [hourFormat stringFromDate:date];
    return [hourFormat dateFromString:smoothedData];
}

///////////////////////////////////////////////////////////////////

- (void) getProfile{
    
    NSString * userId = [Fitbit getFitbitUserId];
    NSString* token = [Fitbit getFitbitAccessToken];
    
    NSURL*	url = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.fitbit.com/1/user/%@/profile.json",userId]];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
    [request setHTTPMethod:@"GET"];
    
    if(token == nil) return;
    if(userId == nil) return;
    
    profileData = [[NSMutableData alloc] init];
    
    __weak NSURLSession *session = nil;
    NSURLSessionConfiguration *sessionConfig = nil;

//    if ([AWAREUtils isBackground]) {
        sessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:identificationForFitbitProfile];
        sessionConfig.timeoutIntervalForRequest = 180.0;
        sessionConfig.timeoutIntervalForResource = 60.0;
        sessionConfig.HTTPMaximumConnectionsPerHost = 60;
        sessionConfig.allowsCellularAccess = YES;
        sessionConfig.allowsCellularAccess = YES;
        sessionConfig.discretionary = YES;
        session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:Nil];
        NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request];
        [dataTask resume];
//    }else{
//        sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
//        sessionConfig.timeoutIntervalForRequest = 180.0;
//        sessionConfig.timeoutIntervalForResource = 60.0;
//        sessionConfig.HTTPMaximumConnectionsPerHost = 60;
//        sessionConfig.allowsCellularAccess = YES;
//        sessionConfig.allowsCellularAccess = YES;
//        sessionConfig.discretionary = YES;
//        session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:Nil];
//        [[session dataTaskWithRequest:request  completionHandler: ^(NSData *data, NSURLResponse *response, NSError *error) {
//            [session finishTasksAndInvalidate];
//            [session invalidateAndCancel];
//            [self saveProfileWithData:data NSURLResponse:response NSError:error];
//        }] resume];
//    }
}


- (void) saveProfileWithData:(NSData *) data NSURLResponse:(NSURLResponse *)response NSError:(NSError *)error{
    NSString *responseString = [[NSString alloc] initWithData: data  encoding: NSUTF8StringEncoding];
    NSLog(@"Success: %@", responseString);
    
    @try {
        if(responseString != nil){
            // NSData *jsonData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
            
            NSError *error = nil;
            NSDictionary *values = [NSJSONSerialization JSONObjectWithData:data
                                                                   options:NSJSONReadingAllowFragments error:&error];
            if (error != nil) {
                NSLog(@"failed to parse JSON: %@", error.debugDescription);
                return;
            }
            
                //{
                //"errors":[{
                //    "errorType":"expired_token",
                //    "message":"Access token expired: eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI1Q1JSQ1QiLCJhdWQiOiIyMjg3VDciLCJpc3MiOiJGaXRiaXQiLCJ0eXAiOiJhY2Nlc3NfdG9rZW4iLCJzY29wZXMiOiJyc29jIHJzZXQgcmFjdCBybG9jIHJ3ZWkgcmhyIHJudXQgcnBybyByc2xlIiwiZXhwIjoxNDg1Mjk4NDU2LCJpYXQiOjE0ODUyNjk2NTZ9.NTEcqo3wOFLAZ6jL-BcGhYrVENb8g3nps-LVpEv4UNQ. Visit https://dev.fitbit.com/docs/oauth2 for more information on the Fitbit Web API authorization process."}
                //    ],
                //"success":false
                // }
            
            //if(![values objectForKey:@"user"]){
            
            NSArray * errors = [values objectForKey:@"errors"];
            if(errors != nil){
                for (NSDictionary * errorDict in errors) {
                    NSString * errorType = [errorDict objectForKey:@"errorType"];
                    if([errorType isEqualToString:@"invalid_token"]){
                        // [Fitbit setFitbitClientId:clientId];
                        // [Fitbit setFitbitApiSecret:apiSecret];
                        [self loginWithOAuth2WithClientId:[Fitbit getFitbitClientId] apiSecret:[Fitbit getFitbitApiSecret]];
                    }else if([errorType isEqualToString:@"expired_token"]){
                        [self refreshToken];
                        [self saveDebugEventWithText:@"responseString" type:DebugTypeWarn label:[NSString stringWithFormat:@"fitbit plugin: refresh token %@", [NSDate new]]];
                    }
                }
            }
                // invalid_token
                // expired_token
                // invalid_client
                // invalid_request
            
            //}else{
                // NSLog(@"%@", responseString);
                // [AWAREUtils sendLocalNotificationForMessage:responseString soundFlag:YES];
            //}
        }
    } @catch (NSException *exception) {
        
    } @finally {
        
    }

}


/////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) downloadTokensFromFitbitServer {
    NSUserDefaults * userDefaults =[NSUserDefaults standardUserDefaults];
    NSString * code = [userDefaults objectForKey:@"fitbit.setting.code"];
    
    if(code!= nil){
        // Set URL
        NSURL*	url = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.fitbit.com/oauth2/token"]];
        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
        // Create NSData object
        NSString * baseAuth = [NSString stringWithFormat:@"%@:%@",[Fitbit getFitbitClientId],[Fitbit getFitbitApiSecret]];
        NSData *nsdata = [baseAuth dataUsingEncoding:NSUTF8StringEncoding];
        // Get NSString from NSData object in Base64
        NSString *base64Encoded = [nsdata base64EncodedStringWithOptions:0];
        // NSLog(@"%@",base64Encoded);
        [request setValue:[NSString stringWithFormat:@"Basic %@", base64Encoded] forHTTPHeaderField:@"Authorization"];
        [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        NSMutableString * bodyStr = [[NSMutableString alloc] init];
        [bodyStr appendFormat:@"clientId=%@&",[Fitbit getFitbitClientId]];
        [bodyStr appendFormat:@"grant_type=authorization_code&"];
        [bodyStr appendFormat:@"redirect_uri=%@&",[AWAREUtils stringByAddingPercentEncoding:@"fitbit://logincallback" unreserved:@"-."]];
        [bodyStr appendFormat:@"code=%@",code];
        
        
        
        [request setHTTPBody: [bodyStr dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES] ];
        [request setHTTPMethod:@"POST"];
        
        __weak NSURLSession *session = nil;
        NSURLSessionConfiguration *sessionConfig = nil;
        
        tokens = [[NSMutableData alloc] init];
        
        // if ([AWAREUtils isBackground]) {
            sessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:identificationForFitbitTokens];
            sessionConfig.timeoutIntervalForRequest = 180.0;
            sessionConfig.timeoutIntervalForResource = 60.0;
            sessionConfig.HTTPMaximumConnectionsPerHost = 60;
            sessionConfig.allowsCellularAccess = YES;
            sessionConfig.allowsCellularAccess = YES;
            sessionConfig.discretionary = YES;
            session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:Nil];
            NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request];
            [dataTask resume];
//        }else{
//            sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
//            sessionConfig.timeoutIntervalForRequest = 180.0;
//            sessionConfig.timeoutIntervalForResource = 60.0;
//            sessionConfig.HTTPMaximumConnectionsPerHost = 60;
//            sessionConfig.allowsCellularAccess = YES;
//            sessionConfig.allowsCellularAccess = YES;
//            sessionConfig.discretionary = YES;
//            session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:Nil];
//            [[session dataTaskWithRequest:request  completionHandler: ^(NSData *data, NSURLResponse *response, NSError *error) {
//                if(error != nil){
//                    NSLog(@"Fitbit Login Error: %@", error.debugDescription);
//                }else{
//                    NSLog(@"Fitbit Login Sucess:");
//                    [self saveTokens:data response:response error:error];
//                }
//                [session finishTasksAndInvalidate];
//                [session invalidateAndCancel];
//            }] resume];
//        }
        
    }else{
        UIAlertView *av = [[UIAlertView alloc]initWithTitle:@"Fitbit Login Error"
                                                    message:@"The Fitbit code is Null."
                                                   delegate:self
                                          cancelButtonTitle:@"Close"
                                          otherButtonTitles:nil];
        [av show];
        NSLog(@"Fitbit Login Error: The Fitbit code is Null");
    }
}

- (BOOL) handleURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation{
    
    // aware-client://com.aware.ios.oauth2?code=35c0ec0d9b3873b270f0c1787ac33472e58176ec,_=_
    ////////////  Authorization Code Flow ////////////
    // NSString * userId = [Fitbit getFitbitUserId];
    // NSString * token = [Fitbit getFitbitAccessToken];
    
    NSArray *components = [url.absoluteString componentsSeparatedByString:@"?"];
    if(components!=nil && components.count > 1){
        NSMutableString * code = [NSMutableString stringWithString:[components objectAtIndex:1]];
        [code deleteCharactersInRange:NSMakeRange(code.length-4, 4)];
        [code deleteCharactersInRange:NSMakeRange(0, 5)];
        // Save the code
        if(code != nil){
            NSUserDefaults * userDefaults =[NSUserDefaults standardUserDefaults];
            [userDefaults setObject:code forKey:@"fitbit.setting.code"];
            [userDefaults synchronize];
            [self downloadTokensFromFitbitServer];
        }
    }else{
        UIAlertView *av = [[UIAlertView alloc]initWithTitle:@"Fitbit Login Error"
                                                    message:url.absoluteString
                                                   delegate:self
                                          cancelButtonTitle:@"Close"
                                          otherButtonTitles:nil];
        [av show];
        NSLog(@"Fitbit Login Error: %@", url.absoluteString);
    }
    
    
    //////////////////////////////////////////////////
    
    ///////////// Implicit Grant Flow  //////////////
//    NSArray *components = [url.absoluteString componentsSeparatedByString:@"#"];
//    if(components.count > 1){
//        NSString *value = components[1];
//        NSArray * parameters = [value componentsSeparatedByString:@"&"];
//        if(parameters != nil){
//            for (NSString * paramStr in parameters) {
//                NSArray * paramKeyValue = [paramStr componentsSeparatedByString:@"="];
//                if(paramKeyValue){
//                    if([paramKeyValue[0] isEqualToString:@"access_token"]){
//                        [Fitbit setFitbitAccessToken:paramKeyValue[1]];
//                    }else if([paramKeyValue[0] isEqualToString:@"user_id"]){
//                        [Fitbit setFitbitUserId:paramKeyValue[1]];
//                    }else if([paramKeyValue[0] isEqualToString:@"token_type"]){
//                        [Fitbit setFibitTokenType:paramKeyValue[1]];
//                    }
//                }
//            }
//        }
//    }
    return YES;
}

///////////////////////////////////////////////////////////////////////////////////////////////////

- (void) refreshToken {

    if([Fitbit getFitbitClientId] == nil) return;
    if([Fitbit getFitbitApiSecret] == nil) return;
    
    // Set URL
    NSURL*	url = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.fitbit.com/oauth2/token"]];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    // Create NSData object
    NSString * baseAuth = [NSString stringWithFormat:@"%@:%@",[Fitbit getFitbitClientId],[Fitbit getFitbitApiSecret]];
    NSData *nsdata = [baseAuth dataUsingEncoding:NSUTF8StringEncoding];
    NSString *base64Encoded = [nsdata base64EncodedStringWithOptions:0];
    
    [request setValue:[NSString stringWithFormat:@"Basic %@", base64Encoded] forHTTPHeaderField:@"Authorization"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    NSMutableString * bodyStr = [[NSMutableString alloc] init];
    // [bodyStr appendFormat:@"clientId=%@&",[Fitbit getFitbitClientId]];
    [bodyStr appendFormat:@"grant_type=refresh_token&"];
    [bodyStr appendFormat:@"refresh_token=%@",[Fitbit getFitbitRefreshToken]];
    
    [request setHTTPBody: [bodyStr dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES] ];
    [request setHTTPMethod:@"POST"];
    
    __weak NSURLSession *session = nil;
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfiguration.allowsCellularAccess = YES;
    session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:Nil];
    
    refreshTokenData = [[NSMutableData alloc] init];
    
    NSURLSessionConfiguration *sessionConfig = nil;
    
//     if ([AWAREUtils isBackground]) {
        sessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:identificationForFitbitRefreshToken];
        sessionConfig.timeoutIntervalForRequest = 180.0;
        sessionConfig.timeoutIntervalForResource = 60.0;
        sessionConfig.HTTPMaximumConnectionsPerHost = 60;
        sessionConfig.allowsCellularAccess = YES;
        sessionConfig.allowsCellularAccess = YES;
        sessionConfig.discretionary = YES;
        session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:Nil];
        NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request];
        [dataTask resume];
//    }else{
//        sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
//        sessionConfig.timeoutIntervalForRequest = 180.0;
//        sessionConfig.timeoutIntervalForResource = 60.0;
//        sessionConfig.HTTPMaximumConnectionsPerHost = 60;
//        sessionConfig.allowsCellularAccess = YES;
//        sessionConfig.allowsCellularAccess = YES;
//        sessionConfig.discretionary = YES;
//        session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:Nil];
//        [[session dataTaskWithRequest:request  completionHandler: ^(NSData *data, NSURLResponse *response, NSError *error) {
//            [session finishTasksAndInvalidate];
//            [session invalidateAndCancel];
//            [self saveRefreshToken:data response:response error:error];
//        }] resume];
//    }
}


- (void) saveRefreshToken:(NSData *) data response:(NSURLResponse *) response error:(NSError *)error{
    NSString *responseString = [[NSString alloc] initWithData: data  encoding: NSUTF8StringEncoding];
    NSLog(@"Success: %@", responseString);
    
    @try {
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if(responseString != nil){
                NSData *jsonData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
                
                NSError *error = nil;
                NSDictionary *values = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                       options:NSJSONReadingAllowFragments error:&error];
                if (error != nil) {
                    NSLog(@"failed to parse JSON: %@", error.debugDescription);
                    return;
                }
                
                if(values == nil){
                    return;
                }
                
                if([self isDebug]){
                    if([values objectForKey:@"access_token"] == nil){
                        if([AWAREUtils isForeground]){
                            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error Message from Fitbit Plugin"
                                                                        message:responseString
                                                                       delegate:self
                                                              cancelButtonTitle:@"Close"
                                                              otherButtonTitles:nil];
                            [alert show];
                        }else{
                            [AWAREUtils sendLocalNotificationForMessage:responseString soundFlag:NO];
                        }
                        return;
                    }else{
                        if([AWAREUtils isForeground]){
                            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success"
                                                                            message:@"Fitbit Plugin updates its access token using the refresh token."
                                                                           delegate:self
                                                                  cancelButtonTitle:@"Close"
                                                                  otherButtonTitles:nil];
                            [alert show];
                        }else{
                            [AWAREUtils sendLocalNotificationForMessage:responseString soundFlag:NO];
                        }
                    }
                }
                
                
                if([values objectForKey:@"access_token"] != nil){
                    [Fitbit setFitbitAccessToken:[values objectForKey:@"access_token"]];
                }
                if([values objectForKey:@"user_id"] != nil){
                    [Fitbit setFitbitUserId:[values objectForKey:@"user_id"]];
                }
                if([values objectForKey:@"refresh_token"] != nil){
                    [Fitbit setFitbitRefreshToken:[values objectForKey:@"refresh_token"]];
                }
                if([values objectForKey:@"token_type"] != nil){
                    [Fitbit setFitbitTokenType:[values objectForKey:@"token_type"]];
                }
            }else{
                UIAlertView *av = [[UIAlertView alloc]initWithTitle:@"Fitbit Login Error"
                                                            message:@"No access token and user_id"
                                                           delegate:self
                                                  cancelButtonTitle:@"Close"
                                                  otherButtonTitles:nil];
                [av show];
            }
        });
        
    } @catch (NSException *exception) {
        NSLog(@"%@",exception.debugDescription);
        UIAlertView *av = [[UIAlertView alloc]initWithTitle:@"Error"
                                                    message:exception.debugDescription
                                                   delegate:self
                                          cancelButtonTitle:@"Close"
                                          otherButtonTitles:nil];
        [av show];
    } @finally {
        
    }
}

//////////////////////////////////////////////////////////////////

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    
    // NSString * identifier = session.configuration.identifier;
    // NSLog(@"[%@] session:dataTask:didReceiveResponse:completionHandler:",identifier);
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
    int responseCode = (int)[httpResponse statusCode];
    if (responseCode == 200) {
        NSLog(@"[%d] Success",responseCode);
    }
    [super URLSession:session dataTask:dataTask didReceiveResponse:response completionHandler:completionHandler];
}




-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    NSString * identifier = session.configuration.identifier;
    if([identifier isEqualToString:identificationForFitbitProfile]){
        [profileData appendData:data];
    }else if([identifier isEqualToString:identificationForFitbitRefreshToken]){
        [refreshTokenData appendData:data];
    }else if([identifier isEqualToString:identificationForFitbitTokens]){
        [tokens appendData:data];
    }
    [super URLSession:session dataTask:dataTask didReceiveData:data];
}


-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    NSString * identifier = session.configuration.identifier;
    NSData * data = nil;
    if([identifier isEqualToString:identificationForFitbitProfile]){
        data = [profileData copy];
        [self saveProfileWithData:data NSURLResponse:nil NSError:error];
        profileData = [[NSMutableData alloc] init];
    }else if([identifier isEqualToString:identificationForFitbitRefreshToken]){
        data = [refreshTokenData copy];
        [self saveRefreshToken:data response:nil error:error];
        refreshTokenData = [[NSMutableData alloc] init];
    }else if([identifier isEqualToString:identificationForFitbitTokens]) {
        data = [tokens copy];
        [self saveTokens:data response:nil error:error];
        tokens = [[NSMutableData alloc] init];
    }
    
    [super URLSession:session task:task didCompleteWithError:error];
}


- (void) saveTokens:(NSData *) data response:(NSURLResponse*)response error:(NSError *)error{
    NSLog(@"A Fitbit login query is called !!");
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSString *responseString = [[NSString alloc] initWithData: data  encoding: NSUTF8StringEncoding];
        NSLog(@"Success: %@", responseString);
        
        if(responseString != nil){
            NSData *jsonData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
            
            NSError *error = nil;
            NSDictionary *values = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                   options:NSJSONReadingAllowFragments error:&error];
            if (error != nil) {
                NSLog(@"failed to parse JSON: %@", error.debugDescription);
                UIAlertView *av = [[UIAlertView alloc]initWithTitle:@"Fitbit Login Error"
                                                            message:[NSString stringWithFormat:@"failed to parse JSON: %@",error.debugDescription]
                                                           delegate:self
                                                  cancelButtonTitle:@"Close"
                                                  otherButtonTitles:nil];
                [av show];
                return;
            }
            
            if(values == nil){
                UIAlertView *av = [[UIAlertView alloc]initWithTitle:@"Fitbit Login Error"
                                                            message:@"The value is null..."
                                                           delegate:self
                                                  cancelButtonTitle:@"Close"
                                                  otherButtonTitles:nil];
                [av show];
                return;
            }
            
            
            if(![values objectForKey:@"access_token"]){
                // NSLog(@"%@", responseString);
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error Message from Fitbit Plugin"
                                                                message:responseString
                                                               delegate:self
                                                      cancelButtonTitle:@"Close"
                                                      otherButtonTitles:nil];
                [alert show];
                NSLog(@"Fitbit Login Error: %@", responseString);
                return;
            }else{
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success"
                                                                message:@"Fitbit Plugin obtained an access token, refresh token, and user_id from Fitbit API."
                                                               delegate:self
                                                      cancelButtonTitle:@"Close"
                                                      otherButtonTitles:nil];
                [alert show];
            }
            
            
            if([values objectForKey:@"access_token"] != nil){
                [Fitbit setFitbitAccessToken:[values objectForKey:@"access_token"]];
            }
            if([values objectForKey:@"user_id"] != nil){
                [Fitbit setFitbitUserId:[values objectForKey:@"user_id"]];
            }
            if([values objectForKey:@"refresh_token"] != nil){
                [Fitbit setFitbitRefreshToken:[values objectForKey:@"refresh_token"]];
            }
            if([values objectForKey:@"token_type"] != nil){
                [Fitbit setFitbitTokenType:[values objectForKey:@"token_type"]];
            }
            
        }else{
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Fitbit Login Error"
                                                            message:@"The response from Fitbit server is Null."
                                                           delegate:self
                                                  cancelButtonTitle:@"Close"
                                                  otherButtonTitles:nil];
            [alert show];
            NSLog(@"Fitbit Login Error: %@", @"The response from Fitbit server is Null");
        }
        
    });
}

//////////////////////////////////////////////////////////////////////////////

+ (void) setFitbitAccessToken:(NSString * )accessToken{
    NSUserDefaults * userDefualt = [NSUserDefaults standardUserDefaults];
    [userDefualt setObject:accessToken forKey:@"fitbit.setting.access_token"];
    [userDefualt synchronize];
}

+ (void) setFitbitRefreshToken:(NSString *) refreshToken{
    NSUserDefaults * userDefualt = [NSUserDefaults standardUserDefaults];
    [userDefualt setObject:refreshToken forKey:@"fitbit.setting.refresh_token"];
    [userDefualt synchronize];
}

+ (void) setFitbitUserId:(NSString *)userId{
    NSUserDefaults * userDefualt = [NSUserDefaults standardUserDefaults];
    [userDefualt setObject:userId forKey:@"fitbit.setting.user_id"];
    [userDefualt synchronize];
}

+ (void) setFitbitTokenType:(NSString *) tokenType{
    NSUserDefaults * userDefualt = [NSUserDefaults standardUserDefaults];
    [userDefualt setObject:tokenType forKey:@"fitbit.setting.token_type"];
    [userDefualt synchronize];
}

//clientId
+ (void) setFitbitClientId:(NSString *) clientId{
    NSUserDefaults * userDefualt = [NSUserDefaults standardUserDefaults];
    [userDefualt setObject:clientId forKey:@"fitbit.setting.client_id"];
    [userDefualt synchronize];
}

//apiSecret
+ (void) setFitbitApiSecret:(NSString *) apiSecret{
    NSUserDefaults * userDefualt = [NSUserDefaults standardUserDefaults];
    [userDefualt setObject:apiSecret forKey:@"fitbit.setting.api_secret"];
    [userDefualt synchronize];
}


//////////////////////////////////////////////////////////////////////////////

+ (NSString *)getFitbitAccessToken{
    NSUserDefaults * userDefualt = [NSUserDefaults standardUserDefaults];
    return [userDefualt objectForKey:@"fitbit.setting.access_token"];
}

+ (NSString *) getFitbitRefreshToken{
    NSUserDefaults * userDefualt = [NSUserDefaults standardUserDefaults];
    return [userDefualt objectForKey:@"fitbit.setting.refresh_token"];
}

+ (NSString *)getFitbitUserId{
    NSUserDefaults * userDefualt = [NSUserDefaults standardUserDefaults];
    NSString * userId = [userDefualt objectForKey:@"fitbit.setting.user_id"];
    return userId;
}

+ (NSString *)getFitbitTokenType{
    NSUserDefaults * userDefualt = [NSUserDefaults standardUserDefaults];
    return [userDefualt objectForKey:@"fitbit.setting.token_type"];
}


//clientId
+ (NSString *) getFitbitClientId{
    NSUserDefaults * userDefualt = [NSUserDefaults standardUserDefaults];
    return [userDefualt objectForKey:@"fitbit.setting.client_id"];
}

//apiSecret
+ (NSString *) getFitbitApiSecret{
    NSUserDefaults * userDefualt = [NSUserDefaults standardUserDefaults];
    return [userDefualt objectForKey:@"fitbit.setting.api_secret"];
}
/////////////////////////////////////////////////////////////////////////////////////


+ (void)clearAllSettings{
    NSUserDefaults * userDefualt = [NSUserDefaults standardUserDefaults];
    [userDefualt removeObjectForKey:@"fitbit.setting.access_token"];
    [userDefualt removeObjectForKey:@"fitbit.setting.refresh_token"];
    [userDefualt removeObjectForKey:@"fitbit.setting.user_id"];
    [userDefualt removeObjectForKey:@"fitbit.setting.token_type"];
    [userDefualt removeObjectForKey:@"fitbit.setting.client_id"];
    [userDefualt removeObjectForKey:@"fitbit.setting.api_secret"];
    [userDefualt synchronize];
}

@end
