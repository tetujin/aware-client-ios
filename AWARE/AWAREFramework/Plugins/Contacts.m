//
//  Contacts.m
//  AWARE
//
//  Created by Paul McCartney on 2016/12/12.
//  Copyright © 2016年 Yuuki NISHIYAMA. All rights reserved.
//

#import "Contacts.h"
@import Contacts;

NSString * const KEY_PLUGIN_SETTING_CONTACTS_LAST_UPDATE_NSDATE = @"key_plugin_setting_contanct_last_update_date";

@implementation Contacts{
    
}

- (instancetype) initWithAwareStudy:(AWAREStudy *)study
                             dbType:(AwareDBType)dbType {
    self = [super initWithAwareStudy:study
                          sensorName:SENSOR_PLUGIN_CONTACTS
                        dbEntityName:nil
                              dbType:AwareDBTypeTextFile];
    if (self) {
    }
    return self;
}

/** send create table query */
- (void) createTable {
    NSString * query = @"_id integer primary key autoincrement,"
    "timestamp real default 0,"
    "device_id text default '',"
    "name text default '',"
    "phone_number text default '',"
    "email_address text default ''";
    
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
                                                     // Add all
                                                     [people addObject:contact];
                                                 }];
    
    if (success) {
        // Success to collect all contacts
        for(CNContact *contact in people){
            NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
            NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
            NSString *name = [NSString stringWithFormat:@"%@ %@", contact.givenName ,contact.familyName];
            [dict setObject:unixtime forKey:@"timestamp"];
            [dict setObject:[self getDeviceId] forKey:@"device_id"];
            [dict setObject:name forKey:@"name"];
            if (contact.phoneNumbers.count != 0){
                CNPhoneNumber *phoneNumber = contact.phoneNumbers[0].value;
                // NSLog(@"%@",phoneNumber.stringValue);
                [dict setObject:phoneNumber.stringValue forKey:@"phone_number"];
            }
            if (contact.emailAddresses.count != 0){
                NSString *email = [NSString stringWithFormat:@"%@", contact.emailAddresses[0].value];
                [dict setObject:email forKey:@"email_address"];
            }
            [self saveData:dict];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success!"
                                                            message:[NSString stringWithFormat:@"Saved %ld contacts", people.count]
                                                           delegate:nil
                                                  cancelButtonTitle:@"Close"
                                                  otherButtonTitles:nil];
            [alert show];
            [self setLastUpdateDateWithDate:[NSDate new]];
            [self syncAwareDBInBackground];
        });
        
    } else {
        NSLog(@"%s %@",__func__, error);
    }
}

- (NSDate *) getLastUpdateDate{
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    NSDate * date = [userDefaults objectForKey:KEY_PLUGIN_SETTING_CONTACTS_LAST_UPDATE_NSDATE];
    if(date != nil){
        return date;
    }else{
        return nil;
    }
}

- (void) setLastUpdateDateWithDate:(NSDate *)date{
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:date forKey:KEY_PLUGIN_SETTING_CONTACTS_LAST_UPDATE_NSDATE];
    [userDefaults synchronize];
}

@end
