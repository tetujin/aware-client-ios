//
//  AWAREScheduler.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 12/17/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWAREScheduleManager.h"
#import "AWARESchedule.h"
#import "AWAREKeys.h"

@implementation AWAREScheduleManager
{
    UIViewController *_viewController;
    NSMutableArray *awareSchedules;
}


- (instancetype)initWithViewController:(UIViewController *) viewController
{
    self = [super init];
    if (self) {
        _viewController = viewController;
        [self removeAllSchedules];
        awareSchedules = [[NSMutableArray alloc] init];
    }
    return self;
}


- (void) addSchedule:(AWARESchedule *) schedule
{
    // set local notification base on the schdule information
    [self sendLocalNotificationWithSchedule:schedule
                                  soundFlag:YES
                                   fireDate:schedule.schedule
                               fireInterval:[schedule getInterval] ];
    // save shcdules to the list
    [awareSchedules addObject:schedule];
}


- (void) showScheduleIds
{
    int count = 0;
    for (AWARESchedule * schedule in awareSchedules) {
        NSLog(@"[%d] %@", count, schedule.scheduleId);
        count++;
    }
}

- (void) removeScheduleWithScheduleId:(NSString* ) scheduleId
{
    
}


- (AWARESchedule * ) getScheduleByScheduleId:(NSString *)scheduleId
{
    for (AWARESchedule * schedule in awareSchedules) {
        NSLog(@"%@ - %@", schedule.scheduleId, scheduleId);
        if ([schedule.scheduleId isEqualToString:scheduleId]) {
            return schedule;
        }
    }
    return nil;
}


- (void) removeAllSchedules
{
//    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[UIApplication sharedApplication] cancelAllLocalNotifications];;
    [awareSchedules removeAllObjects];
}


- (void) sendLocalNotificationWithSchedule : (AWARESchedule *) schedule
                               soundFlag : (BOOL) soundFlag
                                fireDate : (NSDate *) fireDate
                               fireInterval:(NSInteger ) interval
{
//    if ( fireDate == nil || [fireDate timeIntervalSinceNow] <= 0 ) {
//        return;
//    }
    if (schedule == nil) {
        return;
    }
    
    UILocalNotification *localNotification = [UILocalNotification new];
//    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    CGFloat currentVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    NSLog(@"OS:%f", currentVersion);
    if (currentVersion >= 9.0){
        localNotification.alertTitle = schedule.title;
        localNotification.alertBody = schedule.body;
    } else {
        localNotification.alertBody = schedule.body;
    }
    localNotification.fireDate = fireDate;
    localNotification.timeZone = [NSTimeZone localTimeZone];
    localNotification.category = schedule.scheduleId;
//    switch ( interval ) {
//        case 1:
//            localNotification.repeatInterval = NSMinuteCalendarUnit;
//            break;
//        case 2:
//            localNotification.repeatInterval = NSHourCalendarUnit;
//            break;
//        case 3:
//            localNotification.repeatInterval = NSDayCalendarUnit;
//            break;
//        case 4:
//            localNotification.repeatInterval = NSWeekCalendarUnit;
//            break;
//        default:
//            localNotification.repeatInterval = 0;
//            break;
//    }
//    if (interval <= 0) {
    localNotification.repeatInterval = interval;
//    }
    if(soundFlag) {
        localNotification.soundName = UILocalNotificationDefaultSoundName;
    }
    localNotification.hasAction = YES;
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}


//- (void)registerForNotification {
//    
//    UIMutableUserNotificationAction *action1;
//    action1 = [[UIMutableUserNotificationAction alloc] init];
//    [action1 setActivationMode:UIUserNotificationActivationModeBackground];
//    [action1 setTitle:@"Action 1"];
//    [action1 setIdentifier:NotificationActionOneIdent];
//    [action1 setDestructive:NO];
//    [action1 setAuthenticationRequired:NO];
//    
//    UIMutableUserNotificationAction *action2;
//    action2 = [[UIMutableUserNotificationAction alloc] init];
//    [action2 setActivationMode:UIUserNotificationActivationModeBackground];
//    [action2 setTitle:@"Action 2"];
//    [action2 setIdentifier:NotificationActionTwoIdent];
//    [action2 setDestructive:NO];
//    [action2 setAuthenticationRequired:NO];
//    
//    UIMutableUserNotificationCategory *actionCategory;
//    actionCategory = [[UIMutableUserNotificationCategory alloc] init];
//    [actionCategory setIdentifier:NotificationCategoryIdent];
//    [actionCategory setActions:@[action1, action2]
//                    forContext:UIUserNotificationActionContextDefault];
//    
//    NSSet *categories = [NSSet setWithObject:actionCategory];
//    UIUserNotificationType types = (UIUserNotificationTypeAlert|
//                                    UIUserNotificationTypeSound|
//                                    UIUserNotificationTypeBadge);
//    
//    UIUserNotificationSettings *settings;
//    settings = [UIUserNotificationSettings settingsForTypes:types
//                                                 categories:categories];
//    
//    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
//}


@end
