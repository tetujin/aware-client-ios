//
//  MSBand.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 12/8/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWAREPlugin.h"
#import <MicrosoftBandKit_iOS/MicrosoftBandKit_iOS.h>

@interface MSBand : AWAREPlugin <MSBClientManagerDelegate >

@property (nonatomic, weak) MSBClient *client;

@end
