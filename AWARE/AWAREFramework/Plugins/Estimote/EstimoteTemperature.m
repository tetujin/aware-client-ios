//
//  EstimoteTemperature.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 2017/08/24.
//  Copyright © 2017 Yuuki NISHIYAMA. All rights reserved.
//

#import "EstimoteTemperature.h"
#import "EntityEstimoteTemperature+CoreDataClass.h"

@implementation EstimoteTemperature

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    self = [super initWithAwareStudy:study
                          sensorName:@"estimote_temperature"
                        dbEntityName:NSStringFromClass([EntityEstimoteTemperature class])
                              dbType:AwareDBTypeCoreData];
    if(self!=nil){
        
    }
    return self;
}

- (void)createTable{
    TCQMaker * maker = [[TCQMaker alloc] init];
    [maker addColumn:@"estimote_id"    type:TCQTypeText default:@"''"];
    [maker addColumn:@"temperature"    type:TCQTypeReal default:@"0"];
    [self createTable:[maker getDefaudltTableCreateQuery]];
}

- (void)saveDataWithEstimoteAirpressure:(ESTTelemetryInfoTemperature *)temperature{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if(temperature != nil){
            NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
            NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
            [dict setObject:unixtime forKey:@"timestamp"];
            [dict setObject:[self getDeviceId] forKey:@"device_id"];
            [dict setObject:temperature.shortIdentifier forKey:@"estimote_id"];
            [dict setObject:temperature.temperatureInCelsius forKey:@"temperature"];
            [self setLatestData:dict];
            [self saveData:dict];
        }
    });
}

- (void)insertNewEntityWithData:(NSDictionary *)data managedObjectContext:(NSManagedObjectContext *)childContext entityName:(NSString *)entity{
    EntityEstimoteTemperature * entityET = (EntityEstimoteTemperature *)[NSEntityDescription insertNewObjectForEntityForName:entity
                                                                                                       inManagedObjectContext:childContext];
    entityET.device_id = [data objectForKey:@"device_id"];
    entityET.timestamp = [data objectForKey:@"timestamp"];
    entityET.estimote_id = [data objectForKey:@"estimote_id"];
    entityET.temperature = [data objectForKey:@"temperature"];
}


@end
