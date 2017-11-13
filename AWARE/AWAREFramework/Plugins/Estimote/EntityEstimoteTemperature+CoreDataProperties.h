//
//  EntityEstimoteTemperature+CoreDataProperties.h
//  
//
//  Created by Yuuki Nishiyama on 2017/08/24.
//
//

#import "EntityEstimoteTemperature+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface EntityEstimoteTemperature (CoreDataProperties)

+ (NSFetchRequest<EntityEstimoteTemperature *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *device_id;
@property (nullable, nonatomic, copy) NSString *estimote_id;
@property (nullable, nonatomic, copy) NSNumber *temperature;
@property (nullable, nonatomic, copy) NSNumber *timestamp;

@end

NS_ASSUME_NONNULL_END
