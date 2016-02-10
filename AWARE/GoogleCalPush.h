//
//  GoogleCalPush.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 1/4/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"
#import <EventKit/EventKit.h>
#import <EventKitUI/EventKitUI.h>
#import <UIKit/UIKit.h>

@interface GoogleCalPush : AWARESensor <AWARESensorDelegate, UIAlertViewDelegate>

- (BOOL) isTargetCalendarCondition;
- (void) showTargetCalendarCondition;

@end
