//
//  TodayViewController.m
//  widget-esm
//
//  Created by Yuuki Nishiyama on 2017/06/23.
//  Copyright © 2017 Yuuki NISHIYAMA. All rights reserved.
//

#import "TodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>

@interface TodayViewController () <NCWidgetProviding>

@end

@implementation TodayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler {
    // Perform any setup necessary in order to update the view.
    
    // If an error is encountered, use NCUpdateResultFailed
    // If there's no update required, use NCUpdateResultNoData
    // If there's an update, use NCUpdateResultNewData
    
    completionHandler(NCUpdateResultNewData);
}

- (UIEdgeInsets)widgetMarginInsetsForProposedMarginInsets:(UIEdgeInsets)defaultMarginInsets
{
    return UIEdgeInsetsZero;
}

- (IBAction)pushedESMButton:(id)sender {
    [self openHostApp];
}

- (IBAction)pushedDataUploadButton:(id)sender {
    [self openHostApp];
}

- (IBAction)pushedStudyRefreshButton:(id)sender {
    [self openHostApp];
}

- (IBAction)pushedOpenAWAREButton:(id)sender {
    [self openHostApp];
}

- (void) openHostApp {
    NSString *urlStr = @"aware-client://";
    [[self extensionContext] openURL:[NSURL URLWithString:urlStr] completionHandler:nil];
}
@end
