//
//  EntityAmbientNoise+CoreDataProperties.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 7/8/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "EntityAmbientNoise.h"

NS_ASSUME_NONNULL_BEGIN

@interface EntityAmbientNoise (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *device_id;
@property (nullable, nonatomic, retain) NSNumber *double_decibels;
@property (nullable, nonatomic, retain) NSNumber *double_frequency;
@property (nullable, nonatomic, retain) NSNumber *double_RMS;
@property (nullable, nonatomic, retain) NSNumber *is_silent;
@property (nullable, nonatomic, retain) NSString *raw;
@property (nullable, nonatomic, retain) NSNumber *double_silent_threshold;
@property (nullable, nonatomic, retain) NSNumber *timestamp;

@end

NS_ASSUME_NONNULL_END
