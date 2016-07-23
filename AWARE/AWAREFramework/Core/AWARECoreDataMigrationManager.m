//
//  AWARECoreDataMigrationManager.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 7/23/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARECoreDataMigrationManager.h"
#import "AppDelegate.h"
#import "AWARECore.h"

@implementation AWARECoreDataMigrationManager{
    // AWARECore * awareCore;
    BOOL isMirgrating;
}

- (instancetype)init{
    self = [super init];
    if(self != nil){
        isMirgrating = NO;
    }
    return self;
}

- (void) activate {
    [self initLocationSensor];
}


- (void) deactivate{
    [_locationManager stopUpdatingLocation];
}

/**
 * This method is an initializers for a location sensor.
 * On the iOS, we have to turn on the location sensor
 * for using application in the background.
 * And also, this sensing interval is the most low level.
 */
- (void) initLocationSensor {
    NSLog(@"start location sensing!");
    if ( _locationManager == nil ) {
        _locationManager  = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        _locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
        _locationManager.pausesLocationUpdatesAutomatically = NO;
        _locationManager.activityType = CLActivityTypeOther;
        
        if ([AWAREUtils getCurrentOSVersionAsFloat] >= 9.0) {
            /// After iOS 9.0, we have to set "YES" for background sensing.
            _locationManager.allowsBackgroundLocationUpdates = YES;
        }
        if ([_locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
            [_locationManager requestAlwaysAuthorization];
        }
        // Set a movement threshold for new events.
        // _locationManager.distanceFilter = ; // meters
        [_locationManager startUpdatingLocation];
        [_locationManager startMonitoringSignificantLocationChanges];
    }
}

/**
 * The method is called by location sensor when the device location is changed.
 */
- (void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations{
    
    NSLog(@"Base Location Sensor.");
    dispatch_async(dispatch_get_main_queue(), ^{
        if(!isMirgrating){
            isMirgrating = YES;
            
            AppDelegate * delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
            
            if(delegate.sharedAWARECore == nil){
                delegate.sharedAWARECore = [[AWARECore alloc] init];
                [delegate.sharedAWARECore activate];
                [delegate.sharedAWARECore.sharedSensorManager startAllSensors];
            }
            
            [self deactivate];
        }
    });
    
//    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
//    bool appTerminated = [userDefaults boolForKey:KEY_APP_TERMINATED];
//    if (appTerminated) {
//        NSString * message = @"AWARE client iOS is rebooted";
//        [AWAREUtils sendLocalNotificationForMessage:message soundFlag:YES];
//        // Debug * debugSensor = [[Debug alloc] initWithAwareStudy:_sharedAwareStudy dbType:AwareDBTypeCoreData];
//        // [debugSensor saveDebugEventWithText:message type:DebugTypeInfo label:@""];
//        // [userDefaults setBool:NO forKey:KEY_APP_TERMINATED];
//    }else{
//        // [self sendLocalNotificationForMessage:@"" soundFlag:YES];
//        // NSLog(@"Base Location Sensor.");
//        //        if ([userDefaults boolForKey: SETTING_DEBUG_STATE]) {
//        //            for (CLLocation * location in locations) {
//        //                NSLog(@"%@",location.description);
//        //
//        //            }
//        //        }
//    }
    
}

@end
