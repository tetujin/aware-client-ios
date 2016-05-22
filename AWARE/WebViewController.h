//
//  WebViewController.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 5/22/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WebViewController : UIViewController <UIWebViewDelegate>

@property (strong, nonatomic) NSURL * url;

@property (strong, nonatomic) IBOutlet UIWebView *webView;

@end
