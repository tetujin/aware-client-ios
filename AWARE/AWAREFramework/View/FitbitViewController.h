//
//  FitbitViewController.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 2017/05/15.
//  Copyright © 2017 Yuuki NISHIYAMA. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FitbitViewController : UIViewController<UIGestureRecognizerDelegate, UITextFieldDelegate>

@property(nonatomic, strong) UITapGestureRecognizer *singleTap;

@property (weak, nonatomic) IBOutlet UISegmentedControl *stateSegment;
@property (weak, nonatomic) IBOutlet UISegmentedControl *unitSegment;
@property (weak, nonatomic) IBOutlet UITextField *updateIntervalMin;
@property (weak, nonatomic) IBOutlet UISegmentedControl *generalGranularitySegment;
@property (weak, nonatomic) IBOutlet UISegmentedControl *htGranularitySegment;
@property (weak, nonatomic) IBOutlet UITextField *apiKeyField;
@property (weak, nonatomic) IBOutlet UITextField *apiSecretField;
@property (weak, nonatomic) IBOutlet UITextView *debugTextView;
@property (weak, nonatomic) IBOutlet UITextField *LastSyncDateField;

// Actions
- (IBAction)pushedApplyButton:(id)sender;
- (IBAction)pushedInfoButton:(id)sender;
- (IBAction)pushedClearSettingButton:(id)sender;
- (IBAction)pushedRefreshTokenButton:(id)sender;
- (IBAction)pushedLoginButton:(id)sender;
- (IBAction)pushedGetLatestDataButton:(id)sender;
- (IBAction)pushedRefreshButton:(id)sender;
- (IBAction)pushedGetTokensButton:(id)sender;

@end
