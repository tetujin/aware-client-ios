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

        NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
        NSString * apiKey = [userDefaults objectForKey:@"fitbit.setting.client_id"];
        _apiKeyField.text = apiKey;
        
        NSString * apiSecret = [userDefaults objectForKey:@"fitbit.setting.api_secret"];
        _apiSecretField.text = apiSecret;
        
        NSDate * lastSyncStepData = [FitbitData getLastSyncSteps];
        _lastUpdateDatePicker.date = lastSyncStepData;
    }
}



////////////////////////////////////////

- (IBAction)pushedApplyButton:(id)sender {
    
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:_apiKeyField.text forKey:@"fitbit.setting.client_id"];
    [userDefaults setObject:_apiSecretField.text forKey:@"fitbit.setting.api_secret"];
  
    
    // NSDate * lastSyncStepData = [FitbitData getLastSyncSteps];
    NSDate * date = _lastUpdateDatePicker.date;
    
    [FitbitData setLastSyncSteps:date];
    [FitbitData setLastSyncSleep:date];
    [FitbitData setLastSyncCalories:date];
    [FitbitData setLastSyncHeartrate:date];
}

- (IBAction)pushedInfoButton:(id)sender {
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    NSString * apiKey = [userDefaults objectForKey:@"fitbit.setting.client_id"];
    NSString * apiSecret = [userDefaults objectForKey:@"fitbit.setting.api_secret"];
    
    NSString * message = [NSString stringWithFormat:@"API Key: %@\nAPI Secret: %@\nAccess Token: %@\nRefresh Token: %@\nUser ID: %@\nToken Type: %@",
                          apiKey,
                          apiSecret,
                          [Fitbit getFitbitAccessToken],
                          [Fitbit getFitbitRefreshToken],
                          [Fitbit getFitbitUserId],
                          [Fitbit getFitbitTokenType]];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Current Tokens"
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:alertController animated:YES completion:nil];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Close"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {
                                                          
                                                      }]];
//
//    [alertController addAction:[UIAlertAction actionWithTitle:@"NO"
//                                                        style:UIAlertActionStyleDefault
//                                                      handler:^(UIAlertAction *action) {
//                                                          
//                                                      }]];
    
}

- (IBAction)pushedClearSettingButton:(id)sender {
    [Fitbit clearAllSettings];
    [self showAllSetting];
}

- (IBAction)pushedRefreshTokenButton:(id)sender {
    [fitbit refreshToken];
    [self showAllSetting];
}

- (IBAction)pushedLoginButton:(id)sender {
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:_apiKeyField.text forKey:@"fitbit.setting.client_id"];
    [userDefaults setObject:_apiSecretField.text forKey:@"fitbit.setting.api_secret"];
    
    [fitbit loginWithOAuth2WithClientId:_apiKeyField.text apiSecret:_apiSecretField.text];
    [self showAllSetting];
}

- (IBAction)pushedGetLatestDataButton:(id)sender {
    NSDictionary * settings = [[NSDictionary alloc] initWithObjects:@[@"all"] forKeys:@[@"type"]];
    NSTimer * timer = [[NSTimer alloc] initWithFireDate:[NSDate new]
                                               interval:1 target:fitbit
                                               selector:@selector(getData:)
                                               userInfo:settings
                                                repeats:NO];
    [timer fire];
    [self performSelector:@selector(showAllSetting) withObject:nil afterDelay:3];
    // [self showAllSetting];
    // [fitbit getData:timer];
}

- (IBAction)pushedRefreshButton:(id)sender {
    [awareStudy refreshStudy];
}

@end
