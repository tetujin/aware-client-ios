//
//  EntityGyroscope+CoreDataProperties.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 6/5/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "EntityGyroscope+CoreDataProperties.h"

@implementation EntityGyroscope (CoreDataProperties)

@dynamic accuracy;
@dynamic axis_x;
@dynamic axis_y;
@dynamic axis_z;
@dynamic timestamp;
@dynamic device_id;
@dynamic label;

@end
