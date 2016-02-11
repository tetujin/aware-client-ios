//
//  GoogleCal.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 12/18/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "GoogleCalPull.h"
#import <CoreData/CoreData.h>
#import "CalEvent.h"

@implementation GoogleCalPull {
    // for calendar events
    EKEventStore *store;
    EKSource *awareCalSource;
    NSTimer * calRefreshTimer;
    NSMutableArray *allEvents;
    EKEvent * dailyNotification;
    
    NSString* googleCalPullSensorName;
    
    NSString* PRIMARY_GOOGLE_ACCOUNT_NAME;
    NSString* KEY_AWARE_CAL_FIRST_ACCESS;
    
//    BOOL isAddOrUpdate;
//    EKEvent* targetEvent;
//    CalEvent * deletedEvent;
}


- (instancetype) initWithPluginName:(NSString *)pluginName
                           deviceId:(NSString *)deviceId{
    self  = [super initWithPluginName:pluginName deviceId:deviceId];
        if (self) {
            allEvents = [[NSMutableArray alloc] init];
            store = [[EKEventStore alloc] init];
            
            googleCalPullSensorName = @"balancedcampuscalendar";
            PRIMARY_GOOGLE_ACCOUNT_NAME = @"primary_google_account_name";
            KEY_AWARE_CAL_FIRST_ACCESS  = @"key_aware_cal_first_access";

            [store requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error){
                if(granted){ // yes
                    [[NSNotificationCenter defaultCenter] addObserver:self
                                                             selector:@selector(storeChanged:)
                                                                 name:EKEventStoreChangedNotification
                                                               object:store];
                }else{ // no
                }
            }];
            
            
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            BOOL state = [userDefaults boolForKey:KEY_AWARE_CAL_FIRST_ACCESS];
            if (!state) {
                [self saveOriginalCalEvents];
                [userDefaults setBool:YES forKey:KEY_AWARE_CAL_FIRST_ACCESS];
            }
        }
        return self;
}


- (void) saveOriginalCalEvents {
    [store enumerateEventsMatchingPredicate:[self getPredication] usingBlock:^(EKEvent *ekEvent, BOOL *stop) {
        // Check this event against each ekObjectID in notification
        CalEvent* calEvent = [[CalEvent alloc] initWithEKEvent:ekEvent eventType:CalEventTypeOriginal];
        [self saveCalEvent:calEvent];
    }];
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

- (BOOL)startSensor:(double)upInterval withSettings:(NSArray *)settings {
    
    NSLog(@"[%@] Create table", [self getSensorName]);

    AWARESensor *balancedCampusCalendarSensor = [[AWARESensor alloc] initWithSensorName:googleCalPullSensorName];
    CalEvent *calEvent = [[CalEvent alloc] init];
    [self createTable:[calEvent getCreateTableQuery]];
    [self addAnAwareSensor:balancedCampusCalendarSensor];
    [self startAllSensors:upInterval withSettings:settings];
    [self updateExistingEvents];
    
    return YES;
}

- (BOOL) stopSensor {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:EKEventStoreChangedNotification
                                                  object:store];
    [self stopAndRemoveAllSensors];
    return YES;
}


- (void) storeChanged:(NSNotification *) notification {
    NSLog(@"A calendar event is updated!");
    
    [self saveDebugEventWithText:@"A calendar event is updated!" type:DebugTypeInfo label:@""];
    
    EKEventStore *ekEventStore = notification.object;
    
    NSArray *ekEventStoreChangedObjectIDArray = [notification.userInfo objectForKey:@"EKEventStoreChangedObjectIDsUserInfoKey"];

    //    NSPredicate *predicate = [ekEventStore    predicateForEventsWithStartDate:startDate
    //                                                                      endDate:endDate
    //                                                                    calendars:nil];
    NSMutableArray * currentEvents = [[NSMutableArray alloc] init];
    NSMutableArray * ids = [[NSMutableArray alloc] init];
    
    [ekEventStore enumerateEventsMatchingPredicate:[self getPredication] usingBlock:^(EKEvent *ekEvent, BOOL *stop) {
        // Check this event against each ekObjectID in notification
        [currentEvents addObject:ekEvent];
    }];
    
    [ekEventStoreChangedObjectIDArray enumerateObjectsUsingBlock:^(NSString *ekEventStoreChangedObjectID, NSUInteger idx, BOOL *stop) {
        [ids addObject:ekEventStoreChangedObjectID];
    }];
    
//    BOOL isDeleteOrOther = YES;
//    EKEvent* targetEvent;
    //    for (EKEvent * ekEvent in currentEvents) {
    NSMutableArray * deletedEventIds = [[NSMutableArray alloc] init];
    for (NSString* ekEventStoreChangedObjectID in ids) {
        BOOL deletedFlag = YES;
        for (int i=0; i<currentEvents.count; i++){
            EKEvent* ekEvent = [currentEvents objectAtIndex:i];
            NSObject *ekObjectID = [(NSManagedObject *)ekEvent objectID];
            if ([ekEventStoreChangedObjectID isEqual:ekObjectID]) {
                deletedFlag = NO;
                // Log the event we found and stop (each event should only exist once in store)
                NSLog(@"calendarChanged(): Event Changed: title:%@", ekEvent.title);
                NSLog(@"%@",ekEvent.eventIdentifier);
                if( [self isAdd:ekEvent] ){
                    NSLog(@"add");
                    CalEvent * event = [[CalEvent alloc] initWithEKEvent:ekEvent eventType:CalEventTypeAdd];
                    [self saveCalEvent:event];
                    [self setLatestValueWithEvent:event ];
                } else {
                    NSLog(@"update");
                    CalEvent * event = [[CalEvent alloc] initWithEKEvent:ekEvent eventType:CalEventTypeUpdate];
                    [self saveCalEvent:event];
                    [self setLatestValueWithEvent:event];
                }
            }
        }
        if (deletedFlag) {
            [deletedEventIds addObject:ekEventStoreChangedObjectID];
        }
    }
    
    for (NSObject* deletedEventId in deletedEventIds) {
        CalEvent* deletedEvent = [self getDeletedCalEventWithManageId:deletedEventId];
        [deletedEvent setCalendarEventType:CalEventTypeDelete];
        if(deletedEvent != nil){
            NSLog(@"delete");
            [self saveCalEvent:deletedEvent];
            [self setLatestValueWithEvent:deletedEvent];
        }else{
            NSLog(@"unkown");
        }
    }

    [self updateExistingEvents];
}

- (void) setLatestValueWithEvent:(CalEvent *) event {
    // update latest updated sensor value.
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"YYYY-MM-dd HH:mm"];
    NSString *formattedDateString = [dateFormatter stringFromDate:[NSDate new]];
    [super setLatestValue:[NSString stringWithFormat:@"[%@] %@ (%@)", event.status, event.title, formattedDateString]];
}

- (CalEvent *) getDeletedCalEventWithManageId:(NSObject*) manageId {
    for (CalEvent* calEvent in allEvents) {
        if([calEvent.objectManageId isEqual:manageId]){
            return calEvent;
        }
    }
    return nil;
}

- (void) saveCalEvent:(CalEvent *)calEvent{
//    CalEvent *calEvent = [[CalEvent alloc] initWithEKEvent:event eventType:eventType];
    NSMutableDictionary * dic = [calEvent getCalEventAsDictionaryWithDeviceId:[self getDeviceId]
                                                                    timestamp:[AWAREUtils getUnixTimestamp:[NSDate new]]];
    [self saveData:dic toLocalFile:googleCalPullSensorName];
//    NSLog(@"%@", dic);
}


- (BOOL) isAdd :(EKEvent *) event {
    for (CalEvent* oldCalEvent in allEvents) {
        if ([oldCalEvent.eventId isEqualToString:event.eventIdentifier]) {
            return NO;
        }
    }
    return YES;
}

- (CalEvent *) getDeletedCalEvent:(NSMutableArray *) currentEvents{
    //    EKEvent * deletedEKEvent = nil;
    CalEvent * deletedCalEvent = nil;
    for (CalEvent* oldCalEvent in allEvents) {
        bool deletedFlag = YES;
        for (EKEvent* currentEvent in currentEvents ) {
            if ([oldCalEvent.eventId isEqualToString:currentEvent.eventIdentifier]) {
                deletedFlag = NO;
            }
        }
        if ( deletedFlag ) {
            //            deletedEKEvent = oldCalEvent;
            deletedCalEvent = oldCalEvent;
            NSLog(@"%@", oldCalEvent.description);
            break;
        }
    }
    return deletedCalEvent;
}

- (void) updateExistingEvents {
//    NSLog(@"= Get All Events =");
    
    [allEvents removeAllObjects];
    
    // Loop through all events in range
    [store enumerateEventsMatchingPredicate:[self getPredication] usingBlock:^(EKEvent *ekEvent, BOOL *stop) {
        // Check this event against each ekObjectID in notification
        CalEvent* calEvent = [[CalEvent alloc] initWithEKEvent:ekEvent];
        [allEvents addObject:calEvent];
//        NSLog(@"count %ld", allEvents.count);
//        NSLog(@"calendars: %@ ", ekEvent.calendarItemIdentifier);
    }];
}

- (NSPredicate *) getPredication {
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
    return predicate;
}


@end
