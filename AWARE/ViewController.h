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
#import "AWARESensorManager.h"

@interface ViewController : UITableViewController <UITableViewDelegate, UITableViewDataSource, UITabBarControllerDelegate, UINavigationBarDelegate, CLLocationManagerDelegate, UIAlertViewDelegate>

@property (nonatomic,strong) NSMutableArray *sensors;
@property (strong, nonatomic) AWARESensorManager* sensorManager;
@property (strong, nonatomic) CLLocationManager *homeLocationManager;
//@property (strong, nonatomic) SensorDataManager * sensorDataManager;

- (IBAction)pushedStudyRefreshButton:(id)sender;

@property MQTTClient *client;

@end

