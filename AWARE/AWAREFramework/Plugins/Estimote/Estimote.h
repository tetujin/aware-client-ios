//
//  Estimote.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 2017/08/23.
//  Copyright © 2017 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"
#import "AWAREPlugin.h"
#import <EstimoteSDK/EstimoteSDK.h>

@interface Estimote : AWARESensor <AWARESensorDelegate, ESTDeviceManagerDelegate, ESTBeaconManagerDelegate>

@property (nonatomic) ESTBeaconManager * beaconManager;
@property (nonatomic) ESTDeviceManager * deviceManager;

@end
