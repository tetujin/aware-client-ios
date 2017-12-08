//
//  ContactsViewController.m
//  AWARE
//
//  Created by Paul McCartney on 2016/12/28.
//  Copyright © 2016年 Yuuki NISHIYAMA. All rights reserved.
//

#import "ContactsViewController.h"
#import "Contacts.h"
#import "AppDelegate.h"

@interface ContactsViewController ()

@end

@implementation ContactsViewController{
    Contacts *contacts;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    AppDelegate * delegate = (AppDelegate *) [UIApplication sharedApplication].delegate;
    
    contacts = [[Contacts alloc] initWithAwareStudy:delegate.sharedAWARECore.sharedAwareStudy dbType:AwareDBTypeTextFile];

    [self updateLastUpdateDate];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)uploadContacts:(id)sender {
    [contacts updateContacts];
    [self performSelector:@selector(updateLastUpdateDate) withObject:nil afterDelay:3];
    [self performSelector:@selector(backToRootView:) withObject:nil afterDelay:1];
}

- (void) updateLastUpdateDate{
    NSDate * lastUpdateDate = [contacts getLastUpdateDate];
    if(lastUpdateDate != nil){
        _lastUpdate.text = [NSString stringWithFormat:@"Last Update:\n%@",lastUpdateDate.debugDescription];
    }
}

- (void) backToRootView:(id)sender{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
