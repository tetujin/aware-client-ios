//
//  AWARESQLiteMigrationManager.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 2018/03/23.
//  Copyright © 2018 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESQLiteMigrationManager.h"
#import "AWAREDelegate.h"

@implementation AWARESQLiteMigrationManager

- (bool)executMigration{
    [self removeDB];
    return [self removeDB];
}

- (BOOL)removeDB{

    AWAREDelegate * delegate = (AWAREDelegate *) [UIApplication sharedApplication].delegate;
    for(NSPersistentStore * store in delegate.managedObjectContext.persistentStoreCoordinator.persistentStores){
        NSError * error = nil;
        bool isRemoved = [delegate.managedObjectContext.persistentStoreCoordinator removePersistentStore:store error:&error];
        if (error !=nil) NSLog(@"%@",error.debugDescription);
        if (!isRemoved) {
            return NO;
        }
    }
    return YES;
}

- (NSString*)getDocumentDirectory{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(
                                                         NSDocumentDirectory,
                                                         NSUserDomainMask,
                                                         YES);
    return [paths objectAtIndex:0];
}

@end
