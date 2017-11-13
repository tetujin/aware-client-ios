//
//  EstimoteAmbientLight.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 2017/08/24.
//  Copyright © 2017 Yuuki NISHIYAMA. All rights reserved.
//

#import "EstimoteAmbientLight.h"
#import "EntityEstimoteAmbientLight+CoreDataClass.h"

@implementation EstimoteAmbientLight

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    self = [super initWithAwareStudy:study
                          sensorName:@"estimote_ambient_light"
                        dbEntityName:NSStringFromClass([EntityEstimoteAmbientLight class])
                              dbType:AwareDBTypeCoreData];
    if(self!=nil){
        
    }
    return self;
}


- (void)createTable{
    TCQMaker * maker = [[TCQMaker alloc] init];
    [maker addColumn:@"estimote_id"     type:TCQTypeText default:@"''"];
    [maker addColumn:@"ambient_light"  type:TCQTypeReal default:@"0"];
    
    [self createTable:[maker getDefaudltTableCreateQuery]];
}


- (void)saveDataWithEstimoteAmbientLight:(ESTTelemetryInfoAmbientLight *)ambientLight{
    dispatch_async(dispatch_get_main_queue(), ^{
        if(ambientLight != nil){
            NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
            NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
            [dict setObject:unixtime forKey:@"timestamp"];
            [dict setObject:[self getDeviceId] forKey:@"device_id"];
            [dict setObject:ambientLight.shortIdentifier forKey:@"estimote_id"];
            [dict setObject:ambientLight.ambientLightLevelInLux forKey:@"ambient_light"];
            
            [self setLatestData:dict];
            [self saveData:dict];
        }
    });
}

- (void)insertNewEntityWithData:(NSDictionary *)data managedObjectContext:(NSManagedObjectContext *)childContext entityName:(NSString *)entity{
    EntityEstimoteAmbientLight * entityEAL = ( EntityEstimoteAmbientLight *)[NSEntityDescription insertNewObjectForEntityForName:entity
                                                                                            inManagedObjectContext:childContext];
    entityEAL.device_id = [data objectForKey:@"device_id"];
    entityEAL.timestamp = [data objectForKey:@"timestamp"];
    entityEAL.estimote_id = [data objectForKey:@"estimote_id"];
    entityEAL.ambient_light = [data objectForKey:@"ambient_light"];
}

@end
