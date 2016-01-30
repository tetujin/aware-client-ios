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
#import "AWAREKeys.h"
#import "ESM.h"
#import "AWAREEsmUtils.h"

@implementation Scheduler {
    NSMutableArray * scheduleManager; // This variable manages NSTimers.
    NSString * KEY_SCHEDULE;
    NSString * KEY_TIMER;
    NSString * KEY_PREVIOUS_SCHEDULE_JSON;
    NSTimer * dailyQuestionUpdateTimer;
    NSString* CONFIG_URL;
    NSString* KEY_LATEST_ESM_JSON_JSON_DATA;
    NSMutableData* resultData;
    NSDate* dailyUpdate;
    bool debug;
}

- (instancetype)initWithSensorName:(NSString *)sensorName {
    self = [super initWithSensorName:SENSOR_PLUGIN_CAMPUS];
    if (self) {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        debug = [userDefaults boolForKey:SETTING_DEBUG_STATE];
        resultData = [[NSMutableData alloc] init];
//                [super setSensorName:sensorName];
        scheduleManager = [[NSMutableArray alloc] init];
//        dailyUpdate = [self getTargetTimeAsNSDate:[NSDate new] hour:3 minute:0 second:0];
        _getConfigFileIdentifier = @"get_config_file_identifier";
        KEY_SCHEDULE = @"key_schedule";
        KEY_TIMER = @"key_timer";
        KEY_LATEST_ESM_JSON_JSON_DATA = @"key_latest_esm_json_date";
        KEY_PREVIOUS_SCHEDULE_JSON = @"key_previous_schedule_json";
//        CONFIG_URL = @"https://r2d2.hcii.cs.cmu.edu/esm/ad6e5ac2-ca24-436b-9e4f-77848918c7cb/master.json";
//        CONFIG_URL = @"http://r2d2.hcii.cs.cmu.edu/esm/master_ios.json";
        CONFIG_URL = [NSString stringWithFormat:@"http://r2d2.hcii.cs.cmu.edu/esm/%@/master.json", [self getDeviceId]];
    }
    return self;
}

- (NSData *) getLatestEsmJsonData {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSData * data = [userDefaults dataForKey:KEY_LATEST_ESM_JSON_JSON_DATA];
    return data;
}

-(void) setLatestEsmJsonData: (NSData*) jsonData{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:jsonData forKey:KEY_LATEST_ESM_JSON_JSON_DATA];
}


- (BOOL) isForeground {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults boolForKey:@"APP_STATE"];
}

- (void) setConfigFile:(id) sender {
    // Get Config URL from NSTimer of userInfo.
    resultData = [[NSMutableData alloc] init];
    
    double unixtime = [[NSDate new] timeIntervalSince1970];
    
    NSDictionary *dic = [(NSTimer *) sender userInfo];
    NSString *url = [dic objectForKey:@"configUrl"];
    url = [NSString stringWithFormat:@"%@?%f", url, unixtime];
    NSLog(@"--> %@", url);
    
    __weak NSURLSession *session = nil;
    NSURLSessionConfiguration *sessionConfig = nil;
    
//    double unixtime = [[NSDate new] timeIntervalSince1970];
    _getConfigFileIdentifier = [NSString stringWithFormat:@"%@%f", _getConfigFileIdentifier, unixtime];
    
    NSString *post = [NSString stringWithFormat:@"timestamp=%f&device_id=%@", unixtime, [self getDeviceId] ];
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%ld", [postData length]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:url]];
    //    [request setHTTPMethod:@"POST"];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:postData];
    
    if ([self isForeground]) {
        NSURLSession *session = [NSURLSession sharedSession];
        
        [[session dataTaskWithURL:[NSURL URLWithString:url] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            NSString* resString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"---> %@", resString);
            
            if (response && ! error) {
                // NOTE: For registrate a NSTimer in the backgroung, we have to set it in the main thread!
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self setEsmSchedulesWithJSONData:data];
                });
            }else{
                NSString* errorMessage = [NSString stringWithFormat:@"HTTP Connection Error: %@ %ld", error.debugDescription , error.code];
                NSLog(@"%@", errorMessage);
                // NOTE: case of error
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self setBackupEsmsWithNotification:errorMessage];
                });
                
            }
        }] resume];
    }else{
        sessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:_getConfigFileIdentifier];
        sessionConfig.timeoutIntervalForRequest =60; //180.0;
        sessionConfig.HTTPMaximumConnectionsPerHost = 60; //180;
        sessionConfig.timeoutIntervalForResource = 60*60*24; // 1 day
        sessionConfig.allowsCellularAccess = YES;
        sessionConfig.discretionary = YES;
        
        NSLog(@"--- This is background task for %@ ----", [self getSensorName] );
        session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];
        NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request];
        [dataTask resume];
    }
}


- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
    int responseCode = (int)[httpResponse statusCode];
    NSLog(@"%d",responseCode);
//    if(response != 200 && debug){
//        [self sendLocalNotificationForMessage: soundFlag:]
//    }
    [session finishTasksAndInvalidate];
    [session invalidateAndCancel];
    completionHandler(NSURLSessionResponseAllow);
}


-(void)URLSession:(NSURLSession *)session
         dataTask:(NSURLSessionDataTask *)dataTask
   didReceiveData:(NSData *)data {
    [session finishTasksAndInvalidate];
    [session invalidateAndCancel];
    [resultData appendData:data];
}



- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error {
    NSLog(@"--> finish");
    if (error != nil) {
        NSString* errorMessage = [NSString stringWithFormat:@"HTTP Connection Error: %@ %ld",
                                  error.debugDescription,
                                  error.code];
        NSLog(@"%@", errorMessage);
        // NOTE: case of error
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setBackupEsmsWithNotification:errorMessage];
        });
    }else{
        // NOTE: For registrate a NSTimer in the backgroung, we have to set it in the main thread!
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setEsmSchedulesWithJSONData:resultData];
        });
    }
    [session finishTasksAndInvalidate];
    [session invalidateAndCancel];
}

- (void) setBackupEsmsWithNotification:(NSString*) errorMessage {
    if (debug) {
        [self sendLocalNotificationForMessage:errorMessage soundFlag:NO];
    }
    NSData * data = [self getLatestEsmJsonData];
    if (data != nil) {
        [self setEsmSchedulesWithJSONData:data];
    }
}

- (void) setEsmSchedulesWithJSONData:(NSData *)data {
    
    NSError * error = nil;
    NSString * text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"==> %@",text);
    NSArray *schedules = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    
    if (error != nil) {
        NSLog(@"JSON FORMAT ERROR: %@", error.debugDescription);
        if(debug)[self setBackupEsmsWithNotification:@"JSON Format Error: AWARE iOS sets the schedules with backuped ESMs."];
        return;
    }else{
//        if(debug)[self setBackupEsmsWithNotification:@"Success to "];
        [self setLatestEsmJsonData:data];
    }
    
    [self stopSchedules];
    
    if(debug) [self sendLocalNotificationForMessage:@"AWARE updated ESM schedules." soundFlag:NO];
    
    NSMutableArray * awareSchedules = [[NSMutableArray alloc] init];
    
    //TODO
//    AWARESchedule * awareSchedule = [self getScheduleForTest];
//    awareSchedule.schedule = [NSDate new];
//    [awareSchedule setScheduleType:SCHEDULE_INTERVAL_TEST];
//    [awareSchedules addObject:awareSchedule];
    
    NSString* currentSchedules = @"";//[[NSString alloc] init];
    int i = 0;
    for (NSDictionary * schedule in schedules) {
        NSString * notificationTitle = @"BalancedCampus Question";
        NSString * body = @"Tap to answer.";
        NSString * identifier = [schedule objectForKey:@"schedule_id"];
        NSArray * hours = [schedule objectForKey:@"hours"];
        NSArray * esmsDic = [schedule objectForKey:@"esms"];
        // check esm_ios
        if (esmsDic != nil) {
            esmsDic = [self checkEsmIOS:esmsDic];
        }
        NSError *writeError = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:esmsDic options:0 error:&writeError];
        NSString * esmsStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        for (NSNumber * hour in hours) {
            i++;
            int intHour = [hour intValue]; //TODO
//            NSDate * fireDate = [NSDate new];//[self getTargetTimeAsNSDate:[NSDate new] hour:intHour];
            NSDate * fireDate = [self getTargetTimeAsNSDate:[NSDate new] hour:intHour];
            NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
//            [dateFormatter setDateFormat:@"yyyy-MM-dd 'at' h:mm a"];
            [dateFormatter setDateFormat:@"h:mm a"];
            NSString* fireDateString = [dateFormatter stringFromDate:fireDate];
            NSString * currentSchedule = [NSString stringWithFormat:@"'%@' at '[%@]'\n", identifier, fireDateString];
            currentSchedules = [NSString stringWithFormat:@"%@%@", currentSchedules, currentSchedule];
            
            AWARESchedule * schedule = [[AWARESchedule alloc] initWithScheduleId:identifier];
            [schedule setScheduleAsNormalWithDate:fireDate
                                     intervalType:SCHEDULE_INTERVAL_DAY
                                              esm:esmsStr
                                            title:notificationTitle
                                             body:body
                                       identifier:@"---"];
            schedule.schedule = fireDate;
            [awareSchedules addObject:schedule];
        }
    }
//    NSLog(@"%@", currentSchedules);
    [self setLatestValue:[NSString stringWithFormat:@"You have %d ESM schedules per one day.\n%@",i, currentSchedules]];
    [self startSchedules:awareSchedules];
}


- (NSMutableArray *)checkEsmIOS:esmsDic {
//    NSMutableDictionary esm = [[NSMutableDictionary alloc] initWithDictionary:esmsDic];
    NSMutableArray *newArray = [[NSMutableArray alloc] init];
    for (NSDictionary* esm in esmsDic) {
        NSMutableDictionary* newEsm = [[NSMutableDictionary alloc] initWithDictionary:esm];
        NSMutableDictionary* e = [newEsm objectForKey:@"esm"];
        NSNumber* iosModel = [e objectForKey:@"esm_ios"];
        if ([iosModel intValue] == 1) {
            NSString* iosInstruction = [e objectForKey:@"esm_ios_instruction"];
            NSString* iosTitle = [e objectForKey:@"esm_ios_title"];
            if (iosInstruction) {
                [e setValue:iosInstruction forKey:KEY_ESM_INSTRUCTIONS];
            }else{
                [e setValue:@"" forKey:KEY_ESM_INSTRUCTIONS];
            }
            if (iosTitle) {
                [e setValue:iosTitle forKey:KEY_ESM_TITLE];
            }else{
                [e setValue:@"" forKey:KEY_ESM_TITLE];
            }
            [e setValue:@4 forKey:KEY_ESM_TYPE];
            // remove additional object
            [e removeObjectForKey:@"esm_ios"];
            [e removeObjectForKey:@"esm_ios_instruction"];
            [e removeObjectForKey:@"esm_ios_title"];
        }
        [newArray addObject:newEsm]; // TODO: test
    }
    
    return newArray;
}


- (BOOL)startSensor:(double)upInterval withSettings:(NSArray *)settings{
    
    ESMStorageHelper *helper = [[ESMStorageHelper alloc] init];
    [helper removeEsmTexts];

    
    // init
    if ([self getDebugState]) {
        [self setBackupEsmsWithNotification:@"AWARE initializes ESM schedules with backup ESMs."];
    }
    
    NSMutableDictionary * dic = [[NSMutableDictionary alloc] init];
    [dic setObject:CONFIG_URL forKey:@"configUrl"];
    // --- TEST --
//    dailyUpdate = [AWAREUtils getTargetNSDate:[NSDate new] hour:11 minute:40 second:0 nextDay:NO];
//    dailyQuestionUpdateTimer = [[NSTimer alloc] initWithFireDate:dailyUpdate
//                                                        interval:60*60*24
//                                                          target:self
//                                                        selector:@selector(setConfigFile:)
//                                                        userInfo:dic
//                                                         repeats:YES];
//    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
//    [runLoop addTimer:dailyQuestionUpdateTimer forMode:NSDefaultRunLoopMode];
    
    
    dailyQuestionUpdateTimer = [NSTimer timerWithTimeInterval:0
                                                       target:self
                                                     selector:@selector(setConfigFile:)
                                                     userInfo:dic
                                                      repeats:NO];
    [dailyQuestionUpdateTimer fire];
    
    // init scheduler
    
    // Make schdules
//    AWARESchedule * test = [self getScheduleForTest];
//    AWARESchedule * drinkOne = [self getDringSchedule];
//    AWARESchedule * drinkTwo = [self getDringSchedule];
//    AWARESchedule * emotionOne = [self getEmotionSchedule];
//    AWARESchedule * emotionTwo = [self getEmotionSchedule];
//    AWARESchedule * emotionThree = [self getEmotionSchedule];
//    AWARESchedule * emotionFour = [self getEmotionSchedule];
//    
//    // Set Notification Time using -getTargetTimeAsNSDate:hour:minute:second method.
//    NSDate * now = [NSDate new];
//    drinkOne.schedule = [self getTargetTimeAsNSDate:now hour:9];
//    drinkTwo.schedule = [self getTargetTimeAsNSDate:now hour:1];
//    emotionOne.schedule = [self getTargetTimeAsNSDate:now hour:9];
//    emotionTwo.schedule = [self getTargetTimeAsNSDate:now hour:13];
//    emotionThree.schedule = [self getTargetTimeAsNSDate:now hour:17];
//    emotionFour.schedule = [self getTargetTimeAsNSDate:now hour:21];
////    [emotionFour setScheduleType:SCHEDULE_INTERVAL_TEST];
//    
//    test.schedule = now;
////    drinkTwo.schedule = now; //[self getTargetTimeAsNSDate:now hour:21 minute:52 second:0];
////    emotionFour.schedule = now;//[self getTargetTimeAsNSDate:now hour:13 minute:5 second:0];
////    [emotionFour setScheduleType:SCHEDULE_INTERVAL_TEST];
//    
//    // Add maked schedules to schedules
//    // Set a New ESMSchedule to a SchduleManager
//    NSMutableArray *schedules = [[NSMutableArray alloc] init]
//    ;
//    [schedules addObject:test];
//    [schedules addObject:drinkOne];
//    [schedules addObject:drinkTwo];
//    [schedules addObject:emotionOne];
//    [schedules addObject:emotionTwo];
//    [schedules addObject:emotionThree];
//    [schedules addObject:emotionFour];
//    
//    [self startSchedules:schedules];
    
    return NO;
}

- (void) startSchedules:(NSArray *) schedules {
    for (AWARESchedule * s in schedules) {
        NSMutableDictionary * userInfo = [[NSMutableDictionary alloc] init];
        [userInfo setObject:s.scheduleId forKey:@"schedule_id"];
        NSTimer * notificationTimer = [[NSTimer alloc] initWithFireDate:s.schedule //TODO
                                                               interval:[s.interval doubleValue]
                                                                 target:self
                                                               selector:@selector(scheduleAction:)
                                                               userInfo:userInfo//s.scheduleId
                                                                repeats:YES];
        
        //https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/Timers/Articles/usingTimers.html
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [runLoop addTimer:notificationTimer forMode:NSDefaultRunLoopMode];
        
        NSMutableDictionary * dic = [[NSMutableDictionary alloc] init];
        [dic setObject:s forKey:KEY_SCHEDULE];
        [dic setObject:notificationTimer forKey:KEY_TIMER];
        [scheduleManager addObject:dic];
    }
}

- (void) stopSchedules {
    // stop old esm schedules
    for (NSDictionary * dic in scheduleManager) {
        NSTimer* timer = [dic objectForKey:KEY_TIMER];
        [timer invalidate];
    }
    scheduleManager = [[NSMutableArray alloc] init];
}


- (void) scheduleAction: (NSTimer *) sender {
    // Get a schedule ID
    NSMutableDictionary * userInfo = sender.userInfo;
    NSString* scheduleId = [userInfo objectForKey:@"schedule_id"];
    NSNumber* unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
    // Search the target sechedule by the schedule ID
    for (NSDictionary * dic in scheduleManager) {
        AWARESchedule *schedule = [dic objectForKey:KEY_SCHEDULE];
        NSLog(@"%@ - %@", schedule.scheduleId, scheduleId);
        
        if ([schedule.scheduleId isEqualToString:scheduleId]) {
            NSString* esmStr = [self setEsmApperedTimestamp:schedule.esmStr withTimestamp:unixtime];
            NSNumber* timeout = [self getTimeout:schedule.esmStr];
            // Add esm text to local storage
            ESMStorageHelper * helper = [[ESMStorageHelper alloc] init];
            [helper addEsmText:esmStr withId:scheduleId timeout:timeout];
            [self sendLocalNotificationWithSchedule:schedule soundFlag:YES];
            
            // Save ESM
//            [AWAREEsmUtils saveEsmObjects:schedule withTimestamp:unixtime];
            break;
        }
    }
}


- (NSString *) setEsmApperedTimestamp:(NSString*) jsonStr withTimestamp:(NSNumber *) timestamp {
    /**
     * [{"esm":[{"":""},{"":""},{"":""}]}]
     * - esms -> array
     * - esm -> dictionary
     * - elements -> array
     * - element -> dictionary
     */
    
    NSError *writeError = nil;
    NSArray *esms = [NSJSONSerialization JSONObjectWithData:[jsonStr dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&writeError];

    if (writeError != nil) {
        NSLog(@"ERROR: %@", writeError.debugDescription);
        return jsonStr;
    }
    
    NSMutableArray * newEsms = [[NSMutableArray alloc] init];
    for (NSDictionary * esm in esms) {
        NSDictionary * elements = [esm objectForKey:@"esm"];
        NSMutableDictionary * newElements = [[NSMutableDictionary alloc] initWithDictionary:elements];
        [newElements setObject:timestamp forKey:@"timestamp"];
        NSMutableDictionary * newEsm = [[NSMutableDictionary alloc] init];
        [newEsm setObject:newElements forKey:@"esm"];
        [newEsms addObject:newEsm];
    }
    
    NSError * error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:newEsms options:0 error:&error];
    if (error != nil) {
        return jsonStr;
    }
    jsonStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    return jsonStr;
}

- (NSNumber *) getTimeout:(NSString*) jsonStr {
    /**
     * [{"esm":[{"":""},{"":""},{"":""}]}]
     * - esms -> array
     * - esm -> dictionary
     * - elements -> array
     * - element -> dictionary
     */
    NSNumber * timeout = [AWAREUtils getUnixTimestamp:[NSDate new]];
    NSError *writeError = nil;
    NSArray *esms = [NSJSONSerialization JSONObjectWithData:[jsonStr dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&writeError];
    if (writeError != nil) {
        NSLog(@"ERROR: %@", writeError.debugDescription);
        return timeout;
    }

//    NSMutableArray * newEsms = [[NSMutableArray alloc] init];
    for (NSDictionary * esm in esms) {
        NSDictionary * elements = [esm objectForKey:@"esm"];
        NSNumber * timeoutSecond = (NSNumber *)[elements objectForKey:@"esm_expiration_threshold"];
        NSDate * expireDate = [[NSDate alloc] initWithTimeIntervalSinceNow:[timeoutSecond doubleValue]];
        timeout =[AWAREUtils getUnixTimestamp:expireDate];
    }
    
    return timeout;
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
    localNotification.applicationIconBadgeNumber = 1; //TODO
    localNotification.hasAction = YES;
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}


- (NSDate *) getTargetTimeAsNSDate:(NSDate *) nsDate
                              hour:(int) hour {
    return [self getTargetTimeAsNSDate:nsDate hour:hour minute:0 second:0];
}

- (NSDate *) getTargetTimeAsNSDate:(NSDate *) nsDate
                              hour:(int) hour
                            minute:(int) minute
                            second:(int) second {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dateComps = [calendar components:NSYearCalendarUnit |
                                   NSMonthCalendarUnit  |
                                   NSDayCalendarUnit    |
                                   NSHourCalendarUnit   |
                                   NSMinuteCalendarUnit |
                                   NSSecondCalendarUnit fromDate:nsDate];
    [dateComps setDay:dateComps.day];
    [dateComps setHour:hour];
    [dateComps setMinute:minute];
    [dateComps setSecond:second];
    NSDate * targetNSDate = [calendar dateFromComponents:dateComps];
    // If the maked target day is newer than now, Aware remakes the target day as same time tomorrow.
    if ([targetNSDate timeIntervalSince1970] < [nsDate timeIntervalSince1970]) {
        [dateComps setDay:dateComps.day + 1];
        NSDate * tomorrowNSDate = [calendar dateFromComponents:dateComps];
        return tomorrowNSDate;
    }else{
        return targetNSDate;
    }
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
    NSMutableArray * esm = [[NSMutableArray alloc] init];
    for (NSDictionary * esmObj in arrayForJson) {
        NSMutableDictionary * dic = [[NSMutableDictionary alloc] init];
        [dic setObject:esmObj forKey:@"esm"];
        [esm addObject:dic];
    }
    NSData *data = [NSJSONSerialization dataWithJSONObject:esm options:0 error:nil];
    NSString* jsonStr =  [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    AWARESchedule * schedule = [[AWARESchedule alloc] initWithScheduleId:@"drink"];
    [schedule setScheduleAsNormalWithDate:[NSDate new]
                             intervalType:SCHEDULE_INTERVAL_DAY
                                      esm:jsonStr
                                    title:@"BalancedCampus Question"
                                     body:@"Tap to answer."
                               identifier:@"---"];
    return schedule;
}



- (AWARESchedule *) getEmotionSchedule{
    //    // Likert scale
    NSString * title = @"During the past hour, I would describe myself as..."
    "(Scale: 1=Disagree strongly; 2=Disagree slightly; 3=Neither agree nor disagree; 4=Agree slightly; 5=Agree strongly)";
    NSString *title2 = @"During the past hour, I have been..."
    "(Scale: 1=Not at all; 2=Slightly; 3=Somewhat; 4=Very; 5=Extremely)";
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
    

    NSDictionary * quietLikert = [esmObject getEsmDictionaryAsLikertScaleWithDeviceId:deviceId
                                                                      timestamp:timestamp
                                                                          title:title
                                                                   instructions:@"Quiet, reserved"
                                                                         submit:submit
                                                            expirationThreshold:exprationThreshold
                                                                        trigger:trigger
                                                                      likertMax:likertMax
                                                                 likertMaxLabel:likertMaxLabel
                                                                 likertMinLabel:likertMinLabel
                                                                     likertStep:likertStep];
    

    NSDictionary * compassionateLikert = [esmObject getEsmDictionaryAsLikertScaleWithDeviceId:deviceId
                                                                            timestamp:timestamp
                                                                                title:@""
                                                                         instructions:@"Compassionate, has a soft heart"
                                                                               submit:submit
                                                                  expirationThreshold:exprationThreshold
                                                                              trigger:trigger
                                                                            likertMax:likertMax
                                                                       likertMaxLabel:likertMaxLabel
                                                                       likertMinLabel:likertMinLabel
                                                                           likertStep:likertStep];

    NSDictionary * disorganizedLikert = [esmObject getEsmDictionaryAsLikertScaleWithDeviceId:deviceId
                                                                               timestamp:timestamp
                                                                                   title:@""
                                                                            instructions:@"Disorganized, indifferent"
                                                                                  submit:submit
                                                                     expirationThreshold:exprationThreshold
                                                                                 trigger:trigger
                                                                               likertMax:likertMax
                                                                          likertMaxLabel:likertMaxLabel
                                                                          likertMinLabel:likertMinLabel
                                                                              likertStep:likertStep];
    

    NSDictionary * emotionallyLikert = [esmObject getEsmDictionaryAsLikertScaleWithDeviceId:deviceId
                                                                              timestamp:timestamp
                                                                                  title:@""
                                                                           instructions:@"Emotionally stable, not easily upset"
                                                                                 submit:submit
                                                                    expirationThreshold:exprationThreshold
                                                                                trigger:trigger
                                                                              likertMax:likertMax
                                                                         likertMaxLabel:likertMaxLabel
                                                                         likertMinLabel:likertMinLabel
                                                                             likertStep:likertStep];

    
    NSDictionary * interestLikert = [esmObject getEsmDictionaryAsLikertScaleWithDeviceId:deviceId
                                                                            timestamp:timestamp
                                                                                title:@""
                                                                         instructions:@"Having little interest in abstract ideas"
                                                                               submit:submit
                                                                  expirationThreshold:exprationThreshold
                                                                              trigger:trigger
                                                                            likertMax:likertMax
                                                                       likertMaxLabel:likertMaxLabel
                                                                       likertMinLabel:likertMinLabel
                                                                           likertStep:likertStep];
    
    

    NSDictionary * stressedLikert = [esmObject getEsmDictionaryAsLikertScaleWithDeviceId:deviceId
                                                                          timestamp:timestamp
                                                                              title:title2
                                                                       instructions:@"Stressed, overwhelmed"
                                                                             submit:submit
                                                                expirationThreshold:exprationThreshold
                                                                            trigger:trigger
                                                                          likertMax:likertMax
                                                                     likertMaxLabel:likertMaxLabel
                                                                     likertMinLabel:likertMinLabel
                                                                         likertStep:likertStep];
    

    NSDictionary * productiveLikert = [esmObject getEsmDictionaryAsLikertScaleWithDeviceId:deviceId
                                                                           timestamp:timestamp
                                                                               title:@""
                                                                        instructions:@"Productive, curious, focused, attentive"
                                                                              submit:submit
                                                                 expirationThreshold:exprationThreshold
                                                                             trigger:trigger
                                                                           likertMax:likertMax
                                                                      likertMaxLabel:likertMaxLabel
                                                                      likertMinLabel:likertMinLabel
                                                                          likertStep:likertStep];
    

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
                 
    
    NSDictionary * havingRadio = [esmObject getEsmDictionaryAsRadioWithDeviceId:deviceId
                                                                       timestamp:timestamp
                                                                           title:@"Arousal and Positive/Negative Affect"
                                                                    instructions:@"During the past hour, I have been having..."
                                                                          submit:submit
                                                             expirationThreshold:exprationThreshold
                                                                         trigger:trigger
                                                                          radios: [[NSArray alloc] initWithObjects:@"Low energy", @"Somewhat low energy", @"Neutral", @"Somewhat high energy", @"High Energy", nil]];
    
    NSDictionary * feeringRadio = [esmObject getEsmDictionaryAsRadioWithDeviceId:deviceId
                                                                       timestamp:timestamp
                                                                           title:@""
                                                                    instructions:@"During the past hour, I have been feeling..."
                                                                          submit:submit
                                                             expirationThreshold:exprationThreshold
                                                                         trigger:trigger
                                                                          radios: [[NSArray alloc] initWithObjects:@"Negative", @"Somewhat negative", @"Neutral", @"Somewhat positive", @"Positive", nil]];
    
    NSArray* arrayForJson = [[NSArray alloc] initWithObjects:quietLikert, compassionateLikert, disorganizedLikert,emotionallyLikert, interestLikert, stressedLikert, productiveLikert, boredLikert, havingRadio, feeringRadio, nil];
    NSMutableArray * esm = [[NSMutableArray alloc] init];
    for (NSDictionary * esmObj in arrayForJson) {
        NSMutableDictionary * dic = [[NSMutableDictionary alloc] init];
        [dic setObject:esmObj forKey:@"esm"];
        [esm addObject:dic];
    }
    NSData *data = [NSJSONSerialization dataWithJSONObject:esm options:0 error:nil];
//    NSData *data = [NSJSONSerialization dataWithJSONObject:arrayForJson options:0 error:nil];
    NSString* jsonStr =  [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    AWARESchedule * schedule = [[AWARESchedule alloc] initWithScheduleId:@"emotion"];
    
    [schedule setScheduleAsNormalWithDate:[NSDate new]
                             intervalType:SCHEDULE_INTERVAL_DAY
                                      esm:jsonStr
                                    title:@"BalancedCampus Question"
                                     body:@"Tap to answer."
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
                                                                                likertMax:@7
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
    NSMutableArray * esm = [[NSMutableArray alloc] init];
    for (NSDictionary * esmObj in arrayForJson) {
        NSMutableDictionary * dic = [[NSMutableDictionary alloc] init];
        [dic setObject:esmObj forKey:@"esm"];
        [esm addObject:dic];
    }
//    [esm setObject:arrayForJson forKey:@"esm"];
    NSData *data = [NSJSONSerialization dataWithJSONObject:esm options:0 error:nil];
//    NSData *data = [NSJSONSerialization dataWithJSONObject:arrayForJson options:0 error:nil];
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
