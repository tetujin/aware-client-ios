//
//  MSBandDeviceContact.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 7/13/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "MSBandDeviceContact.h"
#import "EntityMSBandDeviceContact.h"
#import "AWAREUtils.h"

@implementation MSBandDeviceContact

- (instancetype)initWithMSBClient:(MSBClient *)msbClient
                       awareStudy:(AWAREStudy *)study
                       sensorName:(NSString *)name
                     dbEntityName:(NSString *)entity
                           dbType:(AwareDBType)dbType
                       bufferSize:(int)buffer{
    self = [super initWithAwareStudy:study sensorName:name dbEntityName:entity dbType:dbType bufferSize:buffer];
    if( self != nil ){
        self.client = msbClient;
        [self setCSVHeader:@[@"timestamp", @"device_id", @"devicecontact"]];
    }
    return self;
}


- (void)createTable{
    NSString * query = @"_id integer primary key autoincrement,"
    "timestamp real default 0,"
    "device_id text default '',"
    "devicecontact text default ''";
    // "UNIQUE (timestamp,device_id)";
    [self createTable:query];
}


- (BOOL)startSensorWithSettings:(NSArray *)settings{
    
    NSLog(@"Start Device Contact Sensor");
    
    double activeTimeInSec = 2*60;
    int min = [self getSensorSetting:settings withKey:SENSOR_PLUGIN_MSBAND_KEY_ACTIVE_IN_MINUTE];
    if(min > 0){
        activeTimeInSec = min * 60;
    }
    
    void (^bandHandler)(MSBSensorBandContactData *, NSError*) = ^(MSBSensorBandContactData *contactData, NSError *error) {
        NSString * wornState = @"UNKNOWN";
        switch (contactData.wornState) {
            case MSBSensorBandContactStateWorn:
                wornState = @"WORN";
                break;
            case MSBSensorBandContactStateNotWorn:
                wornState = @"NOT_WORN";
                break;
            case MSBSensorBandContactStateUnknown:
                wornState = @"UNKNOWN";
            default:
                break;
        }
        
        NSNumber* unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
        NSMutableDictionary * dict = [[NSMutableDictionary alloc] init];
        [dict setObject:unixtime forKey:@"timestamp"];
        [dict setObject:[self getDeviceId] forKey:@"device_id"];
        [dict setObject:wornState forKey:@"devicecontact"];

        [self saveData:dict];
        [self setLatestData:dict];
    };
    
    NSError * error = nil;
    if(![self.client.sensorManager startBandContactUpdatesToQueue:nil errorRef:&error withHandler:bandHandler]){
    }else{
        [self performSelector:@selector(stopSensor) withObject:nil afterDelay:activeTimeInSec];
    }
    
    return YES;
}

- (BOOL)stopSensor{
    NSLog(@"Stop Device Contact Sensor");
    [self.client.sensorManager stopBandContactUpdatesErrorRef:nil];
    return YES;
}


- (void)insertNewEntityWithData:(NSDictionary *)data
           managedObjectContext:(NSManagedObjectContext *)childContext
                     entityName:(NSString *)entity{
    
    EntityMSBandDeviceContact * entityDeviceContact = (EntityMSBandDeviceContact *)[NSEntityDescription
                                                                                    insertNewObjectForEntityForName:entity
                                                                                    inManagedObjectContext:childContext];
    entityDeviceContact.device_id = [data objectForKey:@"device_id"];
    entityDeviceContact.timestamp = [data objectForKey:@"timestamp"];
    entityDeviceContact.devicecontact = [data objectForKey:@"devicecontact"];
    
    
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
