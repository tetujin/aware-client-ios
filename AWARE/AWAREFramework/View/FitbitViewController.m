//
//  FitbitViewController.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 2017/05/15.
//  Copyright © 2017 Yuuki NISHIYAMA. All rights reserved.
//

#import "FitbitViewController.h"
#import "AppDelegate.h"
#import "Fitbit.h"
#import "FitbitData.h"

@interface FitbitViewController ()

@end

@implementation FitbitViewController{
    AWAREStudy * awareStudy;
    Fitbit * fitbit;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onSingleTap:)];
    _singleTap.delegate = self;
    _singleTap.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:self.singleTap];
    
    AppDelegate * delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    awareStudy = delegate.sharedAWARECore.sharedAwareStudy;
    
    fitbit = [[Fitbit alloc] initWithAwareStudy:awareStudy dbType:AwareDBTypeCoreData];

    [self showAllSetting];
    
//    layer.cornerRadius = 2.0;
//    button.layer.borderWidth = [UIColor BlackColor];
//    button.borderWidth = 1.0;
    
}


- (void)viewDidAppear:(BOOL)animated{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(getData:)
                                                 name:@"action.aware.plugin.fitbit.get.activity.debug"
                                               object:nil];
}

- (void)viewDidDisappear:(BOOL)animated{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"action.aware.plugin.fitbit.get.activity.debug" object:nil];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)onSingleTap:(UITapGestureRecognizer *)recognizer {
    NSLog(@"Single Tap");
    [_updateIntervalMin resignFirstResponder];
    [_apiKeyField resignFirstResponder];
    [_apiSecretField resignFirstResponder];
    [_debugField resignFirstResponder];
}

-(BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (gestureRecognizer == self.singleTap) {
        return YES;
    }
    return NO;
}


- (NSString *) getPluginSettingWithKey:(NSString *)key{
    NSArray * plugins = [awareStudy getPlugins];
    NSString * stringValue = nil;
    for (NSDictionary * plugin in plugins) {
        for (NSDictionary * setting in [plugin objectForKey:@"settings"]) {
            if ([[setting objectForKey:@"setting"] isEqualToString:key]) {
                stringValue = [setting objectForKey:@"value"];
            }
        }
    }
    return stringValue;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
//////////////////////////////////////

- (void) showAllSetting{
    
    NSMutableArray * currentSettings  = [[NSMutableArray alloc] init];
    for (NSDictionary * dict in [fitbit getDefaultSettings]) {
        NSString * key = [dict objectForKey:KEY_CEL_TITLE];
        NSString * value = [self getPluginSettingWithKey:key];
        NSMutableDictionary * mutDict = [[NSMutableDictionary alloc] initWithDictionary:dict];
        
        NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
        if( [key isEqualToString:@"api_key_plugin_fitbit"]){
            value = [userDefaults objectForKey:@"api_key_plugin_fitbit"];
        }else if( [key isEqualToString:@"api_secret_plugin_fitbit"]){
            value = [userDefaults objectForKey:@"api_secret_plugin_fitbit"];
        }
        if(value !=nil){
            [mutDict setValue:value forKey:KEY_CEL_SETTING_VALUE];
        }
        [currentSettings addObject:mutDict];
    }

    
    if(currentSettings != nil){

        for (NSDictionary * dict in currentSettings) {
            NSString * title = [dict objectForKey:KEY_CEL_TITLE];
            // NSString * value = [dict objectForKey:KEY_CEL_SETTING_VALUE];
            if([title isEqualToString:@"status_plugin_fitbit"]){
                NSString * state = [dict objectForKey:KEY_CEL_SETTING_VALUE];
                if ([state isEqualToString:@"true"]) {
                    _stateSegment.selectedSegmentIndex = 0;
                }else{
                    _stateSegment.selectedSegmentIndex = 1;
                }
            }else if([title isEqualToString:@"units_plugin_fitbit"]){
                NSString * unit = [dict objectForKey:KEY_CEL_SETTING_VALUE];
                if([unit isEqualToString:@"metric"]){
                    _unitSegment.selectedSegmentIndex = 0;
                }else{
                    _unitSegment.selectedSegmentIndex = 1;
                }
            }else if([title isEqualToString:@"plugin_fitbit_frequency"]){
                NSString * frequency = [dict objectForKey:KEY_CEL_SETTING_VALUE];
                _updateIntervalMin.text = frequency;
            }else if([title isEqualToString:@"fitbit_granularity"]) {
                NSString * granularity = [dict objectForKey:KEY_CEL_SETTING_VALUE];
                if ([granularity isEqualToString:@"1d"]) {
                    _generalGranularitySegment.selectedSegmentIndex = 0;
                }else if([granularity isEqualToString:@"15min"]){
                    _generalGranularitySegment.selectedSegmentIndex = 1;
                }else{
                    _generalGranularitySegment.selectedSegmentIndex = 3;
                }
            }else if([title isEqualToString:@"fitbit_hr_granularity"]){
                NSString * hrGranularity = [dict objectForKey:KEY_CEL_SETTING_VALUE];
                if([hrGranularity isEqualToString:@"1min"]){
                    _htGranularitySegment.selectedSegmentIndex = 0;
                }else{
                    _htGranularitySegment.selectedSegmentIndex = 1;
                }
            }
        }

        _apiKeyField.text = [Fitbit getFitbitClientIdForUI:YES];
        
        _apiSecretField.text = [Fitbit getFitbitApiSecretForUI:YES];
        
        NSDate * lastSyncStepData = [FitbitData getLastSyncSteps];
        _lastUpdateDatePicker.date = lastSyncStepData;
    }
}



////////////////////////////////////////

- (IBAction)pushedApplyButton:(id)sender {
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Confirmation"
                                                                            message:@"Do you update your current setting?"
                                                                     preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"YES"
                                                        style:UIAlertActionStyleDestructive
                                                      handler:^(UIAlertAction *action) {
                                                          // NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
                                                          // [userDefaults setObject:_apiKeyField.text forKey:@"fitbit.setting.client_id"];
                                                          // [userDefaults setObject:_apiSecretField.text forKey:@"fitbit.setting.api_secret"];
                                                          [Fitbit setFitbitUserId:_apiKeyField.text];
                                                          [Fitbit setFitbitApiSecret:_apiSecretField.text];
                                                          
                                                          // NSDate * lastSyncStepData = [FitbitData getLastSyncSteps];
                                                          NSDate * date = _lastUpdateDatePicker.date;
                                                          
                                                          [FitbitData setLastSyncSteps:date];
                                                          [FitbitData setLastSyncSleep:date];
                                                          [FitbitData setLastSyncCalories:date];
                                                          [FitbitData setLastSyncHeartrate:date];

                                                      }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"NO"
                                                        style:UIAlertActionStyleCancel
                                                      handler:^(UIAlertAction *action) {
                                                      }]];
    
    [self presentViewController:alertController animated:YES completion:nil];
    
}



- (IBAction)pushedInfoButton:(id)sender {
    // NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    NSString * apiKey = [Fitbit getFitbitClientIdForUI:YES]; //[userDefaults objectForKey:@"fitbit.setting.client_id"];
    NSString * apiSecret = [Fitbit getFitbitApiSecretForUI:YES]; // [userDefaults objectForKey:@"fitbit.setting.api_secret"];
    NSString * code = [Fitbit getFitbitCode]; // [userDefaults objectForKey:@"fitbit.setting.code"];
    
    NSString * message = [NSString stringWithFormat:@"API Key: %@\nAPI Secret: %@\nCode: %@\nAccess Token: %@\nRefresh Token: %@\nUser ID: %@\nToken Type: %@",
                          apiKey,
                          apiSecret,
                          code,
                          [Fitbit getFitbitAccessToken],
                          [Fitbit getFitbitRefreshToken],
                          [Fitbit getFitbitUserId],
                          [Fitbit getFitbitTokenType]];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Current Tokens"
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Close"
                                                        style:UIAlertActionStyleCancel
                                                      handler:^(UIAlertAction *action) {
                                                          
                                                      }]];
    [self presentViewController:alertController animated:YES completion:nil];

    
}

- (IBAction)pushedClearSettingButton:(id)sender {
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Warning"
                                                                             message:@"Do you clear your current setting?"
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"YES"
                                                        style:UIAlertActionStyleDestructive
                                                      handler:^(UIAlertAction *action) {
                                                          [Fitbit clearAllSettings];
                                                          [self showAllSetting];
                                                      }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"NO"
                                                        style:UIAlertActionStyleCancel
                                                      handler:^(UIAlertAction *action) {
                                                      }]];
    
    [self presentViewController:alertController animated:YES completion:nil];
    
}

- (IBAction)pushedRefreshTokenButton:(id)sender {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Confirmation"
                                                                             message:@"Do you refresh your access token?"
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"YES"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {
                                                          [fitbit refreshToken];
                                                          [self showAllSetting];
                                                      }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"NO"
                                                        style:UIAlertActionStyleCancel
                                                      handler:^(UIAlertAction *action) {
                                                      }]];
    
    [self presentViewController:alertController animated:YES completion:nil];
    

}

- (IBAction)pushedLoginButton:(id)sender {
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Confirmation"
                                                                             message:[NSString stringWithFormat:@"Do you login to Fitbit with current setting?\nClient ID:%@\nAPI Secret:%@",[Fitbit getFitbitClientIdForUI:NO],[Fitbit getFitbitApiSecretForUI:NO]]
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"YES"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {
                                                          dispatch_async(dispatch_get_main_queue(), ^{
                                                              // [self presentViewController:alertController animated:YES completion:nil];
                                                              // NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
                                                              // [userDefaults setObject:_apiKeyField.text forKey:@"fitbit.setting.client_id"];
                                                              // [userDefaults setObject:_apiSecretField.text forKey:@"fitbit.setting.api_secret"];
                                                              
                                                              [fitbit loginWithOAuth2WithClientId:[Fitbit getFitbitClientIdForUI:NO] apiSecret:[Fitbit getFitbitApiSecretForUI:NO]];
                                                              [self showAllSetting];
                                                          });
                                                      }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"NO"
                                                        style:UIAlertActionStyleCancel
                                                      handler:^(UIAlertAction *action) {
                                                      }]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (IBAction)pushedGetLatestDataButton:(id)sender {
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Confirmation"
                                                                             message:@"Do you access Fitbit server to get the latest data? The response will be shown on alerts."
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"YES"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {
                                                          NSDate * date = _lastUpdateDatePicker.date;
                                                          [FitbitData setLastSyncSteps:date];
                                                          [FitbitData setLastSyncSleep:date];
                                                          [FitbitData setLastSyncCalories:date];
                                                          [FitbitData setLastSyncHeartrate:date];
                                                          
                                                          NSDictionary * settings = [[NSDictionary alloc] initWithObjects:@[@"all"] forKeys:@[@"type"]];
                                                          NSTimer * timer = [[NSTimer alloc] initWithFireDate:[NSDate new]
                                                                                                     interval:1 target:fitbit
                                                                                                     selector:@selector(getData:)
                                                                                                     userInfo:settings
                                                                                                      repeats:NO];
                                                          [timer fire];
                                                          [self performSelector:@selector(showAllSetting) withObject:nil afterDelay:3];
                                                      }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"NO"
                                                        style:UIAlertActionStyleCancel
                                                      handler:^(UIAlertAction *action) {
                                                      }]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (IBAction)pushedRefreshButton:(id)sender {
    [awareStudy refreshStudy];
}

- (IBAction)pushedGetTokensButton:(id)sender {
    [fitbit downloadTokensFromFitbitServer];
}


- (void) getData:(id)sender{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary * userInfo = [sender userInfo];
        NSString * data = [userInfo objectForKey:@"debug"];
        NSString * type = [userInfo objectForKey:@"type"];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:type
                                                        message:data
                                                       delegate:self
                                              cancelButtonTitle:@"Close"
                                              otherButtonTitles:nil];
        [alert show];
        
    });
}

@end
