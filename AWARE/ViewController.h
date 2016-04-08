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

@interface ViewController : UITableViewController <UITableViewDelegate, UITableViewDataSource, UITabBarControllerDelegate, UINavigationBarDelegate, UIAlertViewDelegate>

- (IBAction)pushedStudyRefreshButton:(id)sender;
- (IBAction)pushedGoogleLogin:(id)sender;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *refreshButton;

@property (nonatomic,strong) NSMutableArray *sensors;
@property MQTTClient *client;

@end

