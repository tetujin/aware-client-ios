//
//  ViewController.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/18/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "ViewController.h"
#import "AWAREKeys.h"
#import "GoogleLoginViewController.h"
#import "Accelerometer.h"
#import "AmbientNoise.h"
#import "ActivityRecognition.h"

//#import "TitleViewCell.h"
#import "MSBand.h"


@interface ViewController (){
    NSString *KEY_CEL_TITLE;
    NSString *KEY_CEL_DESC;
    NSString *KEY_CEL_IMAGE;
    NSString *KEY_CEL_STATE;
    NSString *KEY_CEL_SENSOR_NAME;
    NSString *KEY;
    NSString *mqttServer;
    NSString *oldStudyId;
    NSString *mqttPassword;
    NSString *mqttUserName;
    NSString *studyId;
    NSNumber *mqttPort;
    NSNumber *mqttKeepAlive;
    NSNumber *mqttQos;
    NSTimer *listUpdateTimer;
    double uploadInterval;
//    IBOutlet CLLocationManager *homeLocationManager;
    NSTimer* testTimer;
//    NSFileHandle *fh;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//     testTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(test) userInfo:nil repeats:YES];
    KEY_CEL_TITLE = @"title";
    KEY_CEL_DESC = @"desc";
    KEY_CEL_IMAGE = @"image";
    KEY_CEL_STATE = @"state";
    KEY_CEL_SENSOR_NAME = @"sensorName";
    KEY = @"key";
    
    mqttServer = @"";
    oldStudyId = @"";
    mqttPassword = @"";
    mqttUserName = @"";
    studyId = @"";
    mqttPort = @1883;
    mqttKeepAlive = @600;
    mqttQos = @2;
    
    uploadInterval = 60*15;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    // Get default information from local storage
    if (![userDefaults boolForKey:@"aware_inited"]) {
        [userDefaults setBool:NO forKey:SETTING_DEBUG_STATE];
        [userDefaults setBool:YES forKey:SETTING_SYNC_WIFI_ONLY];
        [userDefaults setDouble:uploadInterval forKey:SETTING_SYNC_INT];
        [userDefaults setBool:YES forKey:@"aware_inited"];
        [userDefaults setInteger:0 forKey:KEY_MARK];
        [userDefaults setInteger:1000 * 1000 * 5 forKey:KEY_MAX_DATA_SIZE]; // 5MB
    }

    
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    [self setNaviBarTitle];
    [self initLocationSensor];
    
    _sensorManager = [[AWARESensorManager alloc] init];

//    self.navigationController.navigationBar.delegate = self;
    CGFloat currentVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
//    NSLog(@"OS:%f", currentVersion);
    if (currentVersion >= 9.0) {
        [self.navigationController.navigationBar setDelegate:self];
    }
    [self connectMqttServer];
    
    [self initList];
    
    listUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self.tableView selector:@selector(reloadData) userInfo:nil repeats:YES];
    
    
}


- (void) initLocationSensor{
    NSLog(@"start location sensing!");
    if (nil == _homeLocationManager){
        _homeLocationManager = [[CLLocationManager alloc] init];
        _homeLocationManager.delegate = self;
        // locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;
        _homeLocationManager.desiredAccuracy = kCLLocationAccuracyBest;
        _homeLocationManager.pausesLocationUpdatesAutomatically = NO;
        CGFloat currentVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
        NSLog(@"OS:%f", currentVersion);
        if (currentVersion >= 9.0) {
            _homeLocationManager.allowsBackgroundLocationUpdates = YES; //This variable is an important method for background sensing
        }
        _homeLocationManager.activityType = CLActivityTypeOther;
        if ([_homeLocationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
            [_homeLocationManager requestAlwaysAuthorization];
        }
        // Set a movement threshold for new events.
        _homeLocationManager.distanceFilter = 150; // meters
        [_homeLocationManager startUpdatingLocation];
        //    [_locationManager startMonitoringVisits]; // This method calls didVisit.
        [_homeLocationManager startUpdatingHeading];
    }
}


- (void) setNaviBarTitle {
//    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
//    NSString *email = [defaults objectForKey:@"GOOGLE_EMAIL"];
//    NSString *name = [defaults objectForKey:@"GOOGLE_NAME"];
//    NSLog(@"name:%@", name);
//    if (![name isEqualToString:@""]) {
//        [self.navigationController.navigationBar.topItem setTitle:name];
//    }else{
//        [self.navigationController.navigationBar.topItem setTitle:@"AWARE"];
//    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) initList {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    _sensors = [[NSMutableArray alloc] init];
    // devices
    NSString *deviceId = [userDefaults objectForKey:KEY_MQTT_USERNAME];
    NSString *awareStudyId = [userDefaults objectForKey:KEY_STUDY_ID];
    NSString *mqttServerName = [userDefaults objectForKey:KEY_MQTT_SERVER];
    [userDefaults synchronize];
    NSString *email = [userDefaults objectForKey:@"GOOGLE_EMAIL"];
    NSString *name = [userDefaults objectForKey:@"GOOGLE_NAME"];
    NSString *accountInfo = [NSString stringWithFormat:@"%@ (%@)", name, email];
    if(name == nil) accountInfo = @"";
    if(deviceId == nil) deviceId = @"";
    if(awareStudyId == nil) awareStudyId = @"";
    if(mqttServerName == nil) mqttServerName = @"";
    
    NSString* debugState = @"OFF";
    if ([userDefaults boolForKey:SETTING_DEBUG_STATE]) {
        debugState = @"ON";
    }else{
        debugState = @"OFF";
    }
    
    NSString *syncInterval = [NSString stringWithFormat:@"%d",(int)[userDefaults doubleForKey:SETTING_SYNC_INT]/60];
    
    NSString *wifiOnly = @"YES";
    if ([userDefaults boolForKey:SETTING_SYNC_WIFI_ONLY]) {
        wifiOnly = @"YES";
    }else{
        wifiOnly = @"NO";
    }
    
    
    [_sensors addObject:[self getCelContent:@"Study" desc:@"" image:@"" key:@"TITLE_CELL_VIEW"]];
    [_sensors addObject:[self getCelContent:@"AWARE Device ID" desc:deviceId image:@"" key:@"STUDY_CELL_VIEW"]];
    [_sensors addObject:[self getCelContent:@"AWARE Study" desc:awareStudyId image:@"" key:@"STUDY_CELL_VIEW"]]; //ic_action_study
    [_sensors addObject:[self getCelContent:@"MQTT Server" desc:mqttServerName image:@"" key:@"STUDY_CELL_VIEW"]]; //ic_action_mqtt
    [_sensors addObject:[self getCelContent:@"Google Account" desc:accountInfo image:@"" key:@"STUDY_CELL_VIEW"]];
    // sensor
    [_sensors addObject:[self getCelContent:@"Sensors" desc:@"" image:@"" key:@"TITLE_CELL_VIEW"]];
    [_sensors addObject:[self getCelContent:@"Accelerometer" desc:@"Acceleration, including the force of gravity(m/s^2)" image:@"ic_action_accelerometer" key:SENSOR_ACCELEROMETER]];
    [_sensors addObject:[self getCelContent:@"Barometer" desc:@"Atomospheric air pressure (mbar/hPa)" image:@"ic_action_barometer" key:SENSOR_BAROMETER]];
    [_sensors addObject:[self getCelContent:@"Battery" desc:@"Battery and power event" image:@"ic_action_battery" key:SENSOR_BATTERY]];
    [_sensors addObject:[self getCelContent:@"Bluetooth" desc:@"Bluetooth sensing" image:@"ic_action_bluetooth" key:SENSOR_BLUETOOTH]];
    [_sensors addObject:[self getCelContent:@"Gyroscope" desc:@"Rate of rotation of device (rad/s)" image:@"ic_action_gyroscope" key:SENSOR_GYROSCOPE]];
    [_sensors addObject:[self getCelContent:@"Gravity" desc:@"Gravity provides a three dimensional vector indicating the direction and magnitude of gravity (in m/s²)" image:@"ic_action_gravity" key:SENSOR_GRAVITY]];
    [_sensors addObject:[self getCelContent:@"Linear Accelerometer" desc:@"The linear accelerometer measures the acceleration applied to the sensor built-in into the device, excluding the force of gravity, in m/s" image:@"ic_action_linear_acceleration" key:SENSOR_LINEAR_ACCELEROMETER]];
    [_sensors addObject:[self getCelContent:@"Locations" desc:@"User's estimated location by GPS and network triangulation" image:@"ic_action_locations" key:SENSOR_LOCATIONS]];
    [_sensors addObject:[self getCelContent:@"Magnetometer" desc:@"Geomagnetic field strength around the device (uT)" image:@"ic_action_magnetometer" key:SENSOR_MAGNETOMETER]];
    [_sensors addObject:[self getCelContent:@"Mobile ESM/EMA" desc:@"Mobile questionnaries" image:@"ic_action_esm" key:SENSOR_ESMS]];
    [_sensors addObject:[self getCelContent:@"Network" desc:@"Network usage and traffic" image:@"ic_action_network" key:SENSOR_NETWORK]];
//    [_sensors addObject:[self getCelContent:@"Processor" desc:@"CPU workload for user, system and idle(%)" image:@"ic_action_processor" key:SENSOR_PROCESSOR]];
//    [_sensors addObject:[self getCelContent:@"Telephony" desc:@"Mobile operator and specifications, cell tower and neighbor scanning" image:@"ic_action_telephony" key:SENSOR_TELEPHONY]];
    [_sensors addObject:[self getCelContent:@"WiFi" desc:@"Wi-Fi sensing" image:@"ic_action_wifi" key:SENSOR_WIFI]];
//    [_sensors addObject:[self getCelContent:@"AmbientNoise" desc:@"AmbientNoise sensor" image:@"" key:SENSOR_AMBIENT_NOISE]];

    // android specific sensors
    //[_sensors addObject:[self getCelContent:@"Gravity" desc:@"Force of gravity as a 3D vector with direction and magnitude of gravity (m^2)" image:@"ic_action_ gravity"]];
    //[_sensors addObject:[self getCelContent:@"Light" desc:@"Ambient Light (lux)" image:@"ic_action_light"]];
    //[_sensors addObject:[self getCelContent:@"Proximity" desc:@"" image:@"ic_action_proximity"]];
    //[_sensors addObject:[self getCelContent:@"Temperature" desc:@"" image:@"ic_action_temperature"]];
    
    // iOS specific sensors
//    [_sensors addObject:[self getCelContent:@"Screen (iOS)" desc:@"Screen events (on/off, locked/unlocked)" image:@"ic_action_screen" key:SENSOR_SCREEN]];
//    [_sensors addObject:[self getCelContent:@"Direction (iOS)" desc:@"Device's direction (0-360)" image:@"safari_copyrighted" key:SENSOR_DIRECTION]];
//    [_sensors addObject:[self getCelContent:@"Rotation (iOS)" desc:@"Orientation of the device" image:@"ic_action_rotation" key:SENSOR_ROTATION]];
    
    [_sensors addObject:[self getCelContent:@"Ambient Noise" desc:@"Anbient noise sensing by using a microphone on a smartphone." image:@"" key:SENSOR_AMBIENT_NOISE]];
    [_sensors addObject:[self getCelContent:@"Activity Recognition" desc:@"iOS Activity Recognition" image:@"" key:SENSOR_PLUGIN_GOOGLE_ACTIVITY_RECOGNITION]];
    [_sensors addObject:[self getCelContent:@"Open Weather" desc:@"Weather information by OpenWeatherMap API." image:@"" key:SENSOR_PLUGIN_OPEN_WEATHER]];
    
    [_sensors addObject:[self getCelContent:@"Settings" desc:@"" image:@"" key:@"TITLE_CELL_VIEW"]];
    [_sensors addObject:[self getCelContent:@"Debug" desc:debugState image:@"" key:@"STUDY_CELL_DEBUG"]]; //ic_action_mqtt
    [_sensors addObject:[self getCelContent:@"Sync Interval to AWARE Server (min)" desc:syncInterval image:@"" key:@"STUDY_CELL_SYNC"]]; //ic_action_mqtt
    [_sensors addObject:[self getCelContent:@"Sync only wifi" desc:wifiOnly image:@"" key:@"STUDY_CELL_WIFI"]]; //ic_action_mqtt

    //for test
    AWARESensor *msBand = [[MSBand alloc] initWithSensorName:SENSOR_PLUGIN_MSBAND];
    [msBand startSensor:60.0f withSettings:nil];
    [_sensorManager addNewSensor:msBand];

}




- (NSMutableDictionary *) getCelContent:(NSString *)title
                                   desc:(NSString *)desc
                                  image:(NSString *)image
                                    key:(NSString *)key{
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setObject:title forKey:KEY_CEL_TITLE];
    [dic setObject:desc forKey:KEY_CEL_DESC];
    [dic setObject:image forKey:KEY_CEL_IMAGE];
    [dic setObject:key forKey:KEY_CEL_SENSOR_NAME];

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSArray *sensors = [userDefaults objectForKey:KEY_SENSORS];
    NSArray *plugins = [userDefaults objectForKey:KEY_PLUGINS];
    // [NOTE] If this sensor is "active", addNewSensorWithSensorName method return TRUE value.
    uploadInterval = [userDefaults doubleForKey:SETTING_SYNC_INT];
    bool state = [_sensorManager addNewSensorWithSensorName:key settings:sensors plugins:plugins uploadInterval:uploadInterval];
    if (state) {
        [dic setObject:@"true" forKey:KEY_CEL_STATE];
    }
    return dic;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"%ld is selected!", indexPath.row);
    NSDictionary *item = (NSDictionary *)[_sensors objectAtIndex:indexPath.row];
    NSString *key = [item objectForKey:KEY_CEL_SENSOR_NAME];
    if ([key isEqualToString:@"STUDY_CELL_DEBUG"]) { //Debug
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Debug Statement" message:@"" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"ON", @"OFF", nil];
        [alert show];
    } else if ([key isEqualToString:@"STUDY_CELL_SYNC"]) { //Sync
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Sync Interval (min)" message:@"Please inpute a sync interval to the server." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Done",nil];
        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
        
        [[alert textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeNumberPad];
        [[alert textFieldAtIndex:0] becomeFirstResponder];
        [alert textFieldAtIndex:0].text = [NSString stringWithFormat:@"%d", (int)uploadInterval/60];
        [alert show];
    }else if([key isEqualToString:@"STUDY_CELL_WIFI"]){ //wifi
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Sync Statement" message:@"Do you want to sync your data only WiFi enviroment?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"YES",@"NO",nil];
        [alert show];
    }
}

- (void)alertView:(UIAlertView *)alertView
clickedButtonAtIndex:(NSInteger)buttonIndex{
    NSString* title = alertView.title;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    if([title isEqualToString:@"Debug Statement"]){
        NSLog(@"%ld", buttonIndex);
        if (buttonIndex == 1){ //yes
            [userDefaults setBool:YES forKey:SETTING_DEBUG_STATE];
            [self pushedStudyRefreshButton:nil];
        } else if (buttonIndex == 2){ // no
            //reset clicked
            [userDefaults setBool:NO forKey:SETTING_DEBUG_STATE];
            [self pushedStudyRefreshButton:nil];
        } else {
            NSLog(@"Cancel");
        }
        
    }else if([title isEqualToString:@"Sync Interval (min)"]){
        if ( buttonIndex == [alertView cancelButtonIndex]){
            NSLog(@"Cancel");
            return;
        }
        NSString *interval = [alertView textFieldAtIndex:0].text;
        if ([interval isEqualToString:@""] || [interval isEqualToString:@"0"]) {
            return;
        }
        double syncInterval = [interval doubleValue] * 60.0f;
        [userDefaults setObject:[NSNumber numberWithDouble:syncInterval] forKey:SETTING_SYNC_INT];
        [self pushedStudyRefreshButton:nil];
    }else if([title isEqualToString:@"Sync Statement"]){
        NSLog(@"%ld", buttonIndex);
        if (buttonIndex == 1){ //yes
            [userDefaults setBool:YES forKey:SETTING_SYNC_WIFI_ONLY];
            [self pushedStudyRefreshButton:nil];
        } else if (buttonIndex == 2){ // no
            //reset clicked
            [userDefaults setBool:NO forKey:SETTING_SYNC_WIFI_ONLY];
            [self pushedStudyRefreshButton:nil];
        } else {
            NSLog(@"Cancel");
        }
    }
    

}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_sensors count];
}



- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = (NSDictionary *)[_sensors objectAtIndex:indexPath.row];
    if ([[item objectForKey:KEY_CEL_SENSOR_NAME] isEqualToString:@"TITLE_CELL_VIEW"]) {
        return 40;//[TitleViewCell rowHeight];
    }else if ([[item objectForKey:KEY_CEL_SENSOR_NAME] isEqualToString:@"STUDY_CELL_VIEW"]){
        return 80;
    }else{
        return [tableView rowHeight];
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    @autoreleasepool {
        static NSString *MyIdentifier = @"MyReuseIdentifier";
        
        NSDictionary *item = (NSDictionary *)[_sensors objectAtIndex:indexPath.row];
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle  reuseIdentifier:MyIdentifier];
        }
        
//        if([[item objectForKey:KEY_CEL_SENSOR_NAME] isEqualToString:@"TITLE_CELL_VIEW"]){
////            [cell.textLabel setTextColor:self.view.tintColor];
//            [cell.textLabel setTextColor:[UIColor grayColor]];
//        }
//        
//        if([[item objectForKey:KEY_CEL_SENSOR_NAME] isEqualToString:@"STUDY_CELL_VIEW"]){
//            [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
//        }
        
        
        cell.textLabel.text = [item objectForKey:KEY_CEL_TITLE];
        cell.detailTextLabel.text = [item objectForKey:KEY_CEL_DESC];
//        [cell.detailTextLabel setNumberOfLines:2];
        NSString * imageName = [item objectForKey:KEY_CEL_IMAGE];
        UIImage *theImage= nil;
        if (![imageName isEqualToString:@""]) {
             theImage = [UIImage imageNamed:imageName];
        }
        NSString *stateStr = [item objectForKey:KEY_CEL_STATE];
        cell.imageView.image = theImage;
        
        //update latest sensor data
        NSString *sensorKey = [item objectForKey:KEY_CEL_SENSOR_NAME];
        NSString* latestSensorData = [_sensorManager getLatestSensorData:sensorKey];
        if(![latestSensorData isEqualToString:@""]){
            [cell.detailTextLabel setText:latestSensorData];
        }
    //    NSLog(@"-> %@",latestSensorData);
        
        if ([stateStr isEqualToString:@"true"]) {
            theImage = [theImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            UIImageView *aImageView = [[UIImageView alloc] initWithImage:theImage];
            aImageView.tintColor = UIColor.redColor;
            cell.imageView.image = theImage;
        }
        return cell;
    }
}



- (IBAction)pushedStudyRefreshButton:(id)sender {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"AWARE Study"
                                                    message:@"AWARE Study was refreshed!"
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
    @autoreleasepool {
        [_sensorManager stopAllSensors];
        NSLog(@"remove all sensors");
    }
    [self initList];
    [self.tableView reloadData];
    [self connectMqttServer];
    //if you return NO, the back button press is cancelled
//    [self setNaviBarTitle];
}


-(BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item
{
    NSLog(@"Back button got pressed!");
    [self.navigationController popToRootViewControllerAnimated:YES];
    //update sensor list !
    [_sensorManager stopAllSensors];
    NSLog(@"remove all sensors");
    [self initList];
    [self.tableView reloadData];
    [self connectMqttServer];
    //if you return NO, the back button press is cancelled
    [self setNaviBarTitle];
    return YES;
}


- (bool) connectMqttServer {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    // if Study ID is new, AWARE adds new Device ID to the AWARE server.
    mqttServer = [userDefaults objectForKey:KEY_MQTT_SERVER];
    oldStudyId = [userDefaults objectForKey:KEY_STUDY_ID];
    mqttPassword = [userDefaults objectForKey:KEY_MQTT_PASS];
    mqttUserName = [userDefaults objectForKey:KEY_MQTT_USERNAME];
    mqttPort = [userDefaults objectForKey:KEY_MQTT_PORT];
    mqttKeepAlive = [userDefaults objectForKey:KEY_MQTT_KEEP_ALIVE];
    mqttQos = [userDefaults objectForKey:KEY_MQTT_QOS];
    studyId = [userDefaults objectForKey:KEY_STUDY_ID];
//    NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
//    NSNumber* unixtime = [NSNumber numberWithDouble:timeStamp];
    if (mqttPassword == nil) {
        NSLog(@"An AWARE study is not registed! Please read QR code");
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"AWARE Study"
                                                        message:@"You have not registed an AWARE study yet. Please read a QR code for AWARE study."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        return NO;
    }
    
    if ([self.client connected]) {
        [self.client disconnectWithCompletionHandler:^(NSUInteger code) {
            NSLog(@"disconnected!");
            [self.client unsubscribe:[NSString stringWithFormat:@"%@/%@/broadcasts",studyId,mqttUserName] withCompletionHandler:^{
                //
            }];
            [self.client unsubscribe:[NSString stringWithFormat:@"%@/%@/esm", studyId,mqttUserName] withCompletionHandler:^{
                //                         NSLog(grantedQos.description);
            }];
            [self.client unsubscribe:[NSString stringWithFormat:@"%@/%@/configuration",studyId,mqttUserName]  withCompletionHandler:^ {
                //                         NSLog(grantedQos.description);
            }];
            [self.client unsubscribe:[NSString stringWithFormat:@"%@/%@/#",studyId,mqttUserName] withCompletionHandler:^ {
                //                         NSLog(grantedQos.description);
            }];
            
            
            //Device specific subscribes
            [self.client unsubscribe:[NSString stringWithFormat:@"%@/esm", mqttUserName] withCompletionHandler:^{
                //                         NSLog(grantedQos.description);
            }];
            [self.client unsubscribe:[NSString stringWithFormat:@"%@/broadcasts", mqttUserName] withCompletionHandler:^{
                //                         NSLog(grantedQos.description);
            }];
            [self.client unsubscribe:[NSString stringWithFormat:@"%@/configuration", mqttUserName] withCompletionHandler:^ {
                //                         NSLog(grantedQos.description);
            }];
            [self.client unsubscribe:[NSString stringWithFormat:@"%@/#", mqttUserName] withCompletionHandler:^{
                //                         NSLog(grantedQos.description);
            }];
            //                                 [self uploadSensorData];

        }];
    }
    
    self.client = [[MQTTClient alloc] initWithClientId:mqttUserName cleanSession:YES];
    [self.client setPort:[mqttPort intValue]];
    [self.client setKeepAlive:[mqttKeepAlive intValue]];
    [self.client setPassword:mqttPassword];
    [self.client setUsername:mqttUserName];
    // define the handler that will be called when MQTT messages are received by the client
    [self.client setMessageHandler:^(MQTTMessage *message) {
        NSString *text = message.payloadString;
//        NSLog(@"Received messages %@", text);
        NSData *data = [text dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary * dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
        NSLog(@"%@",dic);
        NSArray *array = [dic objectForKey:KEY_SENSORS];
        NSArray *plugins = [dic objectForKey:KEY_PLUGINS];
        [userDefaults setObject:array forKey:KEY_SENSORS];
        [userDefaults setObject:plugins forKey:KEY_PLUGINS];
        [userDefaults synchronize];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // Refreh sensors
            [_sensorManager stopAllSensors];
            [self initList];
            [self.tableView reloadData];
            [self sendLocalNotificationForMessage:@"AWARE study is updated via MQTT." soundFlag:NO];
        });
//        NSLog(@"%@", dic);
    }];

    [self.client connectToHost:mqttServer
             completionHandler:^(MQTTConnectionReturnCode code) {
                 if (code == ConnectionAccepted) {
                     NSLog(@"Connected to the MQTT server!");
                     // when the client is connected, send a MQTT message
                     //Study specific subscribes
                     [self.client subscribe:[NSString stringWithFormat:@"%@/%@/broadcasts",studyId,mqttUserName] withQos:[mqttQos intValue] completionHandler:^(NSArray *grantedQos) {
//                         NSLog(grantedQos.description);
                     }];
                     [self.client subscribe:[NSString stringWithFormat:@"%@/%@/esm", studyId,mqttUserName] withQos:[mqttQos intValue]  completionHandler:^(NSArray *grantedQos) {
//                         NSLog(grantedQos.description);
                     }];
                     [self.client subscribe:[NSString stringWithFormat:@"%@/%@/configuration",studyId,mqttUserName]  withQos:[mqttQos intValue] completionHandler:^(NSArray *grantedQos) {
//                         NSLog(grantedQos.description);
                     }];
                     [self.client subscribe:[NSString stringWithFormat:@"%@/%@/#",studyId,mqttUserName] withQos:[mqttQos intValue]  completionHandler:^(NSArray *grantedQos) {
//                         NSLog(grantedQos.description);
                     }];


                     //Device specific subscribes
                     [self.client subscribe:[NSString stringWithFormat:@"%@/esm", mqttUserName] withQos:[mqttQos intValue] completionHandler:^(NSArray *grantedQos) {
//                         NSLog(grantedQos.description);
                     }];
                     [self.client subscribe:[NSString stringWithFormat:@"%@/broadcasts", mqttUserName] withQos:[mqttQos intValue] completionHandler:^(NSArray *grantedQos) {
//                         NSLog(grantedQos.description);
                     }];
                     [self.client subscribe:[NSString stringWithFormat:@"%@/configuration", mqttUserName] withQos:[mqttQos intValue] completionHandler:^(NSArray *grantedQos) {
//                         NSLog(grantedQos.description);
                     }];
                     [self.client subscribe:[NSString stringWithFormat:@"%@/#", mqttUserName] withQos:[mqttQos intValue] completionHandler:^(NSArray *grantedQos) {
//                         NSLog(grantedQos.description);
                     }];
                     //                                 [self uploadSensorData];
                 }
             }];
    return YES;
}


/**
 Local push notification method
 @param message text message for notification
 @param sound type of sound for notification
 */
- (void)sendLocalNotificationForMessage:(NSString *)message soundFlag:(BOOL)soundFlag {
    UILocalNotification *localNotification = [UILocalNotification new];
    localNotification.alertBody = message;
    //    localNotification.fireDate = [NSDate date];
    localNotification.repeatInterval = 0;
    if(soundFlag) {
        localNotification.soundName = UILocalNotificationDefaultSoundName;
    }
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}

//- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
//    if (newHeading.headingAccuracy < 0)
//        return;
//    //    CLLocationDirection  theHeading = ((newHeading.trueHeading > 0) ?
//    //                                       newHeading.trueHeading : newHeading.magneticHeading);
//    //    [sdManager addSensorDataMagx:newHeading.x magy:newHeading.y magz:newHeading.z];
//    //    [sdManager addHeading: theHeading];
//}

//- (void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations{
//    for (CLLocation* location in locations) {
//        [self saveLocation:location];
//    }
//}


@end
