//
//  EntityEstimoteAirpressure+CoreDataProperties.m
//  
//
//  Created by Yuuki Nishiyama on 2017/08/24.
//
//

#import "EntityEstimoteAirpressure+CoreDataProperties.h"

@implementation EntityEstimoteAirpressure (CoreDataProperties)

+ (NSFetchRequest<EntityEstimoteAirpressure *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"EntityEstimoteAirpressure"];
}

@dynamic device_id;
@dynamic estimote_id;
@dynamic pressure;
@dynamic timestamp;

@end
