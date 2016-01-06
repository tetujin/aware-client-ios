//
//  GoogleCalPush.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 1/4/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "GoogleCalPush.h"

@implementation GoogleCalPush{
    // for calendar events
    EKEventStore *store;
//    EKSource *awareCalSource;
//    NSTimer * calRefreshTimer;
//    NSMutableArray *allEvents;
//    EKEvent * dailyNotification;
    
    NSTimer * uploadTimer;
    NSTimer * calendarUpdateTimer;
    NSString* AWARE_CAL_NAME;
    
    // for locations
    double miniDistrance;
    IBOutlet CLLocationManager *locationManager;
    NSMutableArray * locationsToday;
}

- (instancetype)initWithSensorName:(NSString *)sensorName {
    self = [super initWithSensorName:sensorName];
    if (self) {
        AWARE_CAL_NAME = @"AWARE Calendar";
        miniDistrance = 15;
//        allEvents = [[NSMutableArray alloc] init];
        store = [[EKEventStore alloc] init];
        locationsToday = [[NSMutableArray alloc] init];
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


- (void) createTable {
    NSMutableString* query = [[NSMutableString alloc] init];
    [query appendFormat:@"_id integer primary key autoincrement,"];
    [query appendFormat:@"timestamp real default 0,"];
    [query appendFormat:@"device_id text default '',"];
    
//    [query appendFormat:@"%@ text default '',", CAL_ID];
//    [query appendFormat:@"%@ text default '',", ACCOUNT_NAME];
//    [query appendFormat:@"%@ text default '',", CAL_NAME];
//    [query appendFormat:@"%@ text default '',", OWNER_ACCOUNT];
//    [query appendFormat:@"%@ text default '',", CAL_COLOR];
//    
//    [query appendFormat:@"%@ text default '',", EVENT_ID];
//    [query appendFormat:@"%@ text default '',", TITLE];
//    [query appendFormat:@"%@ text default '',", LOCATION];
//    [query appendFormat:@"%@ text default '',", DESCRIPTION];
//    [query appendFormat:@"%@ text default '',", BEGIN];
//    [query appendFormat:@"%@ text default '',", END];
//    [query appendFormat:@"%@ text default '',", ALL_DAY];
//    [query appendFormat:@"%@ text default '',", COLOR];
//    [query appendFormat:@"%@ text default '',", HAS_ALARM];
//    [query appendFormat:@"%@ text default '',", AVAILABILITY];
//    [query appendFormat:@"%@ text default '',", IS_ORGANIZER];
//    [query appendFormat:@"%@ text default '',", EVENT_TIMEZONE];
//    [query appendFormat:@"%@ text default '',", RRULE];
//    
//    [query appendFormat:@"%@ text default '',", STATUS];
//    [query appendFormat:@"%@ text default '',", SEEN];
    
    [query appendString:@"UNIQUE (timestamp,device_id)"];
    
    [super createTable:query];
}

- (BOOL)startSensor:(double)upInterval withSettings:(NSArray *)settings {
    NSLog(@"[%@] Create table", [self getSensorName]);
    [self createTable];
    
    uploadTimer = [NSTimer scheduledTimerWithTimeInterval:upInterval target:self selector:@selector(syncAwareDB) userInfo:nil repeats:YES];
    [uploadTimer fire];
    
    [self setDailyNotification];
    [self startLocationSensor];

    return YES;
}


- (void) setDailyNotification {
    // Get fix time
    NSDate* date = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dateComps = [calendar components:NSYearCalendarUnit |
                                   NSMonthCalendarUnit  |
                                   NSDayCalendarUnit    |
                                   NSHourCalendarUnit   |
                                   NSMinuteCalendarUnit |
                                   NSSecondCalendarUnit fromDate:date];
    [dateComps setDay:dateComps.day];
    [dateComps setHour:23];
    [dateComps setMinute:0];
    [dateComps setSecond:0];
    
    NSDate * elevenOClock  = [calendar dateFromComponents:dateComps];
    NSLog(@"date: %@", elevenOClock );
    calendarUpdateTimer = [[NSTimer alloc] initWithFireDate:elevenOClock
                                                   interval:60*60*24
                                                     target:self
                                                   selector:@selector(checkAllEvents:)
                                                   userInfo:nil
                                                    repeats:YES];
    //https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/Timers/Articles/usingTimers.html
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    [runLoop addTimer:calendarUpdateTimer forMode:NSDefaultRunLoopMode];

    // test code
//    [self checkAllEvents:nil];
//    [calendarUpdateTimer fire];
}

- (void) checkAllEvents:(id) sender {
    // Get all events
    NSLog(@"Cal event id updated !!!");
    
    EKCalendar * awareCal = nil;
    // Get the aware calendar in Google Calendars
    for (EKCalendar * cal in [store calendarsForEntityType:EKEntityTypeEvent]) {
        NSLog(@"[%@] %@", cal.title, cal.calendarIdentifier );
        if ([cal.title isEqualToString:@"AWARE Calendar"]) {
            awareCal = cal;
        }
    }
    
    if (awareCal == nil) {
        NSLog(@"[ERROR] AWARE iOS can not find a Google calendar for AWARE. Please add 'AWARE Calendar' to your google calendar. ");
        return;
    }
    
//    EKEventStore *ekEventStore = notification.object;
    
    
    //http://stackoverflow.com/questions/1889164/get-nsdate-today-yesterday-this-week-last-week-this-month-last-month-var
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *components = [cal components:( NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit ) fromDate:[[NSDate alloc] init]];
    [components setHour:-[components hour]];
    [components setMinute:-[components minute]];
    [components setSecond:-[components second]];
    NSDate *startDate = [cal dateByAddingComponents:components toDate:[[NSDate alloc] init] options:0]; //This variable should now be pointing at a date object that is the start of today (midnight);
    
    [components setDay:1];
    NSDate *endDate = [cal dateByAddingComponents:components toDate:[[NSDate alloc] init] options:0];
    
    NSMutableArray * currentEvents = [[NSMutableArray alloc] init];
    NSPredicate *predicate = [store predicateForEventsWithStartDate:startDate
                                                            endDate:endDate
                                                             calendars:nil];
    [store enumerateEventsMatchingPredicate:predicate usingBlock:^(EKEvent *ekEvent, BOOL *stop) {
        // Check this event against each ekObjectID in notification
        if(!ekEvent.allDay){
            if(ekEvent.calendar != awareCal){
                [currentEvents addObject:ekEvent];
            }
        }
//        NSLog(@"count %@", ekEvent);
    }];
    
    NSString * questions = @"\n\n - - - - - - \n This is sample.";
    
    // == Make new events (Aware Events), and Get Null events ==
    NSMutableArray * nullTimes = [[NSMutableArray alloc] init];
    EKEvent * lastEvent = nil;
    
    NSMutableArray * awareEvents = [[NSMutableArray alloc] initWithArray:currentEvents];
    for (EKEvent * event in awareEvents) {
        NSLog(@"%@", event.notes);
        EKEvent * awareEvent = [EKEvent eventWithEventStore:store];
        // Add questions to a note of aware events
        awareEvent.notes = [NSString stringWithFormat:@"%@%@", event.notes, questions];
        awareEvent.title = event.title;
        awareEvent.startDate = event.startDate;
        awareEvent.endDate = event.endDate;
        awareEvent.location = event.location;
        // Change an aware event's calendar
        awareEvent.calendar = awareCal;
        NSError * error;
        // save events to the aware calendar
        [store saveEvent:awareEvent span:EKSpanThisEvent commit:YES error:&error];
        
        // startDate - endDate
        if (lastEvent != nil) {
            NSDate * nullStart = lastEvent.endDate;
            NSDate * nullEnd = event.startDate;
            int gap = [nullEnd timeIntervalSince1970] - [nullStart timeIntervalSince1970];
            if (gap > 0) {
                [nullTimes addObject:[[NSArray alloc] initWithObjects:nullStart, nullEnd, nil]];
            }
        }
        lastEvent = event;
    }
    
    // == Make empty events, and add events to aware calendars ==
    for (NSArray * times in nullTimes) {
        NSDate * nullStart = [times objectAtIndex:0];
        NSDate * nullEnd = [times objectAtIndex:1];
        EKEvent *emptyEvent = [EKEvent eventWithEventStore:store];
        emptyEvent.title = @"Empty";
        emptyEvent.notes = questions;
        emptyEvent.startDate = nullStart;
        emptyEvent.endDate = nullEnd;
        emptyEvent.calendar = awareCal;
        [store saveEvent:emptyEvent span:EKSpanThisEvent commit:YES error:nil];
    }
    
    // == Send Notification ==
     [self sendLocalNotificationForMessage:@"Hi! Your Google Calendar is updated." soundFlag:YES];
    
    // == Remove past locations ==
//     [locationsToday removeAllObjects];
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
        [locationsToday addObject:location];
    }
}


- (BOOL) stopSensor {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [uploadTimer invalidate];
    [calendarUpdateTimer invalidate];
    calendarUpdateTimer = nil;
    return YES;
}


@end
