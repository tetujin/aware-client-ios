//
//  EntityActivityRecognition+CoreDataProperties.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 6/21/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "EntityActivityRecognition.h"

NS_ASSUME_NONNULL_BEGIN

@interface EntityActivityRecognition (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *activities;
@property (nullable, nonatomic, retain) NSString *activity_name;
@property (nullable, nonatomic, retain) NSString *activity_type;
@property (nullable, nonatomic, retain) NSNumber *confidence;
@property (nullable, nonatomic, retain) NSString *device_id;
@property (nullable, nonatomic, retain) NSNumber *timestamp;

@end

NS_ASSUME_NONNULL_END
