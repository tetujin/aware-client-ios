//
//  EntityEstimoteAmbientLight+CoreDataProperties.m
//  
//
//  Created by Yuuki Nishiyama on 2017/08/24.
//
//

#import "EntityEstimoteAmbientLight+CoreDataProperties.h"

@implementation EntityEstimoteAmbientLight (CoreDataProperties)

+ (NSFetchRequest<EntityEstimoteAmbientLight *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"EntityEstimoteAmbientLight"];
}

@dynamic ambient_light;
@dynamic device_id;
@dynamic estimote_id;
@dynamic timestamp;

@end
