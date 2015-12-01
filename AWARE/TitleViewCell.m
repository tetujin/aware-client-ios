//
//  TitleViewCell.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 12/1/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "TitleViewCell.h"

@implementation TitleViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}


+ (CGFloat)rowHeight
{
    return 60.0f;
}

@end
