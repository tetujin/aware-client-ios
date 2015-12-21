//
//  GoogleCal.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 12/18/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

/**
 * How about save events via Apple Calender
 */

#import "GoogleCal.h"
#import "AWAREKeys.h"

@implementation GoogleCal

- (instancetype)initWithSensorName:(NSString *)sensorName
{
    self = [super initWithSensorName:sensorName];
    if (self) {
        //        [super setSensorName:sensorName];
    }
    return self;
}

@end
