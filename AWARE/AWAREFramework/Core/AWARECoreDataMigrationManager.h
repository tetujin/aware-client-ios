//
//  AWARECoreDataMigrationManager.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 7/23/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface AWARECoreDataMigrationManager : NSObject <CLLocationManagerDelegate>

@property (strong, nonatomic) CLLocationManager *locationManager;

- (void)activate;
- (void)deactivate;

@end
