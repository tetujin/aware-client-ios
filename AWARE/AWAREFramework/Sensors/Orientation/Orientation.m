//
//  Orientation.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 2/22/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "Orientation.h"

@implementation Orientation{
    NSString * KEY_ORIENTATION_TIMESTAMP;
    NSString * KEY_ORIENTATION_DEVICE_ID;
    NSString * KEY_ORIENTATION_STATUS;
    NSString * KEY_ORIENTATION_LABEL;
}

/** Initializer */
- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    self = [super initWithAwareStudy:study
                          sensorName:SENSOR_ORIENTATION
                        dbEntityName:nil
                              dbType:AwareDBTypeTextFile];
    if (self) {
        KEY_ORIENTATION_TIMESTAMP = @"timestamp";
        KEY_ORIENTATION_DEVICE_ID = @"device_id";
        KEY_ORIENTATION_STATUS = @"orientation_status";
        KEY_ORIENTATION_LABEL = @"label";
    }
    return self;
}

- (void) createTable {
    NSMutableString * query = [[NSMutableString alloc] init];
    [query appendString:@"_id integer primary key autoincrement,"];
    [query appendString:[NSString stringWithFormat:@"%@ real default 0,", KEY_ORIENTATION_TIMESTAMP]];
    [query appendString:[NSString stringWithFormat:@"%@ text default '',", KEY_ORIENTATION_DEVICE_ID]];
    [query appendString:[NSString stringWithFormat:@"%@ integer default 0,", KEY_ORIENTATION_STATUS]];
    [query appendString:[NSString stringWithFormat:@"%@ text default '',", KEY_ORIENTATION_LABEL]];
    [query appendString:@"UNIQUE (timestamp,device_id)"];
    [super createTable:query];
}


- (BOOL) startSensor{
    return [self startSensorWithSettings:nil];
}

// Start sensor
- (BOOL)startSensorWithSettings:(NSArray *)settings {
//    [self setBufferSize:5];
    
    // Start and set an orientation monitoring
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationDidChange:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
    return YES;
}

// Stop sensor
- (BOOL)stopSensor{
    [NSNotificationCenter.defaultCenter removeObserver:self
                                                  name:UIDeviceOrientationDidChangeNotification
                                                object:nil];
    return YES;
}


///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

// https://happyteamlabs.com/blog/ios-using-uideviceorientation-to-determine-orientation/

// 0 = UIDeviceOrientationUnknown,
// 1 = UIDeviceOrientationPortrait,            // Device oriented vertically, home button on the bottom
// 2 = UIDeviceOrientationPortraitUpsideDown,  // Device oriented vertically, home button on the top
// 3 = UIDeviceOrientationLandscapeLeft,       // Device oriented horizontally, home button on the right
// 4 = UIDeviceOrientationLandscapeRight,      // Device oriented horizontally, home button on the left
// 5 = UIDeviceOrientationFaceUp,              // Device oriented flat, face up
// 6 = UIDeviceOrientationFaceDown             // Device oriented flat, face down

- (void) orientationDidChange: (id) sender {
    NSNumber * deviceOrientation = @0;
    NSString * label = @"";
    switch ([[UIDevice currentDevice] orientation]) {
        case UIDeviceOrientationUnknown:
            deviceOrientation = @0;
            label = @"unknown";
            break;
        case UIDeviceOrientationPortrait:
            deviceOrientation = @1;
            label = @"portrait";
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            deviceOrientation = @2;
            label = @"portrait_upside_down";
            break;
        case UIDeviceOrientationLandscapeLeft:
            deviceOrientation = @3;
            label = @"land_scape_left";
            break;
        case UIDeviceOrientationLandscapeRight:
            deviceOrientation = @4;
            label = @"land_scape_right";
            break;
        case UIDeviceOrientationFaceUp:
            deviceOrientation = @5;
            label = @"face_up";
            break;
        case UIDeviceOrientationFaceDown:
            deviceOrientation = @6;
            label = @"face_down";
            break;
        default:
            deviceOrientation = @0;
            label = @"unknown";
            break;
    }
    NSMutableDictionary * dic = [[NSMutableDictionary alloc] init];
    [dic setObject:[AWAREUtils getUnixTimestamp:[NSDate new]] forKey:KEY_ORIENTATION_TIMESTAMP];
    [dic setObject:[self getDeviceId] forKey:KEY_ORIENTATION_DEVICE_ID];
    [dic setObject:deviceOrientation forKey:KEY_ORIENTATION_STATUS];
    [dic setObject:label forKey:KEY_ORIENTATION_LABEL];
    [self setLatestValue:label];
    [self saveData:dic];
    
    NSLog(@"%@", label);
}

@end
