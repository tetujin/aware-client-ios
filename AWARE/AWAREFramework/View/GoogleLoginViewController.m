//
//  GoogleLoginViewController.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/23/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "GoogleLoginViewController.h"
#import "ViewController.h"
#import "GoogleLogin.h"
#import "AppDelegate.h"

@interface GoogleLoginViewController ()

@end

@implementation GoogleLoginViewController{
    GoogleLogin * googleLogin;
    id observer;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // -- For Google Login --
    [GIDSignIn sharedInstance].uiDelegate = self;
    [[GIDSignIn sharedInstance] signInSilently];
    
    AppDelegate * delegate = (AppDelegate *) [UIApplication sharedApplication].delegate;
    
    googleLogin = [[GoogleLogin alloc] initWithAwareStudy:delegate.sharedAWARECore.sharedAwareStudy dbType:AwareDBTypeTextFile];
    
    _account.text = [GoogleLogin getGoogleAccountEmail];
    if([GoogleLogin getGoogleAccountEmail] == nil){
        [self accountIsEmpty];
    }else{
        [self accountIsExist];
    }
}

- (void)viewDidAppear:(BOOL)animated{
    if(self!=nil){
        observer = [NSNotificationCenter.defaultCenter addObserverForName:ACTION_AWARE_GOOGLE_LOGIN_SUCCESS
                                                                   object:nil
                                                                    queue:[NSOperationQueue mainQueue]
                                                               usingBlock:^(NSNotification * _Nonnull note) {
                                                                   [self showGoogleInfo];
                                                               }];
    }
}

- (void)viewDidDisappear:(BOOL)animated{
    [NSNotificationCenter.defaultCenter removeObserver:observer];
}
    

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


//////////////////////////
- (void) accountIsExist{
    NSString * message = @"Thank you for registering your Google Account.";
    _messageLabel.text = message;
}

- (void) accountIsEmpty{
    NSString * message = @"Google Login is required for this study. Please tap to Login to your account.";
    _messageLabel.text = message;
}

/////////////////////////

// Present a view that prompts the user to sign in with Google
- (void)signIn:(GIDSignIn *)signIn presentViewController:(UIViewController *)viewController {
    [self presentViewController:viewController animated:YES completion:nil];
    _account.text = [GoogleLogin getGoogleAccountEmail];
}


- (void) showGoogleInfo {
    _account.text = [GoogleLogin getGoogleAccountEmail];
    if(_account.text != nil){
        [self accountIsExist];
        UIAlertController * controller = [UIAlertController alertControllerWithTitle:@"Login Succeeded"
                                                                             message:@"Yout Google account information is stored into the local-storage."
                                                                      preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction * backAction = [UIAlertAction actionWithTitle:@"Back to main view"
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction * _Nonnull action) {
                                                                // back to main view
                                                                [self.navigationController popToRootViewControllerAnimated:YES];
        }];
        [controller addAction:backAction];
        [self presentViewController:controller animated:YES completion:nil];
    }else{
        [self accountIsEmpty];
    }
}

- (IBAction)didTapSignOut:(id)sender {
    [[GIDSignIn sharedInstance] signOut];
    
    [GoogleLogin deleteGoogleAccountFromLocalStorage];
    
    UIAlertController * controller = [UIAlertController alertControllerWithTitle:@"Logout Succeeded"
                                                                         message:@"Logout from Google account, and remove the account information from the local-storage."
                                                                  preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction * closeAction = [UIAlertAction actionWithTitle:@"Close"
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction * _Nonnull action) {
                                                            // back to main view
                                                            // [self.navigationController popToRootViewControllerAnimated:YES];
                                                        }];
    [controller addAction:closeAction];
    [self presentViewController:controller animated:YES completion:nil];
    
    _account.text = @"";
    [self accountIsEmpty];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

//[self dismissViewControllerAnimated:YES completion:nil];
//[self performSelector:@selector(showGoogleInfo) withObject:nil afterDelay:1];
//
//NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
//NSString * userId = [defaults objectForKey:@"GOOGLE_ID"];
//if(userId == nil){
//    [self.navigationController popToRootViewControllerAnimated:YES];
//}

@end
