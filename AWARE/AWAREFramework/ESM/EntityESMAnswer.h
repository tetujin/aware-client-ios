//
//  EntityESMAnswer.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 7/17/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface EntityESMAnswer : NSManagedObject

// Insert code here to declare functionality of your managed object subclass

- (NSString *) getCSVHeader;
- (NSString *) getCSVBody;

@end

NS_ASSUME_NONNULL_END

#import "EntityESMAnswer+CoreDataProperties.h"
