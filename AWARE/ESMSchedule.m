//
//  ESMSchedule.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 4/13/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "ESMSchedule.h"
#import "AWAREUtils.h"
#import "ESMStorageHelper.h"

@implementation ESMSchedule{
    ESMStorageHelper * helper;
    NSString* esmsJsonStr;
}

- (instancetype)init{
    self = [self initWithIdentifier:@""
                      scheduledESMs:nil
                          fireDates:nil
                              title:@""
                               body:@""
                           interval:NSCalendarUnitDay
                           category:@""
                               icon:0];
    if (self != nil) {
        
    }
    return self;
}


- (instancetype)initWithIdentifier:(NSString *)esmIdentifier{
    return [self initWithIdentifier:esmIdentifier
                      scheduledESMs:nil
                          fireDates:nil
                              title:@""
                               body:@""
                           interval:NSCalendarUnitDay
                           category:@""
                               icon:0
                            timeout:0];
}

- (instancetype)initWithIdentifier:(NSString *)esmIdentifier
                     scheduledESMs:(NSMutableArray *)esms
                         fireDates:(NSMutableArray *)dates
                             title:(NSString *)notificationTitle
                              body:(NSString *)notificationBody
                          interval:(NSCalendarUnit)interval
                          category:(NSString *)notificationCategory
                              icon:(NSInteger)iconNumber{
    return [self initWithIdentifier:esmIdentifier
                      scheduledESMs:esms
                          fireDates:dates
                              title:notificationTitle
                               body:notificationBody
                           interval:interval
                           category:notificationCategory
                               icon:iconNumber
                            timeout:0];
}

- (instancetype)initWithIdentifier:(NSString *)esmIdentifier
                     scheduledESMs:(NSMutableArray *)esms
                         fireDates:(NSMutableArray *)dates
                             title:(NSString *)notificationTitle
                              body:(NSString *)notificationBody
                          interval:(NSCalendarUnit)interval
                          category:(NSString *)notificationCategory
                              icon:(NSInteger)iconNumber
                           timeout:(NSInteger)second{
    self = [super init];
    if (self != nil) {
        helper = [[ESMStorageHelper alloc] init];
        _identifier = esmIdentifier;
        _scheduledESMs = esms;
        _fireDates = dates;
        _title = notificationTitle;
        _body = notificationBody;
        _interval = interval;
        _category = notificationCategory;
        _icon = iconNumber;
        _timeoutSecond = second;
        if (_scheduledESMs == nil) _scheduledESMs = [[NSMutableArray alloc] init];
        if (_fireDates == nil) _fireDates = [[NSMutableArray alloc] init];
        if (_timeoutSecond <= 0) _timeoutSecond = 60*10; // defualt timeout duration is 10 min
    }
    return self;

}

- (void)addESM:(NSDictionary *)esm{
    if (esm != nil) {
        [_scheduledESMs addObject:esm];
    }
}

- (void)addESMs:(NSArray *)esms{
    if (esms != nil) {
        for (NSDictionary * esm in esms) {
            [_scheduledESMs addObject:esm];
        }
    }
}

- (void) addFireDate:(NSDate *)date{
    if (date != nil){
        [_fireDates addObject:date];
    }
}

- (void)addFireDates:(NSArray *)dates{
    if(dates != nil){
        for (NSDate * date in dates){
            [_fireDates addObject:date];
        }
    }
}

-(BOOL)startScheduledESM{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm"];

    NSData *esmsData = [NSJSONSerialization dataWithJSONObject:_scheduledESMs options:0 error:nil];
    esmsJsonStr =  [[NSString alloc] initWithData:esmsData encoding:NSUTF8StringEncoding];
    
    for (NSDate * fireDate in _fireDates) {
        // Set notification
        [AWAREUtils sendLocalNotificationForMessage:_body
                                              title:_title
                                          soundFlag:YES
                                           category:_category
                                           fireDate:fireDate
                                     repeatInterval:_interval
                                           userInfo:nil
                                    iconBadgeNumber:_icon];
        
        // Add esm text to local storage
        [helper addEsmText:esmsJsonStr withId:_identifier timeout:[NSNumber numberWithInteger:_timeoutSecond]];
    }
    return YES;
}

- (BOOL)stopScheduledESM{
    for (UILocalNotification *notification in [[UIApplication sharedApplication] scheduledLocalNotifications]) {
        if([notification.category isEqualToString:_category]) {
            [[UIApplication sharedApplication] cancelLocalNotification:notification];
        }
    }
    
    if (esmsJsonStr != nil) {
        [helper removeEsmWithText:esmsJsonStr];
    }
    return YES;
}


@end
