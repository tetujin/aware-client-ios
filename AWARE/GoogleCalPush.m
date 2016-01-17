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
    
//    NSTimer * uploadTimer;
    NSTimer * calendarUpdateTimer;
    NSString* AWARE_CAL_NAME;
    
    // for locations
//    double miniDistrance;
//    IBOutlet CLLocationManager *locationManager;
//    double interval;
//    NSTimer* locationTimer;
}

- (instancetype)initWithSensorName:(NSString *)sensorName {
    self = [super initWithSensorName:sensorName];
    if (self) {
//        [self managedObjectContext];
//        [self managedObjectModel];
//        [self persistentStoreCoordinator];
        AWARE_CAL_NAME = @"BalancedCampusJournal";
//        miniDistrance = 15;
//        interval = 60;
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


- (BOOL)startSensor:(double)upInterval withSettings:(NSArray *)settings {
    
    [self setDailyNotification];
//    [self startLocationSensor];

    return YES;
}


- (void) setDailyNotification {
    // Get fix time
    NSDate* date = [NSDate date];
    NSDate * elevenOClock  = [self getTargetTimeAsNSDate:date hour:13 minute:40 second:0 nextDay:YES];
    NSLog(@"date: %@", elevenOClock );
    calendarUpdateTimer = [[NSTimer alloc] initWithFireDate:elevenOClock
                                                   interval:60*60*24
                                                     target:self
                                                   selector:@selector(checkAllEvents:)
                                                   userInfo:nil
                                                    repeats:YES];
//    [calendarUpdateTimer fire];
    //https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/Timers/Articles/usingTimers.html
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    [runLoop addTimer:calendarUpdateTimer forMode:NSDefaultRunLoopMode];
    
    
//    [self checkAllEvents:nil];
}

- (void) checkAllEvents:(id) sender {
    // Get all events
    NSLog(@"Cal event id updated !!!");
    
    EKCalendar * awareCal = nil;
    // Get the aware calendar in Google Calendars
    for (EKCalendar * cal in [store calendarsForEntityType:EKEntityTypeEvent]) {
        NSLog(@"[%@] %@", cal.title, cal.calendarIdentifier );
        if ([cal.title isEqualToString:AWARE_CAL_NAME]) {
            awareCal = cal;
        }
    }
    
    if (awareCal == nil) {
        NSLog(@"[ERROR] AWARE iOS can not find a Google calendar for AWARE. Please add 'AWARE Calendar' to your google calendar. ");
        return;
    }
    
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

    
    // == Make new events (Aware Events), and Get Null events ==
    NSMutableArray * nullTimes = [[NSMutableArray alloc] init];
    EKEvent * lastEvent = [EKEvent eventWithEventStore:store];
    lastEvent.startDate = [self getTargetTimeAsNSDate:[NSDate date] hour:0 minute:0 second:0 nextDay:NO];
    lastEvent.endDate   = [self getTargetTimeAsNSDate:[NSDate date] hour:0 minute:0 second:0 nextDay:NO];
    
    NSMutableArray * awareEvents = [[NSMutableArray alloc] initWithArray:currentEvents];

    int g = 1;
    for ( EKEvent * event in awareEvents ) {

//        NSLog(@"%@", event.notes);
        EKEvent * awareEvent = [EKEvent eventWithEventStore:store];
        // Add questions to a note of aware events
        awareEvent.notes = event.notes; //[NSString stringWithFormat:@"%@%@", event.notes, questions];
        awareEvent.title = event.title;
        awareEvent.startDate = event.startDate;
        awareEvent.endDate = event.endDate;
        awareEvent.location = event.location;
        // Change an aware event's calendar
        awareEvent.calendar = awareCal;
        // save events to the aware calendar
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, g * 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            NSError * error = nil;
            [store saveEvent:awareEvent span:EKSpanThisEvent commit:YES error:&error];
            if (error != nil) {
                NSLog(@"[%d] error: %@", g, error.debugDescription);
            }else{
                NSLog(@"[%d] success!",g);
            }
        });
        g++;
        
        
        
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
    
    // Add last NSDate to NullEvents
    NSDate * endOfTimeToday = [self getTargetTimeAsNSDate:[NSDate date] hour:24 minute:0 second:0 nextDay:NO];
    NSDate * lastEventEndDate = lastEvent.endDate;
    double gap = [endOfTimeToday timeIntervalSince1970] - [lastEventEndDate timeIntervalSince1970];
    if (gap > 0) {
        [nullTimes addObject:[[NSArray alloc] initWithObjects:lastEventEndDate,endOfTimeToday,nil]];
    }
    
    NSMutableArray *hours = [[NSMutableArray alloc] init];
    for (int i=0; i<25; i++) {
        NSDate * today = [NSDate date];
        [hours addObject:[self getTargetTimeAsNSDate:today hour:i minute:0 second:0 nextDay:NO]];
    }
    
    for (NSArray * times in nullTimes) {
        NSDate * nullStart = [times objectAtIndex:0];
        NSDate * nullEnd = [times objectAtIndex:1];
        NSDate * tempNullTime = nullStart;
        for (int i=0; i<hours.count; i++) {
            NSDate * currentHour = [hours objectAtIndex:i];
            //set start date
//            NSLog(@"%@",currentHour);
            if (tempNullTime < currentHour ){
                if (nullEnd >= currentHour) {
                    EKEvent * event = [EKEvent eventWithEventStore:store];
                    event.title = @"#event_category #Location #brief_description"; //@"#event_category #Location #brief_description"
                    event.calendar  = awareCal;
//                    NSLog(@"-->  %@", currentHour);
                    double gap = [nullEnd timeIntervalSince1970] - [currentHour timeIntervalSince1970];
//                    NSLog(@"gap: %f", gap);
                    if ( gap < 60*60) {
                        NSLog(@"start:%@  end:%@", tempNullTime, nullEnd );
                        event.startDate = tempNullTime;
                        event.endDate   = nullEnd;
                    } else{
                        NSLog(@"start:%@  end:%@", tempNullTime, currentHour);
                        event.startDate = tempNullTime;
                        event.endDate   = currentHour;
                    }
                    // save events to the aware calendar
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, i * 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                        NSError * error;
                        [store saveEvent:event span:EKSpanThisEvent commit:YES error:&error];
                        if (error != nil) {
                            NSLog(@"[%d] error: %@", i, error.debugDescription);
                        }else{
                            NSLog(@"[%d] success!", i);
                        }
                    });
                    
                    tempNullTime = currentHour;
                }
            }
        }
    }
    //set end date

    
    
    //make a calendar by one hour
//    for (int i=0; i<23; i++) {
//        EKEvent * event = [EKEvent eventWithEventStore:store];
//        NSDate * today = [NSDate date];
//        event.title = [NSString stringWithFormat:@"%d", i];
//        event.startDate = [self getTargetTimeAsNSDate:today hour:i minute:0 second:0];
//        event.endDate   = [self getTargetTimeAsNSDate:today hour:i+1 minute:0 second:0];
//        event.calendar = awareCal;
//        NSError * error;
//        // save events to the aware calendar
//        for (EKEvent * existingEvent in awareEvents) {
//            existingEvent.startDate;
//            existingEvent.endDate;
//        }
//        [store saveEvent:event span:EKSpanThisEvent commit:YES error:&error];
//        NSLog(@"error: %@", error.debugDescription);
//    }
    
    
    // Make and add pre-determinate events to AWARE Calendar
//    for (NSArray * times in nullTimes) {
//        NSDate * nullStart = [times objectAtIndex:0];
//        NSDate * nullEnd = [times objectAtIndex:1];
//        while (true) {
//            
//        }
//    }
    
    
    // == Make pre-determinate events from visit events, and add events to aware calendars ==
//    for (NSArray * times in nullTimes) {
//        NSDate * nullStart = [times objectAtIndex:0];
//        NSDate * nullEnd = [times objectAtIndex:1];
//        
//        //Get Visit Information
//        NSFetchRequest *searchRequest = [[NSFetchRequest alloc] init];
//        [searchRequest setEntity:[NSEntityDescription entityForName:@"Visit" inManagedObjectContext:_managedObjectContext]];
//        [searchRequest setIncludesPropertyValues:NO];
//        NSError *error = nil;
//        NSArray *results = [_managedObjectContext executeFetchRequest:searchRequest error:&error];
//        NSLog(@"Number of location data: %ld", results.count);
//        
//        for (NSManagedObject *visit in results) {
////            NSDictionary * visit = (NSDictionary *)data;//[_managedObjectContext objectWithID:data.objectID];
//            if (visit != nil) {
//                double departure = [[visit valueForKey:@"departure"] doubleValue];
//                double arrival = [[visit valueForKey:@"arrival"] doubleValue];
//                NSString * name = [visit valueForKey:@"name"];
//                
//                // If there are visit events in the database during nullEvents, the plugin add visit events as a pre-determinate event.
//                if ([nullStart timeIntervalSince1970] > arrival || [nullEnd timeIntervalSince1970] < departure ) {
//                    EKEvent *preEvent = [EKEvent eventWithEventStore:store];
//                    preEvent.title = name;
//                    preEvent.location = name;
////                    preEvent.notes = questions;
//                    preEvent.startDate = [[NSDate alloc] initWithTimeIntervalSince1970:arrival];
//                    preEvent.endDate = [[NSDate alloc] initWithTimeIntervalSince1970:departure];
//                    preEvent.calendar = awareCal;
//                    [store saveEvent:preEvent span:EKSpanThisEvent error:nil];
//                }
//            }
//        }
//    }
    
    
    // get today's events from AWARE Calendar
//    NSMutableArray* currentAwareEvents = [[NSMutableArray alloc] init];
//    predicate = [store predicateForEventsWithStartDate:startDate
//                                                            endDate:endDate
//                                                          calendars:nil];
//    [store enumerateEventsMatchingPredicate:predicate usingBlock:^(EKEvent *ekEvent, BOOL *stop) {
//        // Check this event against each ekObjectID in notification
//        if(!ekEvent.allDay){
//            if(ekEvent.calendar == awareCal){
//                [currentAwareEvents addObject:ekEvent];
//            }
//        }
//    }];
//    
//    lastEvent = [EKEvent eventWithEventStore:store];
//    lastEvent.startDate = [self getTargetTimeAsNSDate:[NSDate date] hour:0 minute:0 second:0];
//    lastEvent.endDate   = [self getTargetTimeAsNSDate:[NSDate date] hour:0 minute:0 second:0];
//    NSMutableArray * awareNullTimes = [[NSMutableArray alloc] init];
//    for (EKEvent * event in currentAwareEvents) {
//        EKEvent * awareEvent = [EKEvent eventWithEventStore:store];
//        awareEvent.startDate = event.startDate;
//        awareEvent.endDate = event.endDate;
//        // startDate - endDate
//        if (lastEvent != nil) {
//            NSDate * nullStart = lastEvent.endDate;
//            NSDate * nullEnd = event.startDate;
//            int gap = [nullEnd timeIntervalSince1970] - [nullStart timeIntervalSince1970];
//            if (gap > 0) {
//                [awareNullTimes addObject:[[NSArray alloc] initWithObjects:nullStart, nullEnd, nil]];
//            }
//        }
//        lastEvent = event;
//    }
//    endOfTimeToday = [self getTargetTimeAsNSDate:[NSDate date] hour:24 minute:0 second:0];
//    lastEventEndDate = lastEvent.endDate;
//    gap = [endOfTimeToday timeIntervalSince1970] - [lastEventEndDate timeIntervalSince1970];
//    if (gap > 0) {
//        [awareNullTimes addObject:[[NSArray alloc] initWithObjects:lastEventEndDate,endOfTimeToday,nil]];
//    }
//
//    for (NSArray * times in awareNullTimes) {
//        NSDate * nullStart = [times objectAtIndex:0];
//        NSDate * nullEnd = [times objectAtIndex:1];
//        EKEvent * awareEvent = [EKEvent eventWithEventStore:store];
//        // Add questions to a note of aware events
////        awareEvent.notes = [NSString stringWithFormat:@"%@%@", @"Empty", questions];
//        awareEvent.title = @"#event_category #Location #brief_description";
//        awareEvent.startDate = nullStart;
//        awareEvent.endDate = nullEnd;
//        awareEvent.calendar = awareCal;
//        NSError * error;
//        // save events to the aware calendar
//        [store saveEvent:awareEvent span:EKSpanThisEvent commit:YES error:&error];
//    }
    
//    endOfTimeToday = [self getTargetTimeAsNSDate:[NSDate date] hour:24 minute:0 second:0];
//    gap = [endOfTimeToday timeIntervalSince1970] - [lastEvent.endDate timeIntervalSince1970];
//    if (gap > 0) {
//        [nullTimes addObject:[[NSArray alloc] initWithObjects:lastEvent,endOfTimeToday,nil]];
//    }
    
    // == Send Notification ==
     [self sendLocalNotificationForMessage:@"Hi! Your Google Calendar is updated." soundFlag:YES];
    
    // == Remove past locations ==
//     [locationsToday removeAllObjects];
}


- (NSDate *) getTargetTimeAsNSDate:(NSDate *) nsDate
                              hour:(int) hour
                            minute:(int) minute
                            second:(int) second
                           nextDay:(BOOL)nextDay {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dateComps = [calendar components:NSYearCalendarUnit |
                                   NSMonthCalendarUnit  |
                                   NSDayCalendarUnit    |
                                   NSHourCalendarUnit   |
                                   NSMinuteCalendarUnit |
                                   NSSecondCalendarUnit fromDate:nsDate];
    [dateComps setDay:dateComps.day];
    [dateComps setHour:hour];
    [dateComps setMinute:minute];
    [dateComps setSecond:second];
    NSDate * targetNSDate = [calendar dateFromComponents:dateComps];
//    return targetNSDate;
    
    if (nextDay) {
        if ([targetNSDate timeIntervalSince1970] < [nsDate timeIntervalSince1970]) {
            [dateComps setDay:dateComps.day + 1];
            NSDate * tomorrowNSDate = [calendar dateFromComponents:dateComps];
            return tomorrowNSDate;
        }else{
            return targetNSDate;
        }
    }else{
        return targetNSDate;
    }
}



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
