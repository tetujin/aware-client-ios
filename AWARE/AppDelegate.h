//
//  AppDelegate.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/18/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <Google/SignIn.h>
#import <CoreLocation/CoreLocation.h>
#import "AWAREKeys.h"
#import "AWARESensorManager.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, GIDSignInDelegate,  UIAlertViewDelegate, CLLocationManagerDelegate>{
    NSString* check;
}

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) CLLocationManager *homeLocationManager;

@property (strong, nonatomic) AWARESensorManager * sharedSensorManager;
@property (strong, nonatomic) NSTimer* dailyUpdateTimer;

@end

