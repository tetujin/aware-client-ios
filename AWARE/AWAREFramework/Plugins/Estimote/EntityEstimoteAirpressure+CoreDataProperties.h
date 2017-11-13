//
//  EntityEstimoteAirpressure+CoreDataProperties.h
//  
//
//  Created by Yuuki Nishiyama on 2017/08/24.
//
//

#import "EntityEstimoteAirpressure+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface EntityEstimoteAirpressure (CoreDataProperties)

+ (NSFetchRequest<EntityEstimoteAirpressure *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *device_id;
@property (nullable, nonatomic, copy) NSString *estimote_id;
@property (nullable, nonatomic, copy) NSNumber *pressure;
@property (nullable, nonatomic, copy) NSNumber *timestamp;

@end

NS_ASSUME_NONNULL_END
