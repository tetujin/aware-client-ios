//
//  MSBandPedometer.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 7/13/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "MSBandPedometer.h"
#import "EntityMSBandPedometer.h"
#import "AWAREUtils.h"

@implementation MSBandPedometer

- (instancetype)initWithMSBClient:(MSBClient *)msbClient
                       awareStudy:(AWAREStudy *)study
                       sensorName:(NSString *)name
                     dbEntityName:(NSString *)entity
                           dbType:(AwareDBType)dbType
                       bufferSize:(int)buffer{
    self = [super initWithAwareStudy:study sensorName:name dbEntityName:entity dbType:dbType bufferSize:buffer];
    if( self != nil ){
        self.client = msbClient;
        [self setCSVHeader:@[@"timestamp", @"device_id", @"pedometer"]];
    }
    return self;
}

- (void) createTable {
    NSString *query = @"_id integer primary key autoincrement,"
    "timestamp real default 0,"
    "device_id text default '',"
    "pedometer int default 0";
    // "UNIQUE (timestamp,device_id)";
    [self createTable:query];
}

- (BOOL)startSensorWithSettings:(NSArray *)settings{
    
    NSLog(@"Start Pedometer Sensor");
    
    double activeTimeInSec = 2*60;
    int min = [self getSensorSetting:settings withKey:SENSOR_PLUGIN_MSBAND_KEY_ACTIVE_IN_MINUTE];
    if(min > 0){
        activeTimeInSec = min * 60;
    }
    
    NSError * error = nil;
    void (^pedometerHandler)(MSBSensorPedometerData *, NSError *) = ^(MSBSensorPedometerData *pedometerData, NSError *error){
            NSNumber* unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
            NSMutableDictionary * dict = [[NSMutableDictionary alloc] init];
            [dict setObject:unixtime forKey:@"timestamp"];
            [dict setObject:[self getDeviceId] forKey:@"device_id"];
            [dict setObject:@(pedometerData.totalSteps) forKey:@"pedometer"];
            [self saveData:dict];
            [self setLatestData:dict];
    };
    
    if(![self.client.sensorManager startPedometerUpdatesToQueue:nil errorRef:&error withHandler:pedometerHandler]){

    }else{
        [self performSelector:@selector(stopSensor) withObject:nil afterDelay:activeTimeInSec];
    }
    
    return YES;
}

- (void)insertNewEntityWithData:(NSDictionary *)data managedObjectContext:(NSManagedObjectContext *)childContext entityName:(NSString *)entity{
    
    EntityMSBandPedometer* entityPedometer = (EntityMSBandPedometer *)[NSEntityDescription insertNewObjectForEntityForName:entity
                                                                                                    inManagedObjectContext:childContext];
    entityPedometer.device_id = [data objectForKey:@"device_id"];
    entityPedometer.timestamp = [data objectForKey:@"timestamp"];
    entityPedometer.pedometer = [data objectForKey:@"pedometer"];
    
}


- (BOOL)stopSensor {
    NSLog(@"Stop Pedometer Sensor");
    [self.client.sensorManager stopPedometerUpdatesErrorRef:nil];
    return YES;
}


@end
