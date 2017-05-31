//
//  MSBandSkinTemp.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 7/13/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "MSBandSkinTemp.h"
#import "EntityMSBandSkinTemp.h"
#import "AWAREUtils.h"

@implementation MSBandSkinTemp

- (instancetype)initWithMSBClient:(MSBClient *)msbClient
                       awareStudy:(AWAREStudy *)study
                       sensorName:(NSString *)name
                     dbEntityName:(NSString *)entity
                           dbType:(AwareDBType)dbType
                       bufferSize:(int)buffer{
    
    self = [super initWithAwareStudy:study
                          sensorName:name
                        dbEntityName:entity
                              dbType:AwareDBTypeCoreData
                          bufferSize:buffer];
    if(self != nil){
        self.client = msbClient;
        [self setCSVHeader:@[@"timestamp", @"device_id", @"skintemp"]];
    }
    
    return self;
}


- (void) createTable {
    NSString *query  = @"_id integer primary key autoincrement,"
    "timestamp real default 0,"
    "device_id text default '',"
    "skintemp real default 0";
    // "UNIQUE (timestamp,device_id)";
    [super createTable:query];
}


- (BOOL)startSensorWithSettings:(NSArray *)settings{
    NSLog(@"Start Skin Teamperature Sensor");
    
    double activeTimeInSec = 2*60;
    int min = [self getSensorSetting:settings withKey:SENSOR_PLUGIN_MSBAND_KEY_ACTIVE_IN_MINUTE];
    if(min > 0){
        activeTimeInSec = min*60;
    }
    
    void (^skinHandler)(MSBSensorSkinTemperatureData *, NSError *) = ^(MSBSensorSkinTemperatureData *skinData,  NSError *error){
        NSString *data = [NSString stringWithFormat:@" interval (s): %.2f", skinData.temperature];
        if ([self isDebug]) {
            NSLog(@"Skin: %@",data);
            [AWAREUtils sendLocalNotificationForMessage:[NSString stringWithFormat:@"Skin: %@", data] soundFlag:NO];
        }
        
        
        NSNumber* unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]]; //[NSNumber numberWithDouble:timeStamp];
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        [dict setObject:unixtime forKey:@"timestamp"];
        [dict setObject:[self getDeviceId] forKey:@"device_id"];
        [dict setObject:[NSNumber numberWithDouble:skinData.temperature] forKey:@"skintemp"];
        [self setLatestValue:data];
        [self setLatestData:dict];
        [self saveData:dict];
        
    };
    NSError *stateError;
    if (![self.client.sensorManager startSkinTempUpdatesToQueue:nil errorRef:&stateError withHandler:skinHandler]) {
        return NO;
    }else{
        [self performSelector:@selector(stopSensor) withObject:nil afterDelay:activeTimeInSec];
    }

    return YES;
}

- (BOOL)stopSensor{
    NSLog(@"Stop Skin Temp Sensor");
    [self.client.sensorManager stopSkinTempUpdatesErrorRef:nil];
    return YES;
}

- (void)insertNewEntityWithData:(NSDictionary *)data managedObjectContext:(NSManagedObjectContext *)childContext entityName:(NSString *)entity{
    EntityMSBandSkinTemp * entitySkinTemp = (EntityMSBandSkinTemp *)[NSEntityDescription insertNewObjectForEntityForName:entity
                                                                                        inManagedObjectContext:childContext];
    entitySkinTemp.device_id = [data objectForKey:@"device_id"];
    entitySkinTemp.timestamp = [data objectForKey:@"timestamp"];
    entitySkinTemp.skintemp  = [data objectForKey:@"skintemp"];
    
}

- (void)clientManager:(MSBClientManager *)clientManager clientDidConnect:(MSBClient *)client{
    
}

- (void)clientManager:(MSBClientManager *)clientManager clientDidDisconnect:(MSBClient *)client{
    
}

- (void)clientManager:(MSBClientManager *)clientManager client:(MSBClient *)client didFailToConnectWithError:(NSError *)error{
    
}

@end
