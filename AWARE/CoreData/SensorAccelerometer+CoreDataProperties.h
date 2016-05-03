//
//  SensorAccelerometer+CoreDataProperties.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 5/1/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "SensorAccelerometer.h"

NS_ASSUME_NONNULL_BEGIN

@interface SensorAccelerometer (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *timestamp;
@property (nullable, nonatomic, retain) NSString *device_id;
@property (nullable, nonatomic, retain) NSNumber *double_values_0;
@property (nullable, nonatomic, retain) NSNumber *double_values_1;
@property (nullable, nonatomic, retain) NSNumber *double_values_2;
@property (nullable, nonatomic, retain) NSNumber *accuracy;
@property (nullable, nonatomic, retain) NSString *label;

@end

NS_ASSUME_NONNULL_END
