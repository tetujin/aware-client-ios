//
//  GoogleCal.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 12/18/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

/**
 * How about save events via Apple Calender
 */

#import "GoogleCalPull.h"
#import "AWAREKeys.h"
#import <CoreData/CoreData.h>

@implementation GoogleCalPull {
    // for calendar events
    EKEventStore *store;
    EKSource *awareCalSource;
    NSTimer * calRefreshTimer;
    NSMutableArray *allEvents;
    EKEvent * dailyNotification;
    
    NSString* googleCalPullSensorName;
    
    // for locations
    double miniDistrance;
//    IBOutlet CLLocationManager *locationManager;

    // for AWARE sensor
//    NSTimer* uploadTimer;
    
    // static variable
    NSString* AWARE_CAL_EVENT_UPDATE;
    NSString* AWARE_CAL_EVENT_DELETE;
    NSString* AWARE_CAL_EVENT_ADD;
    
    NSString* AWARE_CAL_NAME;
    NSString* PRIMARY_GOOGLE_ACCOUNT_NAME;
    
    NSString* CAL_ID;
    NSString* ACCOUNT_NAME;
    NSString* CAL_NAME;
    NSString* OWNER_ACCOUNT;
    NSString* CAL_COLOR;
    
    NSString* EVENT_ID;
    NSString* TITLE;
    NSString* LOCATION;
    NSString* DESCRIPTION;
    NSString* BEGIN;
    NSString* END;
    NSString* ALL_DAY;
    NSString* COLOR;
    NSString* HAS_ALARM;
    NSString* AVAILABILITY;
    NSString* IS_ORGANIZER;
    NSString* EVENT_TIMEZONE;
    NSString* RRULE;
    
    NSString* STATUS;
    NSString* SEEN;
}


- (instancetype) initWithPluginName:(NSString *)pluginName
                           deviceId:(NSString *)deviceId{
//        self = [super initWithSensorName:pluginName];
    self  = [super initWithPluginName:pluginName deviceId:deviceId];
        if (self) {
            miniDistrance = 15;
            allEvents = [[NSMutableArray alloc] init];
            store = [[EKEventStore alloc] init];
    
            googleCalPullSensorName = @"balancedcampuscalendar";
            
            AWARE_CAL_EVENT_UPDATE= @"update";
            AWARE_CAL_EVENT_DELETE = @"delete";
            AWARE_CAL_EVENT_ADD = @"add";
    
            AWARE_CAL_NAME = @"AWARE Calendar";
            PRIMARY_GOOGLE_ACCOUNT_NAME = @"primary_google_account_name";
    
            CAL_ID = @"calendar_id";
            ACCOUNT_NAME = @"account_name";
            CAL_NAME = @"calendar_name";
            OWNER_ACCOUNT = @"owner_account";
            CAL_COLOR = @"calendar_color";
    
            EVENT_ID = @"event_id";
            TITLE = @"title";
            LOCATION = @"location";
            DESCRIPTION = @"description";
            BEGIN = @"begin";
            END = @"end";
            ALL_DAY = @"all_day";
            COLOR = @"color";
            HAS_ALARM = @"has_alarm";
            AVAILABILITY = @"availability";
            IS_ORGANIZER = @"is_organizer";
            EVENT_TIMEZONE = @"event_timezone";
            RRULE = @"rrule";
    
            STATUS = @"status";
            SEEN = @"seen";
    
            [store requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error){
                if(granted){ // yes
                    [[NSNotificationCenter defaultCenter] addObserver:self
                                                             selector:@selector(storeChanged:)
                                                                 name:EKEventStoreChangedNotification
                                                               object:store];
                }else{ // no
                }
            }];
        }
        return self;
}


- (BOOL) showSelectPrimaryGoogleCalView {
    UIAlertView * alert = [[UIAlertView alloc] init];
    alert.title = @"Which is your Google Calendar?";
    alert.message = @"Please select your primary Google Calendar.";
    alert.delegate = self;
    for (NSString* name in [self getCals]) {
        [alert addButtonWithTitle:name];
    }
//    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alert show];
    return NO;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    NSLog(@"[%ld] %@", buttonIndex, [alertView buttonTitleAtIndex:buttonIndex] );
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:[alertView buttonTitleAtIndex:buttonIndex] forKey:PRIMARY_GOOGLE_ACCOUNT_NAME];
    [self setLatestValue:[alertView buttonTitleAtIndex:buttonIndex]];
    //make aware cal
//    if (![self isAwareCal]) {
//        [self makeAwareCalWithAccount:[alertView buttonTitleAtIndex:buttonIndex]];
//    }
}


- (NSArray *) getCals {
    NSMutableArray * cals = [[NSMutableArray alloc] init];
    for (EKSource *calSource in store.sources) {
        NSLog(@"%@",calSource);
        [cals addObject:calSource.title];
    }
    return cals;
}

- (void) setPrimaryGoogleCal:(NSString*) googleCalName {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:googleCalName forKey:PRIMARY_GOOGLE_ACCOUNT_NAME];
}

- (NSString* ) getPrimaryGoogleCal {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults objectForKey:PRIMARY_GOOGLE_ACCOUNT_NAME];
}

/**
 * check aware calendar
 */
- (BOOL) isAwareCal {
    for (EKSource *calSource in store.sources) {
        NSLog(@"%@",calSource);
        if ([calSource.title isEqualToString:[self getPrimaryGoogleCal]]) {
//            NSString *identifier = nil;
            for (EKCalendar *cal in [store calendarsForEntityType:EKEntityTypeEvent]) {
//                identifier = cal.calendarIdentifier;
//                NSLog(@"%@", cal.title);
                if ([cal.title isEqualToString:AWARE_CAL_NAME]) {
                    return YES;
                }
            }
        }
    }
    return NO;
}


- (NSString *) getCreateTableQuery {
    NSMutableString* query = [[NSMutableString alloc] init];
    [query appendFormat:@"_id integer primary key autoincrement,"];
    [query appendFormat:@"timestamp real default 0,"];
    [query appendFormat:@"device_id text default '',"];
    
    [query appendFormat:@"%@ text default '',", CAL_ID];
    [query appendFormat:@"%@ text default '',", ACCOUNT_NAME];
    [query appendFormat:@"%@ text default '',", CAL_NAME];
    [query appendFormat:@"%@ text default '',", OWNER_ACCOUNT];
    [query appendFormat:@"%@ text default '',", CAL_COLOR];
    
    [query appendFormat:@"%@ text default '',", EVENT_ID];
    [query appendFormat:@"%@ text default '',", TITLE];
    [query appendFormat:@"%@ text default '',", LOCATION];
    [query appendFormat:@"%@ text default '',", DESCRIPTION];
    [query appendFormat:@"%@ text default '',", BEGIN];
    [query appendFormat:@"%@ text default '',", END];
    [query appendFormat:@"%@ text default '',", ALL_DAY];
    [query appendFormat:@"%@ text default '',", COLOR];
    [query appendFormat:@"%@ text default '',", HAS_ALARM];
    [query appendFormat:@"%@ text default '',", AVAILABILITY];
    [query appendFormat:@"%@ text default '',", IS_ORGANIZER];
    [query appendFormat:@"%@ text default '',", EVENT_TIMEZONE];
    [query appendFormat:@"%@ text default '',", RRULE];
    
    [query appendFormat:@"%@ text default '',", STATUS];
    [query appendFormat:@"%@ text default '',", SEEN];
    
    [query appendString:@"UNIQUE (timestamp,device_id)"];
    
//    [super createTable:query];
    return query;
}

- (BOOL)startSensor:(double)upInterval withSettings:(NSArray *)settings {
    
    NSLog(@"[%@] Create table", [self getSensorName]);

    AWARESensor *balancedCampusCalendarSensor = [[AWARESensor alloc] initWithSensorName:googleCalPullSensorName];
    [self createTable:[self getCreateTableQuery]];
    [self addAnAwareSensor:balancedCampusCalendarSensor];
    [self startAllSensors:upInterval withSettings:settings];
//    uploadTimer = [NSTimer scheduledTimerWithTimeInterval:upInterval
//                                                   target:self
//                                                 selector:@selector(syncAwareDB)
//                                                 userInfo:nil repeats:YES];
    // set current events
    [self setAllEvents];
    
    return YES;
}

- (BOOL) stopSensor {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self stopAndRemoveAllSensors];
//    [uploadTimer invalidate];
    return YES;
}


- (void) storeChanged:(NSNotification *) notification {
    NSLog(@"A calendar event is updated!");
    
    EKEventStore *ekEventStore = notification.object;
    
    NSDate *now = [NSDate date];
    NSDateComponents *offsetComponents = [NSDateComponents new];
    [offsetComponents setDay:0];
    [offsetComponents setMonth:6];
    [offsetComponents setYear:0];
    NSDate *endDate = [[NSCalendar currentCalendar] dateByAddingComponents:offsetComponents toDate:now options:0];
    
    NSDateComponents *offsetComponentsStart = [NSDateComponents new];
    [offsetComponentsStart setDay:-7];
    [offsetComponentsStart setMonth:0];
    [offsetComponentsStart setYear:0];
    NSDate *startDate = [[NSCalendar currentCalendar] dateByAddingComponents:offsetComponentsStart toDate:now options:0];
    
    NSArray *ekEventStoreChangedObjectIDArray = [notification.userInfo objectForKey:@"EKEventStoreChangedObjectIDsUserInfoKey"];
    NSPredicate *predicate = [ekEventStore    predicateForEventsWithStartDate:startDate
                                                                      endDate:endDate
                                                                    calendars:nil];
    NSMutableArray * currentEvents = [[NSMutableArray alloc] init];
    NSMutableArray * ids = [[NSMutableArray alloc] init];
    
    [ekEventStore enumerateEventsMatchingPredicate:predicate usingBlock:^(EKEvent *ekEvent, BOOL *stop) {
        // Check this event against each ekObjectID in notification
        [currentEvents addObject:ekEvent];
    }];
    
    [ekEventStoreChangedObjectIDArray enumerateObjectsUsingBlock:^(NSString *ekEventStoreChangedObjectID, NSUInteger idx, BOOL *stop) {
        [ids addObject:ekEventStoreChangedObjectID];
    }];
    
    BOOL isDeleteOrOther = YES;
    EKEvent* targetEvent;
//    for (EKEvent * ekEvent in currentEvents) {
    for (int i=0; i<currentEvents.count; i++){
        EKEvent* ekEvent = [currentEvents objectAtIndex:i];
        for (NSString* ekEventStoreChangedObjectID in ids) {
            NSObject *ekObjectID = [(NSManagedObject *)ekEvent objectID];
            if ([ekEventStoreChangedObjectID isEqual:ekObjectID]) {
                // Log the event we found and stop (each event should only exist once in store)
                NSLog(@"calendarChanged(): Event Changed: title:%@", ekEvent.title);
                NSLog(@"%@",ekEvent.eventIdentifier);
                targetEvent = ekEvent;
                isDeleteOrOther = NO;
                break;
            }
        }
    }
    
    if ( isDeleteOrOther ) {
//        NSLog(@"%@", AWARE_CAL_EVENT_DELETE);
        EKEvent* deletedEvent = [self getDeletedEKEvent:currentEvents];
        if (deletedEvent) {
//            NSLog(@"AWARE detect a deleted event !!!");
            NSLog(@"%@", AWARE_CAL_EVENT_DELETE);
            [self saveCalEvent:deletedEvent withEventType:AWARE_CAL_EVENT_DELETE];
        } else {
            NSLog(@"AWARE can not find a deleted event."); //TODO
            NSLog(@"%@", AWARE_CAL_EVENT_UPDATE);
            [self saveCalEvent:targetEvent withEventType:AWARE_CAL_EVENT_UPDATE];
        }
    }else{
        if( [self isAdd:targetEvent] ){ // add event
            NSLog(@"%@", AWARE_CAL_EVENT_ADD);
            [self saveCalEvent:targetEvent withEventType:AWARE_CAL_EVENT_ADD];
        } else { // delete event
            NSLog(@"%@", AWARE_CAL_EVENT_UPDATE);
            [self saveCalEvent:targetEvent withEventType:AWARE_CAL_EVENT_UPDATE];
        }
    }
    

    
    [self setAllEvents];
    
    
    // Loop through all events in range
    //    [ekEventStore enumerateEventsMatchingPredicate:predicate usingBlock:^(EKEvent *ekEvent, BOOL *stop) {
    //        // Check this event against each ekObjectID in notification
    //        [ekEventStoreChangedObjectIDArray enumerateObjectsUsingBlock:^(NSString *ekEventStoreChangedObjectID, NSUInteger idx, BOOL *stop) {
    //            NSObject *ekObjectID = [(NSManagedObject *)ekEvent objectID];
    //            if ([ekEventStoreChangedObjectID isEqual:ekObjectID]) {
    //                // Log the event we found and stop (each event should only exist once in store)
    //                NSLog(@"calendarChanged(): Event Changed: title:%@", ekEvent.title);
    //                NSLog(@"%@",ekEvent.eventIdentifier);
    //                *stop = YES;
    //            }
    //        }];
    //    }];
}


- (void) saveCalEvent:(EKEvent *)event withEventType:(NSString*) type {
    
    if (event == NULL) {
        NSLog(@"Event is null");
        return;
    }
    
    CGFloat *components = CGColorGetComponents(event.calendar.CGColor);
    NSString *colorAsString = @"";
//    UIColor *calendarColor = [UIColor colorWithCGColor:event.calendar.CGColor];
    if (components  != NULL) {
        colorAsString = [NSString stringWithFormat:@"%f,%f,%f,%f", components[0], components[1], components[2], components[3]];
//        NSLog(@"%f", @(components));
//        colorAsString = [NSString stringWithFormat:@"%@", calendarColor];
    }

//    https://developer.android.com/reference/android/provider/CalendarContract.EventsColumns.html#AVAILABILITY
//    NSString* availability = @"unavailable";
    NSString* availability = @"0";
    switch (event.availability) {
        case EKEventAvailabilityNotSupported:
//            availability = @"not supported";
            availability = @"-1";
            break;
        case EKEventAvailabilityBusy:
//            availability = @"busy";
            availability = @"0";
            break;
        case EKEventAvailabilityFree:
//            availability = @"free";
            availability = @"1";
            break;
        case EKEventAvailabilityTentative:
//            availability = @"tentative";
            availability = @"2";
            break;
        case EKEventAvailabilityUnavailable:
//            availability = @"unavailable";
            availability = @"-1";
        default:
            break;
    }
    
    
//    NSString * status = @"none";
    NSString * status = @"-1";
    // https://developer.android.com/reference/android/provider/CalendarContract.EventsColumns.html#STATUS
    switch (event.status) {
        case EKEventStatusCanceled:
//            status = @"canceled";
            status = @"2";
            break;
        case EKEventStatusConfirmed:
//            status = @"confirmed";
            status = @"1";
            break;
        case EKEventStatusNone:
//            status = @"none";
            status = @"-1";
            break;
        case EKEventStatusTentative:
//            status = @"tentative";
            status = @"0";
            break;
        default:
            break;
    }
    
//    NSString* seek = @"";
    
//    double timeStamp = [[NSDate date] timeIntervalSince1970] * 1000;
//    NSNumber* unixtime = [NSNumber numberWithLong:timeStamp];
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setObject:[self getUnixtimeWithNSDate:[NSDate date]] forKey:@"timestamp"];
    [dic setObject:[self getDeviceId] forKey:@"device_id"];
    
    if(event.calendarItemIdentifier != nil){
        [dic setObject:event.calendarItemIdentifier forKey:CAL_ID];
    }else{
        [dic setObject:@"" forKey:CAL_ID];
    }

    if (event.calendar.source != nil) {
        [dic setObject:event.calendar.source.title forKey:ACCOUNT_NAME];
    } else {
        [dic setObject:@"" forKey:ACCOUNT_NAME];
    }
    
    if (event.calendar.title != nil) {
        [dic setObject:event.calendar.title forKey:CAL_NAME];
    }else{
        [dic setObject:@"" forKey:CAL_NAME];
    }

    if (event.calendar.source.title != nil) {
        [dic setObject:event.calendar.source.title forKey:OWNER_ACCOUNT];
    }else{
        [dic setObject:@"" forKey:OWNER_ACCOUNT];
    }
    [dic setObject:colorAsString forKey:CAL_COLOR];
    
    if (event.eventIdentifier != nil) {
        [dic setObject:event.eventIdentifier forKey: EVENT_ID];
    }else{
        [dic setObject:@"" forKey:EVENT_ID];
    }
    [dic setObject:event.title forKey: TITLE];
    [dic setObject:event.location forKey: LOCATION];
    // Note
    if (event.notes) {
        [dic setObject:event.notes forKey: DESCRIPTION];
    }else{
        [dic setObject:@"" forKey: DESCRIPTION];
    }
    [dic setObject:[self getUnixtimeWithNSDate:event.startDate] forKey: BEGIN];
    [dic setObject:[self getUnixtimeWithNSDate:event.endDate] forKey: END];
    [dic setObject:[NSString stringWithFormat:@"%d",event.allDay] forKey: ALL_DAY];
    [dic setObject:colorAsString forKey: COLOR];
    [dic setObject:[NSString stringWithFormat:@"%d",event.hasAlarms] forKey: HAS_ALARM];
    [dic setObject:availability forKey: AVAILABILITY];
    
    // organizer
    // https://developer.android.com/reference/android/provider/CalendarContract.EventsColumns.html#IS_ORGANIZER
    if (event.organizer) {
        [dic setObject:event.organizer.description forKey: IS_ORGANIZER];
    } else {
        [dic setObject:@"1" forKey: IS_ORGANIZER];
    }
    
    // timezone
    if (event.timeZone) {
//        NSLog(@"%@", event.timeZone.timeZoneDataVersion );
        [dic setObject:event.timeZone.description forKey: EVENT_TIMEZONE];
    } else {
        [dic setObject:@"" forKey:EVENT_TIMEZONE];
    }
    
    // recrrence rules
    if (event.recurrenceRules) {
//        NSLog(@"%@", event.recurrenceRules.description);
        [dic setObject:event.recurrenceRules.description forKey: RRULE];
    }else{
        [dic setObject:@"" forKey: RRULE];
    }

    [dic setObject:type forKey: STATUS];
    [dic setObject:status forKey: SEEN];
//
//    
    [self saveData:dic toLocalFile:googleCalPullSensorName];
    
    NSLog(@"%@", dic);
    
}


- (BOOL) isAdd :(EKEvent *) event {
    for (EKEvent* oldEvent in allEvents) {
        if ([oldEvent.eventIdentifier isEqualToString:event.eventIdentifier]) {
            return NO;
        }
    }
    return YES;
}

- (EKEvent *) getDeletedEKEvent:(NSMutableArray *) currentEKEvents{
    EKEvent * deletedEKEvent = nil;
    for (EKEvent * oldEvent in allEvents) {
        bool deletedFlag = YES;
        for (EKEvent* currentEvent in currentEKEvents) {
            if ([oldEvent.eventIdentifier isEqualToString:currentEvent.eventIdentifier]) {
                deletedFlag = NO;
            }
        }
        if ( deletedFlag ) {
            deletedEKEvent = oldEvent;
            NSLog(@"%@", oldEvent.description);
            break;
        }
    }
    return deletedEKEvent;
}

- (void) setAllEvents {
//    NSLog(@"= Get All Events =");
    
    [allEvents removeAllObjects];
    
    NSDate *now = [NSDate date];
    NSDateComponents *offsetComponentsEnd = [NSDateComponents new];
    [offsetComponentsEnd setDay:0];
    [offsetComponentsEnd setMonth:6];
    [offsetComponentsEnd setYear:0];
    NSDate *endDate = [[NSCalendar currentCalendar] dateByAddingComponents:offsetComponentsEnd toDate:now options:0];

    NSDateComponents *offsetComponentsStart = [NSDateComponents new];
    [offsetComponentsStart setDay:-7];
    [offsetComponentsStart setMonth:0];
    [offsetComponentsStart setYear:0];
    NSDate *startDate = [[NSCalendar currentCalendar] dateByAddingComponents:offsetComponentsStart toDate:now options:0];
    
    NSPredicate *predicate = [store predicateForEventsWithStartDate:startDate
                                                               endDate:endDate
                                                             calendars:nil];
    // Loop through all events in range
    [store enumerateEventsMatchingPredicate:predicate usingBlock:^(EKEvent *ekEvent, BOOL *stop) {
        // Check this event against each ekObjectID in notification
        [allEvents addObject:ekEvent];
//        NSLog(@"count %ld", allEvents.count);
//        NSLog(@"calendars: %@ ", ekEvent.calendarItemIdentifier);
    }];
}

- (NSNumber *) getUnixtimeWithNSDate:(NSDate *) date {
    double timeStamp = [date timeIntervalSince1970] * 1000;
    NSNumber* unixtime = [NSNumber numberWithLong:timeStamp];
    return unixtime;
}

//
//- (void) addEventToCalender {
//    NSLog(@"= Get Calenders =");
//    // Add Calender -> [TODO] Make Calendar
//    NSArray *cals = [store calendarsForEntityType:EKEntityTypeEvent];
//    NSLog(@"%@", cals);
//    NSString *identifier = nil;
//    for (EKCalendar *cal in cals) {
//        identifier = cal.calendarIdentifier;
//    }
//    
//    EKEvent *eventFromiOS = [EKEvent eventWithEventStore:store];
//    eventFromiOS.title = @"Event from iOS";
//    eventFromiOS.startDate = [NSDate date];
//    eventFromiOS.endDate = [NSDate dateWithTimeIntervalSinceNow:60*60*2];
//    eventFromiOS.calendar = [store calendarWithIdentifier:identifier];
//    EKStructuredLocation* structuredLocation = [EKStructuredLocation locationWithTitle:@"Location"]; // locationWithTitle has the same behavior as event.location
//    CLLocation* location = [[CLLocation alloc] initWithLatitude:0.0 longitude:0.0];
//    structuredLocation.geoLocation = location;
//    [eventFromiOS setValue:structuredLocation forKey:@"structuredLocation"];
//    NSError* error = nil;
//    [store saveEvent:eventFromiOS span:EKSpanThisEvent error:&error];
//    if ( error ) {
//        NSLog(@"%@", error.debugDescription);
//    }
//}

/**
 * Set daily notification with alert
 */
//- (void) setDailyNotification {
//    
//}


@end
