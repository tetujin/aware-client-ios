//
//  GoogleLoginViewController.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/23/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Google/SignIn.h>

@interface GoogleLoginViewController : UIViewController <GIDSignInUIDelegate>

@property(weak, nonatomic) IBOutlet GIDSignInButton *signInButton;
@property (weak, nonatomic) IBOutlet UILabel *account;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;

@end
