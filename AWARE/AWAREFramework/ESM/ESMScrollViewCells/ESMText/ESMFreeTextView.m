//
//  ESMFreeTextView.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 2017/08/11.
//  Copyright © 2017 Yuuki NISHIYAMA. All rights reserved.
//

#import "ESMFreeTextView.h"

@implementation ESMFreeTextView {
    
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
        [self addFreeTextElement:esm withFrame:frame];
    }
    
    return self;
}



/**
 * esm_type=1 : Add a Free Text element
 *
 * @param dic NSDictionary for ESM Object which needs <i>esm_type, esm_title, esm_instructions, esm_submit, esm_expiration_threshold, and esm_trigger.</i>
 * @param tag An tag for identification of the ESM element
 */
- (void) addFreeTextElement:(EntityESM *)esm withFrame:(CGRect)frame {
    
    _freeTextView = [[UITextView alloc] initWithFrame:CGRectMake(3,
                                                                         0,
                                                                         self.mainView.frame.size.width - 6,
                                                                         self.mainView.frame.size.height )];
    _freeTextView.layer.borderWidth = 1.0f;
    _freeTextView.layer.cornerRadius = 5.0f;
    [_freeTextView setDelegate:self];
    
    
    [self.mainView addSubview:_freeTextView];
}




@end
