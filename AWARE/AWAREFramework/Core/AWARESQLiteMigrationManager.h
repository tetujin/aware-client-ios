//
//  AWARESQLiteMigrationManager.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 2018/03/23.
//  Copyright © 2018 Yuuki NISHIYAMA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AWARESQLiteMigrationManager : NSObject

- (bool) executMigration;

@end
