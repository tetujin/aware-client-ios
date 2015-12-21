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

#import "GoogleCal.h"
#import "AWAREKeys.h"
#import <CoreData/CoreData.h>

@implementation GoogleCal {
    // for calendar events
    EKEventStore *store;
    NSTimer * calRefreshTimer;
    
    // for locations
    double miniDistrance;
    IBOutlet CLLocationManager *locationManager;

    // for AWARE sensor
    NSTimer* uploadTimer;
}

- (instancetype)initWithSensorName:(NSString *)sensorName {
    self = [super initWithSensorName:sensorName];
    if (self) {
        miniDistrance = 15;
        store = [[EKEventStore alloc] init];
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


- (void) createTable {
    NSString* query = @""; //TODO Add query
    [super createTable:query];
}

- (BOOL)startSensor:(double)upInterval withSettings:(NSArray *)settings {
    NSLog(@"[%@] Create table", [self getSensorName]);
    
    
    uploadTimer = [NSTimer scheduledTimerWithTimeInterval:upInterval target:self selector:@selector(syncAwareDB) userInfo:nil repeats:YES];

    // [TODO] This is test code
//    [self addEventToCalender];
    
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
    
    return YES;
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
    [offsetComponents setMonth:4];
    [offsetComponents setYear:0];
    NSDate *endDate = [[NSCalendar currentCalendar] dateByAddingComponents:offsetComponents toDate:now options:0];
    
    NSArray *ekEventStoreChangedObjectIDArray = [notification.userInfo objectForKey:@"EKEventStoreChangedObjectIDsUserInfoKey"];
    NSPredicate *predicate = [ekEventStore    predicateForEventsWithStartDate:now
                                                                      endDate:endDate
                                                                    calendars:nil];
    // Loop through all events in range
    [ekEventStore enumerateEventsMatchingPredicate:predicate usingBlock:^(EKEvent *ekEvent, BOOL *stop) {
        // Check this event against each ekObjectID in notification
        [ekEventStoreChangedObjectIDArray enumerateObjectsUsingBlock:^(NSString *ekEventStoreChangedObjectID, NSUInteger idx, BOOL *stop) {
            NSObject *ekObjectID = [(NSManagedObject *)ekEvent objectID];
            if ([ekEventStoreChangedObjectID isEqual:ekObjectID]) {
                // Log the event we found and stop (each event should only exist once in store)
                NSLog(@"calendarChanged(): Event Changed: title:%@", ekEvent.title);
                NSLog(@"%@",ekEvent.eventIdentifier);
                *stop = YES;
            }
        }];
    }];
    
    
    // Delete -> 過去のカレンダーと比較してcalender -> updat
    // Update
    // Add
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
    if(error){
        NSLog(@"%@", error.debugDescription);
    }
}

@end
