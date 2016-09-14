//
//  CertPinning.m
//  AWARE
//
//  Created by Badie Modiri Arash on 26/08/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "CertPinning.h"

@implementation CertPinning

+ (id)sharedPinner {
    static CertPinning *sharedPinner = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedPinner = [[self alloc] init];
    });
    return sharedPinner;
}

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler{
    NSData *localCertData = [[NSUserDefaults standardUserDefaults] objectForKey:@"certificate"];
    SecTrustRef serverTrust = challenge.protectionSpace.serverTrust;
    SecCertificateRef certificate = SecTrustGetCertificateAtIndex(serverTrust, 0);
    NSData *remoteCertificateData = CFBridgingRelease(SecCertificateCopyData(certificate));
    
    NSString *local = [[NSString alloc] initWithData:localCertData encoding:NSASCIIStringEncoding];
    NSString *now = [[NSString alloc] initWithData:remoteCertificateData encoding:NSASCIIStringEncoding];
    CFIndex certsNb = SecTrustGetCertificateCount(serverTrust);
    for(int i=0;i<certsNb;i++) {
        
        // Extract the certificate
        SecCertificateRef certificate = SecTrustGetCertificateAtIndex(serverTrust, i);
        NSData* DERCertificate = (__bridge NSData*) SecCertificateCopyData(certificate);
        // Compare the two certificates
        if (localCertData && [localCertData isEqualToData:DERCertificate]) {
            NSURLCredential *credential = [NSURLCredential credentialForTrust:serverTrust];
            [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
            completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
            return;
        }
    }

    [[challenge sender] cancelAuthenticationChallenge:challenge];
    completionHandler(NSURLSessionAuthChallengeRejectProtectionSpace, nil);
}

@end
