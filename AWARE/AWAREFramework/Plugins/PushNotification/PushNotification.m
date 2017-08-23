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


- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    self = [super initWithAwareStudy:study
                          sensorName:@"push_notification_device_tokens"
                        dbEntityName:NSStringFromClass([EntityPushNotification class])
                              dbType:AwareDBTypeCoreData];
    if(self != nil){
        KEY_PUSH_DEVICE_ID = @"device_id";
        KEY_PUSH_TIMESTAMP = @"timestamp";
        KEY_PUSH_TOKEN = @"token";
        [self allowsCellularAccess];
        [self allowsDateUploadWithoutBatteryCharging];
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
    // [self saveStoredPushNotificationDeviceToken];
    // [self setUploadingState:NO];
    [self performSelector:@selector(syncAwareDBInBackground) withObject:nil afterDelay:1];
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
    NSMutableDictionary * dict = [[NSMutableDictionary alloc] init];
    [dict setObject:[AWAREUtils getUnixTimestamp:[NSDate new]] forKey:KEY_PUSH_TIMESTAMP];
    [dict setObject:[self getDeviceId] forKey:KEY_PUSH_DEVICE_ID];
    [dict setObject:token forKey:KEY_PUSH_TOKEN];
    [self saveData:dict];
    [self setLatestData:dict];
    
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

- (void)insertNewEntityWithData:(NSDictionary *)data
           managedObjectContext:(NSManagedObjectContext *)childContext
                     entityName:(NSString *)entity{
    
    EntityPushNotification * entityPush = (EntityPushNotification *)[NSEntityDescription insertNewObjectForEntityForName:entity
                                                                                              inManagedObjectContext:childContext];
    entityPush.device_id = [data objectForKey:KEY_PUSH_DEVICE_ID];
    entityPush.timestamp = [data objectForKey:KEY_PUSH_TIMESTAMP];
    entityPush.token = [data objectForKey:KEY_PUSH_TOKEN];
}

- (void)saveDummyData{
    [self saveStoredPushNotificationDeviceToken];
}

//////////////////////////////////////////////////

- (BOOL)syncAwareDBInForeground{
    return [super syncAwareDBInForeground];
}

- (NSString *) getPushNotificationToken {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSString * deviceToken = [defaults objectForKey:KEY_APNS_TOKEN];
    return deviceToken;
}

@end
