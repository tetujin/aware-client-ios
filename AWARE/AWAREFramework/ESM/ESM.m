//
//  ESM.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 12/16/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "ESM.h"
#import "AWAREEsmUtils.h"
#import "AWARESchedule.h"
#import "ESMStorageHelper.h"
#import "Debug.h"
#import "ESMSchedule.h"
#import "ESMManager.h"
#import "AWAREUtils.h"

@implementation ESM {
    ESMStorageHelper * helper;
    ESMManager * esmManager;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    self = [super initWithAwareStudy:study
                          sensorName:@"esms"
                        dbEntityName:nil
                              dbType:AwareDBTypeTextFile];
    if (self) {
        helper = [[ESMStorageHelper alloc] init];
        esmManager = [[ESMManager alloc] init];
    }
    return self;
}

- (void) createTable {
    NSLog(@"[%@] Create Table", [self getSensorName]);
    NSString *query = [[NSString alloc] init];
    query =
    @"_id integer primary key autoincrement,"
    "timestamp real default 0,"
    "device_id text default '',"
    "esm_type integer default 0,"
    "esm_title text default '',"
    "esm_submit text default '',"
    "esm_instructions text default '',"
    "esm_radios text default '',"
    "esm_checkboxes text default '',"
    "esm_likert_max integer default 0,"
    "esm_likert_max_label text default '',"
    "esm_likert_min_label text default '',"
    "esm_likert_step real default 0,"
    "esm_quick_answers text default '',"
    "esm_expiration_threshold integer default 0,"
    "esm_status integer default 0,"
    "double_esm_user_answer_timestamp real default 0,"
    "esm_user_answer text default '',"
    "esm_trigger text default '',"
    "esm_scale_min integer default 0,"
    "esm_scale_max integer default 0,"
    "esm_scale_start integer default 0,"
    "esm_scale_max_label text default '',"
    "esm_scale_min_label text default '',"
    "esm_scale_step integer default 0";
    [super createTable:query];
}

/**
 * DEFAULT:
 *
 */
-(BOOL)startSensorWithSettings:(NSArray *)settings{
    [helper removeEsmTexts];
    
    [[[NSOperationQueue alloc] init] addOperationWithBlock:^{
//        ESMSchedule * schedule = [[ESMSchedule alloc] initWithIdentifier:@"sample_esm_for_sport"
//                                                           scheduledESMs:[self getSampleESMsForSports]
//                                                               fireDates:[self getSampleFireHours]
//                                                                   title:@"体育会ラグビー部 コンディションチェック"
//                                                                    body:@"現在のコンディションを入力してください！"
//                                                                interval:NSCalendarUnitDay
//                                                                category:[self getSensorName]
//                                                                    icon:1
//                                                                 timeout:60];
//        // Add the schedule to ESMManager
//        [esmManager addESMSchedules:schedule];
//        
//        dispatch_async(dispatch_get_main_queue(), ^{
//            // Start the schedules using -startAllESMSchedules on ESMManager
//            [esmManager startAllESMSchedules];            
//        });
    }];
    
    
    
    // Remove all esms from the local-temp storage
    //    [helper removeEsmTexts];
    //
    //    // Make ESM configurations
    //    NSString * esmId = @"test_esm"; //Identifer of a notification
    //    NSString * notificationTitle = @"ESM from AWARE iOS client"; // Notification title (iOS9 or later are support this function)
    //    NSString * notificationBody = @"Tap to answer!"; // Notification Body
    //    NSMutableArray * esms = [self getESMDictionaries]; // Generate ESM objects. Please refer to the -getESMDictionaries.
    //    NSDate * now = [NSDate new];
    //    NSArray * hours = [NSArray arrayWithObjects:@1,@2,@3,@4,@5,@6,@7,@8,@9,@10,@11,@12,@13,@14,@15,@16,@17,@18,@19,@20,@21,@22,@23,nil];
    //    NSMutableArray * fireHours = [[NSMutableArray alloc] init]; // Generate fire NSDates
    //    for (NSNumber * hour in hours) {
    //        [fireHours addObject:[AWAREUtils getTargetNSDate:now hour:[hour intValue] nextDay:YES]];
    //    }
    //    NSInteger timeout = 60*10; // Timeout
    //
    //    // Set the information to ESMSchedule
    //    ESMSchedule * schedule = [[ESMSchedule alloc] initWithIdentifier:esmId
    //                                                        scheduledESMs:esms
    //                                                        fireDates:fireHours
    //                                                        title:notificationTitle
    //                                                        body:notificationBody
    //                                                        interval:NSCalendarUnitDay
    //                                                        category:[self getSensorName]
    //                                                                icon:1
    //                                                             timeout:timeout];
    //    // Add the schedule to ESMManager
    //    [esmManager addESMSchedules:schedule];
    //
    //    // Start the schedules using -startAllESMSchedules on ESMManager
    //    [esmManager startAllESMSchedules];
    
    return YES;
}


/**
 * DEFAULT:
 */
- (BOOL)stopSensor{
    [esmManager stopAllESMSchedules];
    return YES;
}


- (NSMutableArray *) getSampleFireHours{
    NSDate * now = [NSDate new];
    NSArray * hours = [NSArray arrayWithObjects:@1,@2,@3,@4,@5,@6,@7,@8,@9,@10,@11,@12,@13,@14,@15,@16,@17,@18,@19,@20,@21,@22,@23,nil];
    NSMutableArray * fireHours = [[NSMutableArray alloc] init]; // Generate fire NSDates
    for (NSNumber * hour in hours) {
        [fireHours addObject:[AWAREUtils getTargetNSDate:now hour:[hour intValue] nextDay:YES]];
    }
    return fireHours;
}

////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////

- (NSMutableArray *) getSampleESMsForSports{
    
    
    
    NSMutableDictionary *sleepTime =
    [SingleESMObject getEsmDictionaryAsDatePickerWithDeviceId:[self getDeviceId]
                                                    timestamp:[[AWAREUtils getUnixTimestamp:[NSDate new]] doubleValue]
                                                        title:@"昨晩は何時に就寝しましたか？"
                                                 instructions:@""
                                                       submit:@"submit"
                                          expirationThreshold:@60
                                                      trigger:@"sleep_start_time"];
    
    NSMutableDictionary *wakeupTime =
    [SingleESMObject getEsmDictionaryAsDatePickerWithDeviceId:[self getDeviceId]
                                                    timestamp:[[AWAREUtils getUnixTimestamp:[NSDate new]] doubleValue]
                                                        title:@"今朝は何時に起床しましたか？"
                                                 instructions:@""
                                                       submit:@"submit"
                                          expirationThreshold:@60
                                                      trigger:@"sleep_end_time"];
    
    NSMutableDictionary *breakfast =
    [SingleESMObject getEsmDictionaryAsRadioWithDeviceId:[self getDeviceId]
                                               timestamp:[[AWAREUtils getUnixTimestamp:[NSDate new]] doubleValue]
                                                   title:@"朝食は食べましたか？"
                                            instructions:@""
                                                  submit:@""
                                     expirationThreshold:@60
                                                 trigger:@"breakfast"
                                                  radios:[NSArray
                                                          arrayWithObjects:@"YES",@"NO",nil]];
    
    NSMutableDictionary *foods =
    [SingleESMObject getEsmDictionaryAsCheckBoxWithDeviceId:[self getDeviceId]
                                                  timestamp:[[AWAREUtils getUnixTimestamp:[NSDate new]] doubleValue]
                                                      title:@"朝食ではどのような食材を食べましか？"
                                               instructions:@""
                                                     submit:@""
                                        expirationThreshold:@60
                                                    trigger:@"foods"
                                                 checkBoxes:[NSArray
                                                             arrayWithObjects:
                                                             @"豚肉",
                                                             @"鶏肉",
                                                             @"牛肉",
                                                             @"魚"
                                                             @"卵",
                                                             @"乳製品",
                                                             @"Other",
                                                             nil]];
    
    NSMutableDictionary *esm1 =
    [SingleESMObject getEsmDictionaryAsScaleWithDeviceId:[self getDeviceId]
                                               timestamp:[[AWAREUtils getUnixTimestamp:[NSDate new]] doubleValue]
                                                   title:@"疲労度"
                                            instructions:@"1-7の数値を選択してください．"
                                                  submit:@""
                                     expirationThreshold:@60
                                                 trigger:@"fatigue"
                                                     min:@1
                                                     max:@7
                                              scaleStart:@4
                                                minLabel:@"Bad(1)"
                                                maxLabel:@"Good(7)"
                                               scaleStep:@0.1];
    
    NSMutableDictionary *esm2 =
    [SingleESMObject getEsmDictionaryAsLikertScaleWithDeviceId:[self getDeviceId]
                                                     timestamp:[[AWAREUtils getUnixTimestamp:[NSDate new]] doubleValue]
                                                         title:@"睡眠の質"
                                                  instructions:@"1-7の数値を選択してください．"
                                                        submit:@""
                                           expirationThreshold:@60
                                                       trigger:@"sleep_quality"
                                                     likertMax:@7
                                                likertMaxLabel:@"Good(7)"
                                                likertMinLabel:@"Bad(1)"
                                                    likertStep:@1];
    
    NSMutableDictionary *esm3 =
    [SingleESMObject getEsmDictionaryAsScaleWithDeviceId:[self getDeviceId]
                                               timestamp:[[AWAREUtils getUnixTimestamp:[NSDate new]] doubleValue]
                                                   title:@"ストレス値"
                                            instructions:@"1-7の数値を選択してください．"
                                                  submit:@""
                                     expirationThreshold:@60
                                                 trigger:@"stress_level"
                                                     min:@1
                                                     max:@7
                                              scaleStart:@4
                                                minLabel:@"Bad(1)"
                                                maxLabel:@"Good(7)"
                                               scaleStep:@0.1];
    
    NSMutableDictionary *esm4 =
    [SingleESMObject getEsmDictionaryAsScaleWithDeviceId:[self getDeviceId]
                                               timestamp:[[AWAREUtils getUnixTimestamp:[NSDate new]] doubleValue]
                                                   title:@"栄養状態"
                                            instructions:@"1-7の数値を選択してください．"
                                                  submit:@""
                                     expirationThreshold:@60
                                                 trigger:@"nutrition"
                                                     min:@1
                                                     max:@7
                                              scaleStart:@4
                                                minLabel:@"Bad(1)"
                                                maxLabel:@"Good(7)"
                                               scaleStep:@0.1];
    
    
    NSMutableDictionary *esm5 =
    [SingleESMObject getEsmDictionaryAsScaleWithDeviceId:[self getDeviceId]
                                               timestamp:[[AWAREUtils getUnixTimestamp:[NSDate new]] doubleValue]
                                                   title:@"水分摂取"
                                            instructions:@"1-7の数値を選択してください．"
                                                  submit:@""
                                     expirationThreshold:@60
                                                 trigger:@"water"
                                                     min:@1
                                                     max:@7
                                              scaleStart:@4
                                                minLabel:@"Bad(1)"
                                                maxLabel:@"Good(7)"
                                               scaleStep:@0.1];
    
    NSMutableDictionary *esm6 =
    [SingleESMObject getEsmDictionaryAsScaleWithDeviceId:[self getDeviceId]
                                               timestamp:[[AWAREUtils getUnixTimestamp:[NSDate new]] doubleValue]
                                                   title:@"ハムストリング筋肉痛"
                                            instructions:@"1-7の数値を選択してください．"
                                                  submit:@""
                                     expirationThreshold:@60
                                                 trigger:@"hamstring"
                                                     min:@1
                                                     max:@7
                                              scaleStart:@4
                                                minLabel:@"Bad(1)"
                                                maxLabel:@"Good(7)"
                                               scaleStep:@0.1];
    
    NSMutableDictionary *esm7 =
    [SingleESMObject getEsmDictionaryAsScaleWithDeviceId:[self getDeviceId]
                                               timestamp:[[AWAREUtils getUnixTimestamp:[NSDate new]] doubleValue]
                                                   title:@"腰背部筋肉痛"
                                            instructions:@"1-7の数値を選択してください．"
                                                  submit:@""
                                     expirationThreshold:@60
                                                 trigger:@"back"
                                                     min:@1
                                                     max:@7
                                              scaleStart:@4
                                                minLabel:@"Bad(1)"
                                                maxLabel:@"Good(7)"
                                               scaleStep:@0.1];
    
    
    NSMutableDictionary *freeText =
    [SingleESMObject getEsmDictionaryAsFreeTextWithDeviceId:[self getDeviceId]
                                                  timestamp:[[AWAREUtils getUnixTimestamp:[NSDate new]] doubleValue]
                                                      title:@"今日の練習では何を意識しますか？"
                                               instructions:@""
                                                     submit:@"Next"
                                        expirationThreshold:@60
                                                    trigger:@"goal_of_today"];
    
    NSMutableDictionary *pam =
    [SingleESMObject getEsmDictionaryAsPAMWithDeviceId:[self getDeviceId]
                                             timestamp:[[AWAREUtils getUnixTimestamp:[NSDate new]] doubleValue]
                                                 title:@"test"
                                          instructions:@""
                                                submit:@"Next"
                                   expirationThreshold:@60
                                               trigger:@"pam"];
    
    
    return [[NSMutableArray alloc] initWithArray:@[sleepTime, wakeupTime, breakfast, foods, esm1,esm2,esm3,esm4,esm5,esm6,esm7, freeText]];
}

- (NSMutableArray *) getESMDictionaries {
    NSString * deviceId = @"";
    NSString * submit = @"Next";
    double timestamp = 0;
    NSNumber * exprationThreshold = [NSNumber numberWithInt:60];
    NSString * trigger = @"trigger";
    
    NSMutableDictionary *dicFreeText = [SingleESMObject getEsmDictionaryAsFreeTextWithDeviceId:deviceId
                                                                               timestamp:timestamp
                                                                                   title:@"ESM Freetext"
                                                                            instructions:@"The user can answer an open ended question." submit:submit
                                                                     expirationThreshold:exprationThreshold
                                                                                 trigger:trigger];
    
    NSMutableDictionary *dicRadio = [SingleESMObject getEsmDictionaryAsRadioWithDeviceId:deviceId
                                                                         timestamp:timestamp
                                                                             title:@"ESM Radio"
                                                                      instructions:@"The user can only choose one option."
                                                                            submit:submit
                                                               expirationThreshold:exprationThreshold
                                                                           trigger:trigger
                                                                            radios:[NSArray arrayWithObjects:@"Aston Martin", @"Lotus", @"Jaguar", nil]];
    
    NSMutableDictionary *dicCheckBox = [SingleESMObject getEsmDictionaryAsCheckBoxWithDeviceId:deviceId
                                                                               timestamp:timestamp
                                                                                   title:@"ESM Checkbox"
                                                                            instructions:@"The user can choose multiple options."
                                                                                  submit:submit
                                                                     expirationThreshold:exprationThreshold
                                                                                 trigger:trigger
                                                                              checkBoxes:[NSArray arrayWithObjects:@"One", @"Two", @"Three", nil]];
    
    NSMutableDictionary *dicLikert = [SingleESMObject getEsmDictionaryAsLikertScaleWithDeviceId:deviceId
                                                                                timestamp:timestamp
                                                                                    title:@"ESM Likert"
                                                                             instructions:@"User rating 1 to 5 or 7 at 1 step increments."
                                                                                   submit:submit
                                                                      expirationThreshold:exprationThreshold
                                                                                  trigger:trigger
                                                                                likertMax:@7
                                                                           likertMaxLabel:@"3"
                                                                           likertMinLabel:@""
                                                                               likertStep:@1];
    
    NSMutableDictionary *dicQuick = [SingleESMObject getEsmDictionaryAsQuickAnswerWithDeviceId:deviceId
                                                                               timestamp:timestamp
                                                                                   title:@"ESM Quick Answer"
                                                                            instructions:@"One touch answer."
                                                                                  submit:submit
                                                                     expirationThreshold:exprationThreshold
                                                                                 trigger:trigger
                                                                            quickAnswers:[NSArray arrayWithObjects:@"Yes", @"No", @"Maybe", nil]];
    
    NSMutableDictionary *dicScale = [SingleESMObject getEsmDictionaryAsScaleWithDeviceId:deviceId
                                                                         timestamp:timestamp
                                                                             title:@"ESM Scale"
                                                                      instructions:@"Between 0 and 10 with 2 increments."
                                                                            submit:submit
                                                               expirationThreshold:exprationThreshold
                                                                           trigger:trigger
                                                                               min:@0
                                                                               max:@10
                                                                        scaleStart:@5
                                                                          minLabel:@"0"
                                                                          maxLabel:@"10"
                                                                         scaleStep:@1];
    
    NSMutableDictionary *dicDatePicker = [SingleESMObject getEsmDictionaryAsDatePickerWithDeviceId:deviceId
                                                                                   timestamp:timestamp
                                                                                       title:@"ESM Date Picker"
                                                                                instructions:@"The user selects date and time."
                                                                                      submit:submit
                                                                         expirationThreshold:exprationThreshold
                                                                                     trigger:trigger];
    
    NSMutableDictionary *dicPAM = [SingleESMObject getEsmDictionaryAsPAMWithDeviceId:deviceId
                                                                                         timestamp:timestamp
                                                                                             title:@"ESM Date Picker"
                                                                                      instructions:@"The user selects date and time."
                                                                                            submit:submit
                                                                               expirationThreshold:exprationThreshold
                                                                                           trigger:trigger];
    
//    NSMutableArray* esms = [[NSMutableArray alloc] initWithObjects:dicFreeText, dicRadio, dicCheckBox,dicLikert, dicQuick, dicScale, dicDatePicker, dicPAM, nil];
    
    NSMutableArray* esms = [[NSMutableArray alloc] initWithObjects:dicPAM, nil];
    
    return esms;
}

///////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////



- (BOOL) syncAwareDBWithData:(NSDictionary *)dictionary {
    return [super syncAwareDBWithData:dictionary];
}

//////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////

+ (BOOL)isAppearedThisSection{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults boolForKey:@"key_esm_appeared_section"];
}

+ (void)setAppearedState:(BOOL)state{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:state forKey:@"key_esm_appeared_section"];
}


@end
