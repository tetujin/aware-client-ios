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
#import "AppDelegate.h"


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
                    // [_button setTitle:@"Find a QR code!" forState:UIControlStateNormal];
                    [_button setTitle:@"Tap to join a study!" forState:UIControlStateNormal];
                    
                    // [self performSelector:@selector(setTapToJoinTextToButton:) withObject:nil afterDelay:1];
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
    
    // https://github.com/tetujin/aware-client/blob/master/aware-core/src/main/java/com/aware/ui/Aware_QRCode.java
    
    // Get the study information from the aware server using the study url
    // https://HOST/index.php/webservice/client_get_study_info/STUDY_API_KEY
    NSURL *url = [NSURL URLWithString:qrcodeStr];

    NSString * apiKey = @"";
    NSArray * pathComponents = [url pathComponents];
    for (NSString * component in pathComponents) {
        apiKey = component;
    }
    
    // NSLog(@"%@", url.absoluteString);
    // https://r2d2.hcii.cs.cmu.edu/aware/dashboard/
    NSRange indexRange = [url.absoluteString rangeOfString:@"index.php"];
    NSString * baseURL = [url.absoluteString substringWithRange:NSMakeRange(0, indexRange.location)];
    
    // baseURL
    NSString * requestUrl = [NSString stringWithFormat:@"%@index.php/webservice/client_get_study_info/%@", baseURL , apiKey];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:requestUrl]];
    [request setHTTPMethod:@"GET"];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSession sharedSession].configuration
                                                          delegate:self
                                                     delegateQueue:nil];
    [[session dataTaskWithRequest:request completionHandler:^(NSData * data,
                                                              NSURLResponse *  response,
                                                              NSError * error) {
        dispatch_async(dispatch_get_main_queue(),^{
            // Success
            if (response && ! error) {
                // NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                // NSLog(@"Success: %@", responseString);
                NSDictionary  * studyInfo    = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                NSString * studyTitle        = [studyInfo objectForKey:@"study_name"];
                NSString * studyDescription  = [studyInfo objectForKey:@"study_description"];
                NSString * researcherFirst   = [studyInfo objectForKey:@"researcher_first"];
                NSString * researcherLast    = [studyInfo objectForKey:@"researcher_last"];
                NSString * researcherContact = [studyInfo objectForKey:@"researcher_contact"];
                
                NSString * description = [NSString stringWithFormat:@"[Description]\n%@\n\n[Researcher]\n%@ %@\n[Contact]\n%@", studyDescription,researcherFirst, researcherLast, researcherContact];
                
                UIAlertView * alert = [[UIAlertView alloc] initWithTitle:studyTitle
                                                                 message:description
                                                                delegate:self
                                                       cancelButtonTitle:@"Cancel"
                                                       otherButtonTitles:@"Join", nil];
                alert.tag = 1;
                [alert show];
            // Error
            } else {
                NSLog(@"ERROR: %@ %ld", error.debugDescription , error.code);
                if (error.code == -1202) {
                    // Install CRT file for SSL: If the error code is -1202, this device needs .crt for SSL(secure) connection.
                    [self installSSLCertificationFile];
                    [self joinStudy];
                } else if (error.code == -1009){
                    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Network Error"
                                                                     message:@"Please connect the Internet. The operation couldn't be completed."
                                                                    delegate:self
                                                           cancelButtonTitle:@"Close"
                                                           otherButtonTitles:nil];
                    [alert show];
                }
            }
            [session finishTasksAndInvalidate];
            [session invalidateAndCancel];
        });

    }] resume];

}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    dispatch_async(dispatch_get_main_queue(), ^{
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
    });
}

- (void) joinStudy {
    // Join a study
    dispatch_async(dispatch_get_main_queue(),^{
        AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
        AWAREStudy * study = delegate.sharedAWARECore.sharedAwareStudy;
        [study setStudyInformationWithURL:qrcodeStr];
        [self moveToTopPage];
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Thank you for joining our study!"
                                                         message:nil
                                                        delegate:self
                                               cancelButtonTitle:@"Close"
                                               otherButtonTitles:nil];
        [alert show];
    });
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


//////////////////////////////////////////////////////
-  (void)URLSession:(NSURLSession *)session
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
  completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition,
                              NSURLCredential * _Nullable credential)) completionHandler{
    // http://stackoverflow.com/questions/19507207/how-do-i-accept-a-self-signed-ssl-certificate-using-ios-7s-nsurlsession-and-its
    
    if([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]){
        
        NSURLProtectionSpace *protectionSpace = [challenge protectionSpace];
        SecTrustRef trust = [protectionSpace serverTrust];
        NSURLCredential *credential = [NSURLCredential credentialForTrust:trust];
        
        // NSArray *certs = [[NSArray alloc] initWithObjects:(id)[[self class] sslCertificate], nil];
        // int err = SecTrustSetAnchorCertificates(trust, (CFArrayRef)certs);
        // SecTrustResultType trustResult = 0;
        // if (err == noErr) {
        //    err = SecTrustEvaluate(trust, &trustResult);
        // }
        
        // if ([challenge.protectionSpace.host isEqualToString:@"aware.ht.sfc.keio.ac.jp"]) {
        //credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        // } else if ([challenge.protectionSpace.host isEqualToString:@"r2d2.hcii.cs.cmu.edu"]) {
        //credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        // } else if ([challenge.protectionSpace.host isEqualToString:@"api.awareframework.com"]) {
        //credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        // } else {
        //credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        // }
        
        completionHandler(NSURLSessionAuthChallengeUseCredential,credential);
    }
}


/* The task has received a response and no further messages will be
 * received until the completion block is called. The disposition
 * allows you to cancel a request or to turn a data task into a
 * download task. This delegate message is optional - if you do not
 * implement it, you can get the response as a property of the task.
 *
 * This method will not be called for background upload tasks (which cannot be converted to download tasks).
 */
- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
    int responseCode = (int)[httpResponse statusCode];
    NSLog(@"%d",responseCode);
    [session finishTasksAndInvalidate];
    [session invalidateAndCancel];
    completionHandler(NSURLSessionResponseAllow);
}


/* Sent when data is available for the delegate to consume.  It is
 * assumed that the delegate will retain and not copy the data.  As
 * the data may be discontiguous, you should use
 * [NSData enumerateByteRangesUsingBlock:] to access it.
 */
-(void)URLSession:(NSURLSession *)session
         dataTask:(NSURLSessionDataTask *)dataTask
   didReceiveData:(NSData *)data {
    
    [session finishTasksAndInvalidate];
    [session invalidateAndCancel];
}


/* Sent as the last message related to a specific task.  Error may be
 * nil, which implies that no error occurred and this task is complete.
 */
- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error {
    /*
    if (error != nil) {
        NSLog(@"ERROR: %@ %ld", error.debugDescription , error.code);
        if (error.code == -1202) {
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            NSString* url = [userDefaults objectForKey:KEY_STUDY_QR_CODE];
            SSLManager *sslManager = [[SSLManager alloc] init];
            [sslManager installCRTWithTextOfQRCode:url];
        }
    }
     */
    [session finishTasksAndInvalidate];
    [session invalidateAndCancel];
}



@end
