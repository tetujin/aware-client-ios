//
//  FusedLocations.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 1/18/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"
#import <CoreLocation/CoreLocation.h>
#import "FusedLocations.h"
#import "AWAREKeys.h"

@interface FusedLocations : AWARESensor <AWARESensorDelegate, CLLocationManagerDelegate>


@end
