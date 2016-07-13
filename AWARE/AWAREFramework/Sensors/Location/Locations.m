//
//  Locations.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/20/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "Locations.h"
#import "EntityLocation.h"
#import "AppDelegate.h"

@implementation Locations{
    NSTimer *locationTimer;
    IBOutlet CLLocationManager *locationManager;
    double defaultInterval;
    double defaultAccuracy;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study{
    self = [super initWithAwareStudy:study
                          sensorName:@"locations"
                        dbEntityName:NSStringFromClass([EntityLocation class])
                              dbType:AwareDBTypeCoreData];
    if (self) {
        defaultInterval = 180; // 180sec(=3min)
        defaultAccuracy = 250; // 250m
    }
    return self;
}


- (void) createTable{
    // Send a query for creating table
    NSLog(@"[%@] Create Table", [self getSensorName]);
    NSString *query = [[NSString alloc] init];
    query =
        @"_id integer primary key autoincrement,"
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
        "UNIQUE (timestamp,device_id)";
    [super createTable:query];
}



- (BOOL)startSensorWithSettings:(NSArray *)settings {
    
    // Get a sensing frequency from settings
    double interval = defaultInterval;
    double frequency = [self getSensorSetting:settings withKey:@"frequency_gps"];
    if(frequency != -1){
        NSLog(@"Sensing requency is %f ", frequency);
        interval = frequency;
    }
    
    // Get a min gps accuracy from settings
    double minAccuracy = [self getSensorSetting:settings withKey:@"min_gps_accuracy"];
    if ( minAccuracy > 0 ) {
        NSLog(@"Mini GSP accuracy is %f", minAccuracy);
    } else {
        minAccuracy = defaultAccuracy;
    }
    
    [self startSensorWithInterval:0 accuracy:minAccuracy];
    
    return YES;
}


- (BOOL)startSensor{
    return [self startSensorWithInterval:defaultInterval accuracy:defaultAccuracy];
}

- (BOOL)startSensorWithInterval:(double)interval{
    return [self startSensorWithInterval:interval accuracy:defaultAccuracy];
}

- (BOOL)startSensorWithAccuracy:(double)accuracyMeter{
    return [self startSensorWithInterval:defaultInterval accuracy:accuracyMeter];
}

- (BOOL)startSensorWithInterval:(double)interval accuracy:(double)accuracyMeter{
    // Set and start a location sensor with the senseing frequency and min GPS accuracy
    NSLog(@"[%@] Start Location Sensor!", [self getSensorName]);
    
    if (nil == locationManager){
        locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        
        // extern const CLLocationAccuracy kCLLocationAccuracyBestForNavigation
        // extern const CLLocationAccuracy kCLLocationAccuracyBest;
        // extern const CLLocationAccuracy kCLLocationAccuracyNearestTenMeters;
        // extern const CLLocationAccuracy kCLLocationAccuracyHundredMeters;
        // extern const CLLocationAccuracy kCLLocationAccuracyKilometer;
        // extern const CLLocationAccuracy kCLLocationAccuracyThreeKilometers;
        
        if (accuracyMeter == 0) {
            locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
        } else if (accuracyMeter > 0 && accuracyMeter <= 10){
            locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        } else if (accuracyMeter > 10 && accuracyMeter <= 25 ){
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
        } else if (accuracyMeter > 25 && accuracyMeter <= 100 ){
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
        } else if (accuracyMeter > 100 && accuracyMeter <= 1000){
            locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;
        } else if (accuracyMeter > 1000 && accuracyMeter <= 3000){
            locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
        } else {
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
        }
        
        locationManager.pausesLocationUpdatesAutomatically = NO;
        CGFloat currentVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
        NSLog(@"OS:%f", currentVersion);
        if (currentVersion >= 9.0) {
            //This variable is an important method for background sensing after iOS9
            locationManager.allowsBackgroundLocationUpdates = YES;
        }
        if ([locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
            [locationManager requestAlwaysAuthorization];
        }
        // Set a movement threshold for new events.
        locationManager.distanceFilter = accuracyMeter; // meter
        // locationManager.activityType = CLActivityTypeFitness;
        
        // Start Monitoring
        [locationManager startMonitoringSignificantLocationChanges];
        // [locationManager startUpdatingLocation];
        // [locationManager startUpdatingHeading];
        // [_locationManager startMonitoringVisits];
        
        [self getGpsData:nil];
        
        if(interval > 0){
            locationTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                             target:self
                                                           selector:@selector(getGpsData:)
                                                           userInfo:nil
                                                            repeats:YES];
            [self getGpsData:nil];
        }else{
            [locationManager startUpdatingLocation];
        }
        
    }
    return YES;
}


- (BOOL)stopSensor{
    // Stop a sensing timer
    [locationTimer invalidate];
    locationTimer = nil;
    
    // Stop location sensors
    [locationManager stopUpdatingHeading];
    [locationManager stopUpdatingLocation];
    locationManager = nil;
    
    return YES;
}


///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////


- (void) getGpsData: (NSTimer *) theTimer {
    //[sdManager addLocation:[_locationManager location]];
    CLLocation* location = [locationManager location];
    [self saveLocation:location];
}

- (void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations{
    for (CLLocation* location in locations) {
        [self saveLocation:location];
    }
}

- (void) saveLocation:(CLLocation *)location{

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
    [dict setObject:@"gps" forKey:@"provider"];
    [dict setObject:[NSNumber numberWithInt:accuracy] forKey:@"accuracy"];
    [dict setObject:@"" forKey:@"label"];
    [self setLatestValue:[NSString stringWithFormat:@"%f, %f, %f", location.coordinate.latitude, location.coordinate.longitude, location.speed]];
    //[self saveData:dict toLocalFile:@"locations"];
    [self saveData:dict];
    
    [self setLatestValue:[NSString stringWithFormat:@"%f, %f, %f",
                          location.coordinate.latitude,
                          location.coordinate.longitude,
                          location.speed]];
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:dict
                                                         forKey:EXTRA_DATA];
    [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_LOCATIONS
                                                        object:nil
                                                      userInfo:userInfo];
}


- (void)insertNewEntityWithData:(NSDictionary *)data
           managedObjectContext:(NSManagedObjectContext *)childContext
                     entityName:(NSString *)entity{
    
    EntityLocation* entityLocation = (EntityLocation *)[NSEntityDescription
                                              insertNewObjectForEntityForName:entity
                                              inManagedObjectContext:childContext];
    
    entityLocation.device_id = [data objectForKey:@"device_id"];
    entityLocation.timestamp = [data objectForKey:@"timestamp"];
    entityLocation.double_latitude = [data objectForKey:@"double_latitude"];
    entityLocation.double_longitude = [data objectForKey:@"double_longitude"];
    entityLocation.double_bearing = [data objectForKey:@"double_bearing"];
    entityLocation.double_speed = [data objectForKey:@"double_speed"];
    entityLocation.double_altitude = [data objectForKey:@"double_altitude"];
    entityLocation.provider = [data objectForKey:@"provider"];
    entityLocation.accuracy = [data objectForKey:@"accuracy"];
    entityLocation.label = [data objectForKey:@"label"];
    
    
    
}




//- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
//    if (newHeading.headingAccuracy < 0)
//        return;
////    CLLocationDirection  theHeading = ((newHeading.trueHeading > 0) ?
////                                       newHeading.trueHeading : newHeading.magneticHeading);
////    [sdManager addSensorDataMagx:newHeading.x magy:newHeading.y magz:newHeading.z];
////    [sdManager addHeading: theHeading];
//}



@end
