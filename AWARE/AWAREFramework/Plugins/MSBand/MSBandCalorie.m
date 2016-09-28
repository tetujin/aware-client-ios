//
//  MSBandCal.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 7/13/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "MSBandCalorie.h"
#import "EntityMSBandCalorie.h"
#import "AWAREUtils.h"

@implementation MSBandCalorie

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
        [self setCSVHeader:@[@"timestamp", @"device_id", @"calories"]];
    }
    
    return self;
}

- (void)createTable
{
    NSString *query = @"_id integer primary key autoincrement,"
    "timestamp real default 0,"
    "device_id text default '',"
    "calories integer default 0";
    // "UNIQUE (timestamp,device_id)";
    [super createTable:query];
}

- (BOOL)startSensorWithSettings:(NSArray *)settings
{
    double activeTimeInSec = 2*60;
    int min = [self getSensorSetting:settings withKey:SENSOR_PLUGIN_MSBAND_KEY_ACTIVE_IN_MINUTE];
    if(min > 0){
        activeTimeInSec = min*60;
    }
    
    NSLog(@"Start Calorie Sensor");
    
    void (^calHandler)(MSBSensorCaloriesData *, NSError *) = ^(MSBSensorCaloriesData *calData, NSError *error) {
        NSString * data = [NSString stringWithFormat:@"Cal: %ld", (unsigned long)calData.calories];
        if ([self isDebug]) {
            NSLog(@"%@", data);
        }
        NSNumber* unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        [dict setObject:unixtime forKey:@"timestamp"];
        [dict setObject:[self getDeviceId] forKey:@"device_id"];
        [dict setObject:@(calData.calories) forKey:@"calories"];
        [self setLatestValue:data];
        [self setLatestData:dict];
        [self saveData:dict];
    };
    NSError *stateError;
    if (![self.client.sensorManager startCaloriesUpdatesToQueue:nil errorRef:&stateError withHandler:calHandler]) {
        return NO;
    }else{
        [self performSelector:@selector(stopSensor) withObject:nil afterDelay:activeTimeInSec];
    }

    return YES;
}


- (BOOL)stopSensor
{
    NSLog(@"Stop Calorie Sensor");
    [self.client.sensorManager stopCaloriesUpdatesErrorRef:nil];
    return YES;
}


- (void)insertNewEntityWithData:(NSDictionary *)data
           managedObjectContext:(NSManagedObjectContext *)childContext
                     entityName:(NSString *)entity
{
    EntityMSBandCalorie * entityCal = (EntityMSBandCalorie *)[NSEntityDescription insertNewObjectForEntityForName:entity
                                                                                      inManagedObjectContext:childContext];
    entityCal.device_id = [data objectForKey:@"device_id"];
    entityCal.timestamp = [data objectForKey:@"timestamp"];
    entityCal.calories =  [data objectForKey:@"calories"];
    
}


@end
