//
//  MSBandHR.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 7/13/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "MSBandHR.h"
#import "EntityMSBandHR.h"
#import "AWAREUtils.h"

@implementation MSBandHR

- (instancetype)initWithMSBClient:(MSBClient *)msbClient
                       awareStudy:(AWAREStudy *)study
                       sensorName:(NSString *)name
                     dbEntityName:(NSString *)entity
                           dbType:(AwareDBType)dbType
                       bufferSize:(int)buffer
{
    self = [super initWithAwareStudy:study sensorName:name dbEntityName:entity dbType:dbType bufferSize:buffer];
    if(self != nil){
        self.client = msbClient;
        [self setCSVHeader:@[@"timestamp", @"device_id", @"heartrate", @"heartrate_quality"]];
    }
    return self;
}

- (void)createTable
{
    NSString *query = @"_id integer primary key autoincrement,"
    "timestamp real default 0,"
    "device_id text default '',"
    "heartrate integer default 0,"
    "heartrate_quality text default ''";
    // "UNIQUE (timestamp,device_id)";
    [super createTable:query];
}



- (BOOL)startSensorWithSettings:(NSArray *)settings
{
    NSLog(@"Start Heart Rate Sensor");
    
    double activeTimeInSec = 2*60;
    int min = [self getSensorSetting:settings withKey:SENSOR_PLUGIN_MSBAND_KEY_ACTIVE_IN_MINUTE];
    if(min > 0){
        activeTimeInSec = min * 60;
    }
    
    void (^hrHandler)(MSBSensorHeartRateData *, NSError *) = ^(MSBSensorHeartRateData *heartRateData, NSError *error) {
        
        NSString* quality = @"";
        switch (heartRateData.quality) {
            case MSBSensorHeartRateQualityAcquiring:
                quality = @"ACQUIRING";
                break;
            case MSBSensorHeartRateQualityLocked:
                quality = @"LOCKED";
                break;
            default:
                quality = @"UNKNOWN";
                break;
        }
        
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        [dict setObject:[AWAREUtils getUnixTimestamp:[NSDate new]] forKey:@"timestamp"];
        [dict setObject:[self getDeviceId] forKey:@"device_id"];
        [dict setObject:[NSNumber numberWithDouble:heartRateData.heartRate] forKey:@"heartrate"];
        [dict setObject:quality forKey:@"heartrate_quality"];

        // set latese sensor value
        NSString * latestValue = [NSString stringWithFormat:@"Heart Rate: %3u %@",
                                  (unsigned int)heartRateData.heartRate,
                                  heartRateData.quality == MSBSensorHeartRateQualityAcquiring ? @"Acquiring" : @"Locked"];
        if ([self isDebug]) {
            NSLog(@"HR: %@", latestValue);
        }
        [super setLatestValue:latestValue];
        [self setLatestData:dict];
        [self saveData:dict];
    };
    
    NSError *stateError;
    if (![self.client.sensorManager startHeartRateUpdatesToQueue:nil errorRef:&stateError withHandler:hrHandler]) {
        
    }else{
        [self performSelector:@selector(stopSensor) withObject:nil afterDelay:activeTimeInSec];
    }

    return YES;
}


- (BOOL)stopSensor
{
    NSLog(@"Stop Heart Rate Sensor");
    [self.client.sensorManager stopHeartRateUpdatesErrorRef:nil];
    return YES;
}


- (void)insertNewEntityWithData:(NSDictionary *)data
           managedObjectContext:(NSManagedObjectContext *)childContext
                     entityName:(NSString *)entity
{
    EntityMSBandHR * entityHR = (EntityMSBandHR *)[NSEntityDescription insertNewObjectForEntityForName:entity
                                                                            inManagedObjectContext:childContext];
    entityHR.device_id = [data objectForKey:@"device_id"];
    entityHR.timestamp = [data objectForKey:@"timestamp"];
    entityHR.heartrate = [data objectForKey:@"heartrate"];
    entityHR.heartrate_quality = [data objectForKey:@"heartrate_quality"];
    
}




////////////////////////////////////////////////

- (void) requestHRUserConsent {
    MSBUserConsent consent = [self.client.sensorManager heartRateUserConsent];
    switch (consent) {
        case MSBUserConsentGranted:
            // user has granted access
            break;
        case MSBUserConsentDeclined:
            // user has declined access
            break;
        case MSBUserConsentNotSpecified:
            // request user consent
            [self.client.sensorManager requestHRUserConsentWithCompletion:^(BOOL userConsent, NSError *error) {
                if (userConsent) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"MicrosoftBand2"
                                                                        message:@"Please push a refresh button on the navigation bar for initializing a sensor."
                                                                       delegate:self
                                                              cancelButtonTitle:nil
                                                              otherButtonTitles:@"OK", nil];
                        [alert show];
                    });
                } else {
                    // user declined access
                }
            }];
            break;
    }
}

//////////////////////////////////////////////////





@end
