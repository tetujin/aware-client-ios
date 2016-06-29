//
//  EntityGyroscope+CoreDataProperties.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 6/5/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "EntityGyroscope.h"

NS_ASSUME_NONNULL_BEGIN

@interface EntityGyroscope (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *accuracy;
@property (nullable, nonatomic, retain) NSNumber *axis_x;
@property (nullable, nonatomic, retain) NSNumber *axis_y;
@property (nullable, nonatomic, retain) NSNumber *axis_z;
@property (nullable, nonatomic, retain) NSNumber *timestamp;
@property (nullable, nonatomic, retain) NSString *device_id;
@property (nullable, nonatomic, retain) NSString *label;

@end

NS_ASSUME_NONNULL_END
