//
//  EntityEstimoteMotion+CoreDataProperties.m
//  
//
//  Created by Yuuki Nishiyama on 2017/08/24.
//
//

#import "EntityEstimoteMotion+CoreDataProperties.h"

@implementation EntityEstimoteMotion (CoreDataProperties)

+ (NSFetchRequest<EntityEstimoteMotion *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"EntityEstimoteMotion"];
}

@dynamic device_id;
@dynamic estimote_id;
@dynamic motion_state;
@dynamic timestamp;
@dynamic acceleration_x;
@dynamic acceleration_y;
@dynamic acceleration_z;
@dynamic previous_motion_state_duration_in_seconds;
@dynamic current_motion_state_duration_in_seconds;

@end
