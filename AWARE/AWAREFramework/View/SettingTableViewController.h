//
//  SettingTableViewController.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 9/28/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

@interface SettingTableViewController : UITableViewController<UITableViewDelegate,UIAlertViewDelegate,MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) NSString *selectedRowKey;

@property (nonatomic, strong) NSMutableArray *settingRows;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *showDataButton;

- (IBAction)pushedActionButton:(id)sender;
- (IBAction)pushedShowDataButton:(id)sender;

@end
