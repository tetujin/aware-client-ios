//----------------------------------------------------------------
//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//
//----------------------------------------------------------------

#import "MSBSensorData.h"

@interface MSBSensorAltimeterData : MSBSensorData

/**
 * Total gain in cm
 */
@property (nonatomic, readonly) NSUInteger totalGain;

/**
 * Total loss in cm
 */
@property (nonatomic, readonly) NSUInteger totalLoss;

/**
 * Gain by stepping in cm
 */
@property (nonatomic, readonly) NSUInteger steppingGain;

/**
 * Loss by stepping in cm
 */
@property (nonatomic, readonly) NSUInteger steppingLoss;

/**
 * Total steps ascended count
 */
@property (nonatomic, readonly) NSUInteger stepsAscended;

/**
 * Total steps descended count
 */
@property (nonatomic, readonly) NSUInteger stepsDescended;

/**
 * Climb/Descend rate in cm/s
 */
@property (nonatomic, readonly) float rate;

/**
 * Total flights ascended count
 */
@property (nonatomic, readonly) NSUInteger flightsAscended;

/**
 * Total flights descended count
 */
@property (nonatomic, readonly) NSUInteger flightsDescended;

@end
