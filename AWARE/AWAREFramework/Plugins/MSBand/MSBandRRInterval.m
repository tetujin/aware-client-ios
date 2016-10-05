//
//  MSBandRRInterval.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 7/13/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "MSBandRRInterval.h"
#import "AWAREUtils.h"
#import "EntityMSBandRRInterval.h"

@implementation MSBandRRInterval

- (instancetype)initWithMSBClient:(MSBClient *)msbClient
                       awareStudy:(AWAREStudy *)study
                       sensorName:(NSString *)name
                     dbEntityName:(NSString *)entity
                           dbType:(AwareDBType)dbType
                       bufferSize:(int)buffer{
    self = [super initWithAwareStudy:study sensorName:name dbEntityName:entity dbType:dbType bufferSize:buffer];
    if( self != nil ){
        self.client = msbClient;
        [self setCSVHeader:@[@"timestamp", @"device_id", @"rrinterval"]];
    }
    return self;
}

- (void)createTable {
    NSString * query = @"_id integer primary key autoincrement,"
    "timestamp real default 0,"
    "device_id text default '',"
    "rrinterval double default 0";
    // "UNIQUE (timestamp,device_id)";
    [self createTable:query];
}


- (BOOL)startSensorWithSettings:(NSArray *)settings{
    NSLog(@"Start RRInterval Sensor");
    
    double activeTimeInSec = 2*60;
    int min = [self getSensorSetting:settings withKey:SENSOR_PLUGIN_MSBAND_KEY_ACTIVE_IN_MINUTE];
    if(min > 0){
        activeTimeInSec = min * 60;
    }
    
    void (^handler)(MSBSensorRRIntervalData *, NSError *) = ^(MSBSensorRRIntervalData *rrIntervalData, NSError *error)
    {
        // [weakSelf output:[NSString stringWithFormat:@" interval (s): %.2f", rrIntervalData.interval]];
        if ([self isDebug]) {
            NSLog(@"RRInterval: %.2f", rrIntervalData.interval);
        }
        
        NSMutableDictionary * dict = [[NSMutableDictionary alloc] init];
        [dict setObject:[self getDeviceId] forKey:@"device_id"];
        [dict setObject:[AWAREUtils getUnixTimestamp:[NSDate new]] forKey:@"timestamp"]; //  data.timestamp = [self getUnixTime];
        [dict setObject:@(rrIntervalData.interval) forKey:@"rrinterval"];
        
        [self saveData:dict];
        [self setLatestData:dict];
    };
    
    NSError * stateError = nil;
    if (![self.client.sensorManager startRRIntervalUpdatesToQueue:nil errorRef:&stateError withHandler:handler]){
        
    }else{
        [self performSelector:@selector(stopSensor) withObject:nil afterDelay:activeTimeInSec];
    }
    return YES;
}


- (BOOL)stopSensor{
    NSLog(@"Stop RRInterval Sensor");
    [self.client.sensorManager stopRRIntervalUpdatesErrorRef:nil];
    return YES;
}

- (void)insertNewEntityWithData:(NSDictionary *)data
           managedObjectContext:(NSManagedObjectContext *)childContext
                     entityName:(NSString *)entity{

    EntityMSBandRRInterval * entityRRInterval = (EntityMSBandRRInterval *)[NSEntityDescription insertNewObjectForEntityForName:entity
                                                                                            inManagedObjectContext:childContext];
    entityRRInterval.device_id = [data objectForKey:@"device_id"];
    entityRRInterval.timestamp = [data objectForKey:@"timestamp"];
    entityRRInterval.rrinterval =  [data objectForKey:@"rrinterval"];
    
    
}

- (void)clientManager:(MSBClientManager *)clientManager clientDidConnect:(MSBClient *)client{
    
}

- (void)clientManager:(MSBClientManager *)clientManager clientDidDisconnect:(MSBClient *)client{
    
}

- (void)clientManager:(MSBClientManager *)clientManager client:(MSBClient *)client didFailToConnectWithError:(NSError *)error{
    
}

- (void)requestHRUserConsent{
    
}

@end
