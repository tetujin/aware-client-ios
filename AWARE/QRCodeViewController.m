//
//  QRCodeViewController.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/18/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import <sys/utsname.h>
//#import "UIDevice+IdentifierAddition.h"
#import "QRCodeViewController.h"
#import "AWAREStudyManager.h"


@interface QRCodeViewController (){
    NSString *crtUrl;
    NSString *deviceId;
    
    NSString *mqttPassword;
    NSString *mqttUsername;
    NSString *studyId;
    NSString *mqttServer;
    NSString *webserviceServer;
    int mqttPort;
    int mqttKeepAlive;
    int mqttQos;
    
    bool readingState;
}
@end

@implementation QRCodeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    crtUrl = @"http://www.awareframework.com/awareframework.crt";
    deviceId = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    
    mqttPassword = @"";
    mqttUsername = @"";
    studyId = @"";
    mqttServer = @"";
    webserviceServer = @"";
    mqttPort = 1883;
    mqttKeepAlive = 600;
    mqttQos = 2;
    readingState = YES;
    
    // Do any additional setup after loading the view.
    _session = [[AVCaptureSession alloc] init];
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *device = nil;
    AVCaptureDevicePosition camera = AVCaptureDevicePositionBack; // Back or Front
    for (AVCaptureDevice *d in devices) {
        device = d;
        if (d.position == camera) {
            break;
        }
    }
    
    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device
                                                                        error:&error];
    [self.session addInput:input];
    
    AVCaptureMetadataOutput *output = [AVCaptureMetadataOutput new];
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    [self.session addOutput:output];
    
    //Select QR code
    output.metadataObjectTypes = output.availableMetadataObjectTypes;
    
    NSLog(@"%@", output.availableMetadataObjectTypes);
    NSLog(@"%@", output.metadataObjectTypes);
    
    [self.session startRunning];
    
    AVCaptureVideoPreviewLayer *preview = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    preview.frame = self.view.bounds;
    preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer addSublayer:preview];
}


- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    NSLog(@"----");
    for (AVMetadataObject *metadata in metadataObjects) {
        if ([metadata.type isEqualToString:AVMetadataObjectTypeQRCode]) {
            NSString *qrcode = [(AVMetadataMachineReadableCodeObject *)metadata stringValue];
            // HTTPS/POST
            if(readingState){
                readingState = NO;
                NSLog(@"%@", qrcode);
                [self getStudyInformation:qrcode withDeviceId:deviceId];
            }
//            if(state){
//                [self.navigationController popToRootViewControllerAnimated:YES];
//            }else{
//                NSString *url =  crtUrl;
//                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
//            }
        }
    }
}

- (bool) getStudyInformation:(NSString *)url withDeviceId:(NSString *)uuid{
    NSString *post = [NSString stringWithFormat:@"device_id=%@", uuid];
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%ld", [postData length]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:postData];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSError *error = nil;
        NSHTTPURLResponse *response = nil;
        NSData *resData = [NSURLConnection sendSynchronousRequest:request
                                                returningResponse:&response error:&error];
        int responseCode = (int)[response statusCode];
        NSLog(@"%d",responseCode);
        if(responseCode == 0){
            NSString *url =  crtUrl;
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
        }else{
            NSArray *mqttArray = [NSJSONSerialization JSONObjectWithData:resData options:NSJSONReadingMutableContainers error:nil];
            id obj = [NSJSONSerialization JSONObjectWithData:resData options:NSJSONReadingMutableContainers error:nil];
            NSData *data = [NSJSONSerialization dataWithJSONObject:obj options:0 error:nil];
            NSLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if(responseCode == 200){
                    NSLog(@"GET Study Information");
                    NSArray * array = [[mqttArray objectAtIndex:0] objectForKey:@"sensors"];
                    
                    for (int i=0; i<[array count]; i++) {
                        NSDictionary *settingElement = [array objectAtIndex:i];
                        NSString *setting = [settingElement objectForKey:@"setting"];
                        NSString *value = [settingElement objectForKey:@"value"];
                        if([setting isEqualToString:@"mqtt_password"]){
                            mqttPassword = value;
                        }else if([setting isEqualToString:@"mqtt_username"]){
                            mqttUsername = value;
                        }else if([setting isEqualToString:@"mqtt_server"]){
                            mqttServer = value;
                        }else if([setting isEqualToString:@"mqtt_server"]){
                            mqttServer = value;
                        }else if([setting isEqualToString:@"mqtt_port"]){
                            mqttPort = [value intValue];
                        }else if([setting isEqualToString:@"mqtt_keep_alive"]){
                            mqttKeepAlive = [value intValue];
                        }else if([setting isEqualToString:@"mqtt_qos"]){
                            mqttQos = [value intValue];
                        }else if([setting isEqualToString:@"study_id"]){
                            studyId = value;
                        }else if([setting isEqualToString:@"webservice_server"]){
                            webserviceServer = value;
                        }
                    }
                    
                    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                    // if Study ID is new, AWARE adds new Device ID to the AWARE server.
                    NSString * oldStudyId = [userDefaults objectForKey:KEY_STUDY_ID];
                    if(![oldStudyId isEqualToString:studyId]){
                        NSLog(@"Add new device ID to the AWARE server.");
                        [self addNewDeviceToAwareServer:url withDeviceId:uuid];
                    }else{
                        NSLog(@"This device ID is already regited to the AWARE server.");
                    }
                    [userDefaults setObject:mqttServer forKey:KEY_MQTT_SERVER];
                    [userDefaults setObject:mqttPassword forKey:KEY_MQTT_PASS];
                    [userDefaults setObject:mqttUsername forKey:KEY_MQTT_USERNAME];
                    [userDefaults setObject:[NSNumber numberWithInt:mqttPort] forKey:KEY_MQTT_PORT];
                    [userDefaults setObject:[NSNumber numberWithInt:mqttKeepAlive] forKey:KEY_MQTT_KEEP_ALIVE];
                    [userDefaults setObject:[NSNumber numberWithInt:mqttQos] forKey:KEY_MQTT_QOS];
                    [userDefaults setObject:studyId forKey:KEY_STUDY_ID];
                    [userDefaults setObject:webserviceServer forKey:KEY_WEBSERVICE_SERVER];
                    [userDefaults synchronize];
                    
                    [userDefaults setObject:array forKey:KEY_SENSORS];
                    
                    readingState = YES;
                    [self.navigationController popToRootViewControllerAnimated:YES];
                }
            });
        }
    });
    return YES;
}


- (bool) addNewDeviceToAwareServer:(NSString *)url withDeviceId:(NSString *) uuid {
    url = [NSString stringWithFormat:@"%@/aware_device/insert", url];
    NSMutableDictionary *jsonQuery = [[NSMutableDictionary alloc] init];
    NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
    NSNumber* unixtime = [NSNumber numberWithDouble:timeStamp] ;
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString* code = [NSString stringWithCString:systemInfo.machine
                                        encoding:NSUTF8StringEncoding];
//    NSString *systemName = [[UIDevice currentDevice] systemName];
    NSString *identifier = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    NSString *name = [[UIDevice currentDevice] name];
    NSString *systemVersion = [[UIDevice currentDevice] systemVersion];
//    NSString *localizeModel = [[UIDevice currentDevice] localizedModel];
    NSString *model = [[UIDevice currentDevice] model];
    NSString *deviceName = [self deviceName];
    NSString *manufacturer = @"Apple";
    
    [jsonQuery setValue:uuid  forKey:@"device_id"];
    [jsonQuery setValue:unixtime forKey:@"timestamp"];
    [jsonQuery setValue:manufacturer forKey:@"board"];//    board	TEXT	Manufacturer’s board name
    [jsonQuery setValue:model forKey:@"brand"];//    brand	TEXT	Manufacturer’s brand name
    [jsonQuery setValue:manufacturer forKey:@"device"];//    device	TEXT	Manufacturer’s device name
    [jsonQuery setValue:code forKey:@"build_id"];//    build_id	TEXT	Android OS build ID
    [jsonQuery setValue:manufacturer forKey:@"hardware"];//    hardware	TEXT	Hardware codename
    [jsonQuery setValue:manufacturer forKey:@"manufacturer"];//    manufacturer	TEXT	Device’s manufacturer
    [jsonQuery setValue:[self deviceName] forKey:@"model"];//    model	TEXT	Device’s model
    [jsonQuery setValue:manufacturer forKey:@"product"];//    product	TEXT	Device’s product name
    [jsonQuery setValue:identifier forKey:@"serial"];//    serial	TEXT	Manufacturer’s device serial, not unique
    [jsonQuery setValue:systemVersion forKey:@"release"];//    release	TEXT	Android’s release
    [jsonQuery setValue:@"user" forKey:@"release_type"];//    release_type	TEXT	Android’s type of release (e.g., user, userdebug, eng)
    [jsonQuery setValue:systemVersion forKey:@"sdk"];//    sdk	INTEGER	Android’s SDK level
    [jsonQuery setValue:name forKey:@"label"];
    
//    [[UIDevice currentDevice] platformType]   // ex: UIDevice4GiPhone
//    [[UIDevice currentDevice] platformString] // ex: @"iPhone 4G"
    
    NSMutableArray *a = [[NSMutableArray alloc] init];
    [a addObject:jsonQuery];
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:a
                                                       options:NSJSONWritingPrettyPrinted // Pass 0 if you don't care about the readability of the generated string
                                                         error:&error];
    NSString *jsonString = @"";
    if (! jsonData) {
        NSLog(@"Got an error: %@", error);
    } else {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        NSLog(@"%@",jsonString);
    }
    NSString *post = [NSString stringWithFormat:@"data=%@&device_id=%@", jsonString,uuid];
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%ld", [postData length]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    //[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    
    //    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSError *error = nil;
        NSHTTPURLResponse *response = nil;
        NSData *resData = [NSURLConnection sendSynchronousRequest:request
                                                returningResponse:&response error:&error];
        int responseCode = (int)[response statusCode];
        dispatch_async(dispatch_get_main_queue(), ^{
            if(responseCode == 200){
                NSLog(@"UPLOADED SENSOR DATA TO A SERVER");
            }else{
                NSLog(@"ERROR");
            }
        });
    });
    return true;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



/**
 * http://stackoverflow.com/questions/11197509/ios-how-to-get-device-make-and-model
 */
- (NSString*) deviceName
{
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString* code = [NSString stringWithCString:systemInfo.machine
                                        encoding:NSUTF8StringEncoding];
    
    static NSDictionary* deviceNamesByCode = nil;
    
    if (!deviceNamesByCode) {
        
        deviceNamesByCode = @{@"i386"      :@"Simulator",
                              @"iPod1,1"   :@"iPod Touch",      // (Original)
                              @"iPod2,1"   :@"iPod Touch",      // (Second Generation)
                              @"iPod3,1"   :@"iPod Touch",      // (Third Generation)
                              @"iPod4,1"   :@"iPod Touch",      // (Fourth Generation)
                              @"iPhone1,1" :@"iPhone",          // (Original)
                              @"iPhone1,2" :@"iPhone",          // (3G)
                              @"iPhone2,1" :@"iPhone",          // (3GS)
                              @"iPad1,1"   :@"iPad",            // (Original)
                              @"iPad2,1"   :@"iPad 2",          //
                              @"iPad3,1"   :@"iPad",            // (3rd Generation)
                              @"iPhone3,1" :@"iPhone 4",        // (GSM)
                              @"iPhone3,3" :@"iPhone 4",        // (CDMA/Verizon/Sprint)
                              @"iPhone4,1" :@"iPhone 4S",       //
                              @"iPhone5,1" :@"iPhone 5",        // (model A1428, AT&T/Canada)
                              @"iPhone5,2" :@"iPhone 5",        // (model A1429, everything else)
                              @"iPad3,4"   :@"iPad",            // (4th Generation)
                              @"iPad2,5"   :@"iPad Mini",       // (Original)
                              @"iPhone5,3" :@"iPhone 5c",       // (model A1456, A1532 | GSM)
                              @"iPhone5,4" :@"iPhone 5c",       // (model A1507, A1516, A1526 (China), A1529 | Global)
                              @"iPhone6,1" :@"iPhone 5s",       // (model A1433, A1533 | GSM)
                              @"iPhone6,2" :@"iPhone 5s",       // (model A1457, A1518, A1528 (China), A1530 | Global)
                              @"iPhone7,1" :@"iPhone 6 Plus",   //
                              @"iPhone7,2" :@"iPhone 6",        //
                              @"iPad4,1"   :@"iPad Air",        // 5th Generation iPad (iPad Air) - Wifi
                              @"iPad4,2"   :@"iPad Air",        // 5th Generation iPad (iPad Air) - Cellular
                              @"iPad4,4"   :@"iPad Mini",       // (2nd Generation iPad Mini - Wifi)
                              @"iPad4,5"   :@"iPad Mini"        // (2nd Generation iPad Mini - Cellular)
                              };
    }
    
    NSString* deviceName = [deviceNamesByCode objectForKey:code];
    
    if (!deviceName) {
        // Not found on database. At least guess main device type from string contents:
        
        if ([code rangeOfString:@"iPod"].location != NSNotFound) {
            deviceName = @"iPod Touch";
        }
        else if([code rangeOfString:@"iPad"].location != NSNotFound) {
            deviceName = @"iPad";
        }
        else if([code rangeOfString:@"iPhone"].location != NSNotFound){
            deviceName = @"iPhone";
        }
    }
    
    return deviceName;
}

/***
 * 1. Get study information
 * 2. Save the information
 * 3. Move to the top-page
 */
@end
