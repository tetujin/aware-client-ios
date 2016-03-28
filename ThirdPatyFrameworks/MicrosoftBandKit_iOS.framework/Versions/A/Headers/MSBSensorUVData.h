//----------------------------------------------------------------
//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//
//----------------------------------------------------------------

#import "MSBSensorData.h"

typedef NS_ENUM(NSUInteger, MSBSensorUVIndexLevel)
{
    MSBSensorUVIndexLevelNone,
    MSBSensorUVIndexLevelLow,
    MSBSensorUVIndexLevelMedium,
    MSBSensorUVIndexLevelHigh,
    MSBSensorUVIndexLevelVeryHigh
};

@interface MSBSensorUVData : MSBSensorData

@property (nonatomic, readonly) MSBSensorUVIndexLevel uvIndexLevel;

@end
