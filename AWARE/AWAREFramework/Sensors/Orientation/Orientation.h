//
//  Orientation.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 2/22/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"

@interface Orientation : AWARESensor <AWARESensorDelegate>

- (BOOL) startSensor;

@end
