//
//  WeatherData.h
//  VQR
//
//  Created by Yuuki Nishiyama on 2014/12/02.
//  Copyright (c) 2014年 tetujin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OpenWeather : NSObject{
//    NSString* deviceOrientation;
//    NSString* proximity;
    NSDictionary* jsonWeatherData;
    NSDate* thisDate;
    double thisLat;
    double thisLon;
    //bool weatherState;
}

- (id) initWithDate:(NSDate *)date Lat:(double)lat Lon:(double)lon;
- (void) updateWeatherData:(NSDate *)date Lat:(double)lat Lon:(double)lon;
- (bool) isNotNil;
- (bool) isNil;
- (bool) isOld:(int)gap;
- (NSString *) getCountry;
- (NSString *) getWeather;
- (NSString *) getWeatherDescription;
- (NSString *) getTemp;
- (NSString *) getTempMax;
- (NSString *) getTempMin;
- (NSString *) getHumidity;
- (NSString *) getPressure;
- (NSString *) getWindSpeed;
- (NSString *) getWindDeg;
- (NSString *) getRain;
- (NSString *) getClouds;
- (NSString *) getName;
- (NSString *) description;

@end
