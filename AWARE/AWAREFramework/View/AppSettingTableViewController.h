//
//  AppSettingTableViewController.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 2017/08/20.
//  Copyright © 2017 Yuuki NISHIYAMA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EAIntroView.h"

@interface AppSettingTableViewController : UITableViewController <UITableViewDelegate,UITableViewDataSource, UITabBarControllerDelegate, UINavigationBarDelegate, UIAlertViewDelegate, EAIntroDelegate>

@property (nonatomic,strong) NSMutableArray *settings;

@end
