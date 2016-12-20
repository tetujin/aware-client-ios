//
//  Contacts.m
//  AWARE
//
//  Created by Paul McCartney on 2016/12/12.
//  Copyright © 2016年 Yuuki NISHIYAMA. All rights reserved.
//

#import "Contacts.h"
@import Contacts;

@implementation Contacts

- (instancetype) initWithAwareStudy:(AWAREStudy *)study
                             dbType:(AwareDBType)dbType {
    self = [super initWithAwareStudy:study
                          sensorName:@"plugin_contacts"
                        dbEntityName:nil
                              dbType:dbType];
    
    if (self) {
    }
    return self;
}

/** send create table query */
- (void) createTable {
    NSString * query = @"_id integer primary key autoincrement,"
    "timestamp real default 0,"
    "device_id text default '',"
    "value text default ''";
    [super createTable:query];
}

/** start sensor */
- (BOOL)startSensorWithSettings:(NSArray *)settings{
    return YES;
}

/** step senspr */
- (BOOL)stopSensor{
    return YES;
}

-(void)checkStatus{
    CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
    switch (status) {
        case CNAuthorizationStatusNotDetermined:
        case CNAuthorizationStatusRestricted:
        {
            CNContactStore *store = [CNContactStore new];
            [store requestAccessForEntityType:CNEntityTypeContacts
                            completionHandler:^(BOOL granted, NSError * _Nullable error) {
                                if (granted) {
                                    // 利用可能
                                    [self getContacts];
                                } else {
                                    // 拒否
                                }
                            }];
        }
            break;
            
        case CNAuthorizationStatusDenied:
            // 拒否
            break;
            
        case CNAuthorizationStatusAuthorized:
            // 利用可能
            [self getContacts];
            break;
            
        default:
            break;
    }
}

-(void)getContacts{
    CNContactStore *store = [CNContactStore new];
    NSError *error;
    CNContactFetchRequest *request = [[CNContactFetchRequest alloc] initWithKeysToFetch:@[CNContactGivenNameKey,
                                                                                          CNContactMiddleNameKey,
                                                                                          CNContactFamilyNameKey,
                                                                                          CNContactPhoneNumbersKey,
                                                                                          CNContactEmailAddressesKey]];
    NSMutableArray *people = @[].mutableCopy;
    BOOL success = [store enumerateContactsWithFetchRequest:request error:&error
                                                 usingBlock:^(CNContact * _Nonnull contact, BOOL * _Nonnull stop) {
                                                     // 全て追加
                                                     [people addObject:contact];
                                                 }];
    
    if (success) {
        // 全件取得成功
        for(CNContact *contact in people){
            NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
            [dict setObject:contact.givenName forKey:@"givenName"];
            [dict setObject:contact.middleName forKey:@"middleName"];
            [dict setObject:contact.familyName forKey:@"familyName"];
            [dict setObject:contact.phoneNumbers forKey:@"phoneNumbers"];
            [dict setObject:contact.emailAddresses forKey:@"emailAddressws"];
            [self saveData:dict];
        }
    } else {
        NSLog(@"%s %@",__func__, error);
    }
}


@end
