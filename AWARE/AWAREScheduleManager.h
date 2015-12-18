//
//  AWAREScheduler.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 12/17/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "AWARESchedule.h"

@interface AWAREScheduleManager: NSObject

- (instancetype)initWithViewController:(UIViewController *) viewController;

- (void) addSchedule:(AWARESchedule *) schedule;
- (void) removeScheduleWithScheduleId:(NSString* ) scheduleId;
- (void) removeAllSchedules;
- (AWARESchedule * ) getScheduleByScheduleId:(NSString *)scheduleId;

- (void) showScheduleIds;

@end
