//
//  MSBandRRInterval.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 7/13/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"
#import <MicrosoftBandKit_iOS/MicrosoftBandKit_iOS.h>

@interface MSBandRRInterval : AWARESensor <AWARESensorDelegate, MSBClientManagerDelegate>

@property (nonatomic, weak) MSBClient *client;

- (instancetype)initWithMSBClient:(MSBClient *)msbClient
                       awareStudy:(AWAREStudy *)study
                       sensorName:(NSString*) name
                     dbEntityName:(NSString *)entity
                           dbType:(AwareDBType)dbType
                       bufferSize:(int)buffer;
- (void) requestHRUserConsent;

@end
