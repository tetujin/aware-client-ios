//
//  WebESM.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 7/8/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "WebESM.h"
#import "TCQMaker.h"

@implementation WebESM {
    
}

-(instancetype)initWithAwareStudy:(AWAREStudy *)study{
    self = [super initWithAwareStudy:study
                          sensorName:@"esm"
                        dbEntityName:@"EntityESM"
                              dbType:AwareDBTypeCoreData];
    if(self != nil){
        
    }
    
    return self;
}

- (void)createTable{
    TCQMaker *tcqMaker = [[TCQMaker alloc] init];
    [tcqMaker addColumn:@"timestamp" type:TCQTypeReal default:@"0"];
    [tcqMaker addColumn:@"device_id" type:TCQTypeText default:@"''"];
    [super createTable:[tcqMaker getTableCreateQueryWithUniques:nil]];
}

- (BOOL)startSensorWithSettings:(NSArray *)settings{
    // Get contents from URL
    NSString * url = [self getURLFromSettings:settings];
    
    // Set the contents to SQLite
    
    // Fire the schedules
    
    // Set auto refresh timer
    
    // Random notification
    
    return YES;
}

- (BOOL) stopSensor{
    // remove the sensor
    return YES;
}


////////////////////////////////////////////////////////////

- (void) answer {
    
}


////////////////////////////////////////////////////////////

- (NSString *)getURLFromSettings:(NSArray *)settings{
    NSString * url;
    for (NSDictionary * dict in settings ) {
        for (NSString * key in [dict allKeys]) {
            if([key isEqualToString:@"setting_url"]){
                url = [dict objectForKey:key];
            }
        }
    }
    return url;
}

@end
