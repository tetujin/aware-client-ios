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
#import "WebESM.h"
#import "ESM.h"
#import "ESMStorageHelper.h"


@implementation ViewController{
    AWAREStudy * awareStudy;
    AWARESensorManager * sensorManager;
    WebESM *webESM;
    AWARECore * core;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];

    /// Initi Core Data Manager
    AppDelegate *delegate= (AppDelegate*)[UIApplication sharedApplication].delegate;
    core = delegate.sharedAWARECore;
    sensorManager =     core.sharedSensorManager;
    awareStudy =        core.sharedAwareStudy;
    
    /// Start an update timer for list view. This timer refreshed the list view every 0.1 sec.
    webESM = [[WebESM alloc] initWithAwareStudy:awareStudy dbType:AwareDBTypeCoreData];
    
    // Set delegates for a navigation bar and table view
    if ([AWAREUtils getCurrentOSVersionAsFloat] >= 9.0) {
        [self.navigationController.navigationBar setDelegate:self];
    }
}

/**
 * This method is called when application did becase active.
 * And also, this method check ESM existance using ESMStorageHelper. 
 * If an ESM is existed, AWARE iOS move to the ESM answer page.
 */
- (void)appDidBecomeActive:(NSNotification *)notification
{
    NSLog(@"did become active notification");
    
    if(![ESM isAppearedThisSection]){
        [self pushedEsmButtonOnNavigationBar:nil];
    }
    
    [core checkComplianceWithViewController:self];
}


- (IBAction)pushedEsmButtonOnNavigationBar:(id)sender
{
    
    NSLog(@"pushed ESM button on navigation bar");
    
    // For schedules ESMs
    ESMStorageHelper * helper = [[ESMStorageHelper alloc] init];
    NSArray * storedEsms = [helper getEsmTexts];
    if(storedEsms != nil){
        if (storedEsms.count > 0 ){
            [ESM setAppearedState:YES];
            [self performSegueWithIdentifier:@"esmView" sender:self];
        }
    }
    
    // For Web ESMs
    NSArray * esms = [webESM getValidESMsWithDatetime:[NSDate new]];
    if(esms != nil && esms.count != 0 ){
        [ESM setAppearedState:YES];
        [self performSegueWithIdentifier:@"webEsmView" sender:self];
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

//////////////////////////////////////////////////////////////////////////

/**
 * ======================
 * Please edit this area
 * ======================
 */


@end
