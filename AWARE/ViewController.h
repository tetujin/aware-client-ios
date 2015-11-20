//
//  ViewController.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/18/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MQTTKit/MQTTKit.h>
#import "AWARESensorManager.h"

@interface ViewController : UITableViewController <UITableViewDelegate, UITableViewDataSource, UITabBarControllerDelegate, UINavigationBarDelegate>

@property (nonatomic,strong) NSMutableArray *sensors;
@property (nonatomic, strong) AWARESensorManager* sensorManager;

@property MQTTClient *client;

@end

