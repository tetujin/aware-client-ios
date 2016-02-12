//
//  ESMObject.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 12/23/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "SingleESMObject.h"

NSString* const KEY_ESM_TYPE = @"esm_type";
NSString* const KEY_ESM_TITLE = @"esm_title";
NSString* const KEY_ESM_SUBMIT = @"esm_submit";
NSString* const KEY_ESM_INSTRUCTIONS = @"esm_instructions";
NSString* const KEY_ESM_RADIOS = @"esm_radios";
NSString* const KEY_ESM_CHECKBOXES = @"esm_checkboxes";
NSString* const KEY_ESM_LIKERT_MAX = @"esm_likert_max";
NSString* const KEY_ESM_LIKERT_MAX_LABEL = @"esm_likert_max_label";
NSString* const KEY_ESM_LIKERT_MIN_LABEL = @"esm_likert_min_label";
NSString* const KEY_ESM_LIKERT_STEP = @"esm_likert_step";
NSString* const KEY_ESM_QUICK_ANSWERS = @"esm_quick_answers";
NSString* const KEY_ESM_EXPIRATION_THRESHOLD = @"esm_expiration_threshold";
NSString* const KEY_ESM_STATUS = @"esm_status";
NSString* const KEY_ESM_USER_ANSWER_TIMESTAMP = @"double_esm_user_answer_timestamp";
NSString* const KEY_ESM_USER_ANSWER = @"esm_user_answer";
NSString* const KEY_ESM_TRIGGER = @"esm_trigger";
NSString* const KEY_ESM_SCALE_MIN = @"esm_scale_min";
NSString* const KEY_ESM_SCALE_MAX = @"esm_scale_max";
NSString* const KEY_ESM_SCALE_START = @"esm_scale_start";
NSString* const KEY_ESM_SCALE_MAX_LABEL = @"esm_scale_max_label";
NSString* const KEY_ESM_SCALE_MIN_LABEL = @"esm_scale_min_label";
NSString* const KEY_ESM_SCALE_STEP = @"esm_scale_step";
//NSString* const KEY_ESM_IOS = @"esm_ios";

@implementation SingleESMObject

- (instancetype)initWithEsm:(NSDictionary* )esmObject
{
    self = [super init];
    if (self) {
        [self setEsm:esmObject];
    }
    return self;
}


- (void) setEsm:(NSDictionary *) esmObject {
    
    NSDictionary * esm = [esmObject objectForKey:@"esm"];
    
    _esmObjectWithKey = [[NSMutableDictionary alloc] initWithDictionary:esmObject];
    _esmObject = [[NSMutableDictionary alloc] initWithDictionary:esm];
    _type = [NSNumber numberWithInteger:[[esm objectForKey:KEY_ESM_TYPE] integerValue]];
    _title = [esm objectForKey:KEY_ESM_TITLE];
    _submit = [esm objectForKey:KEY_ESM_SUBMIT];
    _instructions = [esm objectForKey:KEY_ESM_INSTRUCTIONS];
    _radios = [esm objectForKey:KEY_ESM_RADIOS];
    _checkBoxes = [esm objectForKey:KEY_ESM_CHECKBOXES];
    _likertMax = [NSNumber numberWithInteger:[[esm objectForKey:KEY_ESM_LIKERT_MAX] integerValue]];
    _likertMaxLabel = [esm objectForKey:KEY_ESM_LIKERT_MAX_LABEL];
    _likertMinLabel = [esm objectForKey:KEY_ESM_LIKERT_MIN_LABEL];
    _likerStep = [NSNumber numberWithInteger:[[esm objectForKey:KEY_ESM_LIKERT_STEP] integerValue]];
    _quickAnswers = [esm objectForKey:KEY_ESM_QUICK_ANSWERS];
    _expirationThreshold = [NSNumber numberWithInteger:[[esm objectForKey:KEY_ESM_EXPIRATION_THRESHOLD] integerValue]];
    _status = [NSNumber numberWithInteger:[[esm objectForKey:KEY_ESM_STATUS] integerValue]];
    _userAnswerTimestamp = [esm objectForKey:KEY_ESM_USER_ANSWER_TIMESTAMP];
    _userAnswer = [esm objectForKey:KEY_ESM_USER_ANSWER];
    _esmTrigger = [esm objectForKey:KEY_ESM_TRIGGER];
    _scaleMin = [NSNumber numberWithInteger:[[esm objectForKey:KEY_ESM_SCALE_MIN] integerValue]];
    _scaleMax = [NSNumber numberWithInteger:[[esm objectForKey:KEY_ESM_SCALE_MAX] integerValue]];
    _scaleStart = [NSNumber numberWithInteger:[[esm objectForKey:KEY_ESM_SCALE_START] integerValue]];
    _scaleMaxLabel = [esm objectForKey:KEY_ESM_SCALE_MAX_LABEL];
    _scaleMinLabel = [esm objectForKey:KEY_ESM_SCALE_MIN_LABEL];
    _scaleStep = [NSNumber numberWithInteger:[[esm objectForKey:KEY_ESM_SCALE_STEP] integerValue]];
//    _esmiOS = [NSNumber numberWithInteger:[[esm objectForKey:KEY_ESM_IOS] integerValue]];
}

- (bool)isSingleEsm{
    return YES;
}


/**
 * Make a skelton (NSMutableDictionary) for an ESM
 *
 * @param   deviceId        A device_id for an aware study
 * @param   timestamp       A timestamp value
 * @param   instructions    An instructions for the esm
 * @param   submit          A text for submit button
 * @param   expirationThreshold An expiration threshold value as a second
 * @param   trigger         An unique label for a trigger
 * @return A skelton (NSMutableDictionary) of an ESM
 */
- (NSMutableDictionary*) getEsmDictionaryWithDeviceId:(NSString*)deviceId
                                            timestamp:(double) timestamp
                                                 type:(NSNumber *) type
                                                title:(NSString *) title
                                         instructions:(NSString *) instructions
                                  expirationThreshold:(NSNumber *) expirationThreshold
                                              trigger:(NSString*) trigger {
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setObject:[NSNumber numberWithDouble:timestamp] forKey:@"timestamp"];
    [dic setObject:deviceId forKey:@"device_id"];
    [dic setObject:type forKey:KEY_ESM_TYPE];
    [dic setObject:title forKey:KEY_ESM_TITLE];
    [dic setObject:@"" forKey:KEY_ESM_SUBMIT];
    [dic setObject:instructions forKey:KEY_ESM_INSTRUCTIONS];
    [dic setObject:[[NSArray alloc] init] forKey:KEY_ESM_RADIOS];
    [dic setObject:[[NSArray alloc] init] forKey:KEY_ESM_CHECKBOXES];
    [dic setObject:@0 forKey:KEY_ESM_LIKERT_MAX];
    [dic setObject:@"" forKey:KEY_ESM_LIKERT_MAX_LABEL];
    [dic setObject:@"" forKey:KEY_ESM_LIKERT_MIN_LABEL];
    [dic setObject:@0 forKey:KEY_ESM_LIKERT_STEP];
    [dic setObject:[[NSArray alloc] init] forKey:KEY_ESM_QUICK_ANSWERS];
    [dic setObject:expirationThreshold forKey:KEY_ESM_EXPIRATION_THRESHOLD];
    [dic setObject:@"" forKey:KEY_ESM_STATUS];
    //        "double_esm_user_answer_timestamp default 0,"
    [dic setObject:@0 forKey:KEY_ESM_USER_ANSWER_TIMESTAMP];
    //        "esm_user_answer text default '',"
    [dic setObject:@"" forKey:KEY_ESM_USER_ANSWER];
    [dic setObject:trigger forKey:KEY_ESM_TRIGGER];
    [dic setObject:@0 forKey:KEY_ESM_SCALE_MIN];
    [dic setObject:@0 forKey:KEY_ESM_SCALE_MAX];
    [dic setObject:@0 forKey:KEY_ESM_SCALE_START];
    [dic setObject:@"" forKey:KEY_ESM_SCALE_MAX_LABEL];
    [dic setObject:@"" forKey:KEY_ESM_SCALE_MIN_LABEL];
    [dic setObject:@0 forKey:KEY_ESM_SCALE_STEP];
    return dic;
}


/**
 * Make an ESM Free Text (NSMutableDictionary) for a sample
 *
 * This ESM allows the user to provide free text input as context. This can be leveraged to capture sensor-challenging context, such personal opinions, moods and others.
 *
 * @param   deviceId        A device_id for an aware study
 * @param   timestamp       A timestamp value
 * @param   instructions    An instructions for the esm
 * @param   submit          A text for submit button
 * @param   expirationThreshold An expiration threshold value as a second
 * @param   trigger         An unique label for a trigger
 * @return  A NSMutableDictonary of an ESM Free Text (esm_type=1)
 */
- (NSMutableDictionary*) getEsmDictionaryAsFreeTextWithDeviceId:(NSString*)deviceId
                                                 timestamp:(double) timestamp
                                                     title:(NSString *) title
                                              instructions:(NSString *) instructions
                                                    submit:(NSString *) submit
                                       expirationThreshold:(NSNumber *) expirationThreshold
                                                   trigger:(NSString*) trigger {
    NSMutableDictionary* freeTextEsm = [self getEsmDictionaryWithDeviceId:deviceId
                                                                timestamp:timestamp
                                                                     type:@1
                                                                    title:title
                                                             instructions:instructions
                                                      expirationThreshold:expirationThreshold
                                                                  trigger:trigger];
    return freeTextEsm;
}


/**
 * Make an ESM Radio Button (NSMutableDictionary) for a sample
 *
 * This ESM only allows the user to select a single option from a list of alternatives. One of the options can be defined as “Other”, which will prompt the user to be more specific, replacing “Other” with the users’ defined option.
 *
 * @param   deviceId        A device_id for an aware study
 * @param   timestamp       A timestamp value
 * @param   instructions    An instructions for the esm
 * @param   submit          A text for submit button
 * @param   expirationThreshold An expiration threshold value as a second
 * @param   trigger         An unique label for a trigger
 * @param   radios          Labels for radio button
 * @return  A NSMutableDictonary of an ESM Radio Button (esm_type=2)
 */
- (NSMutableDictionary*) getEsmDictionaryAsRadioWithDeviceId:(NSString*)deviceId
                                                   timestamp:(double) timestamp
                                                       title:(NSString *) title
                                                instructions:(NSString *) instructions
                                                      submit:(NSString *) submit
                                         expirationThreshold:(NSNumber *) expirationThreshold
                                                     trigger:(NSString*) trigger
                                                      radios:(NSArray *) radios {
    NSMutableDictionary * radiosEsm = [self getEsmDictionaryWithDeviceId:deviceId
                                                            timestamp:timestamp
                                                                 type:@2
                                                                title:title
                                                         instructions:instructions
                                                  expirationThreshold:expirationThreshold
                                                              trigger:trigger];
    [radiosEsm setObject:radios forKey:KEY_ESM_RADIOS];
    return radiosEsm;
}



/**
 * Make an ESM Check Box (NSMutableDictionary) for a sample
 *
 * This ESM allows the user to select one or more options from a list of alternatives. Similar to the Radio ESM, one of the options can be defined as “Other”, which will prompt the user to be more specific, replacing “Other” with the users’ defined option.
 *
 * @param   deviceId        A device_id for an aware study
 * @param   timestamp       A timestamp value
 * @param   instructions    An instructions for the esm
 * @param   submit          A text for submit button
 * @param   expirationThreshold An expiration threshold value as a second
 * @param   trigger         An unique label for a trigger
 * @param   checkBoxes      Labels for check boxes
 * @return  NSMutableDictonary of an ESM Check Box (esm_type=3)
 */
- (NSMutableDictionary *) getEsmDictionaryAsCheckBoxWithDeviceId:(NSString*)deviceId
                                                       timestamp:(double) timestamp
                                                           title:(NSString *) title
                                                    instructions:(NSString *) instructions
                                                          submit:(NSString *) submit
                                             expirationThreshold:(NSNumber *) expirationThreshold
                                                         trigger:(NSString*) trigger
                                                      checkBoxes:(NSArray *) checkBoxes {
    NSMutableDictionary * checkBoxEsm = [self getEsmDictionaryWithDeviceId:deviceId
                                                                 timestamp:timestamp
                                                                      type:@3
                                                                     title:title
                                                              instructions:instructions
                                                       expirationThreshold:expirationThreshold
                                                                   trigger:trigger];
    [checkBoxEsm setObject:checkBoxes forKey:KEY_ESM_CHECKBOXES];
    return checkBoxEsm;
}



/**
 * Make an ESM Likert Scale (NSMutableDictionary) for a sample
 *
 * This ESM allows the user to provide ratings, between 0 and 5/7, at 0.5/1 increments. The likert scale labels are also customisable. The default rating is no rating.
 *
 * @param   deviceId        A device_id for an aware study
 * @param   timestamp       A timestamp value
 * @param   instructions    An instructions for the esm
 * @param   submit          A text for submit button
 * @param   expirationThreshold An expiration threshold value as a second
 * @param   trigger         An unique label for a trigger
 * @param   likertMax       A maximum value of the likert scale
 * @param   likertMaxLabel  A maximum value of the scale
 * @param   likertMinLabel  A minimum value of the scale
 * @param   likertStep      A likert steps
 * @return  NSMutableDictonary of an ESM Quick Answer (esm_type=4)
 */
- (NSMutableDictionary *) getEsmDictionaryAsLikertScaleWithDeviceId:(NSString*)deviceId
                                                          timestamp:(double) timestamp
                                                              title:(NSString *) title
                                                       instructions:(NSString *) instructions
                                                             submit:(NSString *) submit
                                                expirationThreshold:(NSNumber *) expirationThreshold
                                                            trigger:(NSString*) trigger
                                                          likertMax:(NSNumber *) likertMax
                                                     likertMaxLabel:(NSString *) likertMaxLabel
                                                     likertMinLabel:(NSString *) likertMinLabel
                                                         likertStep:(NSNumber *) likertStep {
    NSMutableDictionary * likertEsm = [self getEsmDictionaryWithDeviceId:deviceId
                                                               timestamp:timestamp
                                                                    type:@4
                                                                   title:title
                                                            instructions:instructions
                                                     expirationThreshold:expirationThreshold
                                                                 trigger:trigger];
    [likertEsm setObject:likertMax forKey:KEY_ESM_LIKERT_MAX];
    [likertEsm setObject:likertMaxLabel forKey:KEY_ESM_LIKERT_MAX_LABEL];
    [likertEsm setObject:likertMinLabel forKey:KEY_ESM_LIKERT_MIN_LABEL];
    [likertEsm setObject:likertStep forKey:KEY_ESM_LIKERT_STEP];
    return likertEsm;
}



/**
 * Make an ESM Quick Answer (NSMutableDictionary) for a sample
 *
 * This ESM allows the user to quickly answer the ESM. The button arrangement  is fluid, to support more or less inputs. Unlike previous ESMs , there is no “Cancel” button for this type of ESM. However, the user can dismiss the questionnaire by pressing the Home or Back button on the device.
 *
 * @param   deviceId        A device_id for an aware study
 * @param   timestamp       A timestamp value
 * @param   instructions    An instructions for the esm
 * @param   submit          A text for submit button
 * @param   expirationThreshold An expiration threshold value as a second
 * @param   trigger         An unique label for a trigger
 * @param   quickAnswers    Labels for quick answer
 * @return  NSMutableDictonary of an ESM Quick Answer (esm_type=5)
 */
- (NSMutableDictionary *) getEsmDictionaryAsQuickAnswerWithDeviceId:(NSString*)deviceId
                                                          timestamp:(double) timestamp
                                                              title:(NSString *) title
                                                       instructions:(NSString *) instructions
                                                             submit:(NSString *) submit
                                                expirationThreshold:(NSNumber *) expirationThreshold
                                                            trigger:(NSString*) trigger
                                                       quickAnswers:(NSArray *) quickAnswers {
    NSMutableDictionary * quickAnswerEsm = [self getEsmDictionaryWithDeviceId:deviceId
                                                                    timestamp:timestamp
                                                                         type:@5
                                                                        title:title
                                                                 instructions:instructions
                                                          expirationThreshold:expirationThreshold
                                                                      trigger:trigger];
    [quickAnswerEsm setObject:quickAnswers forKey:KEY_ESM_QUICK_ANSWERS];
    return quickAnswerEsm;
}



/**
 * Make a sample Scale ESM Object (NSMutableDictionary) for a DatePicker
 *
 * This ESM allows the user to select a value within a range of values. The range can be positive (e.g., X to Y) where X and Y are both positive numbers; or negatively balanced (e.g., -X to X), where X is the same value.
 *
 * @param   deviceId        A device_id for an aware study
 * @param   timestamp       A timestamp value
 * @param   instructions    An instructions for the esm
 * @param   submit          A text for submit button
 * @param   expirationThreshold An expiration threshold value as a second
 * @param   trigger         An unique label for a trigger
 * @param   min             A minimum value of the scale
 * @param   max             A maximum value of the scale
 * @param   scaleStart      A scale start value
 * @param   minLabel        A minimum value label
 * @param   maxLabel        A maximum value label
 * @param   scaleStep       A scale of step
 * @return  NSMutableDictonary of an ESM Scale (esm_type=6)
 */
- (NSMutableDictionary *) getEsmDictionaryAsScaleWithDeviceId:(NSString*)deviceId
                                                    timestamp:(double) timestamp
                                                        title:(NSString *) title
                                                 instructions:(NSString *) instructions
                                                       submit:(NSString *) submit
                                          expirationThreshold:(NSNumber *) expirationThreshold
                                                      trigger:(NSString*) trigger
                                                          min:(NSNumber *) min
                                                          max:(NSNumber *) max
                                                   scaleStart:(NSNumber *) start
                                                     minLabel:(NSString *) minLabel
                                                     maxLabel:(NSString *) maxLabel
                                                    scaleStep:(NSNumber *) scaleStep {
    NSMutableDictionary *scaleEsm = [self getEsmDictionaryWithDeviceId:deviceId
                                                             timestamp:timestamp
                                                                  type:@6
                                                                 title:title
                                                          instructions:instructions
                                                   expirationThreshold:expirationThreshold
                                                               trigger:trigger];
    [scaleEsm setObject:min forKey:KEY_ESM_SCALE_MIN];
    [scaleEsm setObject:max forKey:KEY_ESM_SCALE_MAX];
    [scaleEsm setObject:start forKey:KEY_ESM_SCALE_START];
    [scaleEsm setObject:minLabel forKey:KEY_ESM_SCALE_MIN_LABEL];
    [scaleEsm setObject:maxLabel forKey:KEY_ESM_SCALE_MAX_LABEL];
    [scaleEsm setObject:scaleStep forKey:KEY_ESM_SCALE_STEP];
    return scaleEsm;
}

/**
 * Make a sample ESM Object (NSMutableDictionary) for a DatePicker
 *
 * @param   deviceId        A device_id for an aware study
 * @param   timestamp       A timestamp value
 * @param   instructions    An instructions for the esm
 * @param   submit          A text for submit button
 * @param   expirationThreshold An expiration threshold value as a second
 * @param   trigger         An unique label for a trigger
 * @return  NSMutableDictonary of a sample ESM Object for DatePicker (esm_type=7)
 */
- (NSMutableDictionary *) getEsmDictionaryAsDatePickerWithDeviceId:(NSString*)deviceId
                                                         timestamp:(double) timestamp
                                                             title:(NSString *) title
                                                      instructions:(NSString *) instructions
                                                            submit:(NSString *) submit
                                               expirationThreshold:(NSNumber *) expirationThreshold
                                                           trigger:(NSString*) trigger{
    NSMutableDictionary * datePickerEsm = [self getEsmDictionaryWithDeviceId:deviceId
                                                                   timestamp:timestamp
                                                                        type:@7
                                                                       title:title
                                                                instructions:instructions
                                                         expirationThreshold:expirationThreshold
                                                                     trigger:trigger];
    return datePickerEsm;
}

@end
