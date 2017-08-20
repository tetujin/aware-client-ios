//
//  ESMCheckBoxView.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 2017/08/11.
//  Copyright © 2017 Yuuki NISHIYAMA. All rights reserved.
//

#import "ESMCheckBoxView.h"

@implementation ESMCheckBoxView {
    NSMutableArray *options;
    NSMutableArray *labels;
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
        [self addCheckBoxElement:esm withFrame:frame];
    }
    return self;
}


//////////////////////////////////////////



/**
 * esm_type=3 : Add a Check Box Element
 *
 * @param dic NSDictionary for ESM Object which needs <i>esm_type, esm_title, esm_instructions, esm_checkboxes, esm_submit, esm_expiration_threshold, and esm_trigger.</i>
 * @param tag An tag for identification of the ESM element
 */
- (void) addCheckBoxElement:(EntityESM *)esm withFrame:(CGRect) frame {
    
    options = [[NSMutableArray alloc] init];
    labels = [[NSMutableArray alloc] init];
    
    NSArray * checkBoxItems = [self convertJsonStringToArray:esm.esm_checkboxes]; // [dic objectForKey:KEY_ESM_CHECKBOXES];
    
    int totalHeight = 0;
    
    for (int i=0; i<checkBoxItems.count; i++) {
        NSString* checkBoxItem  = @"";
        checkBoxItem = [checkBoxItems objectAtIndex:i];
        
        UIButton *s = [[UIButton alloc] initWithFrame:CGRectMake(10,
                                                                 totalHeight,
                                                                 30,
                                                                 30)];
        [s setImage:[UIImage imageNamed:@"unchecked_box"] forState:UIControlStateNormal];
        [s addTarget:self action:@selector(pushedCheckBox:) forControlEvents:UIControlEventTouchUpInside];
        s.tag = i;
        [options addObject:s];
        
        UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake( 10 + 60,
                                                                    totalHeight,
                                                                    self.mainView.frame.size.width - 90,
                                                                    30)];
        label.adjustsFontSizeToFitWidth = YES;
        label.text = checkBoxItem;
        [labels addObject:label];
        
        [self.mainView addSubview:s];
        [self.mainView addSubview:label];
        totalHeight += 30+10; // 9 is buffer.
    }
    
    self.mainView.frame = CGRectMake(self.mainView.frame.origin.x,
                                     self.mainView.frame.origin.y,
                                     self.mainView.frame.size.width,
                                     totalHeight);
    [self refreshSizeOfRootView];
}



- (void) pushedCheckBox:(UIButton *) sender {
    // NSLog(@"button pushed!");
    
    
    if ([sender isSelected]) {
        AudioServicesPlaySystemSound(1104);
        [sender setImage:[UIImage imageNamed:@"unchecked_box"] forState:UIControlStateNormal];
        [sender setSelected:NO];
    } else {
        AudioServicesPlaySystemSound(1105);
        [sender setImage:[UIImage imageNamed:@"checked_box"] forState:UIControlStateSelected];
        [sender setSelected:YES];
    }
    
    NSInteger tag = sender.tag;
    UILabel * label = [labels objectAtIndex:tag];
    // UIButton * option = [options objectAtIndex:tag];
    
    if ([sender isSelected]) {
    
        NSError *error = nil;
        NSString *pattern = @"Other*";
        NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];
        NSTextCheckingResult *match = [regexp firstMatchInString:label.text options:0 range:NSMakeRange(0, label.text.length)];
        NSString *matchedText = @"";
        if (match.numberOfRanges > 0) {
            NSLog(@"matched text: %@", [label.text substringWithRange:[match rangeAtIndex:0]]);
            matchedText = [label.text substringWithRange:[match rangeAtIndex:0]];
        }
        
        if ([matchedText isEqualToString:@"Other"]) {
            UIAlertView *av = [[UIAlertView alloc]initWithTitle:@""
                                                        message:@"Please write your original option."
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"OK", nil];
            av.alertViewStyle = UIAlertViewStylePlainTextInput;
            av.tag = tag;
            [av textFieldAtIndex:0].delegate = self;
            [av show];
        }
    }
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    // NSLog(@"%@",[alertView textFieldAtIndex:0].text);
    NSInteger tag = alertView.tag;
    NSString * inputText = [alertView textFieldAtIndex:0].text;
    
    UILabel * label = [labels objectAtIndex:tag];
    
    NSError *error = nil;
    NSString *pattern = @"Other*";
    NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];
    NSTextCheckingResult *match = [regexp firstMatchInString:label.text options:0 range:NSMakeRange(0, label.text.length)];
    NSString *matchedText = @"";
    if (match.numberOfRanges > 0) {
        NSLog(@"matched text: %@", [label.text substringWithRange:[match rangeAtIndex:0]]);
        matchedText = [label.text substringWithRange:[match rangeAtIndex:0]];
    }
    if ([matchedText isEqualToString:@"Other"]) {
        label.text = [NSString stringWithFormat:@"Other: %@", inputText];
    }
}


- (NSString *)getUserAnswer{
    if ([self isNA]) return @"NA";
    
    bool isDismiss = YES;
    NSMutableArray * selectedOps = [[NSMutableArray alloc] init];
    for (UIButton * btn in options) {
        if(btn.isSelected){
            NSString * selectedLabel = [[labels objectAtIndex:btn.tag] text];
            // NSLog(@"%@",selectedLabel);
            [selectedOps addObject:selectedLabel];
            isDismiss = NO;
        }
    }
    /////////////////////////////////
    if (!isDismiss) {
        // if([NSJSONSerialization isValidJSONObject:selectedOps]){
        NSError *error = nil;
        NSData *data = [NSJSONSerialization dataWithJSONObject:selectedOps options:0 error:&error];
        NSString *jsonStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        // NSLog(@"%@", jsonStr);
        return jsonStr;
        // }
    }else{
        return @"";
    }
}


- (NSNumber *)getESMState{
    if ([self isNA]) return @2;
    if(![[self getUserAnswer] isEqualToString:@""]){
        return @2;
    }else{
        return @1;
    }
}

@end
