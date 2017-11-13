//
//  Estimote.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 2017/08/23.
//  Copyright © 2017 Yuuki NISHIYAMA. All rights reserved.
//

#import "Estimote.h"
#import "EstimoteMotion.h"
#import "EstimoteAirpressure.h"
#import "EstimoteTemperature.h"
#import "EstimoteAmbientLight.h"

@implementation Estimote{
    ESTTelemetryNotificationTemperature  * tempNotif;
    ESTTelemetryNotificationMotion       * motionNotif;
    ESTTelemetryNotificationPressure     * presureNotif;
    ESTTelemetryNotificationAmbientLight * ambientLightNotif;
    ESTTelemetryNotificationMagnetometer * magNotif;
    ESTTelemetryNotificationSystemStatus * systemNotif;
    EstimoteMotion      * sensorMotion;
    EstimoteAirpressure * sensorAirPressure;
    EstimoteTemperature * sensorTemperature;
    EstimoteAmbientLight* sensorAmbientLight;
    AWAREStudy * awareStudy;
    NSMutableArray * sensors;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    
    self = [super initWithAwareStudy:study
                          sensorName:@"estimote"
                        dbEntityName:@"estimote"
                              dbType:AwareDBTypeCoreData];
    if(self != nil){
        awareStudy = study;
        sensorMotion = [[EstimoteMotion alloc] initWithAwareStudy:awareStudy dbType:AwareDBTypeCoreData];
        sensorAirPressure = [[EstimoteAirpressure alloc] initWithAwareStudy:awareStudy dbType:AwareDBTypeCoreData];
        sensorTemperature = [[EstimoteTemperature alloc] initWithAwareStudy:awareStudy dbType:AwareDBTypeCoreData];
        sensorAmbientLight = [[EstimoteAmbientLight alloc] initWithAwareStudy:awareStudy dbType:AwareDBTypeCoreData];
        
        sensors = [[NSMutableArray alloc] init];
        [sensors addObject:sensorMotion];
        [sensors addObject:sensorAirPressure];
        [sensors addObject:sensorTemperature];
        [sensors addObject:sensorAmbientLight];
    }
    return self;
}

- (void)createTable{
    if (sensors != nil) {
        for (AWARESensor * sensor in sensors) {
            [sensor createTable];
        }
    }
}

- (void)syncAwareDB{
    [self syncAwareDBInBackground];
}

- (void)syncAwareDBInBackground {
    if (sensors != nil) {
        for (AWARESensor * sensor in sensors) {
            [sensor syncAwareDB];
        }
    }
    NSMutableDictionary * userInfo = [[NSMutableDictionary alloc] init];
    [userInfo setObject:@100 forKey:@"KEY_UPLOAD_PROGRESS_STR"];
    [userInfo setObject:@YES forKey:@"KEY_UPLOAD_FIN"];
    [userInfo setObject:@YES forKey:@"KEY_UPLOAD_SUCCESS"];
    [userInfo setObject:[self getSensorName] forKey:@"KEY_UPLOAD_SENSOR_NAME"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ACTION_AWARE_DATA_UPLOAD_PROGRESS"
                                                        object:nil
                                                      userInfo:userInfo];
    
}


- (BOOL)startSensorWithSettings:(NSArray *)settings{
    
    self.beaconManager = [ESTBeaconManager new];
    self.beaconManager.delegate = self;
    // self.beaconManager.avoidUnknownStateBeacons = YES;
    self.beaconManager.returnAllRangedBeaconsAtOnce = YES;
    
    // this is were we left off:
    [self.beaconManager requestAlwaysAuthorization];
    // add this below:
    [self.beaconManager startMonitoringForRegion:[[CLBeaconRegion alloc]
                                                  initWithProximityUUID:[[NSUUID alloc]
                                                                         initWithUUIDString:@"25C422DB-07E9-7283-4B5F-85F2827B33AD"]
                                                  identifier:@"hello"]];
    
    _deviceManager = [ESTDeviceManager new];
    ESTDeviceFilterLocationBeacon *be = [[ESTDeviceFilterLocationBeacon alloc] initWithIdentifier:@"25C422DB-07E9-7283-4B5F-85F2827B33AD"];
     [_deviceManager startDeviceDiscoveryWithFilter:be];
    _deviceManager.delegate = self;
    
    /// tempterature sensor ///
    tempNotif = [[ESTTelemetryNotificationTemperature alloc] initWithNotificationBlock:^(ESTTelemetryInfoTemperature * _Nonnull temperature) {
        [sensorTemperature saveDataWithEstimoteAirpressure:temperature];
    }];
    [_deviceManager registerForTelemetryNotification:tempNotif];
    
    /// motion sensor ///
    motionNotif = [[ESTTelemetryNotificationMotion alloc] initWithNotificationBlock:^(ESTTelemetryInfoMotion * _Nonnull motion) {
        [sensorMotion saveDataWithEstimoteMotion:motion];
    }];
    [_deviceManager registerForTelemetryNotification:motionNotif];
    
    /// air pressure //
    presureNotif = [[ESTTelemetryNotificationPressure alloc] initWithNotificationBlock:^(ESTTelemetryInfoPressure * _Nonnull pressure) {
        [sensorAirPressure saveDataWithEstimoteAirpressure:pressure];
    }];
    [_deviceManager registerForTelemetryNotification:presureNotif];
    
    ///
    ambientLightNotif = [[ESTTelemetryNotificationAmbientLight alloc] initWithNotificationBlock:^(ESTTelemetryInfoAmbientLight * _Nonnull ambientLight) {
        [sensorAmbientLight saveDataWithEstimoteAmbientLight:ambientLight];
    }];
    [_deviceManager registerForTelemetryNotification:ambientLightNotif];
    
    
    return YES;
}

- (BOOL)stopSensor{
    if(tempNotif!=nil)[_deviceManager unregisterForTelemetryNotification:tempNotif];
    if(motionNotif!=nil)[_deviceManager unregisterForTelemetryNotification:motionNotif];
    if(presureNotif!=nil)[_deviceManager unregisterForTelemetryNotification:presureNotif];
    if(ambientLightNotif!=nil)[_deviceManager unregisterForTelemetryNotification:ambientLightNotif];
    // [_deviceManager unregisterForTelemetryNotification:magNotif];
    return YES;
}

- (void)deviceManager:(ESTDeviceManager *)manager
   didDiscoverDevices:(NSArray<ESTDevice *> *)devices{
    if (devices !=nil) {
        for (ESTDevice * device in devices) {
            NSLog(@"[Estimote device] %@\t%@\t%ld",device.identifier, device.peripheralIdentifier, device.rssi);
        }
    }
}

- (void)deviceManagerDidFailDiscovery:(ESTDeviceManager *)manager{
    
}


//////////////////////////////////////////////
-(void)beaconManager:(id)manager didEnterRegion:(CLBeaconRegion *)region{
    NSLog(@"%@",region.debugDescription);
    region.major;
    region.minor;
    region.identifier;
    region.proximityUUID;
    // message
    // [AWAREUtils sendLocalNotificationForMessage:@"didEnterRegion" soundFlag:YES];
    
}

- (void)beaconManager:(id)manager didExitRegion:(CLBeaconRegion *)region{
    NSLog(@"%@",region.debugDescription);
    // message
    // [AWAREUtils sendLocalNotificationForMessage:@"didExitRegion" soundFlag:YES];
}

- (void)beaconManager:(id)manager didRangeBeacons:(nonnull NSArray<CLBeacon *> *)beacons inRegion:(nonnull CLBeaconRegion *)region{
    
    for (CLBeacon * beacon in beacons) {
        switch (beacon.proximity) {
            case CLProximityFar:
                
                break;
            case CLProximityNear:
                
                break;
            case CLProximityUnknown:
                
                break;
            case CLProximityImmediate:
                
                break;
            default:
                break;
        }
    }
    
}

@end
