//
//  AWAREEsmViewController.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 12/15/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWAREEsmViewController.h"
#import "ESM.h"
#import "AWAREKeys.h"
#import "ViewController.h"
#import "SingleESMObject.h"
#import "ESMStorageHelper.h"

@interface AWAREEsmViewController ()

@end

@implementation AWAREEsmViewController {
    CGRect frameRect;
    int WIDTH_VIEW;
    int HIGHT_TITLE;
    int HIGHT_INSTRUCTION;
    int HIGHT_MAIN_CONTENT;
    int HIGHT_BUTTON;
    int HIGHT_SPACE;
    int HIGHT_LINE;
    int totalHight;
    
    CGRect titleRect;
    CGRect instructionRect;
    CGRect mainContentRect;
    CGRect buttonRect;
    CGRect spaceRect;
    CGRect lineRect;
    NSMutableArray* freeTextViews;
//    NSArray *arrayForJson;
    NSMutableArray *uiElements;
    
    NSString * currentTextOfEsm;
    
    NSString* KEY_ELEMENT;
    NSString* KEY_TAG;
    NSString* KEY_TYPE;
    NSString* KEY_LABLES;
    NSString* KEY_OBJECT;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    currentTextOfEsm = @"";
    
    WIDTH_VIEW = self.view.frame.size.width;
    HIGHT_TITLE = 100;
    HIGHT_INSTRUCTION = 40;
    HIGHT_MAIN_CONTENT = 100;
    HIGHT_BUTTON = 60;
    HIGHT_SPACE = 20;
    HIGHT_LINE = 1;
    
    totalHight = 0;
    int buffer = 10;
    
    titleRect = CGRectMake(buffer, 0, WIDTH_VIEW - buffer*2, HIGHT_TITLE);
    instructionRect = CGRectMake(buffer, 0, WIDTH_VIEW - buffer*2, HIGHT_INSTRUCTION);
    mainContentRect = CGRectMake(buffer, 0, WIDTH_VIEW - buffer*2, HIGHT_MAIN_CONTENT);
    buttonRect = CGRectMake(buffer, 0, WIDTH_VIEW - buffer*2, HIGHT_BUTTON);
    spaceRect = CGRectMake(buffer, 0, WIDTH_VIEW - buffer*2, HIGHT_SPACE);
    lineRect = CGRectMake(buffer, 0, WIDTH_VIEW - buffer*2, HIGHT_LINE);
    
    [self addNullElement];
    
//    self.view = _mainScrollView;
//    [self.navigationController.toolbar setTranslucent:NO];
//    self.automaticallyAdjustsScrollViewInsets = NO;
    
    self.singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onSingleTap:)];
    self.singleTap.delegate = self;
    self.singleTap.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:self.singleTap];
    
    freeTextViews = [[NSMutableArray alloc] init];
    
    KEY_ELEMENT = @"KEY_ELEMENTS";
    KEY_TAG = @"KEY_TAG";
    KEY_TYPE = @"KEY_TYPE";
    KEY_LABLES = @"KEY_LABELS";
    KEY_OBJECT = @"KEY_OBJECT";
}

-(void)onSingleTap:(UITapGestureRecognizer *)recognizer {
    NSLog(@"Single Tap");
    for (UITextView *textView in freeTextViews) {
        [textView resignFirstResponder];
    }
}

-(BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (gestureRecognizer == self.singleTap) {
        return YES;
    }
    return NO;
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.delegate = nil;
    }
}

//- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
//{
//    return NO;
//}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
//- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//    // Get the new view controller using [segue destinationViewController].
//    // Pass the selected object to the new view controller.
////    NSLog(@"hello");
//    if ([[segue identifier] isEqualToString:@"selectRow"]) {
//        CustomViewController *vcntl = [segue destinationViewController];    // <- 1
//        vcntl.rowNumber = [self.tableView indexPathForSelectedRow].row;    // <- 2
//    }
//}


- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    // Remove all UIView contents from super view (_mainScrollView).
    for (UIView * view in _mainScrollView.subviews) {
        [view removeFromSuperview];
    }
    totalHight = 0;
    [_mainScrollView setDelegate:self];
    [_mainScrollView setScrollEnabled:YES];
    [_mainScrollView setFrame:self.view.frame];
    
    uiElements = [[NSMutableArray alloc] init];
    
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.delegate = self;
    }

    ESMStorageHelper *helper = [[ESMStorageHelper alloc] init];
    NSArray* esms = [helper getEsmTexts];
    for (NSString *esm in esms) {
        [self addEsm:esm];
        currentTextOfEsm = esm;
        break;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
//    NSLog(@"hey");
    if (scrollView.tag == 1){
    //handle a
    }else if (scrollView.tag == 2){
    //handle b
    }else if (scrollView.tag == 3){
    }
}


/**
 * Add ESM elements
 */
// add ESM Elements by using JSON text
- (bool) addEsm:(NSString*) jsonStrOfAwareEsm {
    NSData *data = [jsonStrOfAwareEsm dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    id object = [NSJSONSerialization
                 JSONObjectWithData:data
                 options:0
                 error:&error];
    if(error) {
        /* JSON was malformed, act appropriately here */
        NSLog(@"JSON format error!");
        return NO;
    }
    
    NSArray *results = object;
//    bool quick = NO;
    int tag = 0;
    NSLog(@"====== Hello ESM !! =======");
    for (NSDictionary *dic in results) {
        //the ESM type (1-free text, 2-radio, 3-checkbox, 4-likert, 5-quick, 6-scale)
        NSNumber* type = [dic objectForKey:KEY_ESM_TYPE];
        switch ([type intValue]) {
            case 1: // free text
                NSLog(@"Add free text");
                [self addFreeTextElement:dic withTag:tag];
                break;
            case 2: // radio
                NSLog(@"Add radio");
                [self addRadioElement:dic withTag:tag];
                break;
            case 3: // checkbox
                NSLog(@"Add check box");
                [self addCheckBoxElement:dic withTag:tag];
                break;
            case 4: // likert
                NSLog(@"Add likert");
                [self addLikertScaleElement:dic withTag:tag];
                break;
            case 5: // quick
                NSLog(@"Add quick");
//                quick = YES;
                [self addQuickAnswerElement:dic withTag:tag];
                break;
            case 6: // scale
                NSLog(@"Add scale");
                [self addScaleElement:dic withTag:tag];
                break;
            case 7: //timepicker
                NSLog(@"Timer Picker");
                [self addTimePickerElement:dic withTag:tag];
                break;
            default:
            break;
        }
        [self addNullElement];
        [self addLineElement];
        tag++;
    }
    
//    if (results.count == 1 && quick){
    
//    } else {
        [self addNullElement];
        [self addSubmitButtonWithText:@"Submit"];
        [self addNullElement];
        [self addCancelButtonWithText:@"Cancel"];
        [self addNullElement];
//    }
    return YES;
}


// add Free Text
- (void) addFreeTextElement:(NSDictionary *) dic withTag:(int) tag
{
    [self addCommonContents:dic];
    UITextView * textView = [[UITextView alloc] initWithFrame:CGRectMake(mainContentRect.origin.x, totalHight, mainContentRect.size.width, mainContentRect.size.height)];
    [_mainScrollView addSubview:textView];
    [self setContentSizeWithAdditionalHeight:HIGHT_MAIN_CONTENT];
    [textView setDelegate:self];
    
    [freeTextViews addObject:textView];
    
    
//    [uiElements addObject:textView];
    NSMutableDictionary * uiElement = [[NSMutableDictionary alloc] init];
    [uiElement setObject:[NSNumber numberWithInt:tag] forKey:KEY_TAG];
    [uiElement setObject:@1 forKey:KEY_TYPE];
    NSArray * contents = [[NSArray alloc] initWithObjects:textView, nil];
    [uiElement setObject:contents forKey:KEY_ELEMENT];
    [uiElement setObject:[[NSArray alloc] init] forKey:KEY_LABLES];
    [uiElement setObject:dic forKey:KEY_OBJECT];
    
    [uiElements addObject:uiElement];
}

// add Radio Element
- (void) addRadioElement:(NSDictionary *) dic withTag:(int) tag
{
    [self addCommonContents:dic];
    
    NSMutableArray *elements = [[NSMutableArray alloc] init];
    NSMutableArray *labels = [[NSMutableArray alloc] init];
    for (NSString* buttonBoxItem in [dic objectForKey:KEY_ESM_RADIOS]) {
        UIButton *s = [[UIButton alloc] initWithFrame:CGRectMake(mainContentRect.origin.x + 10, totalHight, 30, 30)];
        [s setImage:[UIImage imageNamed:@"unselected_circle"] forState:UIControlStateNormal];
        UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(mainContentRect.origin.x + 10 + 60,
                                                                    totalHight,
                                                                    mainContentRect.size.width - 90,
                                                                    30)];
        label.tag = totalHight;
        label.adjustsFontSizeToFitWidth = YES;
        [s addTarget:self action:@selector(btnSendCommentPressed:) forControlEvents:UIControlEventTouchUpInside];
        [label setText:buttonBoxItem];
        [_mainScrollView addSubview:s];
        [_mainScrollView addSubview:label];
        [self setContentSizeWithAdditionalHeight:31+9]; // 9 is buffer.
        
        [s setTag:tag];
        
        [elements addObject:s];
        [labels addObject:label];
    }
    
    NSMutableDictionary * uiElement = [[NSMutableDictionary alloc] init];
    [uiElement setObject:[NSNumber numberWithInt:tag] forKey:KEY_TAG];
    [uiElement setObject:@2 forKey:KEY_TYPE];
    [uiElement setObject:elements forKey:KEY_ELEMENT];
    [uiElement setObject:labels forKey:KEY_LABLES];
    [uiElement setObject:dic forKey:KEY_OBJECT];
    
    [uiElements addObject:uiElement];
    
}

- (void)btnSendCommentPressed:(UIButton *) sender {
    NSInteger tag = sender.tag;
    for (NSDictionary * dic in uiElements) {
        NSNumber * tagNumber = [dic objectForKey:KEY_TAG];
        if ([tagNumber integerValue] == tag) {
            NSArray* boxes = [dic objectForKey:KEY_ELEMENT];
            for (UIButton * button in boxes) {
                [button setSelected:NO];
            }
        }
    }
    
    NSLog(@"button pushed!");
    if ([sender isSelected]) {
        [sender setImage:[UIImage imageNamed:@"unselected_circle"] forState:UIControlStateNormal];
        [sender setSelected:NO];
    } else {
        [sender setImage:[UIImage imageNamed:@"selected_circle"] forState:UIControlStateSelected];
        [sender setSelected:YES];
    }

    
    for (NSDictionary * dic in uiElements) {
        NSNumber * tagNumber = [dic objectForKey:KEY_TAG];
        if ([tagNumber integerValue] == tag) {
            NSArray* labels = [dic objectForKey:KEY_LABLES];
            for (UILabel * label in labels) {
                NSLog(@"%@ %f", label.text, label.frame.origin.y);
                // selected button's y
                double selectedButtonY = sender.frame.origin.y;
                double labelY = label.frame.origin.y;
                NSError *error = nil;
                NSString *pattern = @"Other*";
                NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];
                NSTextCheckingResult *match = [regexp firstMatchInString:label.text options:0 range:NSMakeRange(0, label.text.length)];
                NSString *matchedText = @"";
                if (match.numberOfRanges > 0) {
                    NSLog(@"matched text: %@", [label.text substringWithRange:[match rangeAtIndex:0]]);
                    matchedText = [label.text substringWithRange:[match rangeAtIndex:0]];
                }
                
                if (selectedButtonY == labelY && [matchedText isEqualToString:@"Other"]) {
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
    }
//

    
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    NSLog(@"%@",[alertView textFieldAtIndex:0].text);
    NSInteger tag = alertView.tag;
    NSString * inputText = [alertView textFieldAtIndex:0].text;
    for (NSDictionary * dic in uiElements) {
        NSNumber * tagNumber = [dic objectForKey:KEY_TAG];
        if ([tagNumber integerValue] == tag) {
            NSArray* labels = [dic objectForKey:KEY_LABLES];
            for (UILabel * label in labels) {
//                NSLog(@"%@ %f", label.text, label.frame.origin.y);
                // selected button's y
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
        }
    }

}



// add Check Box Element
- (void) addCheckBoxElement:(NSDictionary *) dic withTag:(int) tag{
    [self addCommonContents:dic];
    NSMutableArray *elements = [[NSMutableArray alloc] init];
    NSMutableArray *labels = [[NSMutableArray alloc] init];
    for (NSString* checkBoxItem in [dic objectForKey:KEY_ESM_CHECKBOXES]) {
        UIButton *s = [[UIButton alloc] initWithFrame:CGRectMake(mainContentRect.origin.x + 10 , totalHight, 30, 30)];
        [s setImage:[UIImage imageNamed:@"unchecked_box"] forState:UIControlStateNormal];
        UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(mainContentRect.origin.x + 10 + 60, totalHight, mainContentRect.size.width - 90, 30)];
        label.adjustsFontSizeToFitWidth = YES;
        [labels addObject:label];
        [s addTarget:self
              action:@selector(pushedCheckBox:)
    forControlEvents:UIControlEventTouchUpInside];
        [s setTag:tag];
        [label setText:checkBoxItem];
        [_mainScrollView addSubview:s];
        [_mainScrollView addSubview:label];
        [self setContentSizeWithAdditionalHeight:31+9]; // 9 is buffer.
        
        [elements addObject:s];
    }
    
    NSMutableDictionary * uiElement = [[NSMutableDictionary alloc] init];
    [uiElement setObject:[NSNumber numberWithInt:tag] forKey:KEY_TAG];
    [uiElement setObject:@3 forKey:KEY_TYPE];
    [uiElement setObject:elements forKey:KEY_ELEMENT];
    [uiElement setObject:labels forKey:KEY_LABLES];
    [uiElement setObject:dic forKey:KEY_OBJECT];
    
    [uiElements addObject:uiElement];
}



- (void) pushedCheckBox:(UIButton *) sender {
    NSLog(@"button pushed!");
    if ([sender isSelected]) {
        [sender setImage:[UIImage imageNamed:@"unchecked_box"] forState:UIControlStateNormal];
        [sender setSelected:NO];
    } else {
        [sender setImage:[UIImage imageNamed:@"checked_box"] forState:UIControlStateSelected];
        [sender setSelected:YES];
    }
}


// add Likert Scale Element
- (void) addLikertScaleElement:(NSDictionary *) dic withTag:(int) tag {
    [self addCommonContents:dic];
    
    NSMutableArray* elements = [[NSMutableArray alloc] init];
    NSMutableArray* labels = [[NSMutableArray alloc] init];
    
//    UILabel *minLabel = [[UILabel alloc] initWithFrame:CGRectMake(mainContentRect.origin.x,totalHight, 60, 31)];
    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(mainContentRect.origin.x+60, totalHight, mainContentRect.size.width-120, 31)];
    UILabel *maxLabel = [[UILabel alloc] initWithFrame:CGRectMake(mainContentRect.origin.x+mainContentRect.size.width -60, totalHight, 30, 31)];
    // We use a Y location as an unique ID; //TODO
    maxLabel.tag = totalHight;
    
    NSNumber *max = [dic objectForKey:KEY_ESM_LIKERT_MAX];
//    NSNumber *step = [dic objectForKey:KEY_ESM_LIKERT_STEP];
    [slider setMaximumValue: [max floatValue]];
    [slider setMinimumValue: 1];
    double curentValue = [max doubleValue] / 2.0f;
    [slider setValue:roundf(curentValue)];
    [slider setValue:0];
//    [slider setValue:[start floatValue]];
    
    [maxLabel setText:[dic objectForKey:KEY_ESM_LIKERT_MAX_LABEL]];
//    [minLabel setText:[dic objectForKey:KEY_ESM_LIKERT_MIN_LABEL]];
    
//    maxLabel.textAlignment = UITextAlignmentLeft;
//    minLabel.textAlignment = UITextAlignmentRight;
    
    [_mainScrollView addSubview:slider];
    [_mainScrollView addSubview:maxLabel];
//    [_mainScrollView addSubview:minLabel];
    
    [self setContentSizeWithAdditionalHeight:31];
    
    
    [elements addObject:slider];
    [labels addObject:maxLabel];
    
    NSMutableDictionary * uiElement = [[NSMutableDictionary alloc] init];
    [uiElement setObject:[NSNumber numberWithInt:tag] forKey:KEY_TAG];
    [uiElement setObject:@4 forKey:KEY_TYPE];
    [uiElement setObject:elements forKey:KEY_ELEMENT];
    [uiElement setObject:labels forKey:KEY_LABLES];
    [uiElement setObject:dic forKey:KEY_OBJECT];
    
    
    [uiElements addObject:uiElement];
    // add uislder event
    
    [slider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
}


- (IBAction)sliderValueChanged:(UISlider *)sender {
//    NSLog(@"slider value = %f", sender.value);
    int intValue = sender.value;
    [sender setValue:intValue];
    UILabel * label = [_mainScrollView viewWithTag:sender.frame.origin.y];
    [label setText:[NSString stringWithFormat:@"%d", intValue]];
}


// add Quick Answer Element
- (void) addQuickAnswerElement:(NSDictionary *) dic withTag:(int) tag{
    [self addCommonContents:dic];
    NSMutableArray *elements = [[NSMutableArray alloc] init];
    NSMutableArray *labels = [[NSMutableArray alloc] init];
    
    for (NSString* answers in [dic objectForKey:KEY_ESM_QUICK_ANSWERS]) {
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(mainContentRect.origin.x, totalHight, buttonRect.size.width, buttonRect.size.height)];
        [button setTitle:answers forState:UIControlStateNormal];
        [button setBackgroundColor:[UIColor lightGrayColor]];
//        [button addTarget:self action:@selector(pushedQuickAnswerButtons:) forControlEvents:UIControlEventTouchUpInside];
        [_mainScrollView addSubview:button];
        [self setContentSizeWithAdditionalHeight:buttonRect.size.height + 5];
        [elements addObject:button];
        [labels addObject:answers];
        
//        [button addTarget:self action:@selector(changeButton:) forControlEvents:UIControlEventValueChanged];
    
    }
    
    NSMutableDictionary * uiElement = [[NSMutableDictionary alloc] init];
    [uiElement setObject:[NSNumber numberWithInt:tag] forKey:KEY_TAG];
    [uiElement setObject:@5 forKey:KEY_TYPE];
    [uiElement setObject:elements forKey:KEY_ELEMENT];
    [uiElement setObject:labels forKey:KEY_LABLES];
    [uiElement setObject:dic forKey:KEY_OBJECT];
    
    [uiElements addObject:uiElement];
}


//- (void) pushedQuickAnswerButtons:(id) sender {
//    UIButton *resultButton = (UIButton *) sender;
//    NSString *title = resultButton.currentTitle;
//    
//    ESM *esm = [[ESM alloc] initWithSensorName:SENSOR_ESMS];
//    for (NSDictionary *esmDic in arrayForJson) {
//        int type = [[esmDic objectForKey:KEY_ESM_TYPE] intValue];
//        if ( type == 5 ) {
//            NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
//            NSNumber* unixtime = [NSNumber numberWithDouble:timeStamp];
//            NSMutableDictionary *dic = [self getEsmFormatDictionary:(NSMutableDictionary *)esmDic
//                                                       withTimesmap:unixtime
//                                                            devieId:[esm getDeviceId]];
//            [dic setObject:title forKey:KEY_ESM_USER_ANSWER];
//            [esm saveData:dic];
//            [esm performSelector:@selector(syncAwareDB) withObject:0 afterDelay:5];
//            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Thank for submitting your answer!" message:@"" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
//            [alert show];
//            [self.navigationController popToRootViewControllerAnimated:YES];
//            break;
//        }
//    }
//}


//add Scale Element
- (void) addScaleElement:(NSDictionary *) dic withTag:(int) tag{
    [self addCommonContents:dic];
//    UILabel *minLabel = [[UILabel alloc] initWithFrame:CGRectMake(mainContentRect.origin.x,totalHight, 60, 31)];
    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(mainContentRect.origin.x+60, totalHight, mainContentRect.size.width-120, 31)];
    UILabel *maxLabel = [[UILabel alloc] initWithFrame:CGRectMake(mainContentRect.origin.x+mainContentRect.size.width -60, totalHight, 30, 31)];
    [maxLabel setTag:totalHight];
    
    NSNumber *max = [dic objectForKey:KEY_ESM_SCALE_MAX];
    NSNumber *min = [dic objectForKey:KEY_ESM_SCALE_MIN];
    NSNumber *start = [dic objectForKey:KEY_ESM_SCALE_START];
    [slider setMaximumValue: [max floatValue] ];
    [slider setMinimumValue: [min floatValue] ];
    [slider setValue:[start floatValue]];
    
    [maxLabel setText:[dic objectForKey:KEY_ESM_SCALE_MAX_LABEL]];
//    [minLabel setText:[dic objectForKey:KEY_ESM_SCALE_MIN_LABEL]];
    
    [_mainScrollView addSubview:slider];
    [_mainScrollView addSubview:maxLabel];
//    [_mainScrollView addSubview:minLabel];
    
    [self setContentSizeWithAdditionalHeight:31];
    
    NSMutableArray * elements = [[NSMutableArray alloc] init];
    NSMutableArray * labels = [[NSMutableArray alloc] init];
    NSMutableDictionary * uiElement = [[NSMutableDictionary alloc] init];
    [elements addObject:slider];
    [labels addObject:maxLabel];
    [uiElement setObject:[NSNumber numberWithInt:tag] forKey:KEY_TAG];
    [uiElement setObject:@6 forKey:KEY_TYPE];
    [uiElement setObject:elements forKey:KEY_ELEMENT];
    [uiElement setObject:labels forKey:KEY_LABLES];
    [uiElement setObject:dic forKey:KEY_OBJECT];
    
    [uiElements addObject:uiElement];
    [slider addTarget:self action:@selector(sliderChanged:) forControlEvents:UIControlEventValueChanged];
}


- (IBAction)sliderChanged:(UISlider *)sender {
//    NSLog(@"slider value = %f", sender.value);
    int intValue = sender.value;
    [sender setValue:intValue];
    UILabel * label = [_mainScrollView viewWithTag:sender.frame.origin.y];
    [label setText:[NSString stringWithFormat:@"%d", intValue]];
}

// TODO
- (void) addTimePickerElement:(NSDictionary *)dic withTag:(int) tag{
    [self addCommonContents:dic];
    UIDatePicker * datePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(mainContentRect.origin.x, totalHight, mainContentRect.size.width, 100)];
    datePicker.datePickerMode = UIDatePickerModeTime;
    [_mainScrollView addSubview:datePicker];
    [self setContentSizeWithAdditionalHeight:100];
    
    NSMutableArray * elements = [[NSMutableArray alloc] init];
    NSMutableArray * labels = [[NSMutableArray alloc] init];
    [elements addObject:datePicker];
    NSMutableDictionary * uiElement = [[NSMutableDictionary alloc] init];
    [uiElement setObject:[NSNumber numberWithInt:tag] forKey:KEY_TAG];
    [uiElement setObject:@7 forKey:KEY_TYPE];
    [uiElement setObject:elements forKey:KEY_ELEMENT];
    [uiElement setObject:labels forKey:KEY_LABLES];
    [uiElement setObject:dic forKey:KEY_OBJECT];
    
    [uiElements addObject:uiElement];
}




- (void) addNullElement {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, totalHight, WIDTH_VIEW, HIGHT_SPACE)];
//    [view setBackgroundColor:[UIColor grayColor]];
    [_mainScrollView addSubview:view];
    [self setContentSizeWithAdditionalHeight:HIGHT_SPACE];
}

- (void) addLineElement {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(lineRect.origin.x, totalHight, lineRect.size.width, lineRect.size.height)];
    [view setBackgroundColor:[UIColor lightTextColor]];
//    [view setBackgroundColor:[UIColor lightGrayColor]];
    [_mainScrollView addSubview:view];
    [self setContentSizeWithAdditionalHeight:lineRect.size.height];
}

/**
 * Add common contents in the ESM view
 */
- (void) addCommonContents:(NSDictionary *) dic {
    //  make each content
    [self addTitleWithText:[dic objectForKey:KEY_ESM_TITLE]];
    [self addInstructionsWithText:[dic objectForKey:KEY_ESM_INSTRUCTIONS]];
}

- (void) addTitleWithText:(NSString *) title {
    if (![title isEqualToString:@""]) {
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(titleRect.origin.x, totalHight, titleRect.size.width, titleRect.size.height)];
        [titleLabel setText:title];
        titleLabel.font = [titleLabel.font fontWithSize:25];
        titleLabel.numberOfLines = 5;
        titleLabel.adjustsFontSizeToFitWidth = YES;
        [_mainScrollView addSubview:titleLabel];
        [self setContentSizeWithAdditionalHeight:HIGHT_TITLE];
    }
}

- (void) addInstructionsWithText:(NSString*) text {
    if (![text isEqualToString:@""]) {
        UILabel *instructionsLabel = [[UILabel alloc] initWithFrame:CGRectMake(instructionRect.origin.x, totalHight, instructionRect.size.width, instructionRect.size.height)];
        [instructionsLabel setText:text];
        //    [instructionsLabel setBackgroundColor:[UIColor redColor]];
        instructionsLabel.numberOfLines = 5;
        instructionsLabel.adjustsFontSizeToFitWidth = YES;
        [_mainScrollView addSubview:instructionsLabel];
        [self setContentSizeWithAdditionalHeight:HIGHT_INSTRUCTION];
    }
}



- (void) addCancelButtonWithText:(NSString*)text {
    UIButton *cancelBtn = [[UIButton alloc] initWithFrame:CGRectMake(buttonRect.origin.x, totalHight, buttonRect.size.width, buttonRect.size.height)];
    [cancelBtn setTitle:text forState:UIControlStateNormal];
//    [cancelBtn setBackgroundColor:[UIColor grayColor]];
    cancelBtn.layer.borderColor = [UIColor whiteColor].CGColor;
    cancelBtn.layer.borderWidth = 2;
    [_mainScrollView addSubview:cancelBtn];
    [self setContentSizeWithAdditionalHeight:HIGHT_BUTTON];
    [cancelBtn addTarget:self action:@selector(pushedCancelButton:) forControlEvents:UIControlEventTouchUpInside];
}



- (void) pushedSubmitButton:(id) senser {
    NSLog(@"Submit button was pushed!");
    
    NSMutableArray *array = [[NSMutableArray alloc] init];
    ESM *esm = [[ESM alloc] initWithSensorName:SENSOR_ESMS];
    
    NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
    NSNumber* unixtime = [NSNumber numberWithDouble:timeStamp];
    
    for (int i=0; i<uiElements.count; i++) {
        NSDictionary *esmDic = [[uiElements objectAtIndex:i] objectForKey:KEY_OBJECT];
        NSArray * contents = [[uiElements objectAtIndex:i] objectForKey:KEY_ELEMENT];
        NSArray * labels = [[uiElements objectAtIndex:i] objectForKey:KEY_LABLES];
        
        NSMutableDictionary *dic = [self getEsmFormatDictionary:(NSMutableDictionary *)esmDic
                                                   withTimesmap:unixtime
                                                        devieId:[esm getDeviceId]];
        // add special data to dic from each uielements
        NSNumber* type = [esmDic objectForKey:KEY_ESM_TYPE];
        // save each data to the dictionary
        if ([type isEqualToNumber:@1]) {
            NSLog(@"Get free text data.");
            for (UITextView * textView  in contents) {
                [dic setObject:textView.text forKey:KEY_ESM_USER_ANSWER];
                NSLog(@"Value is = %@", textView.text);
            }
        } else if ([type isEqualToNumber:@2]) {
            NSLog(@"Get radio data.");
            if (contents != nil) {
                for (int i=0; i<contents.count; i++) {
                    UIButton * button = [contents objectAtIndex:i];
                    UILabel * label = [labels objectAtIndex:i];
                    if(button.selected) {
                        [dic setObject:label.text forKey:KEY_ESM_USER_ANSWER];
                    }
                }
            }
        } else if ([type isEqualToNumber:@3]) {
            NSLog(@"Get check box data.");
            if (contents != nil) {
                NSString *result = @"";
                for (int i=0; i<contents.count; i++) {
                    UIButton * button = [contents objectAtIndex:i];
                    UILabel * label = [labels objectAtIndex:i];
                    if (button.selected) {
                        result = [NSString stringWithFormat:@"%@,%@", result , label.text];
                    }
                }
                [dic setObject:result forKey:KEY_ESM_USER_ANSWER];
            }
        } else if ([type isEqualToNumber:@4]) {
            NSLog(@"Get likert data");
            if (contents != nil) {
                for (UISlider * slider in contents) {
                    [dic setObject:[NSNumber numberWithFloat:slider.value] forKey:KEY_ESM_USER_ANSWER];
                }
            }
        } else if ([type isEqualToNumber:@5]) {
            NSLog(@"Get Quick button data");
        } else if ([type isEqualToNumber:@6]) {
            NSLog(@"Get Scale data");
            if (contents != nil) {
                for (UISlider * slider in contents) {
                    NSNumber * number = [NSNumber numberWithFloat:slider.value];
                    NSLog(@"%@", number);
                    [dic setObject:number forKey:KEY_ESM_USER_ANSWER];
                }
            }
        } else {

        }
        [array addObject:dic];
    }

    bool result = [esm saveDataWithArray:array];
    
    if ( result ) {
        [esm performSelector:@selector(syncAwareDB) withObject:0 afterDelay:5];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Thank for submitting your answer!" message:@"" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        
        
        ESMStorageHelper * helper = [[ESMStorageHelper alloc] init];
        [helper removeEsmWithText:currentTextOfEsm];
        
        if([helper getEsmTexts].count > 0){
//            [self viewDidLoad] //TODO
            [self viewDidAppear:NO];
            return ;
        }
        
        CGFloat currentVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
        if (currentVersion >= 9.0) {
//            [self.navigationController.navigationBar setDelegate:self];
            [self.navigationController popToRootViewControllerAnimated:YES];
        } else{
            [self dismissViewControllerAnimated:YES completion:nil];
        }
       
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"AWARE can not save your answer" message:@"Please push submit button again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}


- (NSMutableDictionary *) getEsmFormatDictionary:(NSMutableDictionary *)originalDic
                                    withTimesmap:(NSNumber *)unixtime
                                         devieId:(NSString*) deviceId{
    // make base dictionary from SingleEsmObject with device ID and timestamp
    SingleESMObject *singleObject = [[SingleESMObject alloc] init];
    NSMutableDictionary * dic = [singleObject getEsmDictionaryWithDeviceId:deviceId
                                                                 timestamp:[unixtime doubleValue]
                                                                      type:@0
                                                                     title:@""
                                                              instructions:@""
                                                       expirationThreshold:@0
                                                                   trigger:@""];
    // add existing data to base dictionary of an esm
    for (id key in [originalDic keyEnumerator]) {
        NSLog(@"Key: %@ => Value:%@" , key, [originalDic objectForKey:key]);
        if([key isEqualToString:KEY_ESM_RADIOS]){
            [dic setObject:[self convertArrayToCSVFormat:[originalDic objectForKey:key]] forKey:KEY_ESM_RADIOS];
        }else if([key isEqualToString:KEY_ESM_CHECKBOXES]){
            [dic setObject:[self convertArrayToCSVFormat:[originalDic objectForKey:key]] forKey:KEY_ESM_CHECKBOXES];
        }else if([key isEqualToString:KEY_ESM_QUICK_ANSWERS]){
            [dic setObject:[self convertArrayToCSVFormat:[originalDic objectForKey:key]] forKey:KEY_ESM_QUICK_ANSWERS];
        }else{
            NSObject *object = [originalDic objectForKey:key];
            if (object == nil) {
                object = @"";
            }
            [dic setObject:object forKey:key];
        }
    }
    return dic;
}

- (NSString* ) convertArrayToCSVFormat:(NSArray *) array {
    if (array == nil || array.count == 0){
        return @"";
    }
    NSMutableString* csvStr = [[NSMutableString alloc] init];
    for (NSString * item in array) {
        [csvStr appendString:item];
        [csvStr appendString:@","];
    }
    NSRange rangeOfExtraText = [csvStr rangeOfString:@"," options:NSBackwardsSearch];
    if (rangeOfExtraText.location == NSNotFound) {
    }else{
        NSRange deleteRange = NSMakeRange(rangeOfExtraText.location, csvStr.length-rangeOfExtraText.location);
        [csvStr deleteCharactersInRange:deleteRange];
    }
    if (csvStr == nil) {
        return @"";
    }
    return csvStr;
}

- (void) addSubmitButtonWithText:(NSString*) text
{
    UIButton *submitBtn = [[UIButton alloc] initWithFrame:CGRectMake(buttonRect.origin.x, totalHight, buttonRect.size.width, buttonRect.size.height)];
    [submitBtn setTitle:text forState:UIControlStateNormal];
    [submitBtn setBackgroundColor:[UIColor grayColor]];
    [_mainScrollView addSubview:submitBtn];
    [self setContentSizeWithAdditionalHeight:HIGHT_BUTTON];
    [submitBtn setTag:0];
    [submitBtn addTarget:self action:@selector(pushedSubmitButton:) forControlEvents:UIControlEventTouchUpInside];
}

- (void) pushedCancelButton:(id) senser
{
    NSLog(@"Cancel button was pushed!");
    CGFloat currentVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (currentVersion >= 9.0) {
        [self.navigationController popToRootViewControllerAnimated:YES];
    } else{
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}


- (void) setContentSizeWithAdditionalHeight:(int) additionalHeight
{
    totalHight += additionalHeight;
    [_mainScrollView setContentSize:CGSizeMake(WIDTH_VIEW, totalHight)];
}


@end
