//
//  AWARECoreManager.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 6/2/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARECore.h"
#import "Debug.h"
#import "AWAREStudy.h"

@implementation AWARECore


- (instancetype)init{
    self = [super init];
    if(self != nil){
        _sharedAwareStudy = [[AWAREStudy alloc] initWithReachability:YES];
        _sharedSensorManager = [[AWARESensorManager alloc] initWithAWAREStudy:_sharedAwareStudy];
    }
    return self;
}

/////////////////////////////////////////////////////////
@synthesize sharedSensorManager = _sharedSensorManager;
- (AWARESensorManager *) sharedSensorManager {
//    AWAREStudy * study = [[AWAREStudy alloc] initWithReachability:YES];
    if(_sharedSensorManager == nil){
        _sharedSensorManager = [[AWARESensorManager alloc] initWithAWAREStudy:_sharedAwareStudy];
    }
    return _sharedSensorManager;
}

///////////////////////////////////////////////////
@synthesize sharedAwareStudy = _sharedAwareStudy;
- (AWAREStudy *) sharedAwareStudy{
    if(_sharedAwareStudy == nil){
       _sharedAwareStudy = [[AWAREStudy alloc] initWithReachability:YES];
    }
    return _sharedAwareStudy;
}


- (void) activate {
    /// Set defualt settings
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if (![userDefaults boolForKey:@"aware_inited"]) {
        [userDefaults setBool:NO forKey:SETTING_DEBUG_STATE];                 // Default Value: NO
        [userDefaults setBool:YES forKey:SETTING_SYNC_WIFI_ONLY];             // Default Value: YES
        [userDefaults setBool:YES forKey:SETTING_SYNC_BATTERY_CHARGING_ONLY]; // Default Value: YES
        [userDefaults setDouble:60*15 forKey:SETTING_SYNC_INT];               // Default Value: 60*15 (sec)
        [userDefaults setBool:NO forKey:KEY_APP_TERMINATED];                  // Default Value: NO
        [userDefaults setInteger:0 forKey:KEY_UPLOAD_MARK];                   // Defualt Value: 0
        [userDefaults setInteger:1000 * 100 forKey:KEY_MAX_DATA_SIZE];        // Defualt Value: 1000*100 (byte) (100 KB)
        [userDefaults setInteger:cleanOldDataTypeAlways forKey:SETTING_FREQUENCY_CLEAN_OLD_DATA];
        [userDefaults setBool:YES forKey:@"aware_inited"];
    }
    double uploadInterval = [userDefaults doubleForKey:SETTING_SYNC_INT];
    
    /**
     * Start a location sensor for background sensing.
     * On the iOS, we have to turn on the location sensor
     * for using application in the background.
     */
    
    [self initLocationSensor];
    
    // start sensors
    [_sharedSensorManager startAllSensors];
    [_sharedSensorManager startUploadTimerWithInterval:uploadInterval];
    //    [self.sharedSensorManager syncAllSensorsWithDBInBackground];
    
    /// Set a timer for a daily sync update
    /**
     * Every 2AM, AWARE iOS refresh the joining study in the background.
     * A developer can change the time (2AM to xxxAM/PM) by changing the dailyUpdateTime(NSDate) Object
     */
    NSDate* dailyUpdateTime = [AWAREUtils getTargetNSDate:[NSDate new] hour:2 minute:0 second:0 nextDay:YES]; //2AM
    _dailyUpdateTimer = [[NSTimer alloc] initWithFireDate:dailyUpdateTime
                                                 interval:60*60*24 // daily
                                                   target:_sharedAwareStudy
                                                 selector:@selector(refreshStudy)
                                                 userInfo:nil
                                                  repeats:YES];
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    //    [runLoop addTimer:dailyUpdateTimer forMode:NSDefaultRunLoopMode];
    [runLoop addTimer:_dailyUpdateTimer forMode:NSRunLoopCommonModes];
}


- (void) deactivate{
    [_sharedSensorManager stopAndRemoveAllSensors];
    [_sharedLocationManager stopUpdatingLocation];
    [_dailyUpdateTimer invalidate];
}

/**
 * This method is an initializers for a location sensor.
 * On the iOS, we have to turn on the location sensor
 * for using application in the background.
 * And also, this sensing interval is the most low level.
 */
- (void) initLocationSensor {
    NSLog(@"start location sensing!");
    if ( _sharedLocationManager == nil ) {
        _sharedLocationManager  = [[CLLocationManager alloc] init];
        _sharedLocationManager.delegate = self;
        _sharedLocationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
        _sharedLocationManager.pausesLocationUpdatesAutomatically = NO;
        _sharedLocationManager.activityType = CLActivityTypeOther;

        if ([AWAREUtils getCurrentOSVersionAsFloat] >= 9.0) {
            /// After iOS 9.0, we have to set "YES" for background sensing.
            _sharedLocationManager.allowsBackgroundLocationUpdates = YES;
        }
        if ([_sharedLocationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
            [_sharedLocationManager requestAlwaysAuthorization];
        }
        // Set a movement threshold for new events.
        // _sharedLocationManager.distanceFilter = 200; // meters
        [_sharedLocationManager startUpdatingLocation];
        [_sharedLocationManager startMonitoringSignificantLocationChanges];
    }
}

/**
 * The method is called by location sensor when the device location is changed.
 */
- (void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    bool appTerminated = [userDefaults boolForKey:KEY_APP_TERMINATED];
    if (appTerminated) {
        NSString * message = @"AWARE iOS is rebooted!";
        [AWAREUtils sendLocalNotificationForMessage:message soundFlag:YES];
        Debug * debugSensor = [[Debug alloc] initWithAwareStudy:nil];
        [debugSensor saveDebugEventWithText:message type:DebugTypeInfo label:@""];
        [userDefaults setBool:NO forKey:KEY_APP_TERMINATED];
    }else{
        // [self sendLocalNotificationForMessage:@"" soundFlag:YES];
        // NSLog(@"Base Location Sensor.");
        for (CLLocation * location in locations) {
            NSLog(@"%@",location.description);
        }
    }
}

@end
