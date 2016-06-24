//
//  Locations.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/20/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"
#import <CoreLocation/CoreLocation.h>
#import "AWAREKeys.h"

@interface Locations : AWARESensor <AWARESensorDelegate, CLLocationManagerDelegate>

- (BOOL) startSensor;
- (BOOL) startSensorWithInterval:(double)interval;
- (BOOL) startSensorWithAccuracy:(double)accuracyMeter;
- (BOOL) startSensorWithInterval:(double)interval accuracy:(double)accuracyMeter;


@end
