//
//  ESMStorageHelper.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 12/24/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "ESMStorageHelper.h"
#import "MultiESMObject.h"

@implementation ESMStorageHelper

-(void)addEsmText:(NSString *)esmText{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray* esms  = [[NSMutableArray alloc] initWithArray:[defaults objectForKey:@"storedEsms"]];
    if (esms == nil) {
        esms = [[NSMutableArray alloc] init];
    }
    [esms addObject:esmText];
    [defaults setObject:(NSArray *)esms forKey:@"storedEsms"];
}

- (void) removeEsmTexts {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:@"storedEsms"];
}

- (void) removeEsmWithText:(NSString *)esmText {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray* esms  = [[NSMutableArray alloc] initWithArray:[defaults objectForKey:@"storedEsms"]];
    if (esms == nil) {
        esms = [[NSMutableArray alloc] init];
    }
    NSMutableArray * newArray = [[NSMutableArray alloc] init];
    for (NSString* str in esms) {
//        NSLog(@"%@", str);
        if ([str isEqualToString:esmText]) {
//            [esms removeObject:esms];
        }else{
            [newArray addObject:str];
        }
    }
    [defaults setObject:(NSArray *)newArray forKey:@"storedEsms"];
}

- (NSArray *) getEsmTexts {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:@"storedEsms"];
}

//- (void) addEsmObject:(MultiESMObject *) esmObject{
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    NSMutableArray* esms  = [defaults objectForKey:@"storedEsms"];
//    if (esms == nil) {
//        esms = [[NSMutableArray alloc] init];
//    }
//    [defaults setObject:esms forKey:@"storedEsms"];
//}
//
//- (NSArray *) getEsmObjects {
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    NSMutableArray* esms  = [defaults objectForKey:@"storedEsms"];
//    return esms;
//}
//
//- (NSArray *) removeEsmObject:(MultiESMObject *) esmObject {
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    NSMutableArray* esms  = [defaults objectForKey:@"storedEsms"];
//    for( MultiESMObject* mEsm in esms ){
//        
//    }
//    return esms;
//}
//
//- (void) removeEsmObjects{
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    [defaults removeObjectForKey:@"storedEsms"];
//}
//
//- (NSMutableArray *) removeExpiredEsms:(NSMutableArray *)esms {
//    for (MultiESMObject *esm in esms) {
//        NSLog(@"%@", esm.expirationThreshold);
//    }
//    return esms;
//}

@end
