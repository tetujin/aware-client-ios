//
//  iBeacon.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 7/19/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//
// http://www.appcoda.com/ios7-programming-ibeacons-tutorial/

#import "IBeacon.h"
#import "TCQMaker.h"

@implementation IBeacon

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    self = [super initWithAwareStudy:study
                          sensorName:@"ibeacon"
                        dbEntityName:nil
                              dbType:dbType
                          bufferSize:0];
    if(self != nil){
        // Initialize location manager and set ourselves as the delegate
//        self.locationManager = [[CLLocationManager alloc] init];
//        self.locationManager.delegate = self;
        //[self setCSVHeader:@[@"timestamp",@"device_id"]];
    }
    return self;
}

/////////////////////////////////////////////////////////////////////////

- (void) createTable {
    
}


- (BOOL)startSensorWithSettings:(NSArray *)settings{
    
    // Create a NSUUID object
//    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:@"00000000-3E8D-1001-B000-001C4DE9694B"];
    
    // Setup a new region with that UUID and same identifier as the broadcasting beacon
//    self.myBeaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid
//                                                             identifier:@"jp.ac.keio.sfc.ht.aware"];
    
    // Tell location manager to start monitoring for the beacon region
//    [self.locationManager startMonitoringForRegion:self.myBeaconRegion];
//    [self.locationManager startRangingBeaconsInRegion:self.myBeaconRegion];

    return YES;
}

- (BOOL)stopSensor{
//    [self.locationManager stopMonitoringForRegion:self.myBeaconRegion];
//    [self.locationManager stopRangingBeaconsInRegion:self.myBeaconRegion];
    return YES;
}

////////////////////////////////////////////////////////////////////////

//- (void)locationManager:(CLLocationManager*)manager didEnterRegion:(CLRegion*)region
//{
//    // [self.locationManager startRangingBeaconsInRegion:self.myBeaconRegion];
//}
//
//
//-(void)locationManager:(CLLocationManager*)manager didExitRegion:(CLRegion*)region
//{
//    // [self.locationManager stopRangingBeaconsInRegion:self.myBeaconRegion];
//}
//
//-(void)locationManager:(CLLocationManager*)manager
//       didRangeBeacons:(NSArray*)beacons
//              inRegion:(CLBeaconRegion*)region
//{
//    // Beacon found!
//    // self.statusLabel.text = @"Beacon found!";
//    
//    for (CLBeacon *foundBeacon in beacons) {
//        // You can retrieve the beacon data from its properties
//        NSString *uuid = foundBeacon.proximityUUID.UUIDString;
//        NSString *major = [NSString stringWithFormat:@"%@", foundBeacon.major];
//        NSString *minor = [NSString stringWithFormat:@"%@", foundBeacon.minor];
//        
//        NSString* proximity = @"";
//        switch (foundBeacon.proximity) {
//            case CLProximityUnknown:
//                proximity = @"Unknown";
//                break;
//            case CLProximityImmediate:
//                proximity = @"Immediate";
//                break;
//            case CLProximityNear:
//                proximity = @"Near";
//                break;
//            case CLProximityFar:
//                proximity = @"Far";
//                break;
//            default:
//                break;
//        }
//        double accuracy = foundBeacon.accuracy;
//        NSInteger rssi = foundBeacon.rssi;
//        
//        NSLog(@"UUID:%@, Major:%@, Minor:%@, Proximity:%@, Accuracy:%f, RSSI:%ld",
//              uuid, major, minor, proximity, accuracy, rssi);
//    }
//}


@end
