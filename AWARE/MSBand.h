//
//  MSBand.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 12/8/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"
#import "AWARESensorManager.h"
#import <MicrosoftBandKit_iOS/MicrosoftBandKit_iOS.h>

@interface MSBand : AWARESensor <AWARESensorDelegate, MSBClientManagerDelegate >

@property (nonatomic, weak) MSBClient *client;

@end
