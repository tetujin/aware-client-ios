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
    // for calendar events
    EKEventStore *store;
    
//    NSTimer * uploadTimer;
    NSTimer * calendarUpdateTimer;
    NSString* AWARE_CAL_NAME;
    
    NSDate * fireDate;
    
    // for locations
//    double miniDistrance;
//    IBOutlet CLLocationManager *locationManager;
//    double interval;
//    NSTimer* locationTimer;
}

- (instancetype)initWithSensorName:(NSString *)sensorName {
    self = [super initWithSensorName:sensorName];
    if (self) {
        NSDate* date = [NSDate date];
        fireDate  = [AWAREUtils getTargetNSDate:date hour:20 minute:0 second:0 nextDay:NO];
    
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//        [dateFormatter setDateFormat:@"yyyy-MM-dd 'at' HH:mm"];
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
    //    for (EKSource *calSource in tempStore.sources) {
    for (EKCalendar *cal in [tempStore calendarsForEntityType:EKEntityTypeEvent]) {
        NSLog(@"%@", cal.title);
        if ([cal.title isEqualToString:@"BalancedCampusJournal"]) {
            isAvaiable = YES;
        }
    }
    //    }
    
    tempStore = nil;
//    dispatch_async(dispatch_get_main_queue(), ^{
        if (isAvaiable) {
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Correct"
                                                             message:@"'BalancedCampusJournal' calendar is available!"
                                                            delegate:self
                                                   cancelButtonTitle:@"Cancel"
                                                   otherButtonTitles:nil];
//            NSDate * ninePM = [AWAREUtils getTargetNSDate:[NSDate new] hour:9 minute:0 second:0 nextDay:NO];
            [alert show];
        }else{
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Miss"
                                                             message:@"AWARE can not find 'BalancedCampusJournal' calendar."
                                                            delegate:self
                                                   cancelButtonTitle:@"Cancel"
                                                   otherButtonTitles:nil];
            [alert show];
        }
//    });
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString* title = alertView.title;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if([title isEqualToString:@"Correct"]){
        NSLog(@"%ld", buttonIndex);
//        if (buttonIndex == 1){ //yes
//            [userDefaults setBool:YES forKey:SETTING_DEBUG_STATE];
//            [self pushedStudyRefreshButton:alertView];
//        } else if (buttonIndex == 2){ // no
//            //reset clicked
//            [userDefaults setBool:NO forKey:SETTING_DEBUG_STATE];
//            [self pushedStudyRefreshButton:alertView];
//        } else {
//            NSLog(@"Cancel");
//        }
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

- (void) makePrePopulateEvetnsWith:(NSDate *) date{
    
    //    [self makePrepopulatedEventsWith:]
    
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
        [self sendLocalNotificationForMessage:message soundFlag:YES];
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
            [self sendLocalNotificationForMessage:debugMessage soundFlag:NO];
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
            [self sendLocalNotificationForMessage:debugMessage soundFlag:YES];
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
    
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setDateFormat:@"HH:mm:ss"];
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
    
    [self sendLocalNotificationForMessage:@"Hi! Your Calendar is updated." soundFlag:YES];
    [self saveDebugEventWithText:@"Hi! Your Calendar is updated."type:DebugTypeInfo label:[self getSensorName]];
    
    // == Remove past locations ==
    // [locationsToday removeAllObjects];
}



// Check prepopulated events
//    bool isPopulated = NO;
//    for (int i=1; i<hours.count; i++) {
//        NSDate *start = [hours objectAtIndex:i-1];
//        NSDate *end = [hours objectAtIndex:i];
//        for (EKEvent * populatEvent in prepopulatedEvents) {
//            if (start > populatEvent.endDate && end < populatEvent.endDate) {
//
//            }
//        }
//    }
//




//    NSMutableArray * awareEvents = [[NSMutableArray alloc] initWithArray:currentEvents];

//    for (EKEvent* event in existingJournalEvents ) {
//        NSLog(@"%@ %@", event.calendar.calendarIdentifier, awareCal.calendarIdentifier);
//        if ([event.calendar.calendarIdentifier isEqualToString:awareCal.calendarIdentifier] ) {
//            if ([self getDebugState]) {
//                [self sendLocalNotificationForMessage:@"Your Google Calandar is already updated today." soundFlag:YES];
//
//            }
//            return;
//        }
//    }

/**
 * Add Last NSDate to NullEvents
 */
//    NSDate * endOfTimeToday = [AWAREUtils getTargetNSDate:[NSDate date] hour:24 minute:0 second:0 nextDay:NO];
//    NSDate * lastEventEndDate = lastEvent.endDate;
//    int gap = [endOfTimeToday timeIntervalSince1970] - [lastEventEndDate timeIntervalSince1970];
//    NSLog(@"%d", gap);
//    if (gap > 0) {
//        [nullTimes addObject:[[NSArray alloc] initWithObjects:lastEventEndDate,endOfTimeToday,nil]];
//    }


//
//- (NSDate *) getTargetTimeAsNSDate:(NSDate *) nsDate
//                              hour:(int) hour
//                            minute:(int) minute
//                            second:(int) second
//                           nextDay:(BOOL)nextDay {
//    NSCalendar *calendar = [NSCalendar currentCalendar];
//    NSDateComponents *dateComps = [calendar components:NSYearCalendarUnit |
//                                   NSMonthCalendarUnit  |
//                                   NSDayCalendarUnit    |
//                                   NSHourCalendarUnit   |
//                                   NSMinuteCalendarUnit |
//                                   NSSecondCalendarUnit fromDate:nsDate];
//    [dateComps setDay:dateComps.day];
//    [dateComps setHour:hour];
//    [dateComps setMinute:minute];
//    [dateComps setSecond:second];
//    NSDate * targetNSDate = [calendar dateFromComponents:dateComps];
////    return targetNSDate;
//    
//    if (nextDay) {
//        if ([targetNSDate timeIntervalSince1970] < [nsDate timeIntervalSince1970]) {
//            [dateComps setDay:dateComps.day + 1];
//            NSDate * tomorrowNSDate = [calendar dateFromComponents:dateComps];
//            return tomorrowNSDate;
//        }else{
//            return targetNSDate;
//        }
//    }else{
//        return targetNSDate;
//    }
//}



- (BOOL) stopSensor {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
//    [uploadTimer invalidate];
    [calendarUpdateTimer invalidate];
//    [locationTimer invalidate];
    calendarUpdateTimer = nil;
    return YES;
}


//- (void) startLocationSensor{
//    if (nil == locationManager){
//        locationManager = [[CLLocationManager alloc] init];
//        locationManager.delegate = self;
//        //    locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;
//        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
//        locationManager.pausesLocationUpdatesAutomatically = NO;
//        CGFloat currentVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
//        NSLog(@"OS:%f", currentVersion);
//        if (currentVersion >= 9.0) {
//            //        _homeLocationManager.allowsBackgroundLocationUpdates = YES; //This variable is an important method for background sensing
//            locationManager.allowsBackgroundLocationUpdates = YES; //This variable is an important method for background sensing after iOS9
//        }
//        locationManager.activityType = CLActivityTypeFitness;
//        if ([locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
//            [locationManager requestAlwaysAuthorization];
//        }
//        // Set a movement threshold for new events.
//        locationManager.distanceFilter = miniDistrance; // meters
//        [locationManager startUpdatingLocation];
//        [locationManager startMonitoringVisits]; // This method calls didVisit.
//        [locationManager startUpdatingHeading];
//        //    _location = [[CLLocation alloc] init];
//        if(interval > 0){
//            locationTimer = [NSTimer scheduledTimerWithTimeInterval:interval
//                                                         target:self
//                                                       selector:@selector(getGpsData)
//                                                       userInfo:nil
//                                                        repeats:YES];
//            [locationTimer fire];
//        }
//    }
//}
//
//- (void)locationManager:(CLLocationManager *)manager
//               didVisit:(CLVisit *)visit {
//    NSManagedObject *visitObject = [NSEntityDescription insertNewObjectForEntityForName:@"Visit" inManagedObjectContext:_managedObjectContext];
//    
//    CLGeocoder *ceo = [[CLGeocoder alloc]init];
//    CLLocation *loc = [[CLLocation alloc]initWithLatitude:visit.coordinate.latitude longitude:visit.coordinate.longitude]; //insert your coordinates
//    [ceo reverseGeocodeLocation:loc
//              completionHandler:^(NSArray *placemarks, NSError *error) {
//                  CLPlacemark * placemark = nil;
//                  if (placemarks.count > 0) {
//                      placemark = [placemarks objectAtIndex:0];
//                  }
//                  //                  NSLog(@"placemark %@",placemark);
//                  //                  //String to hold address
//                  NSString *locatedAt = [[placemark.addressDictionary valueForKey:@"FormattedAddressLines"] componentsJoinedByString:@", "];
//                  //                  NSLog(@"addressDictionary %@", placemark.addressDictionary);
//                  //
//                  //                  NSLog(@"placemark %@",placemark.region);
//                  //                  NSLog(@"placemark %@",placemark.country);  // Give Country Name
//                  //                  NSLog(@"placemark %@",placemark.locality); // Extract the city name
//                  //                  NSLog(@"location %@",placemark.name);
//                  //                  NSLog(@"location %@",placemark.ocean);
//                  //                  NSLog(@"location %@",placemark.postalCode);
//                  //                  NSLog(@"location %@",placemark.subLocality);
//                  //
//                  //                  NSLog(@"location %@",placemark.location);
//                  //Print the location to console
//                  NSLog(@"I am currently at %@",locatedAt);
//                  
//                  double timestamp = [[NSDate new] timeIntervalSince1970];
//                  double depature = [[visit departureDate] timeIntervalSince1970];
//                  double arrival = [[visit arrivalDate] timeIntervalSince1970];
//                  
//                  // Process in the main thread.
//                  [visitObject setValue:[NSNumber numberWithDouble:timestamp] forKey:@"timestamp"];
//                  [visitObject setValue:[NSNumber numberWithDouble:visit.coordinate.latitude] forKey:@"latitude"];
//                  [visitObject setValue:[NSNumber numberWithDouble:visit.coordinate.longitude] forKey:@"longitude"];
//                  [visitObject setValue:[NSNumber numberWithDouble:depature] forKey:@"departure"];
//                  [visitObject setValue:[NSNumber numberWithDouble:arrival] forKey:@"arrival"];
//                  [visitObject setValue:[NSNumber numberWithDouble:visit.horizontalAccuracy] forKey:@"accuracy"];
//                  if (placemarks != nil) {
//                      [visitObject setValue:locatedAt forKey:@"name"];
//                  }else{
//                      [visitObject setValue:@"" forKey:@"name"];
//                  }
//                  
//                  
//                  // Save the created NSManagedOobject to DB with NSError.
//                  NSError *e = nil;
//                  if (![_managedObjectContext save:&e]) {
//                      NSLog(@"error = %@", e);
//                  } else {
//                      NSLog(@"Visit : Insert Completed.");
//                  }
//              }];
//
//}
//
//- (void)locationManager:(CLLocationManager *)manager
//       didUpdateHeading:(CLHeading *)newHeading {
//    if (newHeading.headingAccuracy < 0)
//        return;
//    //    CLLocationDirection  theHeading = ((newHeading.trueHeading > 0) ?
//    //                                       newHeading.trueHeading : newHeading.magneticHeading);
//    //    [sdManager addSensorDataMagx:newHeading.x magy:newHeading.y magz:newHeading.z];
//    //    [sdManager addHeading: theHeading];
//}
//
//
//- (void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations{
//    for (CLLocation* location in locations) {
//        // Make a new NSManagedObject with entity name
//        [self saveLocation:location];
//    }
//}
//
//- (void) getGpsData {
//    //[sdManager addLocation:[_locationManager location]];
//    CLLocation* location = [locationManager location];
//    [self saveLocation:location];
//    
//    //削除対象のフェッチ情報を生成
//    NSFetchRequest *deleteRequest = [[NSFetchRequest alloc] init];
//    [deleteRequest setEntity:[NSEntityDescription entityForName:@"Location" inManagedObjectContext:_managedObjectContext]];
//    [deleteRequest setIncludesPropertyValues:NO];
//    
//    NSError *error = nil;
//    
//    //生成したフェッチ情報からデータをフェッチ
//    NSArray *results = [_managedObjectContext executeFetchRequest:deleteRequest error:&error];
//    NSLog(@"Number of location data: %ld", results.count);
//    
//    //[deleteRequest release]; //ARCオフの場合
//    
//    //フェッチしたデータを削除処理
//    //    for (NSManagedObject *data in results) {
//    //        [managedObjectContext deleteObject:data];
//    //    }
//    //    NSError *saveError = nil;
//    //    //削除を反映
//    //    [managedObjectContext save:&saveError];
//}
//
//- (void) saveLocation:(CLLocation *) location {
//    NSManagedObject *object = [NSEntityDescription insertNewObjectForEntityForName:@"Location" inManagedObjectContext:_managedObjectContext];
//    
//    // Add data to the object
//    double timestamp = [[NSDate new] timeIntervalSince1970];
//    [object setValue:[NSNumber numberWithDouble:timestamp] forKey:@"timestamp"];
//    [object setValue:[NSNumber numberWithDouble:location.coordinate.latitude] forKey:@"latitude"];
//    [object setValue:[NSNumber numberWithDouble:location.coordinate.longitude] forKey:@"longitude"];
//    
//    // Save the created NSManagedOobject to DB with NSError.
//    NSError *error = nil;
//    if (![_managedObjectContext save:&error]) {
//        NSLog(@"error = %@", error);
//    } else {
//        NSLog(@"Insert Completed.");
//    }
//    
//    
//    
////    NSManagedObject *visitObject = [NSEntityDescription insertNewObjectForEntityForName:@"Visit" inManagedObjectContext:_managedObjectContext];
////    
////    CLGeocoder *ceo = [[CLGeocoder alloc]init];
////    CLLocation *loc = [[CLLocation alloc]initWithLatitude:location.coordinate.latitude longitude:location.coordinate.longitude]; //insert your coordinates
////    [ceo reverseGeocodeLocation:loc
////              completionHandler:^(NSArray *placemarks, NSError *error) {
////                  CLPlacemark * placemark = nil;
////                  if (placemarks.count > 0) {
////                      placemark = [placemarks objectAtIndex:0];
////                  }
////                  //                  NSLog(@"placemark %@",placemark);
////                  //                  //String to hold address
////                  NSString *locatedAt = [[placemark.addressDictionary valueForKey:@"FormattedAddressLines"] componentsJoinedByString:@", "];
////                  //                  NSLog(@"addressDictionary %@", placemark.addressDictionary);
////                  //
////                  //                  NSLog(@"placemark %@",placemark.region);
////                  //                  NSLog(@"placemark %@",placemark.country);  // Give Country Name
////                  //                  NSLog(@"placemark %@",placemark.locality); // Extract the city name
////                  //                  NSLog(@"location %@",placemark.name);
////                  //                  NSLog(@"location %@",placemark.ocean);
////                  //                  NSLog(@"location %@",placemark.postalCode);
////                  //                  NSLog(@"location %@",placemark.subLocality);
////                  //
////                  //                  NSLog(@"location %@",placemark.location);
////                  //Print the location to console
////                  NSLog(@"I am currently at %@",locatedAt);
////                  
////                  double timestamp = [[NSDate new] timeIntervalSince1970];
////                  double depature = [[NSDate new] timeIntervalSince1970];
////                  double arrival = [[NSDate new] timeIntervalSince1970];
////                  
////                  // Process in the main thread.
////                  [visitObject setValue:[NSNumber numberWithDouble:timestamp] forKey:@"timestamp"];
////                  [visitObject setValue:[NSNumber numberWithDouble:location.coordinate.latitude] forKey:@"latitude"];
////                  [visitObject setValue:[NSNumber numberWithDouble:location.coordinate.longitude] forKey:@"longitude"];
////                  [visitObject setValue:[NSNumber numberWithDouble:depature] forKey:@"departure"];
////                  [visitObject setValue:[NSNumber numberWithDouble:arrival] forKey:@"arrival"];
////                  [visitObject setValue:[NSNumber numberWithDouble:location.horizontalAccuracy] forKey:@"accuracy"];
////                  if (placemarks != nil) {
////                      [visitObject setValue:locatedAt forKey:@"name"];
////                  }else{
////                      [visitObject setValue:@"" forKey:@"name"];
////                  }
////                  
////                  
////                  // Save the created NSManagedOobject to DB with NSError.
////                  NSError *e = nil;
////                  if (![_managedObjectContext save:&e]) {
////                      NSLog(@"error = %@", e);
////                  } else {
////                      NSLog(@"Visit : Insert Completed.");
////                  }
////              }];
//
//    
//    
//}

//
//
//
///**
// * ===========
// * For CoreData
// * ===========
// */
//#pragma mark - Core Data stack
//
//@synthesize managedObjectContext = _managedObjectContext;
//@synthesize managedObjectModel = _managedObjectModel;
//@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
//
//- (NSURL *)applicationDocumentsDirectory {
//    // The directory the application uses to store the Core Data store file. This code uses a directory named "jp.ac.keio.sfc.ht.tetujin.AWARE" in the application's documents directory.
//    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
//}
//
//- (NSManagedObjectModel *)managedObjectModel {
//    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
//    if (_managedObjectModel != nil) {
//        return _managedObjectModel;
//    }
//    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"LocationModel" withExtension:@"momd"];
//    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
//    return _managedObjectModel;
//}
//
//- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
//    // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it.
//    if (_persistentStoreCoordinator != nil) {
//        return _persistentStoreCoordinator;
//    }
//    
//    // Create the coordinator and store
//    
//    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
//    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"LocationProj.sqlite"];
//    NSError *error = nil;
//    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
//    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
//        // Report any error we got.
//        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
//        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
//        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
//        dict[NSUnderlyingErrorKey] = error;
//        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
//        // Replace this with code to handle the error appropriately.
//        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
//        abort();
//    }
//    
//    return _persistentStoreCoordinator;
//}
//
//
//- (NSManagedObjectContext *)managedObjectContext {
//    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
//    if (_managedObjectContext != nil) {
//        return _managedObjectContext;
//    }
//    
//    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
//    if (!coordinator) {
//        return nil;
//    }
//    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
//    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
//    return _managedObjectContext;
//}
//
//#pragma mark - Core Data Saving support
//
//- (void)saveContext {
//    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
//    if (managedObjectContext != nil) {
//        NSError *error = nil;
//        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
//            // Replace this implementation with code to handle the error appropriately.
//            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
//            abort();
//        }
//    }
//}


@end
