//
//  GoogleCal.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 12/18/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

//#import "AWARESensor.h"
#import "AWAREPlugin.h"
#import <EventKit/EventKit.h>
#import <EventKitUI/EventKitUI.h>
//#import <CoreLocation/CoreLocation.h>

@interface GoogleCalPull : AWAREPlugin <UIAlertViewDelegate>

- (BOOL) showSelectPrimaryGoogleCalView;

@end
