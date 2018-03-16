//
//  SettingTableViewController.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 9/28/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "SettingTableViewController.h"
#import "AWAREKeys.h"
#import "AWARESensors.h"
#import "AppDelegate.h"
#import "AWAREStudy.h"
#import "DataVisualizationViewController.h"

@interface SettingTableViewController (){
    AWAREStudy * awareStudy;
    AWARESensor * awareSensor;
    NSString* selectedSettingKey;
}

@end

@implementation SettingTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;

    selectedSettingKey = @"";
    
    self.title = _selectedRowKey;
    [self.showDataButton setEnabled:NO];
    
    AppDelegate * delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    awareStudy = delegate.sharedAWARECore.sharedAwareStudy;
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;

    [self refreshRows];
}

- (void) refreshRows {
    _settingRows = [[NSMutableArray alloc] init];
    
    // AWARESensor * sensor = nil;
    if([_selectedRowKey isEqualToString:SENSOR_ACCELEROMETER]){
        awareSensor = [[Accelerometer alloc] initWithAwareStudy:awareStudy dbType:AwareDBTypeTextFile];
    }else if([_selectedRowKey isEqualToString:SENSOR_BAROMETER]){
        awareSensor = [[Barometer alloc] initWithAwareStudy:awareStudy dbType:AwareDBTypeTextFile];
        [self.showDataButton setEnabled:YES];
    }else if([_selectedRowKey isEqualToString:SENSOR_BATTERY]){
        awareSensor = [[Battery alloc] initWithAwareStudy:awareStudy dbType:AwareDBTypeTextFile];
        [self.showDataButton setEnabled:YES];
    }else if([_selectedRowKey isEqualToString:SENSOR_BLUETOOTH]){
        awareSensor = [[Bluetooth alloc] initWithAwareStudy:awareStudy dbType:AwareDBTypeTextFile];
        [self.showDataButton setEnabled:YES];
    }else if([_selectedRowKey isEqualToString:SENSOR_CALLS]){
        awareSensor = [[Calls alloc] initWithAwareStudy:awareStudy dbType:AwareDBTypeTextFile];
        [self.showDataButton setEnabled:YES];
    }else if([_selectedRowKey isEqualToString:SENSOR_GRAVITY]){
        awareSensor = [[Gravity alloc] initWithAwareStudy:awareStudy dbType:AwareDBTypeTextFile];
    }else if([_selectedRowKey isEqualToString:SENSOR_GYROSCOPE]){
        awareSensor = [[Gyroscope alloc] initWithAwareStudy:awareStudy dbType:AwareDBTypeTextFile];
    }else if([_selectedRowKey isEqualToString:SENSOR_LINEAR_ACCELEROMETER]){
        awareSensor = [[LinearAccelerometer alloc] initWithAwareStudy:awareStudy dbType:AwareDBTypeTextFile];
    }else if([_selectedRowKey isEqualToString:SENSOR_LOCATIONS]){
        awareSensor = [[Locations alloc] initWithAwareStudy:awareStudy dbType:AwareDBTypeTextFile];
        [self.showDataButton setEnabled:YES];
    }else if([_selectedRowKey isEqualToString:SENSOR_MAGNETOMETER]){
        awareSensor = [[Magnetometer alloc] initWithAwareStudy:awareStudy dbType:AwareDBTypeTextFile];
    }else if([_selectedRowKey isEqualToString:SENSOR_NETWORK]){
        awareSensor = [[Network alloc] initWithAwareStudy:awareStudy dbType:AwareDBTypeTextFile];
        [self.showDataButton setEnabled:YES];
    }else if([_selectedRowKey isEqualToString:SENSOR_ORIENTATION]){
        awareSensor = [[Orientation alloc] initWithAwareStudy:awareStudy dbType:AwareDBTypeTextFile];
    }else if([_selectedRowKey isEqualToString:SENSOR_PROCESSOR]){
        awareSensor = [[Processor alloc] initWithAwareStudy:awareStudy dbType:AwareDBTypeTextFile];
    }else if([_selectedRowKey isEqualToString:SENSOR_PROXIMITY]){
        awareSensor = [[Proximity alloc] initWithAwareStudy:awareStudy dbType:AwareDBTypeTextFile];
    }else if([_selectedRowKey isEqualToString:SENSOR_ROTATION]){
        awareSensor = [[Rotation alloc] initWithAwareStudy:awareStudy dbType:AwareDBTypeTextFile];
    }else if([_selectedRowKey isEqualToString:SENSOR_SCREEN]){
        awareSensor = [[Screen alloc] initWithAwareStudy:awareStudy dbType:AwareDBTypeTextFile];
    }else if([_selectedRowKey isEqualToString:SENSOR_TIMEZONE]){
        awareSensor = [[Timezone alloc] initWithAwareStudy:awareStudy dbType:AwareDBTypeTextFile];
    }else if([_selectedRowKey isEqualToString:SENSOR_WIFI]){
        awareSensor = [[Wifi alloc] initWithAwareStudy:awareStudy dbType:AwareDBTypeTextFile];
        [self.showDataButton setEnabled:YES];
    }else if([_selectedRowKey isEqualToString:SENSOR_HEALTH_KIT]){
        awareSensor = [[AWAREHealthKit alloc] initWithAwareStudy:awareStudy dbType:AwareDBTypeTextFile];
        ///// plugins
    }else if([_selectedRowKey isEqualToString:SENSOR_IOS_ACTIVITY_RECOGNITION]){
        awareSensor = [[IOSActivityRecognition alloc] initWithAwareStudy:awareStudy dbType:AwareDBTypeTextFile];
        [self.showDataButton setEnabled:YES];
    }else if([_selectedRowKey isEqualToString:SENSOR_GOOGLE_FUSED_LOCATION]){
        awareSensor = [[FusedLocations alloc] initWithAwareStudy:awareStudy dbType:AwareDBTypeTextFile];
        [self.showDataButton setEnabled:YES];
    }else if([_selectedRowKey isEqualToString:SENSOR_AMBIENT_NOISE]){
        awareSensor = [[AmbientNoise alloc] initWithAwareStudy:awareStudy dbType:AwareDBTypeTextFile];
    }else if([_selectedRowKey isEqualToString:SENSOR_PLUGIN_MSBAND]){
        awareSensor = [[MSBand alloc] initWithAwareStudy:awareStudy dbType:AwareDBTypeTextFile];
    }else if([_selectedRowKey isEqualToString:SENSOR_PLUGIN_NTPTIME]){
        awareSensor = [[NTPTime alloc] initWithAwareStudy:awareStudy dbType:AwareDBTypeTextFile];
    }else if([_selectedRowKey isEqualToString:SENSOR_PLUGIN_DEVICE_USAGE]){
        awareSensor = [[DeviceUsage alloc] initWithAwareStudy:awareStudy dbType:AwareDBTypeTextFile];
    }else if([_selectedRowKey isEqualToString:SENSOR_PLUGIN_OPEN_WEATHER]){
        awareSensor = [[OpenWeather alloc] initWithAwareStudy:awareStudy dbType:AwareDBTypeTextFile];
    }else if([_selectedRowKey isEqualToString:SENSOR_PLUGIN_IOS_ESM]){
        awareSensor = [[IOSESM alloc] initWithAwareStudy:awareStudy dbType:AwareDBTypeTextFile];
    }else if([_selectedRowKey isEqualToString:SENSOR_PLUGIN_BLE_HR]){
        awareSensor = [[BLEHeartRate alloc] initWithAwareStudy:awareStudy dbType:AwareDBTypeTextFile];
    }else if([_selectedRowKey isEqualToString:SENSOR_PLUGIN_PEDOMETER]){
        awareSensor = [[Pedometer alloc] initWithAwareStudy:awareStudy dbType:AwareDBTypeTextFile];
    }else if([_selectedRowKey isEqualToString:SENSOR_PLUGIN_FITBIT]){
        awareSensor = [[Fitbit alloc] initWithAwareStudy:awareStudy dbType:AwareDBTypeTextFile];
    }else if([_selectedRowKey isEqualToString:SENSOR_PLUGIN_CONTACTS]){
        awareSensor = [[Contacts alloc] initWithAwareStudy:awareStudy dbType:AwareDBTypeTextFile];
    }
    
    if(awareSensor != nil){
        NSMutableArray * currentSetting  = [[NSMutableArray alloc] init];
        
        if([awareSensor isSensor]){
            for (NSDictionary * dict in [awareSensor getDefaultSettings]) {
                NSString * key = [dict objectForKey:KEY_CEL_TITLE];
                NSString * value = [self getSensorSettingWithKey:key];
                NSMutableDictionary * mutDict = [[NSMutableDictionary alloc] initWithDictionary:dict];
                if(value !=nil){
                    [mutDict setValue:value forKey:KEY_CEL_SETTING_VALUE];
                }
                [currentSetting addObject:mutDict];
            }
        }else{
            for (NSDictionary * dict in [awareSensor getDefaultSettings]) {
                NSString * key = [dict objectForKey:KEY_CEL_TITLE];
                NSString * value = [self getPluginSettingWithKey:key];
                NSMutableDictionary * mutDict = [[NSMutableDictionary alloc] initWithDictionary:dict];
                
                /// TODO ///
                NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
                if( [key isEqualToString:@"api_key_plugin_fitbit"]){
                    value = [userDefaults objectForKey:@"api_key_plugin_fitbit"];
                }else if( [key isEqualToString:@"api_secret_plugin_fitbit"]){
                    value = [userDefaults objectForKey:@"api_secret_plugin_fitbit"];
                }
                
                if(value !=nil){
                    [mutDict setValue:value forKey:KEY_CEL_SETTING_VALUE];
                }
                [currentSetting addObject:mutDict];
            }
        }
        _settingRows = [[NSMutableArray alloc] initWithArray:currentSetting];
    }
    
    [self.tableView reloadData];
}

//////////////////////////////////////////////////////////////

- (NSString *) getSensorSettingWithKey:(NSString *)key{
    NSArray * sensorSettings = [awareStudy getSensors];
    NSString * stringValue = nil;
    for (NSDictionary * dict in sensorSettings) {
        if ([[dict objectForKey:@"setting"] isEqualToString:key]) {
            stringValue = [dict objectForKey:@"value"];
        }
    }
    return stringValue;
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


////////////////////////////////////////////////////////////////




///////////////////////////////////////////////////////////////

- (void) viewDidAppear:(BOOL)animated{
    [self.tableView reloadData];
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
// #warning Incomplete implementation, return the number of sections
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
// #warning Incomplete implementation, return the number of rows
    return _settingRows.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    @autoreleasepool {
        static NSString *MyIdentifier = @"settingViewCellId";
        if(_settingRows==nil) return nil;
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle  reuseIdentifier:MyIdentifier];
        }
        
        NSDictionary * dict = [_settingRows objectAtIndex:indexPath.row];
        
        NSString * title = [dict objectForKey:KEY_CEL_TITLE];
        NSString * value = [dict objectForKey:KEY_CEL_SETTING_VALUE];
        
        // TODO //
        NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
        if( [title isEqualToString:@"api_key_plugin_fitbit"]){
            value = [userDefaults objectForKey:@"api_key_plugin_fitbit"];
        }else if( [title isEqualToString:@"api_secret_plugin_fitbit"]){
            value = [userDefaults objectForKey:@"api_secret_plugin_fitbit"];
        }
        
        cell.textLabel.text = title;
        if(value !=nil){
            cell.detailTextLabel.text = value;
        }
        
        return cell;
    }
}

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 80;
}

/////////////////////////////////

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if(_settingRows == nil) return;
    
    NSDictionary * dict = [_settingRows objectAtIndex:indexPath.row];
    
    NSString * title = [dict objectForKey:KEY_CEL_TITLE];
    NSString * value = [dict objectForKey:KEY_CEL_SETTING_VALUE];
    NSString * type  = [dict objectForKey:KEY_CEL_SETTING_TYPE];
    NSString * desc  = [dict objectForKey:KEY_CEL_DESC];

    selectedSettingKey = title;
    
    value = [dict objectForKey:KEY_CEL_SETTING_VALUE];
    
    UIAlertView * alert = nil;
    if([type isEqualToString:KEY_CEL_SETTING_TYPE_BOOL]){
        alert = [[UIAlertView alloc] initWithTitle:title
                                           message:desc
                                          delegate:self
                                 cancelButtonTitle:@"Cancel"
                                 otherButtonTitles:@"true",@"false",nil];
        alert.tag = 0;
    }else if ([type isEqualToString:KEY_CEL_SETTING_TYPE_NUMBER]){
        alert = [[UIAlertView alloc] initWithTitle:title
                                           message:desc
                                          delegate:self
                                 cancelButtonTitle:@"Cancel"
                                 otherButtonTitles:@"Done",nil];
        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
        [[alert textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeNumberPad];
        [[alert textFieldAtIndex:0] becomeFirstResponder];
        
        [alert textFieldAtIndex:0].text = value;
        alert.tag = 1;
    }else if ([type isEqualToString:KEY_CEL_SETTING_TYPE_STRING]) {
        
        alert = [[UIAlertView alloc] initWithTitle:title
                                           message:desc
                                          delegate:self
                                 cancelButtonTitle:@"Cancel"
                                 otherButtonTitles:@"Done",nil];
        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
        [[alert textFieldAtIndex:0] becomeFirstResponder];
        [alert textFieldAtIndex:0].text = value;
        alert.tag = 2;
    }
    
    if(alert != nil){
        [alert show];
    }
}


- (void)alertView:(UIAlertView *)alertView
clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    NSInteger tag = alertView.tag;
    NSString * stringValue = [alertView textFieldAtIndex:0].text;
    
    if([awareSensor isSensor]){
        switch (tag) {
            case 0: // BOOLEAN(Yes/No)
                if (buttonIndex == 1) { //YES
                    [awareStudy setUserSensorSettingWithString:@"true" key:selectedSettingKey];
                    [awareStudy refreshStudy];
                }else if (buttonIndex == 2){ // NO
                    [awareStudy setUserSensorSettingWithString:@"false" key:selectedSettingKey];
                    [awareStudy refreshStudy];
                }
                break;
            case 1: // Number
                [awareStudy setUserSensorSettingWithString:stringValue key:selectedSettingKey];
                [awareStudy refreshStudy];
                break;
            case 2: // Text
                [awareStudy setUserSensorSettingWithString:stringValue key:selectedSettingKey];
                [awareStudy refreshStudy];
                break;
            default:
                break;
        }
    }else{
        switch (tag) {
            case 0: // BOOLEAN(Yes/No)
                if (buttonIndex == 1) { //YES
                    [awareStudy setUserPluginSettingWithString:@"true" key:selectedSettingKey statusKey:[awareSensor getSensorStatusKey] ];
                    [awareStudy refreshStudy];
                }else if (buttonIndex == 2){ // NO
                    [awareStudy setUserPluginSettingWithString:@"false" key:selectedSettingKey statusKey:[awareSensor getSensorStatusKey]];
                    [awareStudy refreshStudy];
                }
                break;
            case 1: // Number
                [awareStudy setUserPluginSettingWithString:stringValue key:selectedSettingKey statusKey:[awareSensor getSensorStatusKey]];
                [awareStudy refreshStudy];
                break;
            case 2: // Text
                [awareStudy setUserPluginSettingWithString:stringValue key:selectedSettingKey statusKey:[awareSensor getSensorStatusKey]];
                [awareStudy refreshStudy];
                break;
            default:
                break;
        }
    }
    
    // NSLog(@"%@",selectedSettingKey);
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    if( [selectedSettingKey isEqualToString:@"api_key_plugin_fitbit"]){
        [userDefaults setObject:stringValue forKey:@"api_key_plugin_fitbit"];
    }else if( [selectedSettingKey isEqualToString:@"api_secret_plugin_fitbit"]){
        [userDefaults setObject:stringValue forKey:@"api_secret_plugin_fitbit"];
    }
    [userDefaults synchronize];
    
    
    ////////////////
    
    [self refreshRows];
    // [self.tableView reloadData];

}


////////////////////////////////
/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//     Get the new view controller using [segue destinationViewController].
//     Pass the selected object to the new view controller.
    if([segue.identifier isEqualToString:@"visualizeDataVC"]){
        DataVisualizationViewController * dataVVC = [segue destinationViewController];
        dataVVC.sensor = awareSensor;
    }
}


- (IBAction)pushedActionButton:(id)sender {
    
    if (![MFMailComposeViewController canSendMail]){
        return;
    }
    
    MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
    picker.mailComposeDelegate = self;
    
    [picker setSubject:[NSString stringWithFormat:@"[AWARE][CSV][%@][%@]",[awareSensor getSensorName],[awareSensor getDeviceId]]];
    [picker setMessageBody:@"" isHTML:NO];
    
    // set 'text/csv' as a mimeType
    NSData * csvData = [awareSensor getCSVData];
    if(csvData != nil){
        NSString * fileName = [NSString stringWithFormat:@"%@_%@_%@.csv",[awareSensor getSensorName], [awareSensor getDeviceId],[NSDate new].debugDescription];
        [picker addAttachmentData:csvData mimeType:@"text/csv" fileName:fileName];
    }
    
    [self presentViewController:picker animated:YES completion:^{
        
    }];
}

- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error{
    
    switch (result) {
        case MFMailComposeResultCancelled:
            NSLog(@"Mail cancelled");
            [AWAREUtils sendLocalNotificationForMessage:@"Mail is cancelled!" soundFlag:NO];
            break;
        case MFMailComposeResultSaved:
            NSLog(@"Mail saved");
            [AWAREUtils sendLocalNotificationForMessage:@"Mail is saved!" soundFlag:NO];
            break;
        case MFMailComposeResultSent:
            NSLog(@"Mail sent");
            [AWAREUtils sendLocalNotificationForMessage:@"Mail is sent!" soundFlag:NO];
            break;
        case MFMailComposeResultFailed:
            NSLog(@"Mail sent failure: %@", [error localizedDescription]);
            [AWAREUtils sendLocalNotificationForMessage:@"Sending the mail is failured. Please try it again." soundFlag:YES];
            break;
        default:
            break;
    }
    
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

@end
