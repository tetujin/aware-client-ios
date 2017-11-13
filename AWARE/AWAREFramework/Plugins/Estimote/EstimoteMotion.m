//
//  EstimoteMotion.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 2017/08/24.
//  Copyright © 2017 Yuuki NISHIYAMA. All rights reserved.
//

#import "EstimoteMotion.h"
#import "EntityEstimoteMotion+CoreDataClass.h"

@implementation EstimoteMotion


- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    self = [super initWithAwareStudy:study
                          sensorName:@"estimote_motion"
                        dbEntityName:NSStringFromClass([EntityEstimoteMotion class])
                              dbType:AwareDBTypeCoreData];
    if(self!=nil){
        
    }
    return self;
}


- (void)createTable{
    TCQMaker * maker = [[TCQMaker alloc] init];
    [maker addColumn:@"estimote_id"     type:TCQTypeText default:@"''"];
    [maker addColumn:@"acceleration_x"  type:TCQTypeReal default:@"0"];
    [maker addColumn:@"acceleration_y"  type:TCQTypeReal default:@"0"];
    [maker addColumn:@"acceleration_z"  type:TCQTypeReal default:@"0"];
    [maker addColumn:@"current_motion_state_duration_in_seconds" type:TCQTypeInteger default:@"0"];
    [maker addColumn:@"previous_motion_state_duration_in_seconds" type:TCQTypeInteger default:@"0"];
    [maker addColumn:@"motion_state" type:TCQTypeText default:@"''"];
    
    [self createTable:[maker getDefaudltTableCreateQuery]];
}

- (void)saveDataWithEstimoteMotion:(ESTTelemetryInfoMotion *)motion{
    dispatch_async(dispatch_get_main_queue(), ^{
        if(motion != nil){
            NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
            NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
            [dict setObject:unixtime forKey:@"timestamp"];
            [dict setObject:[self getDeviceId] forKey:@"device_id"];
            [dict setObject:motion.shortIdentifier forKey:@"estimote_id"];
            [dict setObject:motion.accelerationX forKey:@"acceleration_x"];
            [dict setObject:motion.accelerationY forKey:@"acceleration_y"];
            [dict setObject:motion.accelerationZ forKey:@"acceleration_z"];
            [dict setObject:motion.currentMotionStateDurationInSeconds forKey:@"current_motion_state_duration_in_seconds"];
            [dict setObject:motion.previousMotionStateDurationInSeconds forKey:@"previous_motion_state_duration_in_seconds"];
            [dict setObject:motion.motionState.stringValue forKey:@"motion_state"];
            [self setLatestData:dict];
            [self saveData:dict];
        }
    });
}

- (void)insertNewEntityWithData:(NSDictionary *)data managedObjectContext:(NSManagedObjectContext *)childContext entityName:(NSString *)entity{
    EntityEstimoteMotion * entityEM = (EntityEstimoteMotion *)[NSEntityDescription insertNewObjectForEntityForName:entity
                                                                                                       inManagedObjectContext:childContext];
    entityEM.device_id = [data objectForKey:@"device_id"];
    entityEM.timestamp = [data objectForKey:@"timestamp"];
    entityEM.estimote_id = [data objectForKey:@"estimote_id"];
    entityEM.acceleration_x = [data objectForKey:@"acceleration_x"];
    entityEM.acceleration_y = [data objectForKey:@"acceleration_y"];
    entityEM.acceleration_z = [data objectForKey:@"acceleration_z"];
    entityEM.current_motion_state_duration_in_seconds = [data objectForKey:@"current_motion_state_duration_in_seconds"];
    entityEM.previous_motion_state_duration_in_seconds = [data objectForKey:@"previous_motion_state_duration_in_seconds"];
    entityEM.motion_state =  [data objectForKey:@"motion_state"];
}



@end
