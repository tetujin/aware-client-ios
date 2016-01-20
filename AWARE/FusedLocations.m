//
//  FusedLocations.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 1/18/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//
#import "FusedLocations.h"

@implementation FusedLocations {
    NSTimer *uploadTimer;
    NSTimer *locationTimer;
    IBOutlet CLLocationManager *locationManager;
}

- (instancetype)initWithSensorName:(NSString *)sensorName{
    self = [super initWithSensorName:@"locations"];
    if (self) {
        [super setSensorName:@"locations"];
    }
    return self;
}


- (void) createTable{
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
    NSLog(@"[%@] Create Table", [self getSensorName]);
    [self createTable];
    
    NSLog(@"[%@] Start Location Sensor!", [self getSensorName]);
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
    
    uploadTimer = [NSTimer scheduledTimerWithTimeInterval:upInterval target:self selector:@selector(syncAwareDB) userInfo:nil repeats:YES];
    
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
    double timeStamp = [[NSDate date] timeIntervalSince1970] * 1000;
    NSNumber* unixtime = [NSNumber numberWithLong:timeStamp];
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
    [self saveData:dic];
}


- (BOOL)stopSensor{
    [locationManager stopUpdatingHeading];
    [locationManager stopUpdatingLocation];
    [uploadTimer invalidate];
    uploadTimer = nil;
    if (locationTimer != nil) {
        [locationTimer invalidate];
        locationTimer = nil;
    }
    return YES;
}

@end
