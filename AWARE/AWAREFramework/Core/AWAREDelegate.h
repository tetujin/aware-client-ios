//
//  AWAREDelegate.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 6/2/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Google/SignIn.h>
#import <DeployGateSDK/DeployGateSDK.h>
#import <CoreData/CoreData.h>
#import "AWARECore.h"

@interface AWAREDelegate : UIResponder <UIApplicationDelegate, GIDSignInDelegate,  UIAlertViewDelegate>

@property (strong, nonatomic) AWARECore * sharedAWARECore;

@property (strong, nonatomic) UIWindow *window;

// CoreDate
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;

- (void)setNotification:(UIApplication *)application;

- (BOOL)isRequiredMigration;
- (BOOL)doMigration;

// for migration
//- (BOOL)isRequiredMigration;
//- (BOOL)doMigration;

@end
