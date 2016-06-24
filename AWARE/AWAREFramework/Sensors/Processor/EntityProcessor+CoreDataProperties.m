//
//  EntityProcessor+CoreDataProperties.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 6/22/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "EntityProcessor+CoreDataProperties.h"

@implementation EntityProcessor (CoreDataProperties)

@dynamic device_id;
@dynamic timestamp;
@dynamic double_last_user;
@dynamic double_last_system;
@dynamic double_last_idle;
@dynamic double_user_load;
@dynamic double_system_load;
@dynamic double_idle;

@end
