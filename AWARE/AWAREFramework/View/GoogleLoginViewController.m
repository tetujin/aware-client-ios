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

// Implement these methods only if the GIDSignInUIDelegate is not a subclass of
// UIViewController.

// Stop the UIActivityIndicatorView animation that was started when the user
// pressed the Sign In button
- (void)signInWillDispatch:(GIDSignIn *)signIn error:(NSError *)error {

}

// Present a view that prompts the user to sign in with Google
- (void)signIn:(GIDSignIn *)signIn presentViewController:(UIViewController *)viewController {
    [self presentViewController:viewController animated:YES completion:nil];

    _account.text = [GoogleLogin getGoogleAccountEmail];
}

// Dismiss the "Sign in with Google" view
- (void)signIn:(GIDSignIn *)signIn
dismissViewController:(UIViewController *)viewController {
    [self dismissViewControllerAnimated:YES completion:nil];
    [self performSelector:@selector(showGoogleInfo) withObject:nil afterDelay:1];
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSString * userId = [defaults objectForKey:@"GOOGLE_ID"];
    if(userId == nil){
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

- (void) showGoogleInfo{
    _account.text = [GoogleLogin getGoogleAccountEmail];
    if(_account.text != nil){
        UIAlertView *av = [[UIAlertView alloc]initWithTitle:@"Login is successed"
                                                    message:@"Google account information is stored to the local-storage."
                                                   delegate:self
                                          cancelButtonTitle:nil
                                          otherButtonTitles:@"Close", nil];
        [av show];
        [self accountIsExist];
    }else{
        [self accountIsEmpty];
    }
}

- (IBAction)didTapSignOut:(id)sender {
    [[GIDSignIn sharedInstance] signOut];
    
    [GoogleLogin deleteGoogleAccountFromLocalStorage];
    
    UIAlertView *av = [[UIAlertView alloc]initWithTitle:@"Logout is successed"
                                                message:@"Logout from Google Account, and remove Google account information from local storage."
                                               delegate:self
                                      cancelButtonTitle:nil
                                      otherButtonTitles:@"Close", nil];
    [av show];
    
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

@end
