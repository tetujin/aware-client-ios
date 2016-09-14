//
//  Observer.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 4/6/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "Observer.h"
#import "AWAREUtils.h"
#import "CertPinning.h"

@implementation Observer{
    AWAREStudy * awareStudy;
    NSString* KEY_TIMESTAMP;
    NSString* KEY_DEVICE_ID;
}

-(instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    self = [super initWithAwareStudy:study
                          sensorName:@"aware_observer"
                        dbEntityName:nil
                              dbType:AwareDBTypeTextFile];
    if(self != nil){
        awareStudy = study;
        KEY_TIMESTAMP = @"timestamp";
        KEY_DEVICE_ID = @"device_id";
    }
    return self;
}

-(void)createTable{
    NSMutableString *query = [[NSMutableString alloc] init];
    [query appendString:@"_id integer primary key autoincrement,"];
    [query appendFormat:@"%@ real default 0,", KEY_TIMESTAMP];
    [query appendFormat:@"%@ text default '',", KEY_DEVICE_ID];
//    [query appendFormat:@"UNIQUE (timestamp,device_id)"];
    [self createTable:query];
}

- (BOOL)startSensorWithSettings:(NSArray *)settings{
    return YES;
}

- (BOOL) stopSensor{
    return YES;
}


//////////////////////////////////////////
//////////////////////////////////////////

- (bool)sendSurvivalSignal{
    
    // Make a survial signal
    NSMutableDictionary * dic = [[NSMutableDictionary alloc] init];
    [dic setObject:[AWAREUtils getUnixTimestamp:[NSDate new]] forKey:KEY_TIMESTAMP];
    [dic setObject:[self getDeviceId] forKey:KEY_DEVICE_ID];
    NSMutableArray * array = [[NSMutableArray alloc] init];
    [array addObject:dic];
    // Convert the query to JSON format string
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:array
                                                       options:0// Pass 0 if you don't care about the readability of the generated string
                                                         error:&error];
    NSString *jsonString = @"";
    if (! jsonData) {
        NSLog(@"Got an error: %@", error);
    } else {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    
    // Make a HTTP/POST body
    NSString *post = [NSString stringWithFormat:@"device_id=%@&data=%@", [self getDeviceId], jsonString];
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%ld", [postData length]];
    
    // Make a HTTP/POST header
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:[self getInsertUrl:[self getSensorName]]]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:postData];
    
    // Set a HTTP/POST session
    __weak NSURLSession *session = nil;
    session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:[CertPinning sharedPinner] delegateQueue:[NSOperationQueue mainQueue]];
    [[session dataTaskWithRequest: request  completionHandler: ^(NSData *data, NSURLResponse *response, NSError *error) {
        [session finishTasksAndInvalidate];
        [session invalidateAndCancel];
        
        if ([self isDebug]) {
            if (response && ! error) {
                NSString *responseString = [[NSString alloc] initWithData: data  encoding: NSUTF8StringEncoding];
                NSLog(@"Success: %@", responseString);
                [self sendLocalNotificationForMessage:@"[Success] Send a survival signal." soundFlag:NO];
            }else{
                [self sendLocalNotificationForMessage:@"[Fail] Send a survival signal" soundFlag:NO];
            }
        }
    }] resume];
    return YES;
}



@end
