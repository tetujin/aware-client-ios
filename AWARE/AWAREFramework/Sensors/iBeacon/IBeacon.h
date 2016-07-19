//
//  iBeacon.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 7/19/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"

#import <CoreLocation/CoreLocation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface IBeacon : AWARESensor <CLLocationManagerDelegate>

@property (strong, nonatomic) CLBeaconRegion *myBeaconRegion;
@property (strong, nonatomic) CLLocationManager *locationManager;

@end
