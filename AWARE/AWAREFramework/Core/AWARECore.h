//
//  AWARECoreManager.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 6/2/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "AWAREKeys.h"
#import "AWARESensorManager.h"

@interface AWARECore : NSObject <CLLocationManagerDelegate>

// Core Location Manager
@property (strong, nonatomic) CLLocationManager *sharedLocationManager;

// shared AWAREStudy
@property (strong, nonatomic) AWAREStudy* sharedAwareStudy;

// Shared AWARESensorManager
@property (strong, nonatomic) AWARESensorManager * sharedSensorManager;

// Daily Update Timer
@property (strong, nonatomic) NSTimer * dailyUpdateTimer;

- (void) activate;
- (void) deactivate;
- (void) initLocationSensor;
- (void) checkLocationSensorWithViewController:(UIViewController *) viewController;

@end
