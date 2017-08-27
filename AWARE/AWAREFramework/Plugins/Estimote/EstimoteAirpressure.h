//
//  EstimoteAirpressure.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 2017/08/24.
//  Copyright © 2017 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"
#import <EstimoteSDK/EstimoteSDK.h>

@interface EstimoteAirpressure : AWARESensor

- (void) saveDataWithEstimoteAirpressure:(ESTTelemetryInfoPressure *)pressure;

@end
