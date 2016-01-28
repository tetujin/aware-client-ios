
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
    
    
    NSMutableArray * newEsms = [[NSMutableArray alloc] init];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray* esms  = [[NSArray alloc] initWithArray:[defaults objectForKey:@"storedEsms"]];
    if (esms == nil) {
        esms = [[NSMutableArray alloc] init];
    }
    for (NSDictionary * existingEsm in esms) {
        NSString *existingScheduleId = [existingEsm objectForKey:@"scheduleId"];
        if ([existingScheduleId isEqualToString:scheduleId]) {
            NSString* esmStr = [existingEsm objectForKey:@"esmText"];  //[dic objectForKey:@"esmText"];
            [self storeEsmAsTimeout:esmStr];
//            [esms removeObject:existingEsm];
        }else{
            [newEsms addObject:existingEsm];
        }
    }
    
    NSMutableDictionary * dic = [[NSMutableDictionary alloc] init];
    [dic setObject:esmText forKey:@"esmText"];
    [dic setObject:scheduleId forKey:@"scheduleId"];
    [dic setObject:timeout forKey:@"timeout"];
    [newEsms addObject:dic];
    
    [defaults setObject:(NSArray *)newEsms forKey:@"storedEsms"];
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


- (void) storeEsmAsTimeout:(NSString*) esmStr{
    NSLog(@"Store a dismissed esm object");
    
    // If the local esm storage stored some esms,(1)AWARE iOS save the answer as cancel(dismiss). In addition, (2)UI view moves to a next stored esm.
    // Answers object
    NSMutableArray *answers = [[NSMutableArray alloc] init];
    
    // Create
    ESM *esm = [[ESM alloc] initWithSensorName:SENSOR_ESMS];
    //    double timeStamp = [[NSDate date] timeIntervalSince1970] * 1000;
    //    NSNumber* unixtime = [NSNumber numberWithLong:timeStamp];
    NSNumber * answeredTime = [AWAREUtils getUnixTimestamp:[NSDate new]];
    NSString *deviceId = [esm getDeviceId];
    
    MultiESMObject * multiEsmObject = [[MultiESMObject alloc] initWithEsmText:esmStr];
    
    for (SingleESMObject * singleEsm in multiEsmObject.esms) {
        NSMutableDictionary *dic = [AWAREEsmUtils getEsmFormatDictionary:(NSMutableDictionary *)singleEsm.esmObject
                                                            withTimesmap:answeredTime
                                                                 devieId:deviceId];
        
        NSNumber *unixtime = [self getUnixtimeInEsm:esmStr];
        if (unixtime == nil) {
            unixtime = answeredTime;
        }
        NSLog(@"[Answer] %@ - %@", unixtime, answeredTime);
        [dic setObject:unixtime forKey:@"timestamp"];
        [dic setObject:deviceId forKey:@"device_id"];
        // set answerd timestamp with KEY_ESM_USER_ANSWER_TIMESTAMP
        [dic setObject:answeredTime forKey:KEY_ESM_USER_ANSWER_TIMESTAMP];
        // Set "expired" status to KEY_ESM_STATUS. //TODO: Check!
        [dic setObject:@3 forKey:KEY_ESM_STATUS];
        // Add the esm to answer object.
        [answers addObject:dic];
    }
    
    // Save the answers to the local storage.
    [esm saveDataWithArray:answers];
    // Sync with AWARE database immediately
//    [esm performSelector:@selector(syncAwareDB) withObject:0 afterDelay:5];
    
    
    
//    NSMutableArray *answers = [[NSMutableArray alloc] init];
//    // Create
//    ESM *esm = [[ESM alloc] initWithSensorName:SENSOR_ESMS];
//    //    double timeStamp = [[NSDate date] timeIntervalSince1970] * 1000;
//    //    NSNumber* unixtime = [NSNumber numberWithLong:timeStamp];
//    NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
//    NSString *deviceId = [esm getDeviceId];
//    for (int i=0; i<uiElements.count; i++) {
//        NSDictionary *esmDic = [[uiElements objectAtIndex:i] objectForKey:KEY_OBJECT];
//        NSMutableDictionary *dic = [self getEsmFormatDictionary:(NSMutableDictionary *)esmDic
//                                                   withTimesmap:unixtime
//                                                        devieId:deviceId];
//        //        [dic setObject:unixtime forKey:@"timestamp"];
//        [dic setObject:deviceId forKey:@"device_id"];
//        // set answerd timestamp with KEY_ESM_USER_ANSWER_TIMESTAMP
//        [dic setObject:unixtime forKey:KEY_ESM_USER_ANSWER_TIMESTAMP];
//        // Set "dismiss" status to KEY_ESM_STATUS. //TODO: Check!
//        [dic setObject:@1 forKey:KEY_ESM_STATUS];
//        // Add the esm to answer object.
//        [answers addObject:dic];
//    }
//    // Save the answers to the local storage.
//    [esm saveDataWithArray:answers];
//    // Sync with AWARE database immediately
//    [esm performSelector:@selector(syncAwareDB) withObject:0 afterDelay:5];
//    
//    // Remove the answerd ESM from local storage.
//    ESMStorageHelper * helper = [[ESMStorageHelper alloc] init];
//    [helper removeEsmWithText:currentTextOfEsm];
}

- (NSNumber *) getUnixtimeInEsm:(NSString* )jsonStr {
    /**
     * [{"esm":[{"":""},{"":""},{"":""}]}]
     * - esms -> array
     * - esm -> dictionary
     * - elements -> array
     * - element -> dictionary
     */
    NSNumber * timestamp = nil;
    NSError *writeError = nil;
    NSArray *esms = [NSJSONSerialization JSONObjectWithData:[jsonStr dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&writeError];
    if (writeError != nil) {
        NSLog(@"ERROR: %@", writeError.debugDescription);
        return timestamp;
    }
    
    //    NSMutableArray * newEsms = [[NSMutableArray alloc] init];
    for (NSDictionary * esm in esms) {
        NSDictionary * elements = [esm objectForKey:@"esm"];
        timestamp = (NSNumber *)[elements objectForKey:@"timestamp"];
//        NSDate * expireDate = [[NSDate alloc] initWithTimeIntervalSinceNow:[timeoutSecond doubleValue]];
//        timeout =[AWAREUtils getUnixTimestamp:expireDate];
    }
    NSLog(@"%@", timestamp);
    
    return timestamp;
}

@end
