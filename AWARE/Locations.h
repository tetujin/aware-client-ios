//
//  Locations.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/20/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"
#import <CoreLocation/CoreLocation.h>
#import "AWAREStudyManager.h"

@interface Locations : AWARESensor <AWARESensorDelegate, CLLocationManagerDelegate>

@end
