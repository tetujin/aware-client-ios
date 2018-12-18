//
//  OnboardingViewController.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 2018/12/18.
//  Copyright © 2018 Yuuki NISHIYAMA. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OnboardingViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UILabel *studyTitle;
@property (weak, nonatomic) IBOutlet UITextView *studyDescription;
@property (weak, nonatomic) IBOutlet UITextView *reseacher;
@property (weak, nonatomic) IBOutlet UITextField *userLabel;
@property (weak, nonatomic) IBOutlet UITableView *requiredSensorsTable;
- (IBAction)pushedQuitStudyButton:(UIButton *)sender;
- (IBAction)pushedSignUpButton:(UIButton *)sender;

- (void) setStudyURL:(NSString *) url;

@end

NS_ASSUME_NONNULL_END
