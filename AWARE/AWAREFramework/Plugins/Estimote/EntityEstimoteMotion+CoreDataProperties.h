//
//  EntityEstimoteMotion+CoreDataProperties.h
//  
//
//  Created by Yuuki Nishiyama on 2017/08/24.
//
//

#import "EntityEstimoteMotion+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface EntityEstimoteMotion (CoreDataProperties)

+ (NSFetchRequest<EntityEstimoteMotion *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *device_id;
@property (nullable, nonatomic, copy) NSString *estimote_id;
@property (nullable, nonatomic, copy) NSString *motion_state;
@property (nullable, nonatomic, copy) NSNumber *timestamp;
@property (nullable, nonatomic, copy) NSNumber *acceleration_x;
@property (nullable, nonatomic, copy) NSNumber *acceleration_y;
@property (nullable, nonatomic, copy) NSNumber *acceleration_z;
@property (nullable, nonatomic, copy) NSNumber *previous_motion_state_duration_in_seconds;
@property (nullable, nonatomic, copy) NSNumber *current_motion_state_duration_in_seconds;

@end

NS_ASSUME_NONNULL_END
