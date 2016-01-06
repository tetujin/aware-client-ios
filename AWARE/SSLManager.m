//
//  SSLManager.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 1/6/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "SSLManager.h"

@implementation SSLManager

- (bool)installCRTWithTextOfQRCode:(NSString *)text {
    NSLog(@"%@", text);
    // https://api.awareframework.com/index.php/webservice/index/502/Fuvl8P6Atay0
    
    NSArray *elements = [text componentsSeparatedByString:@"/"];
    if (elements.count > 2) {
        if ([[elements objectAtIndex:0] isEqualToString:@"https:"] || [[elements objectAtIndex:0] isEqualToString:@"http:"]) {
            [self installCRTWithAwareHostURL:[elements objectAtIndex:2]];
        }
    }
    return NO;
}

- (bool)installCRTWithAwareHostURL:(NSString *)url {
    if ([url isEqualToString:@"api.awareframework.com"]) {
        url = @"awareframework.com";
    }
    NSString * awareCrtUrl = [NSString stringWithFormat:@"http://%@/public/server.crt", url];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:awareCrtUrl]];
    return NO;
}

@end
