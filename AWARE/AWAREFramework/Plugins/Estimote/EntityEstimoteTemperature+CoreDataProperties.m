//
//  EntityEstimoteTemperature+CoreDataProperties.m
//  
//
//  Created by Yuuki Nishiyama on 2017/08/24.
//
//

#import "EntityEstimoteTemperature+CoreDataProperties.h"

@implementation EntityEstimoteTemperature (CoreDataProperties)

+ (NSFetchRequest<EntityEstimoteTemperature *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"EntityEstimoteTemperature"];
}

@dynamic device_id;
@dynamic estimote_id;
@dynamic temperature;
@dynamic timestamp;

@end
