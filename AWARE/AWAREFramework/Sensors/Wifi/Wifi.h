//
//  Wifi.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/20/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"
#import "AWAREKeys.h"
#import <SystemConfiguration/CaptiveNetwork.h>
#import <NetworkExtension/NetworkExtension.h>

@interface Wifi : AWARESensor <AWARESensorDelegate>

- (BOOL)startSensor;
- (BOOL)startSensorWithInterval:(double) interval;

@end
