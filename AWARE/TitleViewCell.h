//
//  TitleViewCell.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 12/1/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TitleViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

+ (CGFloat)rowHeight;

@end
