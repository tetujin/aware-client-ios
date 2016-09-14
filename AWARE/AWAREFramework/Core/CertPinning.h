//
//  CertPinning.h
//  AWARE
//
//  Created by Badie Modiri Arash on 26/08/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CertPinning : NSObject <NSURLSessionDelegate>

+ (id)sharedPinner;

@end
