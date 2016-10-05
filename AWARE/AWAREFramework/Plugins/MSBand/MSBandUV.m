//
//  MSBandUV.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 7/13/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "MSBandUV.h"
#import "EntityMSBandUV.h"

@implementation MSBandUV

- (instancetype)initWithMSBClient:(MSBClient *)msbClient
                       awareStudy:(AWAREStudy *)study
                        sensorName:(NSString*) name
                      dbEntityName:(NSString *)entity
                            dbType:(AwareDBType)dbType
                        bufferSize:(int)buffer
{
    self = [super initWithAwareStudy:study
                          sensorName:name
                        dbEntityName:entity
                              dbType:dbType
                          bufferSize:buffer];
    if(self != nil){
        self.client = msbClient;
        [self setCSVHeader:@[@"timestamp", @"device_id", @"uv"]];
    }
    return self;
}

// Create table
- (void) createTable
{
    NSString *query = @"_id integer primary key autoincrement,"
    "timestamp real default 0,"
    "device_id text default '',"
    "uv text default ''";
    // "UNIQUE (timestamp,device_id)";
    [self createTable:query];
}


// Start sensor
- (BOOL) startSensorWithSettings:(NSArray *)settings
{
    NSLog(@"Start UV Sensor on MicrosoftBand2");
    
    double activeTimeInSec = 2*60;
    int min = [self getSensorSetting:settings withKey:SENSOR_PLUGIN_MSBAND_KEY_ACTIVE_IN_MINUTE];
    if(min > 0){
        activeTimeInSec = min*60;
    }
    
    void (^uvHandler)(MSBSensorUVData *, NSError *) = ^(MSBSensorUVData *uvData,  NSError *error){
        NSString *data = [NSString stringWithFormat:@" interval (s): %ld", uvData.uvIndexLevel];
        if ([self isDebug]) {
            NSLog(@"UV: %@",data);
            // [AWAREUtils sendLocalNotificationForMessage:[NSString stringWithFormat:@"UV: %@", data] soundFlag:NO];
        }
        NSString * uvLevelStr = @"UNKNOWN";
        switch (uvData.uvIndexLevel) {
            case MSBSensorUVIndexLevelNone:
                uvLevelStr = @"NONE";
                break;
            case MSBSensorUVIndexLevelLow:
                uvLevelStr = @"LOW";
                break;
            case MSBSensorUVIndexLevelMedium:
                uvLevelStr = @"MEDIUM";
                break;
            case MSBSensorUVIndexLevelHigh:
                uvLevelStr = @"HIGH";
                break;
            case MSBSensorUVIndexLevelVeryHigh:
                uvLevelStr = @"VERY_HIGH";
            default:
                break;
        }
        
        NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        [dict setObject:unixtime forKey:@"timestamp"];
        [dict setObject:[self getDeviceId] forKey:@"device_id"];
        [dict setObject:uvLevelStr forKey:@"uv"];
        [self setLatestData:dict];
        [self saveData:dict];
    };
    
    NSError *stateError;
    if (![self.client.sensorManager startUVUpdatesToQueue:nil errorRef:&stateError withHandler:uvHandler]) {
        NSLog(@"UV sensor is failed: %@", stateError.description);
        return NO;
    }else{
        [self performSelector:@selector(stopSensor) withObject:nil afterDelay:activeTimeInSec];
    }
    
    return YES;
}

// Stop Sensor
- (BOOL)stopSensor{
    NSLog(@"Stop UV Sensor");
    [self.client.sensorManager stopUVUpdatesErrorRef:nil];
    return YES;
}


- (void)insertNewEntityWithData:(NSDictionary *)data
           managedObjectContext:(NSManagedObjectContext *)childContext
                     entityName:(NSString *)entity{
    
        EntityMSBandUV * entityUV = (EntityMSBandUV *)[NSEntityDescription insertNewObjectForEntityForName:entity
                                                                                inManagedObjectContext:childContext];
        entityUV.device_id = [data objectForKey:@"device_id"];
        entityUV.timestamp = [data objectForKey:@"timestamp"];
        entityUV.uv = [data objectForKey:@"uv"];
    
}

- (void)clientManager:(MSBClientManager *)clientManager clientDidConnect:(MSBClient *)client{
    
}

- (void)clientManager:(MSBClientManager *)clientManager clientDidDisconnect:(MSBClient *)client{
    
}

- (void)clientManager:(MSBClientManager *)clientManager client:(MSBClient *)client didFailToConnectWithError:(NSError *)error{
    
}

@end
