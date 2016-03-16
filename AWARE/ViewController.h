//
//  ViewController.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/18/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MQTTKit/MQTTKit.h>
#import <CoreLocation/CoreLocation.h>
#import <SVProgressHUD.h>
#import "AWARESensorManager.h"
#import <RNGridMenu/RNGridMenu.h>

@interface ViewController : UITableViewController <UITableViewDelegate, UITableViewDataSource, UITabBarControllerDelegate, UINavigationBarDelegate, CLLocationManagerDelegate, UIAlertViewDelegate, RNGridMenuDelegate>

@property (nonatomic,strong) NSMutableArray *sensors;
@property (strong, nonatomic) AWARESensorManager* sensorManager;
@property (strong, nonatomic) CLLocationManager *homeLocationManager;

- (IBAction)pushedStudyRefreshButton:(id)sender;
- (IBAction)pushedGoogleLogin:(id)sender;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *refreshButton;

@property MQTTClient *client;

@end

