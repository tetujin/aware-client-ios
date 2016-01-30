//
//  WeatherData.m
//  VQR
//
//  Created by Yuuki Nishiyama on 2014/12/02.
//  Copyright (c) 2014年 tetujin. All rights reserved.
//

#import "OpenWeather.h"
#import "AWAREKeys.h"

@implementation OpenWeather{
    IBOutlet CLLocationManager *locationManager;
    NSTimer* syncTimer;
    NSTimer* sensingTimer;
    NSDictionary* jsonWeatherData;
    NSDate* thisDate;
    double thisLat;
    double thisLon;
    NSString* identificationForOpenWeather;
}
/** api */
NSString* OPEN_WEATHER_API = @"http://api.openweathermap.org/data/2.5/weather?lat=%d&lon=%d&APPID=54e5dee2e6a2479e0cc963cf20f233cc";
/** sys */
NSString* KEY_SYS         = @"sys";
NSString* ELE_COUNTORY    = @"country";
NSString* ELE_SUNSET      = @"sunset";
NSString* ELE_SUNRISE      = @"sunrise";

/** weather */
NSString* KEY_WEATHER     = @"weather";
NSString* ELE_MAIN        = @"main";
NSString* ELE_DESCRIPTION = @"description";
NSString* ELE_ICON        = @"icon";

/** main */
NSString* KEY_MAIN        = @"main";
NSString* ELE_TEMP        = @"temp";
NSString* ELE_TEMP_MAX    = @"temp_max";
NSString* ELE_TEMP_MIN    = @"temp_min";
NSString* ELE_HUMIDITY    = @"humidity";
NSString* ELE_PRESSURE    = @"pressure";
/** wind */
NSString* KEY_WIND        = @"wind";
NSString* ELE_SPEED       = @"speed";
NSString* ELE_DEG         = @"deg";
/** rain */
NSString* KEY_RAIN        = @"rain";
NSString* KEY_SNOW        = @"snow";
NSString* ELE_3H          = @"3h";
/** clouds */
NSString* KEY_CLOUDS      = @"clouds";
NSString* ELE_ALL         = @"all";
/** city */
NSString* KEY_NAME        = @"name";

NSString* ZERO            = @"0";
    
int ONE_HOUR = 60*60;

//- (instancetype) initWithDate:(NSDate *) date
//               Lat:(double)lat
//               Lon:(double)lon
//{
//    locationManager = nil;
//    [self updateWeatherData:date Lat:0 Lon:0];
//    return self;
//}

- (instancetype) initWithSensorName:(NSString *)sensorName {
    self = [super initWithSensorName:SENSOR_PLUGIN_OPEN_WEATHER];
    if (self) {
        locationManager = nil;
        NSDate *date = [NSDate new];
        identificationForOpenWeather = @"http_for_open_weather_";
        [self updateWeatherData:date Lat:0 Lon:0];
    }
    return self;
}


- (BOOL)startSensor:(double)upInterval withSettings:(NSArray *)settings{
    NSLog(@"Start Open Weather Map");
    [self createTable];
    [self initLocationSensor];
    syncTimer = [NSTimer scheduledTimerWithTimeInterval:upInterval
                                                 target:self selector:@selector(syncAwareDB)
                                               userInfo:nil
                                                repeats:YES];
    sensingTimer = [NSTimer scheduledTimerWithTimeInterval:ONE_HOUR
                                                    target:self
                                                  selector:@selector(getNewWeatherData)
                                                  userInfo:nil
                                                   repeats:YES];
    [self getNewWeatherData];
    return YES;
}

- (BOOL)stopSensor{
    [syncTimer invalidate];
    [sensingTimer invalidate];
    return YES;
}

- (void) createTable{
    NSString *query = [[NSString alloc] init];
    query =
    @"_id integer primary key autoincrement,"
    "timestamp real default 0,"
    "device_id text default '',"
    "city text default '',"
    "temperature real default 0,"
    "temperature_max real default 0,"
    "temperature_min real default 0,"
    "unit text default '',"
    "humidity real default 0,"
    "pressure real default 0,"
    "wind_speed real default 0,"
    "wind_degrees real default 0,"
    "cloudiness real default 0,"
    "weather_icon_id default 0,"
    "rain real default 0,"
    "snow real default 0,"
    "sunrise real default 0,"
    "sunset real default 0,"
    "UNIQUE (timestamp,device_id)";
    [super createTable:query];
}

- (void) initLocationSensor {
//    NSLog(@"start location sensing!");
    if (locationManager == nil){
        locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        // locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
        locationManager.pausesLocationUpdatesAutomatically = NO;
        CGFloat currentVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
        NSLog(@"OS:%f", currentVersion);
        if (currentVersion >= 9.0) {
            locationManager.allowsBackgroundLocationUpdates = YES; //This variable is an important method for background sensing
        }
        locationManager.activityType = CLActivityTypeOther;
        if ([locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
            [locationManager requestAlwaysAuthorization];
        }
        // Set a movement threshold for new events.
        locationManager.distanceFilter = 300; // meters
        [locationManager startUpdatingLocation];
        //    [_locationManager startMonitoringVisits]; // This method calls didVisit.
        [locationManager startUpdatingHeading];
    }
}

- (void) getNewWeatherData {
    //[sdManager addLocation:[_locationManager location]];
    CLLocation* location = [locationManager location];
    NSDate *now = [NSDate new];
    [self updateWeatherData:now
                        Lat:location.coordinate.latitude
                        Lon:location.coordinate.longitude];
}

//- (void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations{
//    for (CLLocation* location in locations) {
//        //        [self saveLocation:location];
//        NSDate *now = [NSDate new];
//        [self updateWeatherData:now
//                            Lat:location.coordinate.latitude
//                            Lon:location.coordinate.longitude];
//    }
//}

//- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
//    if (newHeading.headingAccuracy < 0)
//        return;
//    //    CLLocationDirection  theHeading = ((newHeading.trueHeading > 0) ?
//    //                                       newHeading.trueHeading : newHeading.magneticHeading);
//    //    [sdManager addSensorDataMagx:newHeading.x magy:newHeading.y magz:newHeading.z];
//    //    [sdManager addHeading: theHeading];
//}




//- (void) saveLocation:(CLLocation *)location{
////    NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
////    NSNumber* unixtime = [NSNumber numberWithDouble:timeStamp];
////    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
////    [dic setObject:unixtime forKey:@"timestamp"];
////    [dic setObject:[self getDeviceId] forKey:@"device_id"];
////    [dic setObject:[NSNumber numberWithDouble:location.coordinate.latitude] forKey:@"double_latitude"];
////    [dic setObject:[NSNumber numberWithDouble:location.coordinate.longitude] forKey:@"double_longitude"];
////    [dic setObject:[NSNumber numberWithDouble:location.course] forKey:@"double_bearing"];
////    [dic setObject:[NSNumber numberWithDouble:location.speed] forKey:@"double_speed"];
////    [dic setObject:[NSNumber numberWithDouble:location.altitude] forKey:@"double_altitude"];
////    [dic setObject:@"gps" forKey:@"provider"];
////    [dic setObject:[NSNumber numberWithInt:location.verticalAccuracy] forKey:@"accuracy"];
////    [dic setObject:@"" forKey:@"label"];
////    [self setLatestValue:[NSString stringWithFormat:@"%f, %f, %f", location.coordinate.latitude, location.coordinate.longitude, location.speed]];
////    [self saveData:dic toLocalFile:@"locations"];
//}


- (void)updateWeatherData:(NSDate *)date Lat:(double)lat Lon:(double)lon
{
    thisDate = date;
    thisLat = lat;
    thisLon = lon;
    if( lat !=0  &&  lon != 0){
        [self getWeatherJSONStr:lat lon:lon];
    }
}

- (void) getWeatherJSONStr:(double)lat
                             lon:(double)lon{
    NSMutableURLRequest *request = nil;
    __weak NSURLSession *session = nil;
    NSString *postLength = nil;
    
    // Set settion configu and HTTP/POST body.
    NSURLSessionConfiguration *sessionConfig = nil;
    
    identificationForOpenWeather = [NSString stringWithFormat:@"%@%f", identificationForOpenWeather, [[NSDate new] timeIntervalSince1970]];
    sessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:identificationForOpenWeather];
    sessionConfig.timeoutIntervalForRequest = 180.0;
    sessionConfig.timeoutIntervalForResource = 60.0;
    sessionConfig.HTTPMaximumConnectionsPerHost = 60;
    sessionConfig.allowsCellularAccess = YES;
    sessionConfig.discretionary = YES;
    
    NSString *url = [NSString stringWithFormat:OPEN_WEATHER_API, (int)lat, (int)lon];
    request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"GET"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    
    // set HTTP/POST body information
    NSLog(@"--- [%@] This is background task ----", [self getSensorName] );
    session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];
    NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request];
    [dataTask resume];

}



- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    
    [session finishTasksAndInvalidate];
    [session invalidateAndCancel];
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
    int responseCode = (int)[httpResponse statusCode];
    if (responseCode == 200) {
        NSLog(@"[%@] Got Weather Information from API!", [self getSensorName]);
    }

    completionHandler(NSURLSessionResponseAllow);
}


-(void)URLSession:(NSURLSession *)session
         dataTask:(NSURLSessionDataTask *)dataTask
   didReceiveData:(NSData *)data {
    if(data != nil){
        NSError *e = nil;
        jsonWeatherData = [NSJSONSerialization JSONObjectWithData:data
                                                          options:NSJSONReadingAllowFragments
                                                            error:&e];
        
        // NSLog(@"%@", jsonWeatherData);
        if ( jsonWeatherData == nil) {
            NSLog( @"%@", e.debugDescription );
//            [self sendLocalNotificationForMessage:e.debugDescription soundFlag:YES];
            return;
        };
        
//        [self sendLocalNotificationForMessage:@"Get Weather Information" soundFlag:YES];
        
        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
//        double timeStamp = [[NSDate date] timeIntervalSince1970] * 1000;
//        NSNumber* unixtime = [NSNumber numberWithLong:timeStamp];
        NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
        [dic setObject:unixtime forKey:@"timestamp"];
        [dic setObject:[self getDeviceId] forKey:@"device_id"];
        [dic setObject:[self getName] forKey:@"city"];
        [dic setObject:[self getTemp] forKey:@"temperature"];
        [dic setObject:[self getTempMax] forKey:@"temperature_max"];
        [dic setObject:[self getTempMax] forKey:@"temperature_min"];
        [dic setObject:@"" forKey:@"unit"];
        [dic setObject:[self getHumidity] forKey:@"humidity"];
        [dic setObject:[self getPressure] forKey:@"pressure"];
        [dic setObject:[self getWindSpeed] forKey:@"wind_speed"];
        [dic setObject:[self getWindDeg] forKey:@"wind_degrees"];
        [dic setObject:[self getClouds] forKey:@"cloudiness"];
        [dic setObject:[self getWeatherIcon] forKey:@"weather_icon_id"];
        [dic setObject:[self getWeatherDescription] forKey:@"weather_description"];
        [dic setObject:[self getRain] forKey:@"rain"];
        [dic setObject:[self getSnow] forKey:@"snow"];
        [dic setObject:[self getSunRise] forKey:@"sunrise"];
        [dic setObject:[self getSunSet] forKey:@"sunset"];

        dispatch_async(dispatch_get_main_queue(), ^{
            [self setLatestValue:[NSString stringWithFormat:@"%@: %@", [self getWeather], [self getWeatherDescription]]];
            [self saveData:dic];
        });
    }

    [session finishTasksAndInvalidate];
    [session invalidateAndCancel];
}


- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    [session finishTasksAndInvalidate];
    [session invalidateAndCancel];
    
    
}


- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error{
    if (error != nil) {
        NSLog(@"[%@] the session did become invaild with error: %@", [self getSensorName], error.debugDescription);
    }
    [session invalidateAndCancel];
    [session finishTasksAndInvalidate];
}



- (NSString *) getCountry
{
    NSString* value = [[jsonWeatherData valueForKey:KEY_SYS] valueForKey:ELE_COUNTORY];
    if(value != nil){
        return value;
    }else{
        return @"0";
    }
}

- (NSString *) getWeather
{
    NSString *value = [[[jsonWeatherData valueForKey:KEY_WEATHER] objectAtIndex:0] valueForKey:ELE_MAIN];
    if (value != nil) {
        return value;
    }else{
        return @"0";
    }
}


- (NSString *) getWeatherIcon
{
    NSString * value = [[[jsonWeatherData valueForKey:KEY_WEATHER] objectAtIndex:0] valueForKey:ELE_ICON];
    if(value != nil){
        return  value;
    }else{
        return @"0";
    }
}

- (NSString *) getWeatherDescription
{
    NSString * value= [[[jsonWeatherData valueForKey:KEY_WEATHER] objectAtIndex:0] valueForKey:ELE_DESCRIPTION];
    if(value != nil){
        return  value;
    }else{
        return @"0";
    }
}

- (NSNumber *) getTemp
{
   // NSLog(@"--> %@", [self convertKelToCel:[[jsonWeatherData valueForKey:KEY_MAIN] valueForKey:ELE_TEMP]]);
    double temp = [[[jsonWeatherData valueForKey:KEY_MAIN] objectForKey:ELE_TEMP] doubleValue];
    return [NSNumber numberWithDouble:temp];
}

- (NSNumber *) getTempMax
{
    double maxTemp = [[[jsonWeatherData valueForKey:KEY_MAIN] objectForKey:ELE_TEMP_MAX] doubleValue];
    return [NSNumber numberWithDouble:maxTemp];
//    return [self convertKelToCel:[[jsonWeatherData valueForKey:KEY_MAIN] valueForKey:ELE_TEMP_MAX]];
}

- (NSNumber *) getTempMin
{
    double minTemp = [[[jsonWeatherData valueForKey:KEY_MAIN] objectForKey:ELE_TEMP_MIN] doubleValue];
    return [NSNumber numberWithDouble:minTemp];
//    return [self convertKelToCel:[[jsonWeatherData valueForKey:KEY_MAIN] valueForKey:ELE_TEMP_MIN]];
}

- (NSNumber *) getHumidity
{
    //NSLog(@"--> %@",  [[jsonWeatherData valueForKey:KEY_MAIN] valueForKey:ELE_HUMIDITY]);
    double humidity = [[[jsonWeatherData valueForKey:KEY_MAIN] objectForKey:ELE_HUMIDITY] doubleValue];
    return [NSNumber numberWithDouble:humidity];
//    return [[jsonWeatherData valueForKey:KEY_MAIN] valueForKey:ELE_HUMIDITY];
}

- (NSNumber *) getPressure
{
    double pressure = [[[jsonWeatherData valueForKey:KEY_MAIN] objectForKey:ELE_PRESSURE] doubleValue];
    return [NSNumber numberWithDouble:pressure];
//    return [[jsonWeatherData valueForKey:KEY_MAIN] valueForKey:ELE_PRESSURE];
}

- (NSNumber *) getWindSpeed
{
    double windSpeed = [[[jsonWeatherData valueForKey:KEY_WIND] objectForKey:ELE_SPEED] doubleValue];
    return [NSNumber numberWithDouble:windSpeed];
//    return [[jsonWeatherData valueForKey:KEY_WIND] valueForKey:ELE_SPEED];
}

- (NSNumber *) getWindDeg
{
    double windDeg = [[[jsonWeatherData valueForKey:KEY_WIND] objectForKey:ELE_DEG] doubleValue];
    return [NSNumber numberWithDouble:windDeg];
//    return [[jsonWeatherData valueForKey:KEY_WIND] valueForKey:ELE_DEG];
}

- (NSNumber *) getRain
{
    double rain =  [[[jsonWeatherData valueForKey:KEY_RAIN] objectForKey:ELE_3H] doubleValue];
    return [NSNumber numberWithDouble:rain];
//    return [[jsonWeatherData valueForKey:KEY_RAIN] valueForKey:ELE_3H];
}

- (NSNumber *) getSnow
{
    double snow =  [[[jsonWeatherData valueForKey:KEY_SNOW] objectForKey:ELE_3H] doubleValue];
    return [NSNumber numberWithDouble:snow];
//    return [[jsonWeatherData valueForKey:KEY_RAIN] valueForKey:ELE_3H];
}

- (NSNumber *) getClouds
{
    double cloudiness = [[[jsonWeatherData valueForKey:KEY_CLOUDS] objectForKey:ELE_ALL] doubleValue];
    return [NSNumber numberWithDouble:cloudiness];
//    return [[jsonWeatherData valueForKey:KEY_CLOUDS] valueForKey:ELE_ALL];
}


- (NSNumber *) getSunRise
{
    double value = [[[jsonWeatherData valueForKey:KEY_SYS] valueForKey:ELE_SUNRISE] doubleValue];
    return [NSNumber numberWithDouble:value];
}

- (NSNumber *) getSunSet
{
    double value = [[[jsonWeatherData valueForKey:KEY_SYS] valueForKey:ELE_SUNSET] doubleValue];
    return [NSNumber numberWithDouble:value];
}


- (NSString *) getName
{
    return [jsonWeatherData valueForKey:KEY_NAME];
}

- (NSString *) convertKelToCel:(NSString *) kelStr
{
    //return kelStr;
    if(kelStr != nil){
        float kel = kelStr.floatValue;
        return [NSString stringWithFormat:@"%f",(kel-273.15)];
    }else{
        return nil;
    }
}

- (bool) isNotNil
{
    if(jsonWeatherData==nil){
        return false;
    }else{
        return true;
    }
}

- (bool) isNil
{
    if(jsonWeatherData==nil){
        return true;
    }else{
        return false;
    }
}

- (bool) isOld:(int)gap
{
    NSDate *now = [NSDate date];
    NSTimeInterval delta = [now timeIntervalSinceDate:thisDate];
    if(delta > gap){
        return true;
    }else{
        return false;
    }
}

- (NSString *)description
{
    return [jsonWeatherData description];
}

@end
