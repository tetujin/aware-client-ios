//
//  GoogleLogin.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 1/6/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"

@interface GoogleLogin : AWARESensor <AWARESensorDelegate>
- (void) saveName:(NSString* )name withEmail:(NSString *)email;
@end
