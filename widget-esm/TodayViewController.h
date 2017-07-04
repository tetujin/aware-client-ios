//
//  TodayViewController.h
//  widget-esm
//
//  Created by Yuuki Nishiyama on 2017/06/23.
//  Copyright © 2017 Yuuki NISHIYAMA. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TodayViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIView *mainView;

- (IBAction)pushedESMButton:(id)sender;
- (IBAction)pushedDataUploadButton:(id)sender;
- (IBAction)pushedStudyRefreshButton:(id)sender;
- (IBAction)pushedOpenAWAREButton:(id)sender;

@end
