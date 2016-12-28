//
//  Contacts.h
//  AWARE
//
//  Created by Paul McCartney on 2016/12/28.
//  Copyright © 2016年 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"
#import <AddressBook/AddressBook.h>

@interface Contacts : AWARESensor<AWARESensorDelegate>

-(void)checkStatus;

@end
