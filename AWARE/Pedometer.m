//
//  Steps.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 1/31/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//
// http://pinkstone.co.uk/how-to-access-the-step-counter-and-pedometer-data-in-ios-9/
//

#import "Pedometer.h"
#import "AWAREKeys.h"

@implementation Pedometer{
//    NSTimer * timer;
    NSString* KEY_DEVICE_ID;
    NSString* KEY_TIMESTAMP;
    NSString* KEY_NUMBER_OF_STEPS;
    NSString* KEY_DISTANCE;
    NSString* KEY_CURRENT_PACE;
    NSString* KEY_CURRENT_CADENCE;
    NSString* KEY_FLOORS_ASCENDED;
    NSString* KEY_FLOORS_DESCENDED;
    
    NSNumber * totalSteps;
    NSNumber * totalDistance;
    NSNumber * totalFloorsAscended;
    NSNumber * totalFllorsDescended;
    
    NSDate * lastUpdate;
}

- (instancetype)initWithSensorName:(NSString *)sensorName withAwareStudy:(AWAREStudy *)study{
    self = [super initWithSensorName:SENSOR_PLUGIN_PEDOMETER withAwareStudy:study];
    if (self) {
        KEY_DEVICE_ID = @"device_id";
        KEY_TIMESTAMP =@"timestamp";
        KEY_NUMBER_OF_STEPS = @"number_of_steps";
        KEY_DISTANCE = @"distance";
        KEY_CURRENT_PACE = @"current_pace";
        KEY_CURRENT_CADENCE = @"current_cadence";
        KEY_FLOORS_ASCENDED = @"floors_ascended";
        KEY_FLOORS_DESCENDED = @"floors_descended";
        totalSteps = @0;
        totalDistance = @0;
        totalFloorsAscended = @0;
        totalFllorsDescended = @0;
    }
    return self;
}


- (void) createTable{
    NSMutableString *query = [[NSMutableString alloc] init];
    [query appendString:@"_id integer primary key autoincrement,"];
    [query appendFormat:@"%@ real default 0,", KEY_TIMESTAMP];
    [query appendFormat:@"%@ text default '',", KEY_DEVICE_ID];
    [query appendFormat:@"%@ integer default 0,", KEY_NUMBER_OF_STEPS];
    [query appendFormat:@"%@ integer default 0,", KEY_DISTANCE];
    [query appendFormat:@"%@ real default 0,", KEY_CURRENT_PACE];
    [query appendFormat:@"%@ real default 0,", KEY_CURRENT_CADENCE];
    [query appendFormat:@"%@ integer default 0,", KEY_FLOORS_ASCENDED];
    [query appendFormat:@"%@ integer default 0,", KEY_FLOORS_DESCENDED];
    [query appendString:@"UNIQUE (timestamp,device_id)"];
    [super createTable:query];
}


- (BOOL)startSensor:(double)upInterval withSettings:(NSArray *)settings{
    // Send a table create query
    NSLog(@"[%@] create table!", [self getSensorName]);
    [self createTable];
    
    // Start a data uploader
//    timer = [NSTimer scheduledTimerWithTimeInterval:upInterval
//                                             target:self
//                                           selector:@selector(syncAwareDB)
//                                           userInfo:nil
//                                            repeats:YES];
    
    // Check a pedometer sensor
    if (![CMPedometer isStepCountingAvailable]) {
        NSLog(@"[%@] Your device is not support this sensor.", [self getSensorName]);
        return NO;
    }else{
        NSLog(@"[%@] start sensor!", [self getSensorName]);
    }
    
    // Initialize a pedometer sensor
    if (!_pedometer) {
        _pedometer = [[CMPedometer alloc]init];
    }
    
    // Start live tracking
    [_pedometer startPedometerUpdatesFromDate:[NSDate new]
                                  withHandler:^(CMPedometerData * _Nullable pedometerData, NSError * _Nullable error) {
            NSNumber * numberOfSteps = @0;
            NSNumber * distance = @0;
            NSNumber * currentPace = @0;
            NSNumber * currentCadence = @0;
            NSNumber * floorsAscended = @0;
            NSNumber * floorsDescended = @0;
            
            // step counting
            if ([CMPedometer isStepCountingAvailable]) {
                if (!pedometerData.numberOfSteps) {
                    numberOfSteps = @0;
                }else{
                    numberOfSteps = [NSNumber numberWithInteger:(pedometerData.numberOfSteps.integerValue - totalSteps.integerValue)];
                    totalSteps = pedometerData.numberOfSteps;
                }
            } else {
                NSLog(@"Step Counter not available.");
            }
            
            // distance (m)
            if ([CMPedometer isDistanceAvailable]) {
                if (!pedometerData.distance) {
                    distance = @0;
                }else{
                    distance = [NSNumber numberWithDouble:(pedometerData.distance.doubleValue - totalDistance.doubleValue)];
                    totalDistance = pedometerData.distance;
                }
            } else {
                NSLog(@"Distance estimate not available.");
            }
            
            // pace (s/m)
            if ([CMPedometer isPaceAvailable] && pedometerData.currentPace) {
                currentPace = pedometerData.currentPace;
                if (! currentPace) currentPace = @0;
            } else {
                NSLog(@"Pace not available.");
            }
            
            // cadence (steps/second)
            if ([CMPedometer isCadenceAvailable] && pedometerData.currentCadence) {
                currentCadence = pedometerData.currentCadence;
                if(!currentCadence) currentCadence = @0;
            } else {
                NSLog(@"Cadence not available.");
            }
            
            // flights climbed
            if ([CMPedometer isFloorCountingAvailable] && pedometerData.floorsAscended) {
                floorsAscended = [NSNumber numberWithInteger:(pedometerData.floorsAscended.integerValue - totalFloorsAscended.integerValue)];
                totalFloorsAscended = pedometerData.floorsAscended;
            } else {
                NSLog(@"Floors ascended not available.");
            }
            
            // floors descended
            if ([CMPedometer isFloorCountingAvailable] && pedometerData.floorsDescended) {
                floorsDescended =  [NSNumber numberWithInteger:(pedometerData.floorsDescended.integerValue - totalFllorsDescended.integerValue)];
                totalFllorsDescended = pedometerData.floorsDescended;
            } else {
                NSLog(@"Floors descended not available.");
            }

            NSMutableDictionary * dic = [[NSMutableDictionary alloc] init];
            [dic setObject:[self getDeviceId] forKey:KEY_DEVICE_ID];
            [dic setObject:[AWAREUtils getUnixTimestamp:[NSDate new]] forKey:KEY_TIMESTAMP];
            [dic setObject:numberOfSteps forKey:KEY_NUMBER_OF_STEPS];
            [dic setObject:distance forKey:KEY_DISTANCE];
            [dic setObject:currentPace forKey:KEY_CURRENT_PACE];
            [dic setObject:currentCadence forKey:KEY_CURRENT_CADENCE];
            [dic setObject:floorsAscended forKey:KEY_FLOORS_ASCENDED];
            [dic setObject:floorsDescended forKey:KEY_FLOORS_DESCENDED];
            
            [self saveData:dic];
            
            NSString * message = [NSString stringWithFormat:@"%@(%@) %@(%@) %@ %@ %@(%@) %@(%@)", numberOfSteps, totalSteps, distance, totalDistance, currentPace, currentCadence, floorsAscended,totalFloorsAscended, floorsDescended, totalFllorsDescended];
            // [self sendLocalNotificationForMessage:message soundFlag:NO];
            [self setLatestValue:[NSString stringWithFormat:@"%@", message]];
    }];
    return NO;
}

- (BOOL)stopSensor{
    // stop live tracking
//    if (timer != nil) {
//        [timer invalidate];
//        timer = nil;
//    }
    [_pedometer stopPedometerUpdates];
    _pedometer = nil;
    return NO;
}

@end
