//
//  FusedLocations.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 1/18/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//
#import "FusedLocations.h"
#import "AppDelegate.h"
#import "EntityLocation.h"
#import "EntityLocationVisit.h"

@implementation FusedLocations {
    NSTimer *locationTimer;
    IBOutlet CLLocationManager *locationManager;
    
    AWARESensor * fusedLocationsSensor;
    AWARESensor * visitLocationSensor;
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
        fusedLocationsSensor = [[AWARESensor alloc] initWithAwareStudy:awareStudy
                                                            sensorName:@"locations"
                                                          dbEntityName:NSStringFromClass([EntityLocation class])
                                                                dbType:AwareDBTypeCoreData];
        // Make a visit location sensor
        visitLocationSensor = [[AWARESensor alloc] initWithAwareStudy:awareStudy
                                                           sensorName:@"locations_visit"
                                                         dbEntityName:NSStringFromClass([EntityLocation class])
                                                               dbType:AwareDBTypeCoreData];
    }
    return self;
}

- (void)createTable{
    // Send a table create query
    [fusedLocationsSensor createTable:@"_id integer primary key autoincrement,"
     "timestamp real default 0,"
     "device_id text default '',"
     "double_latitude real default 0,"
     "double_longitude real default 0,"
     "double_bearing real default 0,"
     "double_speed real default 0,"
     "double_altitude real default 0,"
     "provider text default '',"
     "accuracy integer default 0,"
     "label text default '',"
     "UNIQUE (timestamp,device_id)"];
    //////////////////////////
    
    // Send a table create query
    [visitLocationSensor createTable:@"_id integer primary key autoincrement,"
     "timestamp real default 0,"
     "device_id text default '',"
     "double_latitude real default 0,"
     "double_longitude real default 0,"
     "double_arrival real default 0,"
     "double_departure real default 0,"
     "address text default '',"
     "name text default '',"
     "provider text default '',"
     "accuracy integer default 0,"
     "label text default '',"
     "UNIQUE (timestamp,device_id)"];
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
        // Set a movement threshold for new events.
        [locationManager startMonitoringVisits]; // This method calls didVisit.
        [locationManager startMonitoringSignificantLocationChanges];
        [fusedLocationsSensor setBufferSize:3];
        // [locationManager startUpdatingHeading];
        
        if(interval > 0){
            locationTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                             target:self
                                                           selector:@selector(getGpsData:)
                                                           userInfo:nil
                                                            repeats:YES];
        }else{
            [locationManager startUpdatingLocation];
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
    NSLog(@"Get a location")
    
    ;
    CLLocation* location = [locationManager location];
    [self saveLocation:location];
}

- (void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations{
    for (CLLocation* location in locations) {
        [self saveLocation:location];
    }
}

- (void) saveLocation:(CLLocation *)location{

    NSNumber *unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
    
    // AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
    EntityLocation * locationData = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([EntityLocation class])
                                                                  inManagedObjectContext:[fusedLocationsSensor getSensorManagedObjectContext]];
    locationData.device_id = [self getDeviceId];
    locationData.timestamp = unixtime;
    locationData.double_latitude = [NSNumber numberWithDouble:location.coordinate.latitude];
    locationData.double_longitude = [NSNumber numberWithDouble:location.coordinate.longitude];
    locationData.double_bearing = [NSNumber numberWithDouble:location.course];
    locationData.double_speed = [NSNumber numberWithDouble:location.speed];
    locationData.double_altitude = [NSNumber numberWithDouble:location.altitude];
    locationData.provider = @"fused";
    locationData.accuracy = [NSNumber numberWithInt:location.verticalAccuracy];
    locationData.label = @"";
    
    [self setLatestValue:[NSString stringWithFormat:@"%f, %f, %f", location.coordinate.latitude, location.coordinate.longitude, location.speed]];
    
    [fusedLocationsSensor saveDataToDB];

    if ([self isDebug]) {
        [AWAREUtils sendLocalNotificationForMessage:[NSString stringWithFormat:@"Location: %f, %f, %f", location.coordinate.latitude, location.coordinate.longitude, location.speed] soundFlag:NO];
    }

}


- (void)locationManager:(CLLocationManager *)manager
               didVisit:(CLVisit *)visit {

    CLGeocoder *ceo = [[CLGeocoder alloc]init];
    CLLocation *loc = [[CLLocation alloc]initWithLatitude:visit.coordinate.latitude longitude:visit.coordinate.longitude]; //insert your coordinates
    [ceo reverseGeocodeLocation:loc
              completionHandler:^(NSArray *placemarks, NSError *error) {
                  CLPlacemark * placemark = nil;
                  // NSMutableDictionary * visitDic = [[NSMutableDictionary alloc] init];
                  NSString * name = @"";
                  NSString * address = @"";
                  if (placemarks.count > 0) {
                      placemark = [placemarks objectAtIndex:0];
                      address = [[placemark.addressDictionary valueForKey:@"FormattedAddressLines"] componentsJoinedByString:@", "];
                      [self setLatestValue:address];
                      NSString* visitMsg = [NSString stringWithFormat:@"I am currently at %@", address];
                      NSLog( @"%@", visitMsg );
                      // Set name
                      if (placemark.name != nil) {
                          //[visitDic setObject:placemark.name forKey:@"name"];
                          name = placemark.name;
                          if ([self isDebug]) {
                              [AWAREUtils sendLocalNotificationForMessage:visitMsg soundFlag:YES];
                          }
                      }
                  }
                  
                  NSNumber * timestamp = [AWAREUtils getUnixTimestamp:[NSDate new]];
                  NSNumber * depature = [AWAREUtils getUnixTimestamp:[visit departureDate]];
                  NSNumber * arrival = [AWAREUtils getUnixTimestamp:[visit arrivalDate]];
                  
                  /*
                   *  arrivalDate
                   *
                   *  Discussion:
                   *    The date when the visit began.  This may be equal to [NSDate
                   *    distantPast] if the true arrival date isn't available.
                   */
                  if([[visit departureDate] isEqualToDate:[NSDate distantPast]]){
                      arrival = @-1;
//                      [self sendLocalNotificationForMessage:[NSString stringWithFormat:@"departure date is %@",[NSDate distantPast]] soundFlag:NO];
                  }
                  
                  /*
                   *  departureDate
                   *
                   *  Discussion:
                   *    The date when the visit ended.  This is equal to [NSDate
                   *    distantFuture] if the device hasn't yet left.
                   */
                  
                  if([[visit arrivalDate] isEqualToDate:[NSDate distantFuture]]){
                      depature = @-1;
//                      [self sendLocalNotificationForMessage:[NSString stringWithFormat:@"departure date is %@",[NSDate distantFuture]] soundFlag:NO];
                  }
                  
                   dispatch_async(dispatch_get_main_queue(), ^{
                      // AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
                      EntityLocationVisit * visitData = (EntityLocationVisit *)[NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([EntityLocationVisit class])
                                                                                                             inManagedObjectContext:[visitLocationSensor getSensorManagedObjectContext]];
                      
                      visitData.device_id = [self getDeviceId];
                      visitData.timestamp = timestamp;
                      visitData.double_latitude = [NSNumber numberWithDouble:visit.coordinate.latitude];
                      visitData.double_longitude = [NSNumber numberWithDouble:visit.coordinate.longitude];
                      visitData.provider = @"fused";
                      visitData.accuracy = [NSNumber numberWithInt:visit.horizontalAccuracy];
                      visitData.address = address;
                      visitData.name = name;
                      visitData.double_arrival = arrival;
                      visitData.double_departure = depature;
                      visitData.label = @"";
                      
                      [visitLocationSensor saveDataToDB];
                   });
                  return;
    }];
}

- (bool)isUploading{
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



//    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
//    [dic setObject:unixtime forKey:@"timestamp"];
//    [dic setObject:[self getDeviceId] forKey:@"device_id"];
//    [dic setObject:[NSNumber numberWithDouble:location.coordinate.latitude] forKey:@"double_latitude"];
//    [dic setObject:[NSNumber numberWithDouble:location.coordinate.longitude] forKey:@"double_longitude"];
//    [dic setObject:[NSNumber numberWithDouble:location.course] forKey:@"double_bearing"];
//    [dic setObject:[NSNumber numberWithDouble:location.speed] forKey:@"double_speed"];
//    [dic setObject:[NSNumber numberWithDouble:location.altitude] forKey:@"double_altitude"];
//    [dic setObject:@"fused" forKey:@"provider"];
//    [dic setObject:[NSNumber numberWithInt:location.verticalAccuracy] forKey:@"accuracy"];
//    [dic setObject:@"" forKey:@"label"];
//    [self setLatestValue:[NSString stringWithFormat:@"%f, %f, %f", location.coordinate.latitude, location.coordinate.longitude, location.speed]];
//    [fusedLocationsSensor saveData:dic];



@end
