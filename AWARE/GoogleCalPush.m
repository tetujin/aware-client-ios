//
//  GoogleCalPush.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 1/4/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "GoogleCalPush.h"
#import "Debug.h"

@implementation GoogleCalPush {
    EKEventStore *store;
    NSTimer * calendarUpdateTimer;
    NSString* AWARE_CAL_NAME;
    NSDate * fireDate;
}

- (instancetype)initWithSensorName:(NSString *)sensorName withAwareStudy:(AWAREStudy *)study{
    self = [super initWithSensorName:sensorName withAwareStudy:study];
    if (self) {
        NSDate* date = [NSDate date];
        fireDate  = [AWAREUtils getTargetNSDate:date hour:20 minute:0 second:0 nextDay:NO];
    
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"HH:mm"];
        NSString *formattedDateString = [dateFormatter stringFromDate:fireDate];
        [super setLatestValue:[NSString stringWithFormat:@"Next Calendar Update: %@", formattedDateString]];
        NSLog(@"date: %@", fireDate );
        AWARE_CAL_NAME = @"BalancedCampusJournal";
        store = [[EKEventStore alloc] init];
        [store requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error){
            if(granted){
                NSLog(@"ok");
            }else{
                NSLog(@"no");
            }
        }];
    }
    return self;
}

- (BOOL) isTargetCalendarCondition {
    bool isAvaiable = NO;
    EKEventStore *tempStore = [[EKEventStore alloc] init];
    //    for (EKSource *calSource in tempStore.sources) {
    for (EKCalendar *cal in [tempStore calendarsForEntityType:EKEntityTypeEvent]) {
        NSLog(@"%@", cal.title);
        if ([cal.title isEqualToString:@"BalancedCampusJournal"]) {
            isAvaiable = YES;
        }
    }
    return isAvaiable;
}

- (void) showTargetCalendarCondition {
    bool isAvaiable = NO;
    EKEventStore *tempStore = [[EKEventStore alloc] init];
    for (EKCalendar *cal in [tempStore calendarsForEntityType:EKEntityTypeEvent]) {
        NSLog(@"%@", cal.title);
        if ([cal.title isEqualToString:@"BalancedCampusJournal"]) {
            isAvaiable = YES;
        }
    }
    
    tempStore = nil;
    if (isAvaiable) {
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Correct"
                                                         message:@"'BalancedCampusJournal' calendar is available!"
                                                        delegate:self
                                               cancelButtonTitle:@"Cancel"
                                               otherButtonTitles:nil];
        [alert show];
    }else{
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Miss"
                                                         message:@"AWARE can not find 'BalancedCampusJournal' calendar."
                                                        delegate:self
                                               cancelButtonTitle:@"Cancel"
                                               otherButtonTitles:nil];
        [alert show];
    }
}


- (BOOL)startSensor:(double)upInterval withSettings:(NSArray *)settings {
    
    [self setDailyNotification];
//    [self startLocationSensor];

    return YES;
}


- (void) setDailyNotification {
    // Get fix time
    calendarUpdateTimer = [[NSTimer alloc] initWithFireDate:fireDate
                                                   interval:60*60*24
                                                     target:self
                                                   selector:@selector(checkAllEvents:)
                                                   userInfo:nil
                                                    repeats:YES];
//    [calendarUpdateTimer fire];
    
    //https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/Timers/Articles/usingTimers.html
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    [runLoop addTimer:calendarUpdateTimer forMode:NSDefaultRunLoopMode];
    
    // Make yesterday's pre-popluated events
    NSDate * yesterday = [AWAREUtils getTargetNSDate:[NSDate new] hour:-24 minute:0 second:0 nextDay:NO];
    [self makePrePopulateEvetnsWith:yesterday];
    
}



- (void) checkAllEvents:(id) sender {
    // Get all events
//    NSLog(@"Cal event id updated !!!");
    NSDate * now = [NSDate new];
//    NSDate * yesterday = [AWAREUtils getTargetNSDate:now hour:-24 minute:0 second:0 nextDay:NO];
    [self makePrePopulateEvetnsWith:now];
//    [self makePrePopulateEvetnsWith:yesterday];
}

- (void) makePrePopulateEvetnsWith:(NSDate *) date {
    
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setDateFormat:@"HH:mm:ss"];
    NSString * debugMessage = [NSString stringWithFormat:@"[%@] BalancedCampusJournal Plugin start to populate events at ", [timeFormat stringFromDate:date]];
    [self saveDebugEventWithText:debugMessage type:DebugTypeInfo label:[timeFormat stringFromDate:date]];
    
    EKCalendar * awareCal = nil;
    // Get the aware calendar in Google Calendars
    for (EKCalendar * cal in [store calendarsForEntityType:EKEntityTypeEvent]) {
        NSLog(@"[%@] %@", cal.title, cal.calendarIdentifier );
        if ([cal.title isEqualToString:AWARE_CAL_NAME]) {
            awareCal = cal;
        }
    }
    
    if (awareCal == nil) {
        NSString* message = @"[ERROR] AWARE iOS can not find a 'BalancedCampusJournal' on your Calendar.";
        NSLog(@"%@", message);
        [AWAREUtils sendLocalNotificationForMessage:message soundFlag:YES];
        [self saveDebugEventWithText:message type:DebugTypeError label:@""];
        return;
    }
    
    //http://stackoverflow.com/questions/1889164/get-nsdate-today-yesterday-this-week-last-week-this-month-last-month-var
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *components = [cal components:( NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit ) fromDate:date];
    [components setHour:-[components hour]];
    [components setMinute:-[components minute]];
    [components setSecond:-[components second]];
    NSDate *startDate = [cal dateByAddingComponents:components toDate:date options:0];
    //This variable should now be pointing at a date object that is the start of today (midnight);
    
    [components setDay:1];
    NSDate *endDate = [cal dateByAddingComponents:components toDate:date options:0];
    
    NSMutableArray * currentEvents = [[NSMutableArray alloc] init];
    NSMutableArray * existingJournalEvents = [[NSMutableArray alloc] init];
    NSMutableArray * prepopulatedEvents = [[NSMutableArray alloc] init];
    NSPredicate *predicate = [store predicateForEventsWithStartDate:startDate
                                                            endDate:endDate
                                                          calendars:nil];
    __block bool finished = NO;
    [store enumerateEventsMatchingPredicate:predicate usingBlock:^(EKEvent *ekEvent, BOOL *stop) {
        // Check this event against each ekObjectID in notification
        //        NSLog(@"%@", ekEvent.title);
        if (!ekEvent.allDay) {
            [currentEvents addObject:ekEvent]; // add all events
            if(ekEvent.calendar != awareCal){
                [existingJournalEvents addObject:ekEvent]; // add existing journal events
            }else{
                //                NSLog(@"%@", ekEvent.debugDescription);
                [prepopulatedEvents addObject:ekEvent];
            }
        }
        finished = stop;
    }];
    
    int count = 0;
    bool isEmpty = NO;
    while (!finished ) {
        [NSThread sleepForTimeInterval:0.05];
        NSLog(@"%d",count);
        if (count > 60) { // wait 60 sec (maximum)
            NSString * debugMessage = @"TIMEOUT: Calendar Update";
            [AWAREUtils sendLocalNotificationForMessage:debugMessage soundFlag:NO];
            [self saveDebugEventWithText:debugMessage type:DebugTypeError label:@""];
            isEmpty = YES;
            break;
        }
        count++;
    }
    
    /**
     * Make Null Events to ArrayList
     */
    NSDate * startOfNSDate = [AWAREUtils getTargetNSDate:date hour:0 minute:0 second:0 nextDay:NO];
    NSDate * endOfNSDate = [AWAREUtils getTargetNSDate:date hour:24 minute:0 second:0 nextDay:NO];
    NSDate * tempNSDate = startOfNSDate;
    NSMutableArray * nullTimes = [[NSMutableArray alloc] init];
    for ( int i=0; i<currentEvents.count; i++) {
        EKEvent * event= [currentEvents objectAtIndex:i];
        NSDate * nullEnd = event.startDate;
        int gap = [nullEnd timeIntervalSince1970] - [tempNSDate timeIntervalSince1970];
        NSLog(@"Gap between events %d", gap);
        if (gap > 0) {
            [nullTimes addObject:[[NSArray alloc] initWithObjects:tempNSDate, nullEnd, nil]];
        }
        tempNSDate = event.endDate;
    }
    if (tempNSDate != nil) {
        if (([endOfNSDate timeIntervalSince1970] - [tempNSDate timeIntervalSince1970]) > 0) {
            [nullTimes addObject:[[NSArray alloc] initWithObjects:tempNSDate, endOfNSDate, nil]];
        }
    }else{
        if (nullTimes.count == 0) {
            [nullTimes addObject:[[NSArray alloc] initWithObjects:startOfNSDate, endOfNSDate, nil]];
        }
    }
    
    NSMutableArray * preNullEvents = [[NSMutableArray alloc] init];
    //    EKEvent *preLastEvent = [EKEvent eventWithEventStore:store];
    NSDate * nullStartDate = [AWAREUtils getTargetNSDate:date hour:0 minute:0 second:0 nextDay:NO];
    NSDate * nullEndDate = [AWAREUtils getTargetNSDate:date  hour:0 minute:0 second:0 nextDay:NO];
    for ( EKEvent * event in prepopulatedEvents ) {
        //        if (preLastEvent != nil) {
        NSDate * nullStart = nullEndDate;
        NSDate * nullEnd = event.startDate;
        int gap = [nullEnd timeIntervalSince1970] - [nullStart timeIntervalSince1970];
        if (gap > 0) {
            [preNullEvents addObject:[[NSArray alloc] initWithObjects:nullStart, nullEnd, nil]];
        }
        //        }
        nullStartDate = event.startDate;
        nullEndDate = event.endDate;
    }
    
    if (preNullEvents.count == 0 && prepopulatedEvents.count > 0) {
        NSString * debugMessage = @"Your Google Calandar is already updated today.";
        if ([self getDebugState]) {
            [AWAREUtils sendLocalNotificationForMessage:debugMessage soundFlag:YES];
        }
        [self saveDebugEventWithText:debugMessage type:DebugTypeInfo label:@""];
        return;
    }
    
    /**
     * Make hours ArrayList
     */
    NSMutableArray *hours = [[NSMutableArray alloc] init];
    for (int i=0; i<25; i++) {
        NSDate * today = date;
        [hours addObject:[AWAREUtils getTargetNSDate:today hour:i minute:0 second:0 nextDay:NO]];
        
    }
    
//    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
//    [timeFormat setDateFormat:@"HH:mm:ss"];
    //    NSString * prepopulateTitle = @"#event_category #Location #brief_description";
    NSString * prepopulateTitle = @"#event_category #Location #brief_description";
    
    /**
     * Add pre-populate events to calendar!
     */
    for (NSArray * times in nullTimes) {
        NSDate * nullStart = [times objectAtIndex:0];
        NSDate * nullEnd = [times objectAtIndex:1];
        NSDate * tempNullTime = nullStart;
        
        if ((nullEnd.timeIntervalSince1970 - nullStart.timeIntervalSince1970) == 0) {
            continue;
        }
        
        for (int i=0; i<hours.count; i++) {
            NSDate * currentHour = [hours objectAtIndex:i];
            //set start date
            if (tempNullTime <= currentHour ){
                if (nullEnd >= currentHour) {
                    EKEvent * event = [EKEvent eventWithEventStore:store];
                    event.title = prepopulateTitle;
                    event.calendar  = awareCal;
                    double gap = [nullEnd timeIntervalSince1970] - [currentHour timeIntervalSince1970];
                    if ( gap < 60*60) {
                        event.startDate = tempNullTime;
                        event.endDate   = currentHour;
                        
                        // Make a New Calendar
                        EKEvent * additionalEvent = [EKEvent eventWithEventStore:store];
                        additionalEvent.title = prepopulateTitle;
                        additionalEvent.calendar  = awareCal;
                        additionalEvent.startDate = currentHour;
                        additionalEvent.endDate = nullEnd;
                        int gap = [additionalEvent.endDate timeIntervalSince1970] - [additionalEvent.startDate timeIntervalSince1970];
                        if (gap > 0) {
                            NSError * e = nil;
                            [store saveEvent:additionalEvent span:EKSpanThisEvent commit:YES error:&e];
                            if (e != nil) {
                                NSString * debugString = [NSString stringWithFormat:@"[%d] error: %@", i, e.debugDescription];
                                NSLog(@"%@", debugString);
                                [self saveDebugEventWithText:debugString type:DebugTypeError label:[self getSensorName]];
                            } else {
                                NSLog(@"[%d] success!", i);
                            }
                        }
                    } else {
                        // NSLog(@"start:%@  end:%@", [timeFormat stringFromDate:tempNullTime], [timeFormat stringFromDate:currentHour]);
                        NSLog(@"%@ - %@", [timeFormat stringFromDate:tempNullTime], [timeFormat stringFromDate:currentHour]);
                        event.startDate = tempNullTime;
                        event.endDate   = currentHour;
                    }
                    
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, i * 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                        NSError * error;
                        double gapgap = [event.endDate timeIntervalSince1970] - [event.startDate timeIntervalSince1970];
                        if (gapgap > 0) {
                            [store saveEvent:event span:EKSpanThisEvent commit:YES error:&error];
                            if (error != nil) {
//                                NSLog(@"[%d] error: %@", i, error.debugDescription);
                                NSString * debugString = [NSString stringWithFormat:@"[%d] error: %@", i, error.debugDescription];
                                NSLog(@"%@", debugString);
                                [self saveDebugEventWithText:debugString type:DebugTypeError label:[self getSensorName]];
                            }else{
                                NSLog(@"[%d] success to store  ", i);
                            }
                        }else{
                            
                        }
                    });
                    tempNullTime = currentHour;
                }
            }
        }
    }
    
    
    // Add null events: startDate - endDate
    //    if (lastEvent != nil) {
    //        NSDate * nullStart = lastEvent.endDate;
    //        NSDate * nullEnd = event.startDate;
    //        int gap = [nullEnd timeIntervalSince1970] - [nullStart timeIntervalSince1970];
    //        if (gap > 0) {
    //            [nullTimes addObject:[[NSArray alloc] initWithObjects:nullStart, nullEnd, nil]];
    //        }
    //    }
    //    lastEvent = event;
    
    
    
    /**
     * Copy Existing Events
     */
    int g = 1;
    for ( EKEvent * event in existingJournalEvents ) {
        bool isPrepopulated = NO;
        for (EKEvent * preEvent in prepopulatedEvents) {
            if ([preEvent.title isEqualToString:event.title] &&
                [preEvent.startDate isEqualToDate:event.startDate] &&
                [preEvent.endDate isEqualToDate:event.endDate]) {
                isPrepopulated = YES;
                break;
            }
        }
        
        if (isPrepopulated) {
            continue;
        }
        
        // Add questions to a note of aware events
        EKEvent * awareEvent = [EKEvent eventWithEventStore:store];
        awareEvent.notes = event.notes;
        awareEvent.title = event.title;
        awareEvent.startDate = event.startDate;
        awareEvent.endDate = event.endDate;
        awareEvent.location = event.location;
        // Change an aware event's calendar
        awareEvent.calendar = awareCal;
        // Save events to the aware calendar
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, g * 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            NSError * error = nil;
            [store saveEvent:awareEvent span:EKSpanThisEvent commit:YES error:&error];
            if (error != nil) {
//                NSLog(@"[%d] error: %@", g, error.debugDescription);
                NSString * debugString = [NSString stringWithFormat:@"[%d] error: %@", g , error.debugDescription];
                NSLog(@"%@", debugString);
                [self saveDebugEventWithText:debugString type:DebugTypeError label:[self getSensorName]];
            }else{
                NSLog(@"[%d] success!",g);
            }
        });
        g++;
    }
    
    // == Send Notification ==
    NSString * message = @"Hi! Your Calendar is updated.";
    [AWAREUtils sendLocalNotificationForMessage:message soundFlag:YES];
    [self saveDebugEventWithText:message type:DebugTypeInfo label:[self getSensorName]];

}

- (BOOL) stopSensor {
    [calendarUpdateTimer invalidate];
    calendarUpdateTimer = nil;
    return YES;
}



@end
