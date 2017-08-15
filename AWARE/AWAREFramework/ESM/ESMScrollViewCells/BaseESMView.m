//
//  TableViewCell.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 2017/07/30.
//  Copyright © 2017 Yuuki NISHIYAMA. All rights reserved.
//

#import "BaseESMView.h"
#import "EntityESM+CoreDataClass.h"

@implementation BaseESMView{
    bool naState;
    // int totalHeight;
    // EntityESM * esmEntity;
    
    int x;
    int y;
    int w;
    int h;

    int WIDTH_BASE_VIEW;
    int HEIGHT_TITLE;
    int HEIGHT_INSTRUCTION;
    int HEIGHT_MAIN_CONTENT;
    int HEIGHT_BUTTON;
    int HEIGHT_SPACE;
    int HEIGHT_LINE;
    int HEIGHT_NA;

}


// 1. init this view from code
/*
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self loadNib];
    }
    return self;
}
*/


/**
 * You have to set a fixed
 */
- (instancetype)initWithFrame:(CGRect)frame esm:(EntityESM *)esm{
    self = [super initWithFrame:CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, 0)];
    
    if(self != nil){
        _esmEntity = esm;
        
        // x = frame.origin.x;
        // y = frame.origin.y;
        WIDTH_BASE_VIEW = frame.size.width;
        HEIGHT_TITLE = 80;
        HEIGHT_INSTRUCTION = 40;
        HEIGHT_MAIN_CONTENT = 100;
        HEIGHT_BUTTON = 60;
        HEIGHT_SPACE = 5;
        HEIGHT_LINE = 1;
        HEIGHT_NA = 30;
        
        [self generateESMView];
    }
    return self;
}

- (UIView *) generateESMView {
    // set-up title
    _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, WIDTH_BASE_VIEW, HEIGHT_TITLE)];
    _titleLabel.text       = _esmEntity.esm_title;
    _titleLabel.adjustsFontSizeToFitWidth = YES;
    _titleLabel.font = [_titleLabel.font fontWithSize:25];
    _titleLabel.numberOfLines = 5;
    [self addSubview:_titleLabel];
    [self extendHeightOfBaseView:HEIGHT_TITLE];
    
    // set-up instraction
    _instructionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, [self getBaseViewHeight], WIDTH_BASE_VIEW, HEIGHT_INSTRUCTION)];
    _instructionLabel.text = _esmEntity.esm_instructions;
    _instructionLabel.adjustsFontSizeToFitWidth = YES;
    _instructionLabel.numberOfLines = 5;
    [self addSubview:_instructionLabel];
    [self extendHeightOfBaseView:HEIGHT_INSTRUCTION];
    
    // set-up main-content
    _mainView = [[UIView alloc] initWithFrame:CGRectMake(0, [self getBaseViewHeight], WIDTH_BASE_VIEW, HEIGHT_MAIN_CONTENT)];
    [self addSubview:_mainView];
    [self extendHeightOfBaseView:HEIGHT_MAIN_CONTENT];
    
    // base na view
    _naView = [[UIView alloc] initWithFrame:CGRectMake(0, [self getBaseViewHeight], WIDTH_BASE_VIEW, HEIGHT_NA)];
    // na button
    _naButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, HEIGHT_NA, HEIGHT_NA)];
    [_naButton setImage:[UIImage imageNamed:@"unchecked_box"] forState:UIControlStateNormal];
    [_naButton addTarget:self action:@selector(pushedNAButton:) forControlEvents:UIControlEventTouchDown];
    // na label
    UILabel * naLabel = [[UILabel alloc] initWithFrame:CGRectMake(HEIGHT_NA+5, 0, 50, HEIGHT_NA)];
    [naLabel setText:@"NA"];
    // set all na elements
    [_naView addSubview:_naButton];
    [_naView addSubview:naLabel];
    // add a na view to main-content
    [self extendHeightOfBaseView:HEIGHT_NA];
    [self addSubview:_naView];
    
    // line view
    _splitLineView = [[UIView alloc] initWithFrame:CGRectMake(0, [self getBaseViewHeight],WIDTH_BASE_VIEW, HEIGHT_LINE)];
    [_splitLineView setBackgroundColor:[UIColor lightGrayColor]];
    [self extendHeightOfBaseView:HEIGHT_LINE];
    [self addSubview:_splitLineView];
    
    // space
    _spaceView = [[UIView alloc] initWithFrame:CGRectMake(0, [self getBaseViewHeight], WIDTH_BASE_VIEW, HEIGHT_SPACE)];
    [self extendHeightOfBaseView:HEIGHT_SPACE];
    [self addSubview:_spaceView];
    
    ////////////////////////////////////
    if(_esmEntity.esm_na.boolValue){
        _naView.hidden = NO;
    }else{
        _naView.hidden = YES;
    }
    /////////////////////////////////
    
//    [_titleLabel setBackgroundColor:[UIColor greenColor]];
//    [_instructionLabel setBackgroundColor:[UIColor redColor]];
//    [_mainView setBackgroundColor:[UIColor blueColor]];
//    [_naView setBackgroundColor:[UIColor purpleColor]];
//    [_spaceView setBackgroundColor:[UIColor orangeColor]];
    
    return self;
}

- (void) refreshSizeOfRootView {
    self.frame = CGRectMake(self.frame.origin.x, // x
                            self.frame.origin.y, // y
                            self.frame.size.width, // w
                            self.titleLabel.frame.size.height+ // h
                            self.instructionLabel.frame.size.height+
                            self.mainView.frame.size.height+
                            self.naView.frame.size.height+
                            self.splitLineView.frame.size.height+
                            self.spaceView.frame.size.height);
    //////////////////
    [self refreshViewPoint:self.naView under:self.mainView];
    [self refreshViewPoint:self.splitLineView under:self.naView];
    [self refreshViewPoint:self.spaceView under:self.splitLineView];
}

- (void) refreshViewPoint:(UIView *)childView under:(UIView *) parentView{
    childView.frame = CGRectMake(parentView.frame.origin.x,
                                 parentView.frame.origin.y + parentView.frame.size.height,
                                 childView.frame.size.width,
                                 childView.frame.size.height);
}

//- (instancetype)initWithCoder:(NSCoder *)aDecoder{
//
//    self = [super initWithCoder:aDecoder];
//    if(self != nil){
//        // [self commonInit];
//    }
//    return self;
//}
//- (void) commonInit{
//    // NSString *className = NSStringFromClass([self class]);
//    // UIView * view = [[NSBundle mainBundle] loadNibNamed:className owner:self options:0].firstObject;
//    
//    // view.frame = self.bounds;
//    // [self addSubview:view];
//
//    //////////////////////////////
//    // [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:self options:nil];
//    [[NSBundle mainBundle] loadNibNamed:@"BaseESMView" owner:self options:nil];
//    [self addSubview:self.contentView];
//}



- (IBAction)pushedNAButton:(id)sender {
    UIImage *img = nil;
    if(naState){
        img = [UIImage imageNamed:@"unchecked_box"];
        AudioServicesPlaySystemSound(1104);
        naState = NO;
    }else{
        img = [UIImage imageNamed:@"checked_box"];
        AudioServicesPlaySystemSound(1105);
        naState = YES;
    }
    [_naButton setImage:img forState:UIControlStateNormal];
}

- (BOOL)isNA{
    return naState;
}

- (int)getESMType{
    return AwareESMTypeNone;
}

- (CGFloat) getViewHeight{
    return self.bounds.size.height;
}

- (void) showNAView{
    self.naView.hidden = NO;
}

- (void) hideNAView{
    self.naView.hidden = YES;
}

- (NSString *)getUserAnswer{
    return @"";
}

- (NSString *)getUserAnswerWithJSONString{
    return @"";
}


//////////////////////////////////////////


- (int) getBaseViewHeight {
    return self.frame.size.height;
}


- (void) extendHeightOfBaseView: (int) additionalHeight {
    // totalHeight += additionalHeight;
    CGRect currentRect = self.frame;
    CGRect newRect = CGRectMake(currentRect.origin.x,
                                currentRect.origin.y,
                                currentRect.size.width,
                                currentRect.size.height+additionalHeight);
    self.frame = newRect;
}

////////////////////////////////////////////

- (NSArray *) convertJsonStringToArray:(NSString *) jsonString {
    if(jsonString != nil){
        NSData *jsonData = [jsonString dataUsingEncoding:NSUnicodeStringEncoding];
        NSError *error;
        
        NSArray *array = [NSJSONSerialization JSONObjectWithData:jsonData
                                                         options:NSJSONReadingAllowFragments
                                                           error:&error];
        if(error == nil){
            return array;
        }
    }
    return @[];
}


/////////////////////////////////////////////


//-(void)onSingleTap:(UITapGestureRecognizer *)recognizer {
//    NSLog(@"Single Tap");
//    for (UITextView *textView in freeTextViews) {
//        [textView resignFirstResponder];
//    }
//}
//
//-(BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
//    if (gestureRecognizer == self.singleTap) {
//        return YES;
//    }
//    return NO;
//}


@end
