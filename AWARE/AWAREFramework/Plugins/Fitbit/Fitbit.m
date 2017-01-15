//
//  Fitbit.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 2017/01/15.
//  Copyright © 2017 Yuuki NISHIYAMA. All rights reserved.
//

#import "Fitbit.h"

#import "NXOAuth2.h"

@implementation Fitbit

- (instancetype)initWithAwareStudy:(AWAREStudy *)study
                            dbType:(AwareDBType)dbType{
    
    self = [super initWithAwareStudy:study
                          sensorName:@"plugin_fitbit"
                        dbEntityName:nil];
    if(self != nil){
        
    }
    
    return self;
}



- (BOOL)startSensorWithSettings:(NSArray *)settings{

    [self loginWithOAuth2];
    
    // [self getProfile];
    
    return YES;
}

- (BOOL)stopSensor{
    return YES;
}


- (void) loginWithOAuth2 {
    // [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"url"]];
}

- (void) getProfile{
    
    // Get stored Fitbit information
    NSUserDefaults * userDefault = [NSUserDefaults standardUserDefaults];
    NSString * userId = [userDefault objectForKey:@"fitbit.setting.user_id"];
    NSString* token = [userDefault objectForKey:@"fitbit.setting.access_token"];
    
    // Set URL
    NSURL*	url = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.fitbit.com/1/user/%@/profile.json",userId]];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
    [request setHTTPMethod:@"GET"];
    
    __weak NSURLSession *session = nil;
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfiguration.allowsCellularAccess = YES;
    session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:Nil];

    [[session dataTaskWithRequest:request  completionHandler: ^(NSData *data, NSURLResponse *response, NSError *error) {
        [session finishTasksAndInvalidate];
        [session invalidateAndCancel];

        NSString *responseString = [[NSString alloc] initWithData: data  encoding: NSUTF8StringEncoding];
        NSLog(@"Success: %@", responseString);
        
    }] resume];
}


/////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (BOOL) handleURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation{
    NSArray *components = [url.absoluteString componentsSeparatedByString:@"#"];
    if(components.count > 1){
        NSString *value = components[1];
        NSArray * parameters = [value componentsSeparatedByString:@"&"];
        if(parameters != nil){
            for (NSString * paramStr in parameters) {
                NSArray * paramKeyValue = [paramStr componentsSeparatedByString:@"="];
                if(paramKeyValue){
                    if([paramKeyValue[0] isEqualToString:@"access_token"]){
                        [Fitbit setFitbitAccessToken:paramKeyValue[1]];
                    }else if([paramKeyValue[0] isEqualToString:@"user_id"]){
                        [Fitbit setFitbitUserId:paramKeyValue[1]];
                    }else if([paramKeyValue[0] isEqualToString:@"token_type"]){
                        [Fitbit setFibitTokenType:paramKeyValue[1]];
                    }
                }
            }
        }
    }
    return YES;
}

//////////////////////////////////////////////////////////////////////////////

+ (void) setFitbitAccessToken:(NSString * )accessToken{
    NSUserDefaults * userDefualt = [NSUserDefaults standardUserDefaults];
    [userDefualt setObject:accessToken forKey:@"fitbit.setting.access_token"];
}

+ (void) setFitbitUserId:(NSString *)userId{
    NSUserDefaults * userDefualt = [NSUserDefaults standardUserDefaults];
    [userDefualt setObject:userId forKey:@"fitbit.setting.user_id"];
}

+ (void) setFibitTokenType:(NSString *) tokenType{
    NSUserDefaults * userDefualt = [NSUserDefaults standardUserDefaults];
    [userDefualt setObject:tokenType forKey:@"fitbit.setting.token_type"];
}

//////////////////////////////////////////////////////////////////////////////

+ (NSString *)getFitbitAccessToken{
    NSUserDefaults * userDefualt = [NSUserDefaults standardUserDefaults];
    return [userDefualt objectForKey:@"fitbit.setting.access_token"];
}

+ (NSString *)getFitbitUserId{
    NSUserDefaults * userDefualt = [NSUserDefaults standardUserDefaults];
    return [userDefualt objectForKey:@"fitbit.setting.user_id"];
}

+ (NSString *)getFibitTokenType{
    NSUserDefaults * userDefualt = [NSUserDefaults standardUserDefaults];
    return [userDefualt objectForKey:@"fitbit.setting.token_type"];
}

/////////////////////////////////////////////////////////////////////////////////////


@end
