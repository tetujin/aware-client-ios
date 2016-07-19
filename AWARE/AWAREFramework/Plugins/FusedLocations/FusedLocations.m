//
//  FusedLocations.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 1/18/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//
#import "FusedLocations.h"
#import "Locations.h"
#import "VisitLocations.h"
// #import "AppDelegate.h"
#import "EntityLocation.h"
#import "EntityLocationVisit.h"

@implementation FusedLocations {
    NSTimer *locationTimer;
    IBOutlet CLLocationManager *locationManager;
    
    Locations * fusedLocationsSensor;
    VisitLocations * visitLocationSensor;
    AWAREStudy * awareStudy;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study{
    self = [super initWithAwareStudy:study
                          sensorName:@"google_fused_location"
                        dbEntityName:nil
                              dbType:AwareDBTypeTextFile];
    awareStudy = study;
    if (self) {
        // Make a fused location sensor
        fusedLocationsSensor = [[Locations alloc] initWithAwareStudy:awareStudy];
        
        // Make a visit location sensor
        visitLocationSensor = [[VisitLocations alloc] initWithAwareStudy:awareStudy];
    }
    return self;
}

- (void)createTable{
    // Send a table create query
    [fusedLocationsSensor createTable];
    
    //////////////////////////
    // Send a table create query
    [visitLocationSensor createTable];
}

- (BOOL)startSensorWithSettings:(NSArray *)settings {

    // Get a sensing frequency for a location sensor
    double interval = 0;
    double frequency = [self getSensorSetting:settings withKey:@"frequency_google_fused_location"];
    if(frequency != -1){
        NSLog(@"Location sensing requency is %f ", frequency);
        interval = frequency;
    }
    
    // Initialize a location sensor
    if (locationManager == nil){
        // AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
        locationManager = [[CLLocationManager alloc] init];
        // Get a sensing accuracy for a location sensor
        NSInteger accuracySetting = 0;
        int accuracy = [self getSensorSetting:settings withKey:@"accuracy_google_fused_location"];
        if(accuracy == 100){
            accuracySetting = kCLLocationAccuracyBest;
            locationManager.distanceFilter = kCLDistanceFilterNone;
        }else if (accuracy == 101) { // High accuracy
            accuracySetting = kCLLocationAccuracyNearestTenMeters;
            locationManager.distanceFilter = 10;
        } else if (accuracy == 102) { //balanced
            accuracySetting = kCLLocationAccuracyHundredMeters;
            locationManager.distanceFilter = 100;
        } else if (accuracy == 104) { //low power
            accuracySetting = kCLLocationAccuracyKilometer;
            locationManager.distanceFilter = 1000;
        } else if (accuracy == 105) { //no power
            accuracySetting = kCLLocationAccuracyThreeKilometers;
            locationManager.distanceFilter = 3000;
        } else {
            accuracySetting = kCLLocationAccuracyHundredMeters;
            locationManager.distanceFilter = 100;
        }
        // One of the following numbers: 100 (High accuracy); 102 (balanced); 104 (low power); 105 (no power, listens to others location requests)
        // http://stackoverflow.com/questions/3411629/decoding-the-cllocationaccuracy-consts
        //    GPS - kCLLocationAccuracyBestForNavigation;
        //    GPS - kCLLocationAccuracyBest;
        //    GPS - kCLLocationAccuracyNearestTenMeters;
        //    WiFi (or GPS in rural area) - kCLLocationAccuracyHundredMeters;
        //    Cell Tower - kCLLocationAccuracyKilometer;
        //    Cell Tower - kCLLocationAccuracyThreeKilometers;
        locationManager.delegate = self;
        locationManager.desiredAccuracy = accuracySetting;
        locationManager.pausesLocationUpdatesAutomatically = NO;
        if ([AWAREUtils getCurrentOSVersionAsFloat] >= 9.0) {
        //This variable is an important method for background sensing after iOS9
            locationManager.allowsBackgroundLocationUpdates = YES;
        }
        locationManager.activityType = CLActivityTypeOther;
        if ([locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
            [locationManager requestAlwaysAuthorization];
        }
        
        [fusedLocationsSensor saveAuthorizationStatus:[CLLocationManager authorizationStatus]];
    
        // Set a movement threshold for new events.
        [locationManager startMonitoringVisits]; // This method calls didVisit.
        [locationManager startMonitoringSignificantLocationChanges];
        [locationManager startUpdatingLocation];
        
        // [fusedLocationsSensor setBufferSize:3];
        // [locationManager startUpdatingHeading];
        
        if(interval > 0){
            locationTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                             target:self
                                                           selector:@selector(getGpsData:)
                                                           userInfo:nil
                                                            repeats:YES];
            
        }

    }
    
    return YES;
}


- (BOOL)stopSensor{
    if (locationManager != nil) {
        [locationManager stopUpdatingHeading];
        [locationManager stopUpdatingLocation];
        [locationManager stopMonitoringVisits];
    }
    
    if (locationTimer != nil) {
        [locationTimer invalidate];
        locationTimer = nil;
    }
    
    locationManager = nil;
    
    return YES;
}


- (void) syncAwareDB {
    [fusedLocationsSensor syncAwareDB];
    [visitLocationSensor syncAwareDB];
}

- (void) syncAwareDBWithLocationTable {
    [fusedLocationsSensor syncAwareDB];
}

- (void) syncAwareDBWithLocationVisitTable {
    [visitLocationSensor syncAwareDB];
}

- (BOOL)syncAwareDBInForeground{
    if(![visitLocationSensor syncAwareDBInForeground]){
        return NO;
    }
    if(![fusedLocationsSensor syncAwareDBInForeground]){
        return NO;
    }
    
    [super syncAwareDBInForeground];

    
    return YES;
}

- (NSString *) getSyncProgressAsText{
    return [self getSyncProgressAsText:@"locations"];
}


/////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////



- (void) getGpsData: (NSTimer *) theTimer {
    if([self isDebug]){
        NSLog(@"Get a location");
    }
    CLLocation* location = [locationManager location];
    [self saveLocation:location];
}

- (void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations{
    for (CLLocation* location in locations) {
        [self saveLocation:location];
    }
}

- (void) saveLocation:(CLLocation *)location{

    // save location data by using location sensor
    int accuracy = (location.verticalAccuracy + location.horizontalAccuracy) / 2;
    
    NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:unixtime forKey:@"timestamp"];
    [dict setObject:[self getDeviceId] forKey:@"device_id"];
    [dict setObject:[NSNumber numberWithDouble:location.coordinate.latitude] forKey:@"double_latitude"];
    [dict setObject:[NSNumber numberWithDouble:location.coordinate.longitude] forKey:@"double_longitude"];
    [dict setObject:[NSNumber numberWithDouble:location.course] forKey:@"double_bearing"];
    [dict setObject:[NSNumber numberWithDouble:location.speed] forKey:@"double_speed"];
    [dict setObject:[NSNumber numberWithDouble:location.altitude] forKey:@"double_altitude"];
    [dict setObject:@"fused" forKey:@"provider"];
    [dict setObject:[NSNumber numberWithInt:accuracy] forKey:@"accuracy"];
    [dict setObject:@"" forKey:@"label"];
    [fusedLocationsSensor saveData:dict];
    
    [self setLatestValue:[NSString stringWithFormat:@"%f, %f, %f",
                          location.coordinate.latitude,
                          location.coordinate.longitude,
                          location.speed]];
    
    if ([self isDebug]) {
        [AWAREUtils sendLocalNotificationForMessage:[NSString stringWithFormat:@"Location: %f, %f, %f",
                                                     location.coordinate.latitude,
                                                     location.coordinate.longitude,
                                                     location.speed]
                                          soundFlag:NO];
    }
}


- (void)locationManager:(CLLocationManager *)manager
               didVisit:(CLVisit *)visit {

    [visitLocationSensor locationManager:manager didVisit:visit];
    
}


- (bool)isUploading:(CLAuthorizationStatus ) state{
    if([fusedLocationsSensor isUploading] || [visitLocationSensor isUploading]){
        return YES;
    }else{
        return NO;
    }
}

//- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
//    if (newHeading.headingAccuracy < 0)
//        return;
//    //    CLLocationDirection  theHeading = ((newHeading.trueHeading > 0) ?
//    //                                       newHeading.trueHeading : newHeading.magneticHeading);
//    //    [sdManager addSensorDataMagx:newHeading.x magy:newHeading.y magz:newHeading.z];
//    //    [sdManager addHeading: theHeading];
//}


- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    [fusedLocationsSensor saveAuthorizationStatus:status];
}

@end
