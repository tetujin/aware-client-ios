//
//  ViewController.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/18/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//
// This branch is for BalancedCampus Project
//

// Views
#import "ViewController.h"
#import "GoogleLoginViewController.h"
#import "WebViewController.h"

// AWARE Core
#import "AppDelegate.h"
#import "AWARECore.h"

// AWARE ESM
#import "IOSESM.h"

#import "Accelerometer.h"

@implementation ViewController{
    AWAREStudy * awareStudy;
    AWARESensorManager * sensorManager;
    AWARECore * core;
    
    IOSESM * iOSESM;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];

    /// Initi Core Data Manager
    AppDelegate *delegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    core          = delegate.sharedAWARECore;
    sensorManager =     core.sharedSensorManager;
    awareStudy    =     core.sharedAwareStudy;
    
    if ([core.sharedLocationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        [core.sharedLocationManager requestAlwaysAuthorization];
        [core activate];
    }
    [delegate setNotification:[UIApplication sharedApplication]];

    ////////// A sample source code for setting aware server //////////////
//    [awareStudy setStudyInformationWithURL:@"https://aware.ht.sfc.keio.ac.jp/index.php/webservice/index/[study_id]/[password]"];
//    [awareStudy refreshStudy];
    ///////////////////////////////////////////////////////////////////////
    
    // Set delegates for a navigation bar and table view
    if ([AWAREUtils getCurrentOSVersionAsFloat] >= 9.0) {
        [self.navigationController.navigationBar setDelegate:self];
    }
    
    iOSESM = [[IOSESM alloc] initWithAwareStudy:awareStudy dbType:AwareDBTypeCoreData];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moveToGoogleLogin:)
                                                 name:ACTION_AWARE_GOOGLE_LOGIN_REQUEST
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moveToContacts:)
                                                 name:ACTION_AWARE_CONTACT_REQUEST
                                               object:nil];

    ////// sample source code for activating an accelerometer sensor //////
//    Accelerometer * accSensor = [[Accelerometer alloc] initWithAwareStudy:awareStudy dbType:AwareDBTypeCoreData];
//    [accSensor startSensorWithInterval:0.01 bufferSize:1000];
//    [accSensor performSelector:@selector(syncAwareDB) withObject:nil afterDelay:5];
//    [sensorManager addNewSensor:accSensor];
    ////////////////////////////////////////////////////////////////////////
}

/**
 * This method is called when application did becase active.
 * And also, this method check ESM existance using ESMStorageHelper. 
 * If an ESM is existed, AWARE iOS move to the ESM answer page.
 */
- (void)appDidBecomeActive:(NSNotification *)notification
{
    NSLog(@"did become active notification");
    
    NSArray * esms = [iOSESM getValidESMsWithDatetime:[NSDate new]];
    if(esms != nil && esms.count != 0 && ![IOSESM isAppearedThisSection]){
        [IOSESM setAppearedState:YES];
        [self performSegueWithIdentifier:@"iOSEsmView" sender:self];
    }
    
    [core checkComplianceWithViewController:self];
}


- (IBAction)pushedEsmButtonOnNavigationBar:(id)sender
{
    
    NSLog(@"pushed ESM button on navigation bar");
    
    NSArray * esms = [iOSESM getValidESMsWithDatetime:[NSDate new]];
    if(esms != nil && esms.count != 0 ){
        [IOSESM setAppearedState:YES];
        [self performSegueWithIdentifier:@"iOSEsmView" sender:self];
    }

}

/**
 When a study is refreshed (e.g., pushed refresh button, changed settings, 
 and/or done daily study update), this method is called before the -initList.
 */
- (IBAction)pushedStudyRefreshButton:(id)sender
{
    // Refresh the study information
    [awareStudy refreshStudy];
    
    _refreshButton.enabled = NO;
    [self performSelector:@selector(refreshButtonEnableYes) withObject:0 afterDelay:10];
}

- (void) refreshButtonEnableYes {
    _refreshButton.enabled = YES;
}


-(BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item
{
    [self.navigationController popToRootViewControllerAnimated:YES];
    return YES;
}


- (void) moveToGoogleLogin:(id)sender{
    if([AWAREUtils isForeground]){
        [self performSegueWithIdentifier:@"googleLogin" sender:self];
    }
}

- (void) moveToContacts:(id)sender{
    if([AWAREUtils isForeground]){
        [self performSegueWithIdentifier:@"contacts" sender:self];
    }
}

//////////////////////////////////////////////////////////////////////////

/**
 * ======================
 * Please edit this area
 * ======================
 */


@end
