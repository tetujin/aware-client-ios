//
//  WeatherData.m
//  VQR
//
//  Created by Yuuki Nishiyama on 2014/12/02.
//  Copyright (c) 2014年 tetujin. All rights reserved.
//

#import "OpenWeather.h"

@implementation OpenWeather
/** api */
NSString* OPEN_WEATHER_API = @"http://api.openweathermap.org/data/2.5/weather?lat=%d&lon=%d&APPID=54e5dee2e6a2479e0cc963cf20f233cc";
/** sys */
NSString* KEY_SYS         = @"sys";
NSString* ELE_COUNTORY    = @"country";
/** weather */
NSString* KEY_WEATHER     = @"weather";
NSString* ELE_MAIN        = @"main";
NSString* ELE_DESCRIPTION = @"description";
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
NSString* ELE_3H          = @"3h";
/** clouds */
NSString* KEY_CLOUDS      = @"clouds";
NSString* ELE_ALL         = @"all";
/** city */
NSString* KEY_NAME        = @"name";

NSString* ZERO            = @"0";

    
int ONE_HOUR = 60*60;

- (id) init
{
    self = [super init];
    if (self) {
        return [self initWithDate:[NSDate date] Lat:0 Lon:0];
    }
    return self;
}

- (id) initWithDate:(NSDate *) date
               Lat:(double)lat
               Lon:(double)lon
{
    [self updateWeatherData:date Lat:lat Lon:lon];
    return self;
}


- (BOOL)startSensor:(double)upInterval withSettings:(NSArray *)settings{
//    NSLog(@"Start Blutooth sensing");
//    uploadTimer = [NSTimer scheduledTimerWithTimeInterval:upInterval target:self selector:@selector(uploadSensorData) userInfo:nil repeats:YES];
    return YES;
}

- (BOOL)stopSensor{
//    [uploadTimer invalidate];
    return YES;
}

- (void)uploadSensorData{
//    NSString * jsonStr = [self getData:SENSOR_BLUETOOTH withJsonArrayFormat:YES];
//    [self insertSensorData:jsonStr withDeviceId:[self getDeviceId] url:[self getInsertUrl:SENSOR_BLUETOOTH]];
}



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
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperationWithBlock:^{
        //Get an access token from API
        NSString *url = [NSString stringWithFormat:OPEN_WEATHER_API, (int)lat, (int)lon];
        
        //Create a request to get weather data
        NSMutableURLRequest *request;
        request = [[NSMutableURLRequest alloc] init];
        [request setHTTPMethod:@"GET"];
        [request setURL:[NSURL URLWithString:url]];
        [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
        [request setTimeoutInterval:20];
        [request setHTTPShouldHandleCookies:FALSE];
        //[request setHTTPBody:[param dataUsingEncoding:NSUTF8StringEncoding]];
        
        // HTTP/GET
        NSURLResponse *response = nil;
        NSError *error = nil;
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        if (error != nil) {
            NSLog(@"Error!");
            NSLog(@"%@",[error description]);
            return;
        }else{
            NSLog(@"Got Weather Information from API!");
        }
        
        NSError *e = nil;
        jsonWeatherData = [NSJSONSerialization JSONObjectWithData:data
                                                          options:NSJSONReadingAllowFragments
                                                            error:&e];
        //NSLog([jsonWeatherData description]);
        //NSLog(jsonWeatherData.description);
        //weatherState = true;
        //return dict;
        //[NSJSONSerialization JSON
    }];
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
    return [[[jsonWeatherData valueForKey:KEY_WEATHER] objectAtIndex:0] valueForKey:ELE_MAIN];
}

- (NSString *) getWeatherDescription
{
     return [[[jsonWeatherData valueForKey:KEY_WEATHER] objectAtIndex:0] valueForKey:ELE_DESCRIPTION];
}

- (NSString *) getTemp
{
   // NSLog(@"--> %@", [self convertKelToCel:[[jsonWeatherData valueForKey:KEY_MAIN] valueForKey:ELE_TEMP]]);
    return [self convertKelToCel:[[jsonWeatherData valueForKey:KEY_MAIN] valueForKey:ELE_TEMP]];
}

- (NSString *) getTempMax
{
    return [self convertKelToCel:[[jsonWeatherData valueForKey:KEY_MAIN] valueForKey:ELE_TEMP_MAX]];
}

- (NSString *) getTempMin
{
    return [self convertKelToCel:[[jsonWeatherData valueForKey:KEY_MAIN] valueForKey:ELE_TEMP_MIN]];
}

- (NSString *) getHumidity
{
    //NSLog(@"--> %@",  [[jsonWeatherData valueForKey:KEY_MAIN] valueForKey:ELE_HUMIDITY]);
    return [[jsonWeatherData valueForKey:KEY_MAIN] valueForKey:ELE_HUMIDITY];
}

- (NSString *) getPressure
{
    return [[jsonWeatherData valueForKey:KEY_MAIN] valueForKey:ELE_PRESSURE];
}

- (NSString *) getWindSpeed
{
    return [[jsonWeatherData valueForKey:KEY_WIND] valueForKey:ELE_SPEED];
}

- (NSString *) getWindDeg
{
    return [[jsonWeatherData valueForKey:KEY_WIND] valueForKey:ELE_DEG];
}

- (NSString *) getRain
{
    return [[jsonWeatherData valueForKey:KEY_RAIN] valueForKey:ELE_3H];
}

- (NSString *) getClouds
{
    return [[jsonWeatherData valueForKey:KEY_CLOUDS] valueForKey:ELE_ALL];
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
    NSTimeInterval delta = [now timeIntervalSinceDate:thisDate]; // => 例えば 500.0 秒後
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
