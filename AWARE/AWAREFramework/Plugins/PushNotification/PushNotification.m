//
//  PushNotification.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 5/2/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "PushNotification.h"
#import "AWAREUtils.h"
#import "AWAREKeys.h"
#import "AppDelegate.h"
#import "EntityPushNotification.h"

@implementation PushNotification{
    NSString * KEY_PUSH_DEVICE_ID;
    NSString * KEY_PUSH_TIMESTAMP;
    NSString * KEY_PUSH_TOKEN;
}


- (instancetype)initWithAwareStudy:(AWAREStudy *)study{
    self = [super initWithAwareStudy:study
                          sensorName:@"push_notification_device_tokens"
                        dbEntityName:NSStringFromClass([EntityPushNotification class])
                              dbType:AwareDBTypeCoreData];
    if(self != nil){
        KEY_PUSH_DEVICE_ID = @"device_id";
        KEY_PUSH_TIMESTAMP = @"timestamp";
        KEY_PUSH_TOKEN = @"token";
    }
    return self;
}


- (void)createTable{
    if([self isDebug]){
        NSLog(@"[%@] Send a create table query", [self getSensorName]);
    }
    NSMutableString *query = [[NSMutableString alloc] init];
    [query appendString:@"_id integer primary key autoincrement,"];
    [query appendString:[NSString stringWithFormat:@"%@ real default 0,", KEY_PUSH_TIMESTAMP]];
    [query appendString:[NSString stringWithFormat:@"%@ text default '',", KEY_PUSH_DEVICE_ID]];
    [query appendString:[NSString stringWithFormat:@"%@ text default '',", KEY_PUSH_TOKEN]];
    [query appendString:@"UNIQUE (timestamp,device_id)"];
    
    [super createTable:query];
}


- (BOOL)startSensorWithSettings:(NSArray *)settings{
    [self saveStoredPushNotificationDeviceToken];
    [self allowsCellularAccess];
    [self allowsDateUploadWithoutBatteryCharging];
    [self syncAwareDB];
    return YES;
}


//////////////////////////////////////////////////
//////////////////////////////////////////////////

/**
 * Save a device token for push notification
 * @param NSString  A device token
 */
- (void) savePushNotificationDeviceToken:(NSString*) token {
    if (token == nil) {
        return;
    }
//    NSMutableDictionary * dict = [[NSMutableDictionary alloc] init];
//    [dict setObject:[AWAREUtils getUnixTimestamp:[NSDate new]] forKey:KEY_PUSH_TIMESTAMP];
//    [dict setObject:[self getDeviceId] forKey:KEY_PUSH_DEVICE_ID];
//    [dict setObject:token forKey:KEY_PUSH_TOKEN];
//    [self saveData:dict];
    NSNumber *unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
    
    AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
    EntityPushNotification * entity = (EntityPushNotification *)[NSEntityDescription insertNewObjectForEntityForName:[self getEntityName]
                                                                  inManagedObjectContext:delegate.managedObjectContext];
    entity.device_id = [self getDeviceId];
    entity.timestamp = unixtime;
    entity.token = token;
    
    [self saveDataToDB];

    // Save the token to user default
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:token forKey:KEY_APNS_TOKEN];
    [defaults synchronize];
}

/**
 * Save a stored device token fro push notification
 * @return BOOL An existance of device token for push notification
 */
- (BOOL) saveStoredPushNotificationDeviceToken {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSString * deviceToken = [defaults objectForKey:KEY_APNS_TOKEN];
    if (deviceToken != nil) {
        [self savePushNotificationDeviceToken:deviceToken];
        return YES;
    }
    return NO;
}

@end
