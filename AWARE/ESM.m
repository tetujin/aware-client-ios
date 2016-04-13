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


@implementation ESM {
    ESMStorageHelper * helper;
}

- (instancetype)initWithSensorName:(NSString *)sensorName withAwareStudy:(AWAREStudy *)study{
    self = [super initWithSensorName:@"esms" withAwareStudy:study];
    if (self) {
        helper = [[ESMStorageHelper alloc] init];
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


- (BOOL) syncAwareDBWithData:(NSDictionary *)dictionary {
    return [super syncAwareDBWithData:dictionary];
}

- (BOOL)startSensor:(double)upInterval withSettings:(NSArray *)settings{
    
//    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//    [dateFormatter setDateFormat:@"HH:mm"];
//    
//    NSString * esmId = @"test_esm";
//    NSString * notificationTitle = @"ESM from AWARE iOS client";
//    NSString * notificationBody = @"Tap to answer!";
//    NSString * esmJsonStr = [self getESMStringForTest];
//    NSDate   * fireDate = [AWAREUtils getTargetNSDate:[NSDate new] hour:10 minute:0 second:0 nextDay:YES];
//    NSString * notificationMessage = [NSString stringWithFormat:@"[%@] %@", [dateFormatter stringFromDate:fireDate], notificationBody];
//    
//    // Set notification
//    [AWAREUtils sendLocalNotificationForMessage:notificationMessage
//                                          title:notificationTitle
//                                      soundFlag:YES
//                                       category:[self getSensorName]
//                                       fireDate:fireDate
//                                 repeatInterval:NSCalendarUnitDay
//                                       userInfo:nil
//                                iconBadgeNumber:1];
//    
//    // Add esm text to local storage
//    [helper addEsmText:esmJsonStr withId:esmId timeout:@0];
    
    return YES;
}

- (BOOL) stopSensor {
    
    // Remove all ESMs from
//    [helper removeEsmTexts];
//    
//    // Remove all ESM notification from sharedApplication
//    for (UILocalNotification *notification in [[UIApplication sharedApplication] scheduledLocalNotifications]) {
//        if([notification.category isEqualToString:[self getSensorName]]) {
//            [[UIApplication sharedApplication] cancelLocalNotification:notification];
//        }
//    }
    
    return YES;
}

////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////

- (NSString *) getESMStringForTest {
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
    
    
    NSArray* esms = [[NSArray alloc] initWithObjects:dicFreeText, dicRadio, dicCheckBox,dicLikert, dicQuick, dicScale, dicDatePicker, nil];
    
    NSData *esmsData = [NSJSONSerialization dataWithJSONObject:esms options:0 error:nil];
    NSString* esmsJsonStr =  [[NSString alloc] initWithData:esmsData encoding:NSUTF8StringEncoding];
    
    return esmsJsonStr;
}


@end
