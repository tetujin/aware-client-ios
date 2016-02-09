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
#import "AWAREKeys.h"


@interface AppDelegate : UIResponder <UIApplicationDelegate, GIDSignInDelegate,  UIAlertViewDelegate>{
    NSString* check;
}

@property (strong, nonatomic) UIWindow *window;



@end

