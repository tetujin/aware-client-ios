//
//  Locations.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/20/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "Locations.h"

@implementation Locations{
    NSTimer *locationTimer;
    IBOutlet CLLocationManager *locationManager;
}

- (instancetype)initWithSensorName:(NSString *)sensorName withAwareStudy:(AWAREStudy *)study{
    self = [super initWithSensorName:@"locations" withAwareStudy:study];
    if (self) {
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



- (BOOL)startSensor:(double)upInterval withSettings:(NSArray *)settings {
    
    // Get a sensing frequency from settings
    double interval = 0;
    double frequency = [self getSensorSetting:settings withKey:@"frequency_gps"];
    if(frequency != -1){
        NSLog(@"Sensing requency is %f ", frequency);
        interval = frequency;
    }
    
    // Get a min gps accuracy from settings
    double minAccuracy = [self getSensorSetting:settings withKey:@"min_gps_accuracy"];
    if (minAccuracy) {
        NSLog(@"Mini GSP accuracy is %f", minAccuracy);
    }else{
        minAccuracy = 25;
    }
    
    // Set and start a location sensor with the senseing frequency and min GPS accuracy
    NSLog(@"[%@] Start Location Sensor!", [self getSensorName]);
    if (nil == locationManager){
        locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        //    locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        locationManager.pausesLocationUpdatesAutomatically = NO;
        CGFloat currentVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
        NSLog(@"OS:%f", currentVersion);
        if (currentVersion >= 9.0) {
             //This variable is an important method for background sensing after iOS9
            locationManager.allowsBackgroundLocationUpdates = YES;
        }
        locationManager.activityType = CLActivityTypeFitness;
        if ([locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
            [locationManager requestAlwaysAuthorization];
        }
        // Set a movement threshold for new events.
        locationManager.distanceFilter = minAccuracy; // meter
        // [locationManager startUpdatingHeading];
        // [_locationManager startMonitoringVisits]; // This method calls didVisit.
        
        if(interval > 0){
            locationTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                             target:self
                                                           selector:@selector(getGpsData:)
                                                           userInfo:nil
                                                            repeats:YES];
        }else{
            [locationManager startUpdatingLocation];
            [self setBufferSize:10];
        }
    }
    return YES;
}


- (BOOL)stopSensor{
    // Stop a sync timer
//    [uploadTimer invalidate];
//    uploadTimer = nil;
    
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


//- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
//    if (newHeading.headingAccuracy < 0)
//        return;
////    CLLocationDirection  theHeading = ((newHeading.trueHeading > 0) ?
////                                       newHeading.trueHeading : newHeading.magneticHeading);
////    [sdManager addSensorDataMagx:newHeading.x magy:newHeading.y magz:newHeading.z];
////    [sdManager addHeading: theHeading];
//}


- (void) saveLocation:(CLLocation *)location{
    NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setObject:unixtime forKey:@"timestamp"];
    [dic setObject:[self getDeviceId] forKey:@"device_id"];
    [dic setObject:[NSNumber numberWithDouble:location.coordinate.latitude] forKey:@"double_latitude"];
    [dic setObject:[NSNumber numberWithDouble:location.coordinate.longitude] forKey:@"double_longitude"];
    [dic setObject:[NSNumber numberWithDouble:location.course] forKey:@"double_bearing"];
    [dic setObject:[NSNumber numberWithDouble:location.speed] forKey:@"double_speed"];
    [dic setObject:[NSNumber numberWithDouble:location.altitude] forKey:@"double_altitude"];
    [dic setObject:@"gps" forKey:@"provider"];
    [dic setObject:[NSNumber numberWithInt:location.verticalAccuracy] forKey:@"accuracy"];
    [dic setObject:@"" forKey:@"label"];
    [self setLatestValue:[NSString stringWithFormat:@"%f, %f, %f", location.coordinate.latitude, location.coordinate.longitude, location.speed]];
    [self saveData:dic toLocalFile:@"locations"];
}




@end
