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
    
    // for locations
    double miniDistrance;
    IBOutlet CLLocationManager *locationManager;

    // for AWARE sensor
    NSTimer* uploadTimer;
    
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

- (instancetype)initWithSensorName:(NSString *)sensorName {
    self = [super initWithSensorName:sensorName];
    if (self) {
        miniDistrance = 15;
        allEvents = [[NSMutableArray alloc] init];
        store = [[EKEventStore alloc] init];
        
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
    if (![self isAwareCal]) {
        [self makeAwareCalWithAccount:[alertView buttonTitleAtIndex:buttonIndex]];
    }
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

/**
 * make new aware calender
 */
- (BOOL) makeAwareCalWithAccount:(NSString*) accountName {
//    NSString* identifier = nil;
//    for (EKSource *calSource in store.sources) {
////        NSLog(@"%@",calSource);
//        if ([calSource.title isEqualToString:[self getPrimaryGoogleCal]]) {
//            EKCalendar *awareCal = [EKCalendar calendarForEntityType:EKEntityTypeEvent eventStore:store];
//            awareCal.source = calSource;
//            awareCal.title = AWARE_CAL_NAME;
//            NSError *error = nil;
//            [store saveCalendar:awareCal commit:YES error:&error];
//            if (error) {
//                NSLog(@"%@", error.debugDescription);
//            }
////            for (EKCalendar *cal in [store calendarsForEntityType:EKEntityTypeEvent]) {
////
//////                if ([cal.title isEqualToString:AWARE_CAL_NAME]) {
//////                    return YES;
//////                }
////            }
//        }
//    }
    return YES;
}


- (void) createTable {
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
    
    [super createTable:query];
}

- (BOOL)startSensor:(double)upInterval withSettings:(NSArray *)settings {
    
//    if ([self getPrimaryGoogleCal] == nil) {
//        [self showSelectPrimaryGoogleCalView];
//    }
    NSLog(@"[%@] Create table", [self getSensorName]);
    [self createTable];
    [self setAllEvents];

    uploadTimer = [NSTimer scheduledTimerWithTimeInterval:upInterval
                                                   target:self
                                                 selector:@selector(syncAwareDB)
                                                 userInfo:nil repeats:YES];

    // [TODO] This is test code
    [self setDailyNotification];
    [self startLocationSensor];
    

    return YES;
}


- (void) startLocationSensor{
    if (nil == locationManager){
        locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        //    locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        locationManager.pausesLocationUpdatesAutomatically = NO;
        CGFloat currentVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
        NSLog(@"OS:%f", currentVersion);
        if (currentVersion >= 9.0) {
            //        _homeLocationManager.allowsBackgroundLocationUpdates = YES; //This variable is an important method for background sensing
            locationManager.allowsBackgroundLocationUpdates = YES; //This variable is an important method for background sensing after iOS9
        }
        locationManager.activityType = CLActivityTypeFitness;
        if ([locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
            [locationManager requestAlwaysAuthorization];
        }
        // Set a movement threshold for new events.
        locationManager.distanceFilter = miniDistrance; // meters
        [locationManager startUpdatingLocation];
        //    [_locationManager startMonitoringVisits]; // This method calls didVisit.
        [locationManager startUpdatingHeading];
        //    _location = [[CLLocation alloc] init];
        //        if(interval > 0){
        //            locationTimer = [NSTimer scheduledTimerWithTimeInterval:interval
        //                                                             target:self
        //                                                           selector:@selector(getGpsData:)
        //                                                           userInfo:nil
        //                                                            repeats:YES];
        //        }
    }
}

- (void)locationManager:(CLLocationManager *)manager
       didUpdateHeading:(CLHeading *)newHeading {
    if (newHeading.headingAccuracy < 0)
        return;
    //    CLLocationDirection  theHeading = ((newHeading.trueHeading > 0) ?
    //                                       newHeading.trueHeading : newHeading.magneticHeading);
    //    [sdManager addSensorDataMagx:newHeading.x magy:newHeading.y magz:newHeading.z];
    //    [sdManager addHeading: theHeading];
}


- (void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations{
    for (CLLocation* location in locations) {
//        [self saveLocation:location];
    }
}


- (BOOL) stopSensor {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [uploadTimer invalidate];
    return YES;
}

- (void) storeChanged:(NSNotification *) notification {
    NSLog(@"Cal event id updated !!!");
    
    EKEventStore *ekEventStore = notification.object;
    
    NSDate *now = [NSDate date];
    NSDateComponents *offsetComponents = [NSDateComponents new];
    [offsetComponents setDay:0];
    [offsetComponents setMonth:6];
    [offsetComponents setYear:0];
    NSDate *endDate = [[NSCalendar currentCalendar] dateByAddingComponents:offsetComponents toDate:now options:0];
    
    NSArray *ekEventStoreChangedObjectIDArray = [notification.userInfo objectForKey:@"EKEventStoreChangedObjectIDsUserInfoKey"];
    NSPredicate *predicate = [ekEventStore    predicateForEventsWithStartDate:now
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
    for (EKEvent * ekEvent in currentEvents) {
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
        NSLog(@"%@", AWARE_CAL_EVENT_DELETE);
        EKEvent* deletedEvent = [self getDeletedEKEvent:currentEvents];
        if (deletedEvent) {
            NSLog(@"AWARE detect a deleted event !!!");
            [self saveCalEvent:deletedEvent withEventType:AWARE_CAL_EVENT_DELETE];
        } else {
            NSLog(@"AWARE can not find a deleted event.");
        }
    } else {
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
        return;
    }
    
    CGFloat *components = CGColorGetComponents(event.calendar.CGColor);
    NSString *colorAsString = @"";
    if (components != NULL) {
        colorAsString = [NSString stringWithFormat:@"%f,%f,%f,%f", components[0], components[1], components[2], components[3]];
    }

    NSString* availability = @"unavailable";
    switch (event.availability) {
        case EKEventAvailabilityNotSupported:
            availability = @"not supported";
            break;
        case EKEventAvailabilityBusy:
            availability = @"busy";
            break;
        case EKEventAvailabilityFree:
            availability = @"free";
            break;
        case EKEventAvailabilityTentative:
            availability = @"tentative";
            break;
        case EKEventAvailabilityUnavailable:
            availability = @"unavailable";
        default:
            break;
    }
    
    
    NSString * status = @"none";
    switch (event.status) {
        case EKEventStatusCanceled:
            status = @"canceled";
            break;
        case EKEventStatusConfirmed:
            status = @"confirmed";
            break;
        case EKEventStatusNone:
            status = @"none";
            break;
        case EKEventStatusTentative:
            status = @"tentative";
            break;
        default:
            break;
    }
    
//    NSString* seek = @"";
    
    NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
    NSNumber* unixtime = [NSNumber numberWithDouble:timeStamp];
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setObject:unixtime forKey:@"timestamp"];
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
    [dic setObject:event.startDate.description forKey: BEGIN];
    [dic setObject:event.endDate.description forKey: END];
    [dic setObject:[NSString stringWithFormat:@"%d",event.allDay] forKey: ALL_DAY];
    [dic setObject:colorAsString forKey: COLOR];
    [dic setObject:[NSString stringWithFormat:@"%d",event.hasAlarms] forKey: HAS_ALARM];
    [dic setObject:availability forKey: AVAILABILITY];
    
    // organizer
    if (event.organizer) {
        [dic setObject:event.organizer.description forKey: IS_ORGANIZER];
    } else {
        [dic setObject:@"" forKey: IS_ORGANIZER];
    }
    
    // timezone
    if (event.timeZone) {
        [dic setObject:event.timeZone.description forKey: EVENT_TIMEZONE];
    } else {
        [dic setObject:@"" forKey:EVENT_TIMEZONE];
    }
    
    // recrrence rules
    if (event.recurrenceRules) {
        [dic setObject:event.recurrenceRules.description forKey: RRULE];
    }else{
        [dic setObject:@"" forKey: RRULE];
    }

    [dic setObject:status forKey: STATUS];
    [dic setObject:type forKey: SEEN];
//
//    
    [self saveData:dic];
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
    NSLog(@"= Get All Events =");
    
    [allEvents removeAllObjects];
    
    NSDate *now = [NSDate date];
    NSDateComponents *offsetComponents = [NSDateComponents new];
    [offsetComponents setDay:0];
    [offsetComponents setMonth:6];
    [offsetComponents setYear:0];
    NSDate *endDate = [[NSCalendar currentCalendar] dateByAddingComponents:offsetComponents toDate:now options:0];
    
    NSPredicate *predicate = [store    predicateForEventsWithStartDate:now
                                                               endDate:endDate
                                                             calendars:nil];
    // Loop through all events in range
    [store enumerateEventsMatchingPredicate:predicate usingBlock:^(EKEvent *ekEvent, BOOL *stop) {
        // Check this event against each ekObjectID in notification
        [allEvents addObject:ekEvent];
//        NSLog(@"count %ld", allEvents.count);
    }];
}



- (void) addEventToCalender {
    NSLog(@"= Get Calenders =");
    // Add Calender -> [TODO] Make Calendar
    NSArray *cals = [store calendarsForEntityType:EKEntityTypeEvent];
    NSLog(@"%@", cals);
    NSString *identifier = nil;
    for (EKCalendar *cal in cals) {
        identifier = cal.calendarIdentifier;
    }
    
    EKEvent *eventFromiOS = [EKEvent eventWithEventStore:store];
    eventFromiOS.title = @"Event from iOS";
    eventFromiOS.startDate = [NSDate date];
    eventFromiOS.endDate = [NSDate dateWithTimeIntervalSinceNow:60*60*2];
    eventFromiOS.calendar = [store calendarWithIdentifier:identifier];
    EKStructuredLocation* structuredLocation = [EKStructuredLocation locationWithTitle:@"Location"]; // locationWithTitle has the same behavior as event.location
    CLLocation* location = [[CLLocation alloc] initWithLatitude:0.0 longitude:0.0];
    structuredLocation.geoLocation = location;
    [eventFromiOS setValue:structuredLocation forKey:@"structuredLocation"];
    NSError* error = nil;
    [store saveEvent:eventFromiOS span:EKSpanThisEvent error:&error];
    if ( error ) {
        NSLog(@"%@", error.debugDescription);
    }
}

/**
 * Set daily notification with alert
 */
- (void) setDailyNotification {
    
}


@end
