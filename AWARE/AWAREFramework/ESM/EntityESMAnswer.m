//
//  EntityESMAnswer.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 7/17/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "EntityESMAnswer.h"

@implementation EntityESMAnswer

// Insert code here to add functionality to your managed object subclass

- (NSString *) getCSVHeader{
    return @"timestamp,double_esm_user_answer_timestamp,device_id,esm_expiration_threshold,esm_status,esm_trigger,esm_user_answer";
}

- (NSString *) getCSVBody{
    NSString * escapedText = [self.esm_user_answer stringByReplacingOccurrencesOfString:@"," withString:@"|"];
    return [NSString stringWithFormat:@"%@,%@,%@,%@,%@,%@,%@",
                                          self.timestamp,
                                          self.double_esm_user_answer_timestamp,
                                          self.device_id,
                                          self.esm_expiration_threshold,
                                          self.esm_status,
                                          self.esm_trigger,
                                          escapedText
                                          ];
}

@end
