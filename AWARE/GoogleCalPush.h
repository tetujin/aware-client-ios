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
#import <CoreLocation/CoreLocation.h>
#import <CoreData/CoreData.h>
//#import <MapKit/MapKit.h>

@interface GoogleCalPush : AWARESensor <AWARESensorDelegate, CLLocationManagerDelegate>

//@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
//@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
//@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;
- (void) showTargetCalendarCondition;

@end
