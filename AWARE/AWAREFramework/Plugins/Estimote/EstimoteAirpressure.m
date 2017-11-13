//
//  EstimoteAirpressure.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 2017/08/24.
//  Copyright © 2017 Yuuki NISHIYAMA. All rights reserved.
//

#import "EstimoteAirpressure.h"
#import "EntityEstimoteAirpressure+CoreDataClass.h"

@implementation EstimoteAirpressure

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    self = [super initWithAwareStudy:study
                          sensorName:@"estimote_airpressure"
                        dbEntityName:NSStringFromClass([EntityEstimoteAirpressure class])
                              dbType:AwareDBTypeCoreData];
    if(self!=nil){
        
    }
    return self;
}

- (void)createTable{
    TCQMaker * maker = [[TCQMaker alloc] init];
    [maker addColumn:@"estimote_id" type:TCQTypeText default:@"''"];
    [maker addColumn:@"pressure"    type:TCQTypeReal default:@"0"];
    [self createTable:[maker getDefaudltTableCreateQuery]];
}

- (void)saveDataWithEstimoteAirpressure:(ESTTelemetryInfoPressure *)pressure{
    dispatch_async(dispatch_get_main_queue(), ^{
        if(pressure != nil){
            NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
            NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
            [dict setObject:unixtime forKey:@"timestamp"];
            [dict setObject:[self getDeviceId] forKey:@"device_id"];
            [dict setObject:pressure.shortIdentifier forKey:@"estimote_id"];
            [dict setObject:pressure.pressureInPascals forKey:@"pressure"];
            [self setLatestData:dict];
            [self saveData:dict];
        }
    });
}

- (void)insertNewEntityWithData:(NSDictionary *)data managedObjectContext:(NSManagedObjectContext *)childContext entityName:(NSString *)entity{
    EntityEstimoteAirpressure * entityEAP = (EntityEstimoteAirpressure *)[NSEntityDescription insertNewObjectForEntityForName:entity
                                                                                inManagedObjectContext:childContext];
    entityEAP.device_id = [data objectForKey:@"device_id"];
    entityEAP.timestamp = [data objectForKey:@"timestamp"];
    entityEAP.estimote_id = [data objectForKey:@"estimote_id"];
    entityEAP.pressure = [data objectForKey:@"pressure"];
}

@end
