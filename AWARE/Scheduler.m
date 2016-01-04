//
//  Scheduler.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 12/17/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "Scheduler.h"
#import "AWARESchedule.h"
#import "ESMStorageHelper.h"
#import "SingleESMObject.h"

@implementation Scheduler {
    NSMutableArray * scheduleManager; // This variable manages NSTimers.
    NSString * KEY_SCHEDULE;
    NSString * KEY_TIMER;
}

- (instancetype)initWithSensorName:(NSString *)sensorName {
    self = [super initWithSensorName:@"scheduler"];
    if (self) {
        //        [super setSensorName:sensorName];
        scheduleManager = [[NSMutableArray alloc] init];
        KEY_SCHEDULE = @"key_schedule";
        KEY_TIMER = @"key_timer";
    }
    return self;
}

- (BOOL)startSensor:(double)upInterval withSettings:(NSArray *)settings{
    
    ESMStorageHelper *helper = [[ESMStorageHelper alloc] init];
    [helper removeEsmTexts];
    
    // Set a New ESMSchedule to a SchduleManager
    NSMutableArray *schedules = [[NSMutableArray alloc] init];
//    [schedules addObject:[self getScheduleForTest]];
    [schedules addObject:[self getDringSchedule]];
    [schedules addObject:[self getEmotionSchedule]];
    for (AWARESchedule * s in schedules) {
        
        NSTimer * notificationTimer = [NSTimer scheduledTimerWithTimeInterval:[s.interval doubleValue]
                                                                       target:self
                                                                     selector:@selector(scheduleAction:)
                                                                     userInfo:s.scheduleId
                                                                      repeats:YES];
        [notificationTimer fire];
        NSMutableDictionary * dic = [[NSMutableDictionary alloc] init];
        [dic setObject:s forKey:KEY_SCHEDULE];
        [dic setObject:notificationTimer forKey:KEY_TIMER];
        [scheduleManager addObject:dic];
        
//        [self scheduleAction:s.scheduleId];
    }
    return NO;
}


- (void) scheduleAction: (NSTimer *) sender {
    // Get a schedule ID
    NSString* scheduleId = [sender userInfo];
    // Search the target sechedule by the schedule ID
    for (NSDictionary * dic in scheduleManager) {
        AWARESchedule *schedule = [dic objectForKey:KEY_SCHEDULE];
        NSLog(@"%@ - %@", schedule.scheduleId, scheduleId);
        
        if ([schedule.scheduleId isEqualToString:scheduleId]) {
            NSString* esmStr = schedule.esmStr;
            // Add esm text to local storage
            ESMStorageHelper * helper = [[ESMStorageHelper alloc] init];
            [helper addEsmText:esmStr];
            [self sendLocalNotificationWithSchedule:schedule soundFlag:YES];
            break;
        }
    }
}

- (BOOL)stopSensor {
    for (NSDictionary * dic in scheduleManager) {
//        AWARESchedule *schedule = [dic objectForKey:KEY_SCHEDULE];
        NSTimer* timer = [dic objectForKey:KEY_TIMER];
        [timer invalidate];
    }
    scheduleManager = [[NSMutableArray alloc] init];
    ESMStorageHelper * helper = [[ESMStorageHelper alloc] init];
    [helper removeEsmTexts];
    return YES;
}

- (void) sendLocalNotificationWithSchedule : (AWARESchedule *) schedule
                                 soundFlag : (BOOL) soundFlag{
    if (schedule == nil) {
        return;
    }
    
    UILocalNotification *localNotification = [UILocalNotification new];
    CGFloat currentVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    NSLog(@"OS:%f", currentVersion);
    if (currentVersion >= 9.0){
        localNotification.alertTitle = schedule.title;
        localNotification.alertBody = schedule.body;
    } else {
        localNotification.alertBody = schedule.body;
    }
    localNotification.fireDate = [NSDate new];
    localNotification.timeZone = [NSTimeZone localTimeZone];
    localNotification.category = schedule.scheduleId;
    if(soundFlag) {
        localNotification.soundName = UILocalNotificationDefaultSoundName;
    }
    localNotification.hasAction = YES;
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}


- (AWARESchedule *) getDringSchedule{
    SingleESMObject *esmObject = [[SingleESMObject alloc] init];
    NSString * deviceId = @"";
    double timestamp = 0;
    NSString * submit = @"Next";
    NSString * trigger = @"AWARE Tester";
    
    // Scale
    NSMutableDictionary *startDatePicker = [esmObject getEsmDictionaryAsDatePickerWithDeviceId:deviceId
                                                                                     timestamp:timestamp
                                                                                         title:@""
                                                                                  instructions:@"Did you drink any alcohol yesterday? If so, approximately what time did you START drinking?"
                                                                                        submit:submit
                                                                           expirationThreshold:@60
                                                                                       trigger:trigger];
    
    NSMutableDictionary *stopDatePicker = [esmObject getEsmDictionaryAsDatePickerWithDeviceId:deviceId
                                                                                    timestamp:timestamp
                                                                                        title:@""
                                                                                 instructions:@"Approximately what time did you STOP drinking?"
                                                                                       submit:submit
                                                                          expirationThreshold:@60
                                                                                      trigger:trigger];
    
    NSMutableDictionary *drinks = [esmObject getEsmDictionaryAsScaleWithDeviceId:deviceId
                                                                       timestamp:timestamp
                                                                           title:@""
                                                                    instructions:@"How many drinks did you have over this time period?"
                                                                          submit:submit
                                                             expirationThreshold:@60
                                                                         trigger:trigger
                                                                             min:@0
                                                                             max:@10
                                                                      scaleStart:@0
                                                                        minLabel:@"0"
                                                                        maxLabel:@"10"
                                                                       scaleStep:@1];
    
    // radio
    NSMutableDictionary *dicRadio = [esmObject getEsmDictionaryAsRadioWithDeviceId:deviceId
                                                                         timestamp:timestamp
                                                                             title:@""
                                                                      instructions:@"Mark any of the reasons you drink alcohol"
                                                                            submit:submit
                                                               expirationThreshold:@60
                                                                           trigger:trigger
                                                                            radios:[NSArray arrayWithObjects:@"Because it makes social events more fun", @"To forget about my problems", @"Because like the feeling", @"So I won't feel left out", @"None", @"Other", nil]];
    
    NSArray* arrayForJson = [[NSArray alloc] initWithObjects:startDatePicker, stopDatePicker, drinks, dicRadio, nil];
    NSData *data = [NSJSONSerialization dataWithJSONObject:arrayForJson options:0 error:nil];
    NSString* jsonStr =  [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    AWARESchedule * schedule = [[AWARESchedule alloc] initWithScheduleId:@"drink"];
    [schedule setScheduleAsNormalWithDate:[NSDate new]
                             intervalType:SCHEDULE_INTERVAL_HOUR
                                      esm:jsonStr
                                    title:@"You have a ESM!"
                                     body:@"Please answer a ESM. Thank you."
                               identifier:@"---"];
    return schedule;
}



- (AWARESchedule *) getEmotionSchedule{
    //    // Likert scale
    NSString * title = @"In the past couple hours, I have been feeling: (Scale: 1=Not at all; 2=A litle bit; 3=somewhat; 4=very much; 5=extremely)";
    NSString * deviceId = @"";
    NSString * submit = @"Next";
    double timestamp = 0;
    NSNumber * exprationThreshold = [NSNumber numberWithInt:60];
    NSString * trigger = @"trigger";
    NSNumber *likertMax = @5;
    NSString *likertMaxLabel = @"3";
    NSString *likertMinLabel = @"";
    NSNumber *likertStep = @0;
    SingleESMObject *esmObject = [[SingleESMObject alloc] init];
    
//    _____ Happy, joyful, satisfied, loved
    NSDictionary * happyLikert = [esmObject getEsmDictionaryAsLikertScaleWithDeviceId:deviceId
                                                                      timestamp:timestamp
                                                                          title:title
                                                                   instructions:@"Happy, joyful, satisfied, loved"
                                                                         submit:submit
                                                            expirationThreshold:exprationThreshold
                                                                        trigger:trigger
                                                                      likertMax:likertMax
                                                                 likertMaxLabel:likertMaxLabel
                                                                 likertMinLabel:likertMinLabel
                                                                     likertStep:likertStep];
    
//    _____ Stressed, overwhelmed
    NSDictionary * stressedLikert = [esmObject getEsmDictionaryAsLikertScaleWithDeviceId:deviceId
                                                                            timestamp:timestamp
                                                                                title:@""
                                                                         instructions:@"Stressed, overwhelmed"
                                                                               submit:submit
                                                                  expirationThreshold:exprationThreshold
                                                                              trigger:trigger
                                                                            likertMax:likertMax
                                                                       likertMaxLabel:likertMaxLabel
                                                                       likertMinLabel:likertMinLabel
                                                                           likertStep:likertStep];
//    
//    _____ Hopeful, optimistic, Enthusiastic
    NSDictionary * hopefulLikert = [esmObject getEsmDictionaryAsLikertScaleWithDeviceId:deviceId
                                                                               timestamp:timestamp
                                                                                   title:@""
                                                                            instructions:@"Hopeful, optimistic, Enthusiastic"
                                                                                  submit:submit
                                                                     expirationThreshold:exprationThreshold
                                                                                 trigger:trigger
                                                                               likertMax:likertMax
                                                                          likertMaxLabel:likertMaxLabel
                                                                          likertMinLabel:likertMinLabel
                                                                              likertStep:likertStep];
    
//    
//    _____ Tired, slow, exhausted
    NSDictionary * tiredLikert = [esmObject getEsmDictionaryAsLikertScaleWithDeviceId:deviceId
                                                                              timestamp:timestamp
                                                                                  title:@""
                                                                           instructions:@"Tired, slow, exhausted"
                                                                                 submit:submit
                                                                    expirationThreshold:exprationThreshold
                                                                                trigger:trigger
                                                                              likertMax:likertMax
                                                                         likertMaxLabel:likertMaxLabel
                                                                         likertMinLabel:likertMinLabel
                                                                             likertStep:likertStep];
    
//
//    _____ Sad, depressed, lonely, miserable
    NSDictionary * sadLikert = [esmObject getEsmDictionaryAsLikertScaleWithDeviceId:deviceId
                                                                            timestamp:timestamp
                                                                                title:@""
                                                                         instructions:@"Sad, depressed, lonely, miserable"
                                                                               submit:submit
                                                                  expirationThreshold:exprationThreshold
                                                                              trigger:trigger
                                                                            likertMax:likertMax
                                                                       likertMaxLabel:likertMaxLabel
                                                                       likertMinLabel:likertMinLabel
                                                                           likertStep:likertStep];
    
//
//    _____ Calm, relieved
    NSDictionary * calmLikert = [esmObject getEsmDictionaryAsLikertScaleWithDeviceId:deviceId
                                                                          timestamp:timestamp
                                                                              title:@""
                                                                       instructions:@"Calm, relieved"
                                                                             submit:submit
                                                                expirationThreshold:exprationThreshold
                                                                            trigger:trigger
                                                                          likertMax:likertMax
                                                                     likertMaxLabel:likertMaxLabel
                                                                     likertMinLabel:likertMinLabel
                                                                         likertStep:likertStep];
    
//
//    _____ Bored
    NSDictionary * boredLikert = [esmObject getEsmDictionaryAsLikertScaleWithDeviceId:deviceId
                                                                           timestamp:timestamp
                                                                               title:@""
                                                                        instructions:@"Bored"
                                                                              submit:submit
                                                                 expirationThreshold:exprationThreshold
                                                                             trigger:trigger
                                                                           likertMax:likertMax
                                                                      likertMaxLabel:likertMaxLabel
                                                                      likertMinLabel:likertMinLabel
                                                                          likertStep:likertStep];
    
//    
//    _____ Creative
    NSDictionary * creativeLikert = [esmObject getEsmDictionaryAsLikertScaleWithDeviceId:deviceId
                                                                            timestamp:timestamp
                                                                                title:@""
                                                                         instructions:@"Creative"
                                                                               submit:submit
                                                                  expirationThreshold:exprationThreshold
                                                                              trigger:trigger
                                                                            likertMax:likertMax
                                                                       likertMaxLabel:likertMaxLabel
                                                                       likertMinLabel:likertMinLabel
                                                                           likertStep:likertStep];
//    
//    _____ Reserved, quiet
    NSDictionary * reservedLikert = [esmObject getEsmDictionaryAsLikertScaleWithDeviceId:deviceId
                                                                            timestamp:timestamp
                                                                                title:@""
                                                                         instructions:@"Reserved, quiet"
                                                                               submit:submit
                                                                  expirationThreshold:exprationThreshold
                                                                              trigger:trigger
                                                                            likertMax:likertMax
                                                                       likertMaxLabel:likertMaxLabel
                                                                       likertMinLabel:likertMinLabel
                                                                           likertStep:likertStep];
    
//    
//    _____ Jealous, envious
    NSDictionary * jealousLikert = [esmObject getEsmDictionaryAsLikertScaleWithDeviceId:deviceId
                                                                            timestamp:timestamp
                                                                                title:@""
                                                                         instructions:@"Jealous, envious"
                                                                               submit:submit
                                                                  expirationThreshold:exprationThreshold
                                                                              trigger:trigger
                                                                            likertMax:likertMax
                                                                       likertMaxLabel:likertMaxLabel
                                                                       likertMinLabel:likertMinLabel
                                                                           likertStep:likertStep];
//    
//    _____ Anxious, upset, hurt, disappointed
    NSDictionary * anxiousLikert = [esmObject getEsmDictionaryAsLikertScaleWithDeviceId:deviceId
                                                                            timestamp:timestamp
                                                                                title:@""
                                                                         instructions:@"Anxious, upset, hurt, disappointed"
                                                                               submit:submit
                                                                  expirationThreshold:exprationThreshold
                                                                              trigger:trigger
                                                                            likertMax:likertMax
                                                                       likertMaxLabel:likertMaxLabel
                                                                       likertMinLabel:likertMinLabel
                                                                           likertStep:likertStep];
    
//    
//    _____ Sympathetic, warm, thoughtful, loving
    NSDictionary * sympatheticLikert = [esmObject getEsmDictionaryAsLikertScaleWithDeviceId:deviceId
                                                                              timestamp:timestamp
                                                                                  title:@""
                                                                           instructions:@"Sympathetic, warm, thoughtful, loving"
                                                                                 submit:submit
                                                                    expirationThreshold:exprationThreshold
                                                                                trigger:trigger
                                                                              likertMax:likertMax
                                                                         likertMaxLabel:likertMaxLabel
                                                                         likertMinLabel:likertMinLabel
                                                                             likertStep:likertStep];
    
//    
//    _____ Disorganized, careless, indifferent
    NSDictionary * disorganizedLikert = [esmObject getEsmDictionaryAsLikertScaleWithDeviceId:deviceId
                                                                                  timestamp:timestamp
                                                                                      title:@""
                                                                               instructions:@"Disorganized, careless, indifferent"
                                                                                     submit:submit
                                                                        expirationThreshold:exprationThreshold
                                                                                    trigger:trigger
                                                                                  likertMax:likertMax
                                                                             likertMaxLabel:likertMaxLabel
                                                                             likertMinLabel:likertMinLabel
                                                                                 likertStep:likertStep];
    
//    
//    _____ Confident, dependable, self-disciplined, determined
    NSDictionary * confidentLikert = [esmObject getEsmDictionaryAsLikertScaleWithDeviceId:deviceId
                                                                                   timestamp:timestamp
                                                                                       title:@""
                                                                                instructions:@"Confident, dependable, self-disciplined, determined"
                                                                                      submit:submit
                                                                         expirationThreshold:exprationThreshold
                                                                                     trigger:trigger
                                                                                   likertMax:likertMax
                                                                              likertMaxLabel:likertMaxLabel
                                                                              likertMinLabel:likertMinLabel
                                                                                  likertStep:likertStep];
    
//    
//    _____ Critical, quarrelsome, stubborn
    NSDictionary * criticalLikert = [esmObject getEsmDictionaryAsLikertScaleWithDeviceId:deviceId
                                                                                timestamp:timestamp
                                                                                    title:@""
                                                                             instructions:@"Critical, quarrelsome, stubborn"
                                                                                   submit:submit
                                                                      expirationThreshold:exprationThreshold
                                                                                  trigger:trigger
                                                                                likertMax:likertMax
                                                                           likertMaxLabel:likertMaxLabel
                                                                           likertMinLabel:likertMinLabel
                                                                               likertStep:likertStep];
//
//    _____ Alert, focused, productive
    NSDictionary * alertLikert = [esmObject getEsmDictionaryAsLikertScaleWithDeviceId:deviceId
                                                                               timestamp:timestamp
                                                                                   title:@""
                                                                            instructions:@"Alert, focused, productive"
                                                                                  submit:submit
                                                                     expirationThreshold:exprationThreshold
                                                                                 trigger:trigger
                                                                               likertMax:likertMax
                                                                          likertMaxLabel:likertMaxLabel
                                                                          likertMinLabel:likertMinLabel
                                                                              likertStep:likertStep];
    
//
//    _____ Conventional, uncreative
    NSDictionary * conventionalLikert = [esmObject getEsmDictionaryAsLikertScaleWithDeviceId:deviceId
                                                                            timestamp:timestamp
                                                                                title:@""
                                                                         instructions:@"Conventional, uncreative"
                                                                               submit:submit
                                                                  expirationThreshold:exprationThreshold
                                                                              trigger:trigger
                                                                            likertMax:likertMax
                                                                       likertMaxLabel:likertMaxLabel
                                                                       likertMinLabel:likertMinLabel
                                                                           likertStep:likertStep];
    
//
//    _____ Confused, frustrated, unfocused, puzzled
    NSDictionary * confusedLikert = [esmObject getEsmDictionaryAsLikertScaleWithDeviceId:deviceId
                                                                                   timestamp:timestamp
                                                                                       title:@""
                                                                                instructions:@"Confused, frustrated, unfocused, puzzled"
                                                                                      submit:submit
                                                                         expirationThreshold:exprationThreshold
                                                                                     trigger:trigger
                                                                                   likertMax:likertMax
                                                                              likertMaxLabel:likertMaxLabel
                                                                              likertMinLabel:likertMinLabel
                                                                                  likertStep:likertStep];
    
//    
//    _____ Guilty, ashamed, embarrassed, regretful
    NSDictionary * guiltyLikert = [esmObject getEsmDictionaryAsLikertScaleWithDeviceId:deviceId
                                                                               timestamp:timestamp
                                                                                   title:@""
                                                                            instructions:@"Guilty, ashamed, embarrassed, regretful"
                                                                                  submit:submit
                                                                     expirationThreshold:exprationThreshold
                                                                                 trigger:trigger
                                                                               likertMax:likertMax
                                                                          likertMaxLabel:likertMaxLabel
                                                                          likertMinLabel:likertMinLabel
                                                                              likertStep:likertStep];
    
//
//    _____ extravert, talkative
    NSDictionary * extravertLikert = [esmObject getEsmDictionaryAsLikertScaleWithDeviceId:deviceId
                                                                             timestamp:timestamp
                                                                                 title:@""
                                                                          instructions:@"extravert, talkative"
                                                                                submit:submit
                                                                   expirationThreshold:exprationThreshold
                                                                               trigger:trigger
                                                                             likertMax:likertMax
                                                                        likertMaxLabel:likertMaxLabel
                                                                        likertMinLabel:likertMinLabel
                                                                            likertStep:likertStep];
    
    
    
    NSArray* arrayForJson = [[NSArray alloc] initWithObjects:happyLikert, stressedLikert, hopefulLikert, tiredLikert, sadLikert, calmLikert, boredLikert, creativeLikert, reservedLikert, jealousLikert, anxiousLikert, sympatheticLikert,disorganizedLikert,confidentLikert, criticalLikert, alertLikert, conventionalLikert, confusedLikert, guiltyLikert, extravertLikert, nil];
    NSData *data = [NSJSONSerialization dataWithJSONObject:arrayForJson options:0 error:nil];
    NSString* jsonStr =  [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    AWARESchedule * schedule = [[AWARESchedule alloc] initWithScheduleId:@"emotion"];
    [schedule setScheduleAsNormalWithDate:[NSDate new]
                             intervalType:SCHEDULE_INTERVAL_HOUR
                                      esm:jsonStr
                                    title:@"You have a ESM!"
                                     body:@"Please answer a ESM. Thank you."
                               identifier:@"---"];
    return schedule;
}


- (AWARESchedule *)getScheduleForTest {
    NSString * deviceId = @"";
    NSString * submit = @"Next";
    double timestamp = 0;
    NSNumber * exprationThreshold = [NSNumber numberWithInt:60];
    NSString * trigger = @"trigger";
    SingleESMObject *esmObject = [[SingleESMObject alloc] init];
    
    NSMutableDictionary *dicFreeText = [esmObject getEsmDictionaryAsFreeTextWithDeviceId:deviceId
                                                                              timestamp:timestamp
                                                                                  title:@"ESM Freetext"
                                                                           instructions:@"The user can answer an open ended question." submit:submit
                                                                    expirationThreshold:exprationThreshold
                                                                                trigger:trigger];
    
    //    NSMutableDictionary *dicRadio = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *dicRadio = [esmObject getEsmDictionaryAsRadioWithDeviceId:deviceId
                                                                         timestamp:timestamp
                                                                             title:@"ESM Radio"
                                                                      instructions:@"The user can only choose one option."
                                                                            submit:submit
                                                               expirationThreshold:exprationThreshold
                                                                           trigger:trigger
                                                                            radios:[NSArray arrayWithObjects:@"Aston Martin", @"Lotus", @"Jaguar", nil]];
    
    //    NSMutableDictionary *dicCheckBox = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *dicCheckBox = [esmObject getEsmDictionaryAsCheckBoxWithDeviceId:deviceId
                                                                               timestamp:timestamp
                                                                                   title:@"ESM Checkbox"
                                                                            instructions:@"The user can choose multiple options."
                                                                                  submit:submit
                                                                     expirationThreshold:exprationThreshold
                                                                                 trigger:trigger
                                                                              checkBoxes:[NSArray arrayWithObjects:@"One", @"Two", @"Three", nil]];
    
    //    NSMutableDictionary *dicLikert = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *dicLikert = [esmObject getEsmDictionaryAsLikertScaleWithDeviceId:deviceId
                                                                                timestamp:timestamp
                                                                                    title:@"ESM Likert"
                                                                             instructions:@"User rating 1 to 5 or 7 at 1 step increments."
                                                                                   submit:submit
                                                                      expirationThreshold:exprationThreshold
                                                                                  trigger:trigger
                                                                                likertMax:@5
                                                                           likertMaxLabel:@"3"
                                                                           likertMinLabel:@""
                                                                               likertStep:@1];
    
    //    NSMutableDictionary *dicQuick = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *dicQuick = [esmObject getEsmDictionaryAsQuickAnswerWithDeviceId:deviceId
                                                                               timestamp:timestamp
                                                                                   title:@"ESM Quick Answer"
                                                                            instructions:@"One touch answer."
                                                                                  submit:submit
                                                                     expirationThreshold:exprationThreshold
                                                                                 trigger:trigger
                                                                            quickAnswers:[NSArray arrayWithObjects:@"Yes", @"No", @"Maybe", nil]];
    
    //    NSMutableDictionary *dicScale = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *dicScale = [esmObject getEsmDictionaryAsScaleWithDeviceId:deviceId
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
    
    //    NSMutableDictionary *datePicker = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *dicDatePicker = [esmObject getEsmDictionaryAsDatePickerWithDeviceId:deviceId
                                                                                   timestamp:timestamp
                                                                                       title:@"ESM Date Picker"
                                                                                instructions:@"The user selects date and time."
                                                                                      submit:submit
                                                                         expirationThreshold:exprationThreshold
                                                                                     trigger:trigger];
    
    
    NSArray* arrayForJson = [[NSArray alloc] initWithObjects:dicFreeText, dicRadio, dicCheckBox,dicLikert, dicQuick, dicScale, dicDatePicker, nil];
    NSData *data = [NSJSONSerialization dataWithJSONObject:arrayForJson options:0 error:nil];
    NSString* jsonStr =  [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    AWARESchedule * schedule = [[AWARESchedule alloc] initWithScheduleId:@"SOME SPECIAL ID"];
    [schedule setScheduleAsNormalWithDate:[NSDate new]
                             intervalType:SCHEDULE_INTERVAL_TEST
                                      esm:jsonStr
                                    title:@"You have a ESM!"
                                     body:@"Please answer a ESM. Thank you."
                               identifier:@"---"];
    return schedule;
}



@end
