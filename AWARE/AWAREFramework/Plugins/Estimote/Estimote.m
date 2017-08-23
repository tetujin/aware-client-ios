//
//  Estimote.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 2017/08/23.
//  Copyright © 2017 Yuuki NISHIYAMA. All rights reserved.
//

#import "Estimote.h"

@implementation Estimote{
    ESTTelemetryNotificationTemperature  * tempNotif;
    ESTTelemetryNotificationMotion       * motionNotif;
    ESTTelemetryNotificationPressure     * presureNotif;
    ESTTelemetryNotificationAmbientLight * ambientLightNotif;
    ESTTelemetryNotificationMagnetometer * magNotif;
    ESTTelemetryNotificationSystemStatus * systemNotif;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    
    // self = [super initWithAwareStudy:study dbType:AwareDBTypeCoreData];
    self = [super initWithAwareStudy:study
                          sensorName:@""
                        dbEntityName:@""
                              dbType:AwareDBTypeCoreData];
    if(self != nil){
        
    }
    return self;
}

- (void)createTable {
    TCQMaker * maker = [[TCQMaker alloc] init];
    [maker addColumn:@"estimote_id" type:TCQTypeText default:@""];
    [maker addColumn:@"estimote_appearance" type:TCQTypeText default:@""];
    [maker addColumn:@"estimote_battery" type:TCQTypeReal default:@"0"];
    [maker addColumn:@"temperature" type:TCQTypeReal default:@"0"];
    [maker addColumn:@"ambient_light" type:TCQTypeReal default:@"0"];
    [maker addColumn:@"magnetometer" type:TCQTypeReal default:@"0"];
    [maker addColumn:@"pressure" type:TCQTypeReal default:@"0"];
    [maker addColumn:@"is_moving" type:TCQTypeText default:@""];
    
    // [super createTable:[maker getDefaudltTableCreateQuery]];
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
                                                                         initWithUUIDString:@"B9407F30-F5F8-466E-AFF9-25556B57FE6D"]
                                                  major:1 minor:47072 identifier:@"monitored region"]];
    
    
    _deviceManager = [ESTDeviceManager new];
    ESTDeviceFilterLocationBeacon *be = [[ESTDeviceFilterLocationBeacon alloc] initWithIdentifier:@"de396be57fbbdd39539a41fad4e1ce2c"];
    [_deviceManager startDeviceDiscoveryWithFilter:be];
    _deviceManager.delegate = self;
    
    /// tempterature sensor ///
    tempNotif = [[ESTTelemetryNotificationTemperature alloc] initWithNotificationBlock:^(ESTTelemetryInfoTemperature * _Nonnull temperature) {
        if(temperature != nil){
            NSLog(@"[temp] %@",temperature.debugDescription);
        }
    }];
    [_deviceManager registerForTelemetryNotification:tempNotif];
    
    /// motion sensor ///
    motionNotif = [[ESTTelemetryNotificationMotion alloc] initWithNotificationBlock:^(ESTTelemetryInfoMotion * _Nonnull motion) {
            NSLog(@"[motion] %@", motion.debugDescription);
    }];
    [_deviceManager registerForTelemetryNotification:motionNotif];
    
    /// air pressure //
    presureNotif = [[ESTTelemetryNotificationPressure alloc] initWithNotificationBlock:^(ESTTelemetryInfoPressure * _Nonnull pressure) {
        NSLog(@"[air pressure] %@", pressure.debugDescription);
    }];
    [_deviceManager registerForTelemetryNotification:presureNotif];
    
    ///
    ambientLightNotif = [[ESTTelemetryNotificationAmbientLight alloc] initWithNotificationBlock:^(ESTTelemetryInfoAmbientLight * _Nonnull ambientLight) {
        NSLog(@"[ambient light] %@", ambientLight.debugDescription);
    }];
    [_deviceManager registerForTelemetryNotification:ambientLightNotif];
    
    ///
    magNotif = [[ESTTelemetryNotificationMagnetometer alloc] initWithNotificationBlock:^(ESTTelemetryInfoMagnetometer * _Nonnull magnetometer) {
        NSLog(@"[mag] %@", magnetometer.debugDescription);
    }];
    [_deviceManager registerForTelemetryNotification:magNotif];
    
    systemNotif = [[ESTTelemetryNotificationSystemStatus alloc] initWithNotificationBlock:^(ESTTelemetryInfoSystemStatus * _Nonnull systemStatus) {
        NSLog(@"[system] %@", systemStatus.batteryVoltageInMillivolts);
    }];
    [_deviceManager registerForTelemetryNotification:systemNotif];
    
    return YES;
}

- (BOOL)stopSensor{
    [_deviceManager unregisterForTelemetryNotification:tempNotif];
    [_deviceManager unregisterForTelemetryNotification:motionNotif];
    [_deviceManager unregisterForTelemetryNotification:presureNotif];
    [_deviceManager unregisterForTelemetryNotification:ambientLightNotif];
    [_deviceManager unregisterForTelemetryNotification:magNotif];
    [_deviceManager unregisterForTelemetryNotification:systemNotif];
    return YES;
}


- (void)deviceManager:(ESTDeviceManager *)manager
   didDiscoverDevices:(NSArray<ESTDevice *> *)devices{
    
}

- (void)deviceManagerDidFailDiscovery:(ESTDeviceManager *)manager{
    
}

//////////////////////////////////////////////
-(void)beaconManager:(id)manager didEnterRegion:(CLBeaconRegion *)region{
    NSLog(@"%@",region.debugDescription);
    
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
