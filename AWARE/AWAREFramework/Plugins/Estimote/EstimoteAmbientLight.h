//
//  EstimoteAmbientLight.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 2017/08/24.
//  Copyright © 2017 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"
#import <EstimoteSDK/EstimoteSDK.h>

@interface EstimoteAmbientLight : AWARESensor

- (void) saveDataWithEstimoteAmbientLight:(ESTTelemetryInfoAmbientLight *)ambientLight;

@end
