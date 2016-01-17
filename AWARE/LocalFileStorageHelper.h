//
//  LocalTextStorageHelper.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 1/16/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LocalFileStorageHelper : NSObject

- (instancetype) initWithStorageName:(NSString *) storageName;
- (NSString *) getStorageName;


- (bool) saveData:(NSDictionary *) data;
- (bool) saveData:(NSDictionary *) data toLocalFile:(NSString*) fileName;
- (bool) saveDataWithArray:(NSArray*) array;
- (BOOL) appendLine:(NSString *)line path:(NSString*) fileName;

@end
