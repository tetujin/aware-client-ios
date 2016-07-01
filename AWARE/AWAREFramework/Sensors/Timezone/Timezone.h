//
//  Timezone.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 12/14/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"

@interface Timezone : AWARESensor <AWARESensorDelegate>

- (BOOL) startSensor;
- (BOOL) startSensorWithInterval:(double)interval;

@end
