//
//  FusedLocations.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 1/18/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//
#import "FusedLocations.h"

@implementation FusedLocations {
    NSTimer *locationDataUploadTimer;
    NSTimer *visitDataUploadTimer;
    NSTimer *locationTimer;
    IBOutlet CLLocationManager *locationManager;
    
    AWARESensor * fusedLocationsSensor;
    AWARESensor * visitLocationSensor;
}

- (instancetype)initWithSensorName:(NSString *)sensorName{
    self = [super initWithSensorName:@"google_fused_location"];
    if (self) {
//        [super setSensorName:@"google_fused_location"];
    }
    return self;
}



- (BOOL)startSensor:(double)upInterval withSettings:(NSArray *)settings {

    fusedLocationsSensor = [[AWARESensor alloc] initWithSensorName:@"locations"];
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
    locationDataUploadTimer = [NSTimer scheduledTimerWithTimeInterval:upInterval
                                                               target:self
                                                             selector:@selector(syncAwareDBWithLocationTable)
                                                             userInfo:nil
                                                              repeats:YES];
    
    
    visitLocationSensor = [[AWARESensor alloc] initWithSensorName:@"locations_visit"];
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
    visitDataUploadTimer = [NSTimer scheduledTimerWithTimeInterval:upInterval
                                                         target:self
                                                       selector:@selector(syncAwareDBWithLocationVisitTable)
                                                        userInfo:nil
                                                         repeats:YES];
    
    
    // frequency
    double interval = 0;
    double frequency = [self getSensorSetting:settings withKey:@"frequency_google_fused_location"];
    if(frequency != -1){
        NSLog(@"Location sensing requency is %f ", frequency);
        interval = frequency;
    }

//    value	__NSCFString *	@"max_frequency_google_fused_location"	0x000000013c6195f0

    
    // One of the following numbers: 100 (High accuracy); 102 (balanced); 104 (low power); 105 (no power, listens to others location requests)
    //min gps
//    double miniDistrance = 25; //[self getSensorSetting:settings withKey:@"min_gps_accuracy"];
    NSInteger accuracySetting = 0;
    int accuracy = [self getSensorSetting:settings withKey:@"accuracy_google_fused_location"];
    if (accuracy == 100) { // High accuracy
        accuracySetting = kCLLocationAccuracyBestForNavigation;
    } else if (accuracy == 102) { //balanced
        accuracySetting = kCLLocationAccuracyHundredMeters;
    } else if (accuracy == 104) { //low power
        accuracySetting = kCLLocationAccuracyKilometer;
    } else if (accuracy == 105) { //no power
        accuracySetting = kCLLocationAccuracyThreeKilometers;
    } else {
        accuracySetting = kCLLocationAccuracyHundredMeters;
    }
    // [memo]
    // http://stackoverflow.com/questions/3411629/decoding-the-cllocationaccuracy-consts
//    GPS - kCLLocationAccuracyBestForNavigation;
//    GPS - kCLLocationAccuracyBest;
//    GPS - kCLLocationAccuracyNearestTenMeters;
//    WiFi (or GPS in rural area) - kCLLocationAccuracyHundredMeters;
//    Cell Tower - kCLLocationAccuracyKilometer;
//    Cell Tower - kCLLocationAccuracyThreeKilometers;
    
    
    if (nil == locationManager){
        locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        locationManager.desiredAccuracy = accuracySetting;
        locationManager.pausesLocationUpdatesAutomatically = NO;
        CGFloat currentVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
        NSLog(@"OS:%f", currentVersion);
        if (currentVersion >= 9.0) {
            //This variable is an important method for background sensing after iOS9
            locationManager.allowsBackgroundLocationUpdates = YES;
        }
        locationManager.activityType = CLActivityTypeOther;
        if ([locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
            [locationManager requestAlwaysAuthorization];
        }
        // Set a movement threshold for new events.
//        locationManager.distanceFilter = miniDistrance;
//        locationManager.distanceFilter = 250;
        [locationManager startUpdatingLocation];
        [locationManager startUpdatingHeading];
        [locationManager startMonitoringVisits]; // This method calls didVisit.
        //    [_locationManager startMonitoringVisits];
        
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


- (void) syncAwareDBWithLocationTable {
    [fusedLocationsSensor syncAwareDB];
}

- (void) syncAwareDBWithLocationVisitTable {
    [visitLocationSensor syncAwareDB];
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
    
    if (locationDataUploadTimer != nil) {
        [locationDataUploadTimer invalidate];
        locationDataUploadTimer = nil;
    }
    
    if(visitDataUploadTimer != nil){
        [visitDataUploadTimer invalidate];
        visitDataUploadTimer = nil;
    }
    
    return YES;
}




- (void) getGpsData: (NSTimer *) theTimer {
    //[sdManager addLocation:[_locationManager location]];
    CLLocation* location = [locationManager location];
    [self saveLocation:location];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
    if (newHeading.headingAccuracy < 0)
        return;
    //    CLLocationDirection  theHeading = ((newHeading.trueHeading > 0) ?
    //                                       newHeading.trueHeading : newHeading.magneticHeading);
    //    [sdManager addSensorDataMagx:newHeading.x magy:newHeading.y magz:newHeading.z];
    //    [sdManager addHeading: theHeading];
}


- (void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations{
    for (CLLocation* location in locations) {
        [self saveLocation:location];
    }
}

- (void) saveLocation:(CLLocation *)location{
//    double timeStamp = [[NSDate date] timeIntervalSince1970] * 1000;
//    NSNumber* unixtime = [NSNumber numberWithLong:timeStamp];
    NSNumber *unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setObject:unixtime forKey:@"timestamp"];
    [dic setObject:[self getDeviceId] forKey:@"device_id"];
    [dic setObject:[NSNumber numberWithDouble:location.coordinate.latitude] forKey:@"double_latitude"];
    [dic setObject:[NSNumber numberWithDouble:location.coordinate.longitude] forKey:@"double_longitude"];
    [dic setObject:[NSNumber numberWithDouble:location.course] forKey:@"double_bearing"];
    [dic setObject:[NSNumber numberWithDouble:location.speed] forKey:@"double_speed"];
    [dic setObject:[NSNumber numberWithDouble:location.altitude] forKey:@"double_altitude"];
    [dic setObject:@"fused" forKey:@"provider"];
    [dic setObject:[NSNumber numberWithInt:location.verticalAccuracy] forKey:@"accuracy"];
    [dic setObject:@"" forKey:@"label"];
    [self setLatestValue:[NSString stringWithFormat:@"%f, %f, %f", location.coordinate.latitude, location.coordinate.longitude, location.speed]];
    [fusedLocationsSensor saveData:dic];
}




- (void)locationManager:(CLLocationManager *)manager
               didVisit:(CLVisit *)visit {

    CLGeocoder *ceo = [[CLGeocoder alloc]init];
    CLLocation *loc = [[CLLocation alloc]initWithLatitude:visit.coordinate.latitude longitude:visit.coordinate.longitude]; //insert your coordinates
    [ceo reverseGeocodeLocation:loc
              completionHandler:^(NSArray *placemarks, NSError *error) {
                  CLPlacemark * placemark = nil;
                  NSMutableDictionary * visitDic = [[NSMutableDictionary alloc] init];
                  if (placemarks.count > 0) {
                      placemark = [placemarks objectAtIndex:0];
                      NSString *address = [[placemark.addressDictionary valueForKey:@"FormattedAddressLines"] componentsJoinedByString:@", "];
                      [self setLatestValue:address];
                      NSString* visitMsg = [NSString stringWithFormat:@"I am currently at %@", address];
                      NSLog( @"%@", visitMsg );
                      if (placemark.name != nil) {
                          [visitDic setObject:placemark.name forKey:@"name"];
                          if ([self getDebugState]) {
                              [AWAREUtils sendLocalNotificationForMessage:visitMsg soundFlag:YES];
                          }
                      }else{
                          
                          [visitDic setObject:@"" forKey:@"name"];
                      }
                      
                      if(address != nil){
                          [visitDic setObject:address forKey:@"address"];
                      }else{
                          [visitDic setObject:@"" forKey:@"address"];
                      }
                  }else{
                      [visitDic setObject:@"" forKey:@"address"];
                      [visitDic setObject:@"" forKey:@"name"];
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
                  
                  
                  [visitDic setObject:timestamp forKey:@"timestamp"];
                  [visitDic setObject:[self getDeviceId] forKey:@"device_id"];
                  [visitDic setObject:[NSNumber numberWithDouble:visit.coordinate.latitude] forKey:@"double_latitude"];
                  [visitDic setObject:[NSNumber numberWithDouble:visit.coordinate.longitude] forKey:@"double_longitude"];
                  [visitDic setObject:depature forKey:@"double_departure"];
                  [visitDic setObject:arrival forKey:@"double_arrival"];
                  [visitDic setObject:@"fused" forKey:@"provider"];
                  [visitDic setObject:[NSNumber numberWithDouble:visit.horizontalAccuracy] forKey:@"accuracy"];
                  [visitDic setObject:@"" forKey:@"label"];
                  
                  [visitLocationSensor saveData:visitDic];
                  
                  return;
    }];
}

- (BOOL)syncAwareDBInForeground{
    if(![visitLocationSensor syncAwareDBInForeground]){
        return NO;
    }
    if(![fusedLocationsSensor syncAwareDBInForeground]){
        return NO;
    }
    return YES;
}

- (NSString *) getSyncProgressAsText{
    return [self getSyncProgressAsText:@"locations"];
}


@end
