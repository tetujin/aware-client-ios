//
//  MSBandGSR.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 7/13/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "MSBandGSR.h"
#import "EntityMSBandGSR.h"
#import "AWAREUtils.h"

@implementation MSBandGSR

- (instancetype)initWithMSBClient:(MSBClient *)msbClient
                       awareStudy:(AWAREStudy *)study
                       sensorName:(NSString *)name
                     dbEntityName:(NSString *)entity
                           dbType:(AwareDBType)dbType
                       bufferSize:(int)buffer{
    self = [super initWithAwareStudy:study
                          sensorName:name
                        dbEntityName:entity
                              dbType:dbType
                          bufferSize:buffer];
    if(self != nil){
        self.client = msbClient;
        [self setCSVHeader:@[@"timestamp", @"device_id", @"gsr"]];
    }
    
    return self;
}

- (void)createTable{
    NSString *query = @"_id integer primary key autoincrement,"
    "timestamp real default 0,"
    "device_id text default '',"
    "gsr integer default 0";
    // "UNIQUE (timestamp,device_id)";
    [super createTable:query];
    // [super createTable:query withTableName:SENSOR_PLUGIN_MSBAND_SENSORS_GSR];
}

- (BOOL)startSensorWithSettings:(NSArray *)settings{
    NSLog(@"Start GSR Sensor");
    
    double activeTimeInSec = 2*60;
    int min = [self getSensorSetting:settings withKey:SENSOR_PLUGIN_MSBAND_KEY_ACTIVE_IN_MINUTE];
    if(min > 0){
        activeTimeInSec = min*60;
    }
    
    void (^gsrHandler)(MSBSensorGSRData *, NSError *error) = ^(MSBSensorGSRData *gsrData, NSError *error){
        NSString *data = [NSString stringWithFormat:@"%8u kOhm", (unsigned int)gsrData.resistance];
        if ([self isDebug]) {
            NSLog(@"GSR: %@", data);
        }
        
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        [dict setObject:[AWAREUtils getUnixTimestamp:[NSDate new]] forKey:@"timestamp"];
        [dict setObject:[self getDeviceId] forKey:@"device_id"];
        [dict setObject:@(gsrData.resistance) forKey:@"gsr"];
        [self setLatestValue:data];
        [self setLatestData:dict];
        [self saveData:dict];
    };
    NSError *stateError;
    if (![self.client.sensorManager startGSRUpdatesToQueue:nil errorRef:&stateError withHandler:gsrHandler]) {
        return NO;
    }else{
        [self performSelector:@selector(stopSensor) withObject:nil afterDelay:activeTimeInSec];
    }

    return YES;
}


- (BOOL)stopSensor{
    NSLog(@"Stop GSR Sensor");
    [self.client.sensorManager stopGSRUpdatesErrorRef:nil];
    return YES;
}


- (void)insertNewEntityWithData:(NSDictionary *)data
           managedObjectContext:(NSManagedObjectContext *)childContext
                     entityName:(NSString *)entity{
    
    EntityMSBandGSR * entityGSR = (EntityMSBandGSR *)[NSEntityDescription insertNewObjectForEntityForName:entity
                                                                              inManagedObjectContext:childContext];
    entityGSR.device_id = [data objectForKey:@"device_id"];
    entityGSR.timestamp = [data objectForKey:@"timestamp"];
    entityGSR.gsr = [data objectForKey:@"gsr"];
    
}



///////////////////////////////////////////////////////
//////////////////////////////////////////////////////

@end
