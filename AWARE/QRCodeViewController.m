//
//  QRCodeViewController.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/18/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import <sys/utsname.h>
#import "QRCodeViewController.h"
#import "AWAREKeys.h"
#import "AWAREStudy.h"
#import "AWAREUtils.h"
#import "SSLManager.h"


@interface QRCodeViewController (){
    // AWARE Study Object
//    AWAREStudy *study;
    bool readingState;
    int buttonHeight;
    NSString * qrcodeStr;
}
@end

@implementation QRCodeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    buttonHeight = 60;
    readingState = YES;
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
    
    [self configureCameraForHighestFrameRate:device];
    [self configureCameraForLowestFrameRate:device];
    
    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device
                                                                        error:&error];
    if ([self.session canAddInput:input]) {
        [self.session addInput: input];
    }
    
    AVCaptureMetadataOutput *output = [AVCaptureMetadataOutput new];
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    [self.session addOutput:output];

    
    //Set QRCode filter
    output.metadataObjectTypes = output.availableMetadataObjectTypes;
    
    NSLog(@"%@", output.availableMetadataObjectTypes);
    NSLog(@"%@", output.metadataObjectTypes);
    
    [self.session startRunning];
    
    AVCaptureVideoPreviewLayer *preview = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    preview.frame = self.view.bounds;
//    preview.frame = CGRectMake(self.view.bounds.origin.x,
//                               self.view.bounds.origin.y,
//                               self.view.bounds.size.width,
//                               self.view.bounds.size.height-buttonHeight);
    preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer addSublayer:preview];
    
    // Add a button to view
    _button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    _button.frame = CGRectMake(0,
                              self.view.bounds.size.height-buttonHeight,
                              self.view.bounds.size.width,
                              buttonHeight);
    [_button setTitle:@"Scanning a QR code now..." forState:UIControlStateNormal];
    [_button setTitleColor:self.view.tintColor forState:UIControlStateNormal];
    _button.layer.cornerRadius = 8.0f;
    [_button setBackgroundColor:[UIColor whiteColor]];
    _button.alpha = 0.8f;
    _button.enabled = NO;
    [_button addTarget:self action:@selector(pushedJoinButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_button];
}



- (void)configureCameraForLowestFrameRate:(AVCaptureDevice *)device {
    AVCaptureDeviceFormat *worstFormat = nil;
    AVFrameRateRange *worstFrameRateRange = nil;
    for ( AVCaptureDeviceFormat *format in [device formats] ) {
        for ( AVFrameRateRange *range in format.videoSupportedFrameRateRanges ) {
            if ( range.minFrameRate < worstFrameRateRange.minFrameRate ) {
                worstFormat = format;
                worstFrameRateRange = range;
            }
        }
    }
    if ( worstFormat ) {
        if ( [device lockForConfiguration:NULL] == YES ) {
            device.activeFormat = worstFormat;
            device.activeVideoMinFrameDuration = worstFrameRateRange.minFrameDuration;
            device.activeVideoMaxFrameDuration = worstFrameRateRange.minFrameDuration;
            [device unlockForConfiguration];
        }
    }
}



- (void)configureCameraForHighestFrameRate:(AVCaptureDevice *)device {
    AVCaptureDeviceFormat *bestFormat = nil;
    AVFrameRateRange *bestFrameRateRange = nil;
    for ( AVCaptureDeviceFormat *format in [device formats] ) {
        for ( AVFrameRateRange *range in format.videoSupportedFrameRateRanges ) {
            if ( range.maxFrameRate > bestFrameRateRange.maxFrameRate ) {
                bestFormat = format;
                bestFrameRateRange = range;
            }
        }
    }
    if ( bestFormat ) {
        if ( [device lockForConfiguration:NULL] == YES ) {
            device.activeFormat = bestFormat;
            device.activeVideoMinFrameDuration = bestFrameRateRange.minFrameDuration;
            device.activeVideoMaxFrameDuration = bestFrameRateRange.minFrameDuration;
            [device unlockForConfiguration];
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


/**
 * When QRcode is detected by the camera and QRcode filter, this method is called
 */
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    dispatch_async(dispatch_get_main_queue(), ^{
        for (AVMetadataObject *metadata in metadataObjects) {
            if ([metadata.type isEqualToString:AVMetadataObjectTypeQRCode]) {
                NSString *qrcode = [(AVMetadataMachineReadableCodeObject *)metadata stringValue];
                
                // Join a study using QR code
                if(readingState){
                    NSLog(@"%@", qrcode);
                    readingState = NO;
                    qrcodeStr = qrcode;
                    _button.enabled = YES;
                    _button.titleLabel.font = [UIFont boldSystemFontOfSize:20];
                    [_button setTitle:@"Find a QR code!" forState:UIControlStateNormal];
                    
                    [self performSelector:@selector(setTapToJoinTextToButton:) withObject:nil afterDelay:2];
                }
            }
        }
    });
}

- (void) setTapToJoinTextToButton:(id) sender{
    [_button setTitle:@"Tap to join a study!" forState:UIControlStateNormal];
}

- (void) moveToTopPage {
    [self.navigationController popToRootViewControllerAnimated:YES];
}


- (void)pushedJoinButton:(id) sender {
    
    if(![AWAREUtils checkURLFormat:qrcodeStr]) return;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:qrcodeStr forKey:KEY_STUDY_QR_CODE];
    
    NSString * alertTitle = @"Join this study?";
    NSString * alertMessage = qrcodeStr;
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:alertTitle
                                                     message:alertMessage
                                                    delegate:self
                                           cancelButtonTitle:@"Cancel"
                                           otherButtonTitles:@"Join", nil];
    alert.tag = 1;
    [alert show];

}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(alertView.tag == 1){
        if( buttonIndex == 1){
            [self joinStudy];
        }
    }else if (alertView.tag == 2){
        if( buttonIndex == 1){
            SSLManager * sslManager = [[SSLManager alloc] init];
            [sslManager installCRTWithTextOfQRCode:qrcodeStr];
        }
    }
}

- (void) joinStudy {
    
    // Check a SSL certification file
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:qrcodeStr]];
    [request setHTTPMethod:@"GET"];
    __weak NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithRequest: request  completionHandler: ^(NSData *data, NSURLResponse *response, NSError *error) {
        [session finishTasksAndInvalidate];
        [session invalidateAndCancel];
        // Success
        if (response && ! error) {
            NSString *responseString = [[NSString alloc] initWithData: data  encoding: NSUTF8StringEncoding];
            NSLog(@"Success: %@", responseString);
            // Join a study
            dispatch_async(dispatch_get_main_queue(),^{
                AWAREStudy *study = [[AWAREStudy alloc] init];
                [study setStudyInformationWithURL:qrcodeStr];
                [self moveToTopPage];
                UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Thank you for joining our study!"
                                                                 message:nil
                                                                delegate:self
                                                       cancelButtonTitle:@"Close"
                                                       otherButtonTitles:nil];
                [alert show];
            });
        } else {
            NSLog(@"ERROR: %@ %ld", error.debugDescription , error.code);
            if (error.code == -1202) {
                // Install CRT file for SSL: If the error code is -1202, this device needs .crt for SSL(secure) connection.
                dispatch_async(dispatch_get_main_queue(),^{
                    [self installSSLCertificationFile];
//                    [self joinStudy];
                });
            }
        }
    }] resume];
}


- (void)installSSLCertificationFile{
    NSString * alertTitle = @"SLL certification is requred!";
    NSString * alertMessage = [NSString stringWithFormat:@"AWARE needs a SSL certification for secure network connection between the server. Could you install the certification file? "];
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:alertTitle
                                                     message:alertMessage
                                                    delegate:self
                                           cancelButtonTitle:@"Cancel"
                                           otherButtonTitles:@"Install", nil];
    alert.tag = 2;
    
    [alert show];
}


@end
