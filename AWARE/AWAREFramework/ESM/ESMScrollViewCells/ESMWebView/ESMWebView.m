//
//  ESMWebView.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 2017/08/14.
//  Copyright © 2017 Yuuki NISHIYAMA. All rights reserved.
//

#import "ESMWebView.h"
#import "AppDelegate.h"

@implementation ESMWebView{
    UIWebView * webView;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/


- (instancetype)initWithFrame:(CGRect)frame esm:(EntityESM *)esm{
    self = [super initWithFrame:frame esm:esm];
    
    if(self != nil){
        [self addWebPageElement:esm withFrame:frame];
    }
    return self;
}



- (void) addWebPageElement:(EntityESM *)esm withFrame:(CGRect) frame {
    
    CGRect rect = [[UIScreen mainScreen] bounds];
    // printf("w:%f, h:%f\n", r2.size.width, r2.size.height);
    
    webView = [[UIWebView alloc] initWithFrame:CGRectMake(8,
                                                          0,
                                                        frame.size.width - 16,
                                                        rect.size.height - 260)];
                                                        // self.mainView.frame.size.height*3)];
    self.mainView.frame = CGRectMake(self.mainView.frame.origin.x,
                                     self.mainView.frame.origin.y,
                                     self.mainView.frame.size.width,
                                     webView.frame.size.height);
    webView.delegate = self;
    
    [self.mainView addSubview:webView];
    
    NSString *path = esm.esm_url;
    if (path!=nil) {
        AppDelegate * delete = (AppDelegate *)[UIApplication sharedApplication].delegate;
        NSString * deviceId = [delete.sharedAWARECore.sharedAwareStudy getDeviceId];
        NSString * newPath = [path stringByReplacingOccurrencesOfString:@"AWARE_DEVICE_ID" withString: deviceId];
        NSURL *url = [NSURL URLWithString:newPath];
        NSURLRequest *req = [NSURLRequest requestWithURL:url];
        [webView loadRequest:req];
    }
    
    [self refreshSizeOfRootView];
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    
}

- (void)webViewDidFinishLoad:(UIWebView *)webView{
    
}

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
    
}

- (NSNumber *)getESMState{
    return @2;
}


@end
