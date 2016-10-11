//
//  MSBand.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 12/8/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWAREPlugin.h"
#import <MicrosoftBandKit_iOS/MicrosoftBandKit_iOS.h>

extern NSString * const AWARE_PREFERENCES_STATUS_MSBAND;
extern NSString * const AWARE_PREFERENCES_MSBAND_INTERVAL_TIME_MIN;
extern NSString * const AWARE_PREFERENCES_MSBAND_ACTIVE_TIME_MIN;

@interface MSBand : AWAREPlugin <MSBClientManagerDelegate >

@property (nonatomic, weak) MSBClient *client;

@end
