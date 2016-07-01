//
//  ActivityRecognition.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/26/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"
#import "AWAREKeys.h"
#import <CoreMotion/CoreMotion.h>

typedef enum: NSInteger {
    ActivityRecognitionModeLive = 0,
    ActivityRecognitionModeHistory = 1
} ActivityRecognitionMode;



@interface ActivityRecognition : AWARESensor <AWARESensorDelegate>


- (BOOL) startSensorWithLiveMode:(CMMotionActivityConfidence) filterLevel;
- (BOOL) startSensorWithHistoryMode:(CMMotionActivityConfidence)filterLevel interval:(double) interval;
- (BOOL) startSensorWithConfidenceFilter:(CMMotionActivityConfidence) filterLevel
                                    mode:(ActivityRecognitionMode)mode
                                interval:(double) interval;

@end
