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


@interface QRCodeViewController (){
    NSString *crtUrl;
    AWAREStudy *study;
    bool readingState;
}
@end

@implementation QRCodeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    crtUrl = @"http://www.awareframework.com/awareframework.crt";
    
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



- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    NSLog(@"----");
    for (AVMetadataObject *metadata in metadataObjects) {
        if ([metadata.type isEqualToString:AVMetadataObjectTypeQRCode]) {
            NSString *qrcode = [(AVMetadataMachineReadableCodeObject *)metadata stringValue];
            // HTTPS/POST
            if(readingState){
                readingState = NO;
                NSLog(@"%@", qrcode);
                AWAREStudy *study = [[AWAREStudy alloc] init];
                bool result = [study setStudyInformationWithURL:qrcode];
//                [self getStudyInformation:qrcode withDeviceId:deviceId];
                if (result) {
                    [self.navigationController popToRootViewControllerAnimated:YES];
                }
//                readingState = YES;
            }
        }
    }
}

@end
