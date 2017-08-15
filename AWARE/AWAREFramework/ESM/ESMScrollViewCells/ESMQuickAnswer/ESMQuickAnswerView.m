//
//  ESMQuickAnswer.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 2017/08/12.
//  Copyright © 2017 Yuuki NISHIYAMA. All rights reserved.
//

#import "ESMQuickAnswerView.h"

@implementation ESMQuickAnswerView{
    NSMutableArray * buttons;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (instancetype)initWithFrame:(CGRect)frame esm:(EntityESM *)esm{
    self = [super initWithFrame:frame esm:esm];
    
    if(self != nil){
        [self addQuickAnswerElement:esm withFrame:frame];
    }
    
    return self;
}




/**
 * esm_type=5 : Add a Quick Answer Element
 *
 * @param dic NSDictionary for ESM Object which needs <i>esm_type, esm_title, esm_instructions, esm_quick_answers, esm_submit, esm_expiration_threshold, and esm_trigger.</i>
 * @param tag An tag for identification of the ESM element
 */
- (void) addQuickAnswerElement:(EntityESM *) esm withFrame:(CGRect) frame {
    buttons = [[NSMutableArray alloc] init];
    
    NSArray * options = [self convertJsonStringToArray:esm.esm_quick_answers];
    int totalHeigth = 0;
    int buttonHeight = 50;
    int verticalSpace = 5;
    
    for (int i=0; i<options.count; i++) {
        NSString * answer = [options objectAtIndex:i];
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(10, totalHeigth, frame.size.width-20, buttonHeight)];
        [button setTitle:answer forState:UIControlStateNormal];
        [button setBackgroundColor:[UIColor lightGrayColor]];
        [button addTarget:self action:@selector(pushedQuickAnswerButtons:) forControlEvents:UIControlEventTouchUpInside];
        button.tag = i;
        [self.mainView addSubview:button];
        totalHeigth += buttonHeight + verticalSpace;
        [buttons addObject:button];
    }
    
    self.mainView.frame = CGRectMake(self.mainView.frame.origin.x,
                                     self.mainView.frame.origin.y,
                                     self.mainView.frame.size.width,
                                     totalHeigth);
    [self refreshSizeOfRootView];
    
}


- (void) pushedQuickAnswerButtons:(UIButton *) button  {
    // int tag = (int)button.tag;
    for (UIButton * b in buttons) {
        b.selected = NO;
        b.layer.borderWidth = 0;
        if ([button.titleLabel isEqual:b.titleLabel]) {
            b.selected = YES;
            b.layer.borderColor = [UIColor redColor].CGColor;
            b.layer.borderWidth = 5.0;
        }
    }
}



@end
