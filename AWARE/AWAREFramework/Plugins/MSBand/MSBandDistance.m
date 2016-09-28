//
//  MSBandDistance.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 7/13/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "MSBandDistance.h"
#import "EntityMSBandDistance.h"
#import "AWAREUtils.h"

@implementation MSBandDistance


- (instancetype)initWithMSBClient:(MSBClient *)msbClient
                       awareStudy:(AWAREStudy *)study
                       sensorName:(NSString *)name
                     dbEntityName:(NSString *)entity
                           dbType:(AwareDBType)dbType
                       bufferSize:(int)buffer{
    self = [super initWithAwareStudy:study sensorName:name dbEntityName:entity dbType:dbType bufferSize:buffer];
    if(self != nil){
         self.client = msbClient;
        [self setCSVHeader:@[@"timestamp", @"device_id", @"distance", @"motiontype"]];
    }
    return self;
}

- (void) createTable {
    NSString *query = @"_id integer primary key autoincrement,"
    "timestamp real default 0,"
    "device_id text default '',"
    "distance integer default 0,"
    "motiontype texte default ''";
    //"UNIQUE (timestamp,device_id)";
    [super createTable:query];
}

- (BOOL)startSensorWithSettings:(NSArray *)settings{
    
    NSLog(@"Start Distance Sensor");
    
    double activeTimeInSec = 2*60;
    int min = [self getSensorSetting:settings withKey:SENSOR_PLUGIN_MSBAND_KEY_ACTIVE_IN_MINUTE];
    if(min > 0){
        activeTimeInSec = min * 60;
    }
    
    void (^distanceHandler)(MSBSensorDistanceData *, NSError *) = ^(MSBSensorDistanceData *distanceData, NSError *error) {
        NSString* data =[NSString stringWithFormat:@"%ld", (unsigned long)distanceData.totalDistance];
        if ([self isDebug]) {
            NSLog(@"Distance: %@", data);
        }
        NSString* motionType = @"";
        switch (distanceData.motionType) {
            case MSBSensorMotionTypeUnknown:
                motionType = @"UNKNOWN";
                break;
            case MSBSensorMotionTypeJogging:
                motionType = @"JOGGING";
                break;
            case MSBSensorMotionTypeRunning:
                motionType = @"RUNNING";
                break;
            case MSBSensorMotionTypeIdle:
                motionType = @"IDLE";
                break;
            case MSBSensorMotionTypeWalking:
                motionType = @"WALKING";
                break;
            default:
                motionType = @"UNKNOWN";
                break;
        }
        
        NSNumber* unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        [dict setObject:unixtime forKey:@"timestamp"];
        [dict setObject:[self getDeviceId] forKey:@"device_id"];
        [dict setObject:[NSNumber numberWithInteger:distanceData.totalDistance] forKey:@"distance"];
        [dict setObject:motionType forKey:@"motiontype"];
        
        [self setLatestValue:data];
        [self setLatestData:dict];
        [self saveData:dict];
    };
    NSError *stateError;
    if (![self.client.sensorManager startDistanceUpdatesToQueue:nil errorRef:&stateError withHandler:distanceHandler]) {
        
    }else{
        [self performSelector:@selector(stopDistanceSensor) withObject:nil afterDelay:activeTimeInSec];
    }
    
    return YES;
}




- (void) stopDistanceSensor{
    NSLog(@"Stop Distance Sensor");
    [self.client.sensorManager stopDistanceUpdatesErrorRef:nil];
}


- (void)insertNewEntityWithData:(NSDictionary *)data
           managedObjectContext:(NSManagedObjectContext *)childContext
                     entityName:(NSString *)entity{
    EntityMSBandDistance * entityDistance = (EntityMSBandDistance *)[NSEntityDescription insertNewObjectForEntityForName:entity
                                                                                        inManagedObjectContext:childContext];
    entityDistance.device_id = [data objectForKey:@"device_id"];
    entityDistance.timestamp = [data objectForKey:@"timestamp"];
    entityDistance.distance =  [data objectForKey:@"distance"];
    entityDistance.motiontype = [data objectForKey:@"motiontype"];
    
}

@end
