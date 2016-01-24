//
//  ESMStorageHelper.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 12/24/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "ESMStorageHelper.h"
#import "MultiESMObject.h"
#import "AWAREUtils.h"
#import "AWAREEsmUtils.h"
#import "ESM.h"
#import "AWAREKeys.h"
#import "SingleESMObject.h"
#import "MultiESMObject.h"

@implementation ESMStorageHelper

- (void) addEsmText:(NSString *)esmText
             withId:(NSString *)scheduleId
            timeout:(NSNumber *)timeout{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray* esms  = [[NSMutableArray alloc] initWithArray:[defaults objectForKey:@"storedEsms"]];
    if (esms == nil) {
        esms = [[NSMutableArray alloc] init];
    }
    NSMutableDictionary * dic = [[NSMutableDictionary alloc] init];
    [dic setObject:esmText forKey:@"esmText"];
    [dic setObject:scheduleId forKey:@"scheduleId"];
    [dic setObject:timeout forKey:@"timeout"];
    
    for (NSMutableDictionary * existingEsm in esms) {
        NSString *existingScheduleId = [existingEsm objectForKey:@"scheduleId"];
        if ([existingScheduleId isEqualToString:scheduleId]) {
            NSString* esmStr = [dic objectForKey:@"esmText"];
            [self storeEsmAsDismiss:esmStr];
            [esms removeObject:existingEsm];
        }
    }
    
    
    [esms addObject:dic];
    [defaults setObject:(NSArray *)esms forKey:@"storedEsms"];
}

- (void) removeEsmTexts {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:@"storedEsms"];
}

- (void) removeEsmWithText:(NSString *)esmText {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray* storedEsms  = [[NSMutableArray alloc] initWithArray:[defaults objectForKey:@"storedEsms"]];
    NSMutableArray* newEsms = [[NSMutableArray alloc] init];
    if (storedEsms != nil) {
        for (NSDictionary * esm in storedEsms) {
            NSString * storedEsmText = [esm objectForKey:@"esmText"];
//            NSString * sid = [esm objectForKey:@"scheduleId"];
//            NSNumber * timeout = [esm objectForKey:@"timeout"];
//            NSNumber * now = [AWAREUtils getUnixTimestamp:[NSDate new]];
            if (![storedEsmText isEqualToString:esmText]) {
                [newEsms addObject:esm];
            }
        }
        [defaults setObject:newEsms forKey:@"storedEsms"];
    }
}

//- (void) removeEsmWithText:(NSString *)esmText {
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    NSMutableArray* esms  = [[NSMutableArray alloc] initWithArray:[defaults objectForKey:@"storedEsms"]];
//    if (esms == nil) {
//        esms = [[NSMutableArray alloc] init];
//    }
//    NSMutableArray * newArray = [[NSMutableArray alloc] init];
//    for (NSString* str in esms) {
////        NSLog(@"%@", str);
//        if ([str isEqualToString:esmText]) {
////            [esms removeObject:esms];
//        }else{
//            [newArray addObject:str];
//        }
//    }
//    [defaults setObject:(NSArray *)newArray forKey:@"storedEsms"];
//}

- (NSArray *) getEsmTexts {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray * array =[defaults objectForKey:@"storedEsms"];
//    return array;
    NSMutableArray * esms = [[NSMutableArray alloc] init];
    if (array != nil) {
        for (NSDictionary * dic in array) {
            NSString * esmText = [dic objectForKey:@"esmText"];
//            NSString * scheduleId = [dic objectForKey:@"scheduleId"];
//            NSNumber * timeout = [dic objectForKey:@"timeout"];
            [esms addObject:esmText];
        }
        return esms;
    }else{
        return nil;
    }
}

//- (void) addEsmObject:(MultiESMObject *) esmObject{
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    NSMutableArray* esms  = [defaults objectForKey:@"storedEsms"];
//    if (esms == nil) {
//        esms = [[NSMutableArray alloc] init];
//    }
//    [defaults setObject:esms forKey:@"storedEsms"];
//}
//
//- (NSArray *) getEsmObjects {
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    NSMutableArray* esms  = [defaults objectForKey:@"storedEsms"];
//    return esms;
//}
//
//- (NSArray *) removeEsmObject:(MultiESMObject *) esmObject {
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    NSMutableArray* esms  = [defaults objectForKey:@"storedEsms"];
//    for( MultiESMObject* mEsm in esms ){
//        
//    }
//    return esms;
//}
//
//- (void) removeEsmObjects{
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    [defaults removeObjectForKey:@"storedEsms"];
//}
//
//- (NSMutableArray *) removeExpiredEsms:(NSMutableArray *)esms {
//    for (MultiESMObject *esm in esms) {
//        NSLog(@"%@", esm.expirationThreshold);
//    }
//    return esms;
//}


- (void) storeEsmAsDismiss:(NSString*) esmStr{
    NSLog(@"Store a dismissed esm object");
    
    // If the local esm storage stored some esms,(1)AWARE iOS save the answer as cancel(dismiss). In addition, (2)UI view moves to a next stored esm.
    // Answers object
    NSMutableArray *answers = [[NSMutableArray alloc] init];
    
    // Create
    ESM *esm = [[ESM alloc] initWithSensorName:SENSOR_ESMS];
    //    double timeStamp = [[NSDate date] timeIntervalSince1970] * 1000;
    //    NSNumber* unixtime = [NSNumber numberWithLong:timeStamp];
    NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
    NSString *deviceId = [esm getDeviceId];

    MultiESMObject * multiEsmObject = [[MultiESMObject alloc] initWithEsmText:esmStr];
    
    for (SingleESMObject * singleEsm in multiEsmObject.esms) {
        NSMutableDictionary *dic = [AWAREEsmUtils getEsmFormatDictionary:(NSMutableDictionary *)singleEsm.esmObject
                                                            withTimesmap:unixtime
                                                                 devieId:deviceId];
        //        [dic setObject:unixtime forKey:@"timestamp"];
        [dic setObject:deviceId forKey:@"device_id"];
        // set answerd timestamp with KEY_ESM_USER_ANSWER_TIMESTAMP
        [dic setObject:unixtime forKey:KEY_ESM_USER_ANSWER_TIMESTAMP];
        // Set "expired" status to KEY_ESM_STATUS. //TODO: Check!
        [dic setObject:@3 forKey:KEY_ESM_STATUS];
        // Add the esm to answer object.
        [answers addObject:dic];
    }
    
    // Save the answers to the local storage.
    [esm saveDataWithArray:answers];
    // Sync with AWARE database immediately
//    [esm performSelector:@selector(syncAwareDB) withObject:0 afterDelay:5];
}

@end
