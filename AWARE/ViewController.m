//
//  ViewController.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/18/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "ViewController.h"
#import "AWAREStudyManager.h"
#import "Accelerometer.h"
#import "Gyroscope.h"
#import "Magnetometer.h"
#import "Battery.h"
#import "Barometer.h"
#import "Locations.h"
#import "Network.h"
#import "Wifi.h"
#import "Processor.h"
#import "Gravity.h"
#import "LinearAccelerometer.h"

@interface ViewController (){
    NSString *KEY_CEL_TITLE;
    NSString *KEY_CEL_DESC;
    NSString *KEY_CEL_IMAGE;
    NSString *KEY_CEL_STATE;
    NSString *KEY_CEL_SENSOR_NAME;
    NSString *KEY;
    NSString *mqttServer;
    NSString * oldStudyId;
    NSString *mqttPassword;
    NSString *mqttUserName;
    NSString* studyId;
    NSNumber *mqttPort;
    NSNumber* mqttKeepAlive;
    NSNumber* mqttQos;
    NSTimer* listUpdateTimer;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
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
    
    _sensorManager = [[AWARESensorManager alloc] init];
    
    [self initList];
    
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.navigationController.navigationBar.delegate = self;
    
    [self connectMqttServer];
    
    listUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self.tableView selector:@selector(reloadData) userInfo:nil repeats:YES];
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
    if(deviceId == nil) deviceId = @"";
    if(awareStudyId == nil) awareStudyId = @"";
    
    [_sensors addObject:[self getCelContent:@"AWARE Device ID" desc:deviceId image:@"" key:@""]];
    [_sensors addObject:[self getCelContent:@"AWARE Study" desc:awareStudyId image:@"ic_action_study" key:@""]];
    [_sensors addObject:[self getCelContent:@"MQTT Server" desc:@"Allows remove questionnaires, P2P context exchange" image:@"ic_action_mqtt" key:@""]];
    
    // sensor
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

    // android specific sensors
    //[_sensors addObject:[self getCelContent:@"Gravity" desc:@"Force of gravity as a 3D vector with direction and magnitude of gravity (m^2)" image:@"ic_action_gravity"]];
    //[_sensors addObject:[self getCelContent:@"Light" desc:@"Ambient Light (lux)" image:@"ic_action_light"]];
    //[_sensors addObject:[self getCelContent:@"Proximity" desc:@"" image:@"ic_action_proximity"]];
    //[_sensors addObject:[self getCelContent:@"Temperature" desc:@"" image:@"ic_action_temperature"]];
    
    // iOS specific sensors
//    [_sensors addObject:[self getCelContent:@"Screen (iOS)" desc:@"Screen events (on/off, locked/unlocked)" image:@"ic_action_screen" key:SENSOR_SCREEN]];
//    [_sensors addObject:[self getCelContent:@"Direction (iOS)" desc:@"Device's direction (0-360)" image:@"safari_copyrighted" key:SENSOR_DIRECTION]];
//    [_sensors addObject:[self getCelContent:@"Rotation (iOS)" desc:@"Orientation of the device" image:@"ic_action_rotation" key:SENSOR_ROTATION]];
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
    for (int i=0; i<sensors.count; i++) {
        NSString *setting = [[sensors objectAtIndex:i] objectForKey:@"setting"];
        NSString *settingKey = [NSString stringWithFormat:@"status_%@",key];
        if ([setting isEqualToString:settingKey]) {
            NSString * value = [[sensors objectAtIndex:i] objectForKey:@"value"];
            if ([value isEqualToString:@"true"]) {
                [dic setObject:@"true" forKey:KEY_CEL_STATE];
                NSLog(@"true");
                [self addAwareSensor:key];
            }
        }
    }
    return dic;
}


- (void) addAwareSensor:(NSString *) key{
    double uploadTime = 60.0f;
    AWARESensor* awareSensor = nil;
    if ([key isEqualToString:SENSOR_ACCELEROMETER]) {
        awareSensor= [[Accelerometer alloc] initWithSensorName:SENSOR_ACCELEROMETER];
        [awareSensor startSensor:0.1f withUploadInterval:uploadTime];
    }else if([key isEqualToString:SENSOR_BAROMETER]){
        awareSensor = [[Barometer alloc] initWithSensorName:SENSOR_BAROMETER];
        [awareSensor startSensor:1.0f withUploadInterval:10.0];
    }else if([key isEqualToString:SENSOR_GYROSCOPE]){
        awareSensor = [[Gyroscope alloc] initWithSensorName:SENSOR_GYROSCOPE];
        [awareSensor startSensor:0.1f withUploadInterval:10.0f];
    }else if([key isEqualToString:SENSOR_MAGNETOMETER]){
        awareSensor = [[Magnetometer alloc] initWithSensorName:SENSOR_MAGNETOMETER];
        [awareSensor startSensor:0.1f withUploadInterval:10.0f];
    }else if([key isEqualToString:SENSOR_BATTERY]){
        awareSensor = [[Battery alloc] initWithSensorName:SENSOR_BATTERY];
        [awareSensor startSensor:1.0f withUploadInterval:10.0f];
    }else if([key isEqualToString:SENSOR_LOCATIONS]){
        awareSensor = [[Locations alloc] initWithSensorName:SENSOR_LOCATIONS];
        [awareSensor startSensor:0 withUploadInterval:10.0f];//0=>auto
    }else if([key isEqualToString:SENSOR_NETWORK]){
        awareSensor = [[Network alloc] initWithSensorName:SENSOR_NETWORK];
        [awareSensor startSensor:1.0f withUploadInterval:10.0f];
    }else if([key isEqualToString:SENSOR_WIFI]){
        awareSensor = [[Wifi alloc] initWithSensorName:SENSOR_WIFI];
        [awareSensor startSensor:1.0f withUploadInterval:10.0f];
    }else if ([key isEqualToString:SENSOR_PROCESSOR]){
        awareSensor = [[Processor alloc] initWithSensorName:SENSOR_PROCESSOR];
        [awareSensor startSensor:1.0f withUploadInterval:10.0f];
    }else if ([key isEqualToString:SENSOR_GRAVITY]){
        awareSensor = [[Gravity alloc] initWithSensorName:SENSOR_GRAVITY];
        [awareSensor startSensor:0.1f withUploadInterval:10.0f];
    }else if([key isEqualToString:SENSOR_LINEAR_ACCELEROMETER]){
        awareSensor = [[LinearAccelerometer alloc] initWithSensorName:SENSOR_LINEAR_ACCELEROMETER];
        [awareSensor startSensor:0.1f withUploadInterval:10.0f];
    }
    
    if (awareSensor != NULL) {
        [_sensorManager addNewSensor:awareSensor];
    }
}



-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_sensors count];
}



//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    return 60;//[AwardTableViewCell rowHeight];
//}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    @autoreleasepool {
        static NSString *MyIdentifier = @"MyReuseIdentifier";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle  reuseIdentifier:MyIdentifier];
        }
        NSDictionary *item = (NSDictionary *)[_sensors objectAtIndex:indexPath.row];
        cell.textLabel.text = [item objectForKey:KEY_CEL_TITLE];
        cell.detailTextLabel.text = [item objectForKey:KEY_CEL_DESC];
        [cell.detailTextLabel setNumberOfLines:2];
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
    return YES;
}

- (bool) connectMqttServer{
    
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
        return NO;
    }
    
    if ([self.client connected]) {
        [self.client disconnectWithCompletionHandler:^(NSUInteger code) {
            NSLog(@"disconnected!");
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
        NSLog(@"received message %@", text);
        
        
        
        NSData *data = [text dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary * dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
        NSArray *array = [dic objectForKey:@"sensors"];
        [userDefaults setObject:array forKey:KEY_SENSORS];
        [userDefaults synchronize];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // Refreh sensors
            [_sensorManager stopAllSensors];
            [self initList];
            [self.tableView reloadData];
        });
        

        NSLog(@"%@", dic);
    }];
    

    

    [self.client connectToHost:mqttServer
             completionHandler:^(MQTTConnectionReturnCode code) {
                 if (code == ConnectionAccepted) {
                     NSLog(@"connected!");
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

@end
