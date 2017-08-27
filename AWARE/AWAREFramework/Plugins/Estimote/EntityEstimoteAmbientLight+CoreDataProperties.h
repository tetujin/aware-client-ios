//
//  EntityEstimoteAmbientLight+CoreDataProperties.h
//  
//
//  Created by Yuuki Nishiyama on 2017/08/24.
//
//

#import "EntityEstimoteAmbientLight+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface EntityEstimoteAmbientLight (CoreDataProperties)

+ (NSFetchRequest<EntityEstimoteAmbientLight *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *ambient_light;
@property (nullable, nonatomic, copy) NSString *device_id;
@property (nullable, nonatomic, copy) NSString *estimote_id;
@property (nullable, nonatomic, copy) NSNumber *timestamp;

@end

NS_ASSUME_NONNULL_END
