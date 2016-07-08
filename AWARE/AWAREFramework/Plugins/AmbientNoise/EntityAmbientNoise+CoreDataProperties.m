//
//  EntityAmbientNoise+CoreDataProperties.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 7/8/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "EntityAmbientNoise+CoreDataProperties.h"

@implementation EntityAmbientNoise (CoreDataProperties)

@dynamic device_id;
@dynamic double_decibels;
@dynamic double_frequency;
@dynamic double_RMS;
@dynamic is_silent;
@dynamic raw;
@dynamic double_silent_threshold;
@dynamic timestamp;

@end
