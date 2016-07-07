//
//  EntityMSBandRRInterval+CoreDataProperties.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 7/7/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "EntityMSBandRRInterval.h"

NS_ASSUME_NONNULL_BEGIN

@interface EntityMSBandRRInterval (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *timestamp;
@property (nullable, nonatomic, retain) NSNumber *rrinterval;
@property (nullable, nonatomic, retain) NSString *device_id;

@end

NS_ASSUME_NONNULL_END
