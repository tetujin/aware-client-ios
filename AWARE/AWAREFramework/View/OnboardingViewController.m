//
//  OnboardingViewController.m
//
//  Created by Yuuki Nishiyama on 2018/12/18.
//  Copyright © 2018 Yuuki NISHIYAMA. All rights reserved.
//

#import "OnboardingViewController.h"
#import "AWAREKeys.h"
#import "AppDelegate.h"

@interface OnboardingViewController ()

@end

@implementation OnboardingViewController {
    NSMutableArray * requiredSensors;
    NSString  * studyURL;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _requiredSensorsTable.dataSource = self;
    _requiredSensorsTable.delegate = self;
    _requiredSensorsTable.rowHeight = UITableViewAutomaticDimension;
    [_requiredSensorsTable registerClass:UITableViewCellStyleDefault forCellReuseIdentifier:@"default"];
    _userLabel.delegate = self;
}

- (void) setStudyURL:(NSString *)url{
    
    studyURL = url;
    
    requiredSensors = [[NSMutableArray alloc] init];

    // get study information from an AWARE server by using the given URL
    [self getStudyInfo:url completion:^(NSData * _Nullable result, NSError * _Nullable error) {
        if (error==nil && result!=nil){
            NSError * e = nil;
            NSDictionary  * studyInfo    = [NSJSONSerialization JSONObjectWithData:result options:NSJSONReadingMutableContainers error:&e];
            if (e==nil) {
                // get study information from a dictionary object
                NSString * studyTitle        = [studyInfo objectForKey:@"study_name"];
                NSString * studyDescription  = [studyInfo objectForKey:@"study_description"];
                NSString * researcherFirst   = [studyInfo objectForKey:@"researcher_first"];
                NSString * researcherLast    = [studyInfo objectForKey:@"researcher_last"];
                NSString * researcherContact = [studyInfo objectForKey:@"researcher_contact"];
                // set the study information into UI objects
                self.studyTitle.text = studyTitle;
                self.studyDescription.text = studyDescription;
                self.reseacher.text = [NSString stringWithFormat:@"%@ %@ <%@>", researcherFirst, researcherLast, researcherContact];
            }
        }else{
            NSLog(@"%@", error.debugDescription);
        }
    }];
    
    // get study config from an AWARE server by using the given URL
    [self getStudyConfig:url completion:^(NSData * _Nullable result, NSError * _Nullable error) {
        if (error==nil && result!=nil){
            NSError * e = nil;
            NSArray  * studyConfig    = [NSJSONSerialization JSONObjectWithData:result options:NSJSONReadingMutableContainers error:&e];
            if (e==nil) {
                if (studyConfig.count > 0){
                    // get required sensors
                    NSArray * sensors = [studyConfig.firstObject objectForKey:@"sensors"];
                    for (NSDictionary * sensor in sensors) {
                        NSString * setting = [sensor objectForKey:@"setting"];
                        NSString * value = [sensor objectForKey:@"value"];
                        if(setting != nil && value != nil){
                            
                            if ([setting hasPrefix:@"status_"] && [value hasPrefix:@"true"]) {
                                NSMutableString * mutableSetting = [[NSMutableString alloc] initWithString:setting];
                                [mutableSetting deleteCharactersInRange:[setting rangeOfString:@"status_"]];
                                [requiredSensors addObject:mutableSetting];
                            }
                        }
                    }
                    
                    // get required plugins
                    NSArray * plugins = [studyConfig.firstObject objectForKey:@"plugins"];
                    for (NSDictionary * plugin in plugins) {
                        NSString * pluginName = [plugin objectForKey:@"plugin"];
                        if (pluginName!=nil) {
                            [requiredSensors addObject:pluginName];
                        }
                    }
                    
                    [self.requiredSensorsTable reloadData];
                }
                
            }
        }
    }];
    
}

- (IBAction)pushedSignUpButton:(UIButton *)sender {
    // https://github.com/tetujin/aware-client/blob/master/aware-core/src/main/java/com/aware/ui/Aware_QRCode.java
    // show alert
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Thank you for joining our study!"
                                                                             message:@"Please permit API access if each sensor requests the permission."
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction * closeAction  = [UIAlertAction actionWithTitle:@"Back to main view" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        // set configurations
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setObject:studyURL forKey:KEY_STUDY_QR_CODE];
        
        AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
        AWAREStudy * study = delegate.sharedAWARECore.sharedAwareStudy;
        
        NSString * label = _userLabel.text;
        if(label != nil){
            [study setDeviceName:label];
        }
        
        [study setStudyInformationWithURL:studyURL];
        
        // back to main page.
        [self.navigationController popToRootViewControllerAnimated:YES];
    }];
    [alertController addAction:closeAction];
    
    // show an alert back to top page
    [self presentViewController:alertController animated:YES completion:nil];
}

- (IBAction)pushedQuitStudyButton:(UIButton *)sender {
    // back to main page.
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (requiredSensors != nil){
        return requiredSensors.count;
    }else{
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"default"];
    if(cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"default"];
    }
    
    if (requiredSensors != nil) {
        if(indexPath != nil){
            NSString * title = [requiredSensors objectAtIndex:indexPath.row];
            cell.textLabel.text = title;
            [cell.textLabel setTextColor:[UIColor darkGrayColor]];
        }
    }
    
    return cell;
}


/**
 Close keyboard when user tapped Return button.

 @param textField A text filed
 @return Is the keyboard correctly closed or not.
 */
- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [_userLabel endEditing:true];
    return true;
}


/**
 Get study configuration

 @param url A study URL
 @param completion A callback handler for the HTTP request
 */
- (void) getStudyConfig:(NSString *)url completion:(void (^)( NSData * _Nullable result,  NSError * _Nullable error)) completion {
    NSURLSession *session = [NSURLSession sharedSession];
    NSString * uuid = [AWAREUtils getSystemUUID];
    NSString * post = [NSString stringWithFormat:@"device_id=%@", uuid];
    NSData   * postData   = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString * postLength = [NSString stringWithFormat:@"%ld", [postData length]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    NSURL * urlObj = [NSURL URLWithString:url];
    [request setURL:urlObj];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:postData];
    [request setAllowsCellularAccess:YES];
    
    [[session dataTaskWithRequest:request completionHandler: ^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(),^{
            // Success
            if (data && !error) {
                if(data != nil){
                    // NSString *responseStr = [[NSString alloc] initWithData: data  encoding: NSUTF8StringEncoding];
                    completion(data, nil);
                }else{
                    completion(nil, nil);
                }
            }else{
                completion(nil, error);
            }
            [session finishTasksAndInvalidate];
            [session invalidateAndCancel];
        });
    }] resume];
}


/**
 Get a study information

 @param url A study URL
 @param completion A callback for the HTTP request
 */
- (void) getStudyInfo:(NSString *)url completion:(void (^)( NSData * _Nullable result,  NSError * _Nullable error)) completion {
    // Get the study information from the aware server using the study url
    // https://HOST/index.php/webservice/client_get_study_info/STUDY_API_KEY
    NSURL *studyURL = [NSURL URLWithString:url];

    NSString * apiKey = @"";
    NSArray * pathComponents = [url pathComponents];
    for (NSString * component in pathComponents) {
        apiKey = component;
    }

    // NSLog(@"%@", url.absoluteString);
    // https://r2d2.hcii.cs.cmu.edu/aware/dashboard/
    NSRange indexRange = [studyURL.absoluteString rangeOfString:@"index.php"];
    NSString * baseURL = [studyURL.absoluteString substringWithRange:NSMakeRange(0, indexRange.location)];

    // baseURL
    NSString * requestUrl = [NSString stringWithFormat:@"%@index.php/webservice/client_get_study_info/%@", baseURL , apiKey];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:requestUrl]];
    [request setHTTPMethod:@"GET"];

    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithRequest:request completionHandler:^(NSData * data,
                                                              NSURLResponse *  response,
                                                              NSError * error) {
        dispatch_async(dispatch_get_main_queue(),^{
            // Success
            if (data && !error) {
                if (response != nil) {
                    completion(data, error);
                }else{
                    completion(nil, nil);
                }
            } else {
                completion(nil, error);
            }
            [session finishTasksAndInvalidate];
            [session invalidateAndCancel];
        });
        
    }] resume];
}

@end
