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

NSString* const KEY_ESM_TYPE = @"esm_type";
NSString* const KEY_ESM_TITLE = @"esm_title";
NSString* const KEY_ESM_SUBMIT = @"esm_submit";
NSString* const KEY_ESM_INSTRUCTIONS = @"esm_instructions";
NSString* const KEY_ESM_RADIOS = @"esm_radios";
NSString* const KEY_ESM_CHECKBOXES = @"esm_checkboxes";
NSString* const KEY_ESM_LIKERT_MAX = @"esm_likert_max";
NSString* const KEY_ESM_LIKERT_MAX_LABEL = @"esm_likert_max_label";
NSString* const KEY_ESM_LIKERT_MIN_LABEL = @"esm_likert_min_label";
NSString* const KEY_ESM_LIKERT_STEP = @"esm_likert_step";
NSString* const KEY_ESM_QUICK_ANSWERS = @"esm_quick_answers";
NSString* const KEY_ESM_EXPIRATION_THRESHOLD = @"esm_expiration_threshold";
NSString* const KEY_ESM_STATUS = @"esm_status";
NSString* const KEY_DOUBLE_ESM_USER_ANSWER_TIMESTAMP = @"double_esm_user_answer_timestamp";
NSString* const KEY_ESM_USER_ANSWER = @"esm_user_answer";
NSString* const KEY_ESM_TRIGGER = @"esm_trigger";
NSString* const KEY_ESM_SCALE_MIN = @"esm_scale_min";
NSString* const KEY_ESM_SCALE_MAX = @"esm_scale_max";
NSString* const KEY_ESM_SCALE_START = @"esm_scale_start";
NSString* const KEY_ESM_SCALE_MAX_LABEL = @"esm_scale_max_label";
NSString* const KEY_ESM_SCALE_MIN_LABEL = @"esm_scale_min_label";
NSString* const KEY_ESM_SCALE_STEP = @"esm_scale_step";

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
    NSArray *arrayForJson;
    NSMutableArray *uiElements;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    WIDTH_VIEW = self.view.frame.size.width;
    HIGHT_TITLE = 40;
    HIGHT_INSTRUCTION = 80;
    HIGHT_MAIN_CONTENT = 100;
    HIGHT_BUTTON = 60;
    HIGHT_SPACE = 20;
    HIGHT_LINE = 2;
    
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
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    NSLog(@"hello");
}


- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [_mainScrollView setDelegate:self];
    [_mainScrollView setScrollEnabled:YES];
    [_mainScrollView setFrame:self.view.frame];
    
    
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.delegate = self;
    }
    
    uiElements = [[NSMutableArray alloc] init];
    
    // free text
    NSMutableDictionary *dicForJson = [[NSMutableDictionary alloc] init];
    [dicForJson setObject:@1 forKey:KEY_ESM_TYPE];
    [dicForJson setObject:@"ESM Freetext" forKey:KEY_ESM_TITLE];
    [dicForJson setObject:@"The user can answer an open ended question." forKey:KEY_ESM_INSTRUCTIONS];
    [dicForJson setObject:@"next" forKey:KEY_ESM_SUBMIT];
    [dicForJson setObject:@60 forKey:KEY_ESM_EXPIRATION_THRESHOLD];
    [dicForJson setObject:@"AWARE Tester" forKey:KEY_ESM_TRIGGER];
    
    // radio
    NSMutableDictionary *dicRadio = [[NSMutableDictionary alloc] init];
    [dicRadio setObject:@2 forKey:KEY_ESM_TYPE];
    [dicRadio setObject:@"ESM Radio" forKey:KEY_ESM_TITLE];
    [dicRadio setObject:@"he user can only choose one option" forKey:KEY_ESM_INSTRUCTIONS];
    [dicRadio setObject:[NSArray arrayWithObjects:@"Aston Martin", @"Lotus", @"Jaguar", nil] forKey:KEY_ESM_RADIOS];
    [dicRadio setObject:@"Next" forKey:KEY_ESM_SUBMIT];
    [dicRadio setObject:@60 forKey:KEY_ESM_EXPIRATION_THRESHOLD];
    [dicRadio setObject:@"AWARE Tester" forKey:KEY_ESM_TRIGGER];
    
    // check box
    NSMutableDictionary *dicCheckBox = [[NSMutableDictionary alloc] init];
    [dicCheckBox setObject:@3 forKey:KEY_ESM_TYPE];
    [dicCheckBox setObject:@"ESM Checkbox" forKey:KEY_ESM_TITLE];
    [dicCheckBox setObject:@"The user can choose multiple options" forKey:KEY_ESM_INSTRUCTIONS];
    [dicCheckBox setObject:[NSArray arrayWithObjects:@"One", @"Two", @"Three", nil] forKey:KEY_ESM_CHECKBOXES];
    [dicCheckBox setObject:@"Next" forKey:KEY_ESM_SUBMIT];
    [dicCheckBox setObject:@60 forKey:KEY_ESM_EXPIRATION_THRESHOLD];
    [dicCheckBox setObject:@"AWARE Tester" forKey:KEY_ESM_TRIGGER];
    
    
    // Likert scale
    NSMutableDictionary *dicLikert = [[NSMutableDictionary alloc] init];
    [dicLikert  setObject:@4 forKey:KEY_ESM_TYPE];
    [dicLikert  setObject:@"ESM Likert" forKey:KEY_ESM_TITLE];
    [dicLikert  setObject:@"User rating 1 to 5 or 7 at 1 step increments" forKey:KEY_ESM_INSTRUCTIONS];
    [dicLikert setObject:@5 forKey:KEY_ESM_LIKERT_MAX];
    [dicLikert setObject:@"Great" forKey:KEY_ESM_LIKERT_MAX_LABEL];
    [dicLikert setObject:@"Bad" forKey:KEY_ESM_LIKERT_MIN_LABEL];
    [dicLikert setObject:@1 forKey:KEY_ESM_LIKERT_STEP];
    [dicLikert  setObject:@"Next" forKey:KEY_ESM_SUBMIT];
    [dicLikert  setObject:@60 forKey:KEY_ESM_EXPIRATION_THRESHOLD];
    [dicLikert  setObject:@"AWARE Tester" forKey:KEY_ESM_TRIGGER];

    // quick
    NSMutableDictionary *dicQuick = [[NSMutableDictionary alloc] init];
    [dicQuick  setObject:@5 forKey:KEY_ESM_TYPE];
    [dicQuick  setObject:@"ESM Quick Answer" forKey:KEY_ESM_TITLE];
    [dicQuick  setObject:@"One touch answer" forKey:KEY_ESM_INSTRUCTIONS];
    [dicQuick  setObject:[NSArray arrayWithObjects:@"Yes", @"No", @"Maybe", nil] forKey:KEY_ESM_QUICK_ANSWERS];
    [dicQuick  setObject:@60 forKey:KEY_ESM_EXPIRATION_THRESHOLD];
    [dicQuick  setObject:@"AWARE Tester" forKey:KEY_ESM_TRIGGER];

    
    // scale
    NSMutableDictionary *dicScale = [[NSMutableDictionary alloc] init];
    [dicScale  setObject:@6 forKey:KEY_ESM_TYPE];
    [dicScale  setObject:@"ESM Scale" forKey:KEY_ESM_TITLE];
    [dicScale  setObject:@"Between 0 and 10 with 2 increments" forKey:KEY_ESM_INSTRUCTIONS];
    [dicScale  setObject:@0 forKey:KEY_ESM_SCALE_MIN];
    [dicScale  setObject:@10 forKey:KEY_ESM_SCALE_MAX];
    [dicScale  setObject:@0 forKey:KEY_ESM_SCALE_START];
    [dicScale setObject:@"10" forKey:KEY_ESM_SCALE_MAX_LABEL];
    [dicScale setObject:@"0" forKey:KEY_ESM_SCALE_MIN_LABEL];
    [dicScale setObject:@2 forKey:KEY_ESM_SCALE_STEP];
    [dicScale setObject:@"OK" forKey:KEY_ESM_SUBMIT];
    [dicScale  setObject:@60 forKey:KEY_ESM_EXPIRATION_THRESHOLD];
    [dicScale  setObject:@"AWARE Tester" forKey:KEY_ESM_TRIGGER];

    
    arrayForJson = [[NSArray alloc] initWithObjects:dicForJson, dicRadio, dicCheckBox,dicLikert, dicQuick, dicScale, nil];
//    arrayForJson = [[NSArray alloc] initWithObjects: dicForJson, dicRadio,  nil];
    NSData *data = [NSJSONSerialization dataWithJSONObject:arrayForJson options:0 error:nil];
    NSString* jsonStr =  [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [self addEsm:jsonStr];
    
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
 * View control element
 */
- (void) showEsm
{
    
}

- (void) hidenEsm
{
    
}

- (void) removeEmss
{
    
}


/**
 * Add ESM elements
 */
// add ESM Elements by using JSON text
- (bool) addEsm:(NSString*) jsonStrOfAwareEsm
{
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
    bool quick = NO;
    NSLog(@"====== Hello ESM !! =======");
    for (NSDictionary *dic in results) {
        //the ESM type (1-free text, 2-radio, 3-checkbox, 4-likert, 5-quick, 6-scale)
        NSNumber* type = [dic objectForKey:KEY_ESM_TYPE];
        switch ([type intValue]) {
            case 1: // free text
            NSLog(@"Add free text");
            [self addFreeTextElement:dic];
            break;
            case 2: // radio
            NSLog(@"Add radio");
            [self addRadioElement:dic];
            break;
            case 3: // checkbox
            NSLog(@"Add check box");
            [self addCheckBoxElement:dic];
            break;
            case 4: // likert
            NSLog(@"Add likert");
            [self addLikertScaleElement:dic];
            break;
            case 5: // quick
            NSLog(@"Add quick");
            quick = YES;
            [self addQuickAnswerElement:dic];
            break;
            case 6: // scale
            NSLog(@"Add scale");
            [self addScaleElement:dic];
            break;
            default:
            break;
        }
        [self addNullElement];
        [self addLineElement];
    }
    
    if (results.count == 1 && quick){
    
    } else {
        [self addNullElement];
        [self addSubmitButtonWithText:@"Submit"];
        [self addNullElement];
        [self addCancelButtonWithText:@"Cancel"];
        [self addNullElement];
    }
    
    return YES;
}


// add Free Text
- (void) addFreeTextElement:(NSDictionary *) dic
{
    [self addCommonContents:dic];
    UITextView * textView = [[UITextView alloc] initWithFrame:CGRectMake(mainContentRect.origin.x, totalHight, mainContentRect.size.width, mainContentRect.size.height)];
    [_mainScrollView addSubview:textView];
    [self setContentSizeWithAdditionalHeight:HIGHT_MAIN_CONTENT];
    [textView setDelegate:self];
    
    [freeTextViews addObject:textView];
    [uiElements addObject:textView];
}

// add Radio Element
- (void) addRadioElement:(NSDictionary *) dic
{
    [self addCommonContents:dic];
    UISegmentedControl *segmentView = [[UISegmentedControl alloc] initWithItems:[dic objectForKey:KEY_ESM_RADIOS]];
    [segmentView setFrame:CGRectMake(mainContentRect.origin.x, totalHight, mainContentRect.size.width, mainContentRect.size.height)];
    [_mainScrollView addSubview:segmentView];
    [self setContentSizeWithAdditionalHeight:mainContentRect.size.height];
    
    [uiElements addObject:segmentView];
}

// add Check Box Element
- (void) addCheckBoxElement:(NSDictionary *) dic
{
    [self addCommonContents:dic];
    NSMutableArray *elements = [[NSMutableArray alloc] init];
    for (NSString* checkBoxItem in [dic objectForKey:KEY_ESM_CHECKBOXES]) {
        UISwitch *s = [[UISwitch alloc] initWithFrame:CGRectMake(mainContentRect.origin.x + 30 , totalHight, 49, 31)];
        UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(mainContentRect.origin.x + 30 + 60, totalHight, mainContentRect.size.width - 60, 31)];
        [label setText:checkBoxItem];
        [_mainScrollView addSubview:s];
        [_mainScrollView addSubview:label];
        [self setContentSizeWithAdditionalHeight:31+9];
        
        [elements addObject:s];
    }
    [uiElements addObject:elements];
}

// add Likert Scale Element
- (void) addLikertScaleElement:(NSDictionary *) dic
{
    [self addCommonContents:dic];
    UILabel *maxLabel = [[UILabel alloc] initWithFrame:CGRectMake(mainContentRect.origin.x,totalHight, 60, 31)];
    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(mainContentRect.origin.x+60, totalHight, mainContentRect.size.width-120, 31)];
    UILabel *minLabel = [[UILabel alloc] initWithFrame:CGRectMake(mainContentRect.origin.x+mainContentRect.size.width -60, totalHight, 30, 31)];
    
    NSNumber *max = [dic objectForKey:KEY_ESM_LIKERT_MAX];
//    NSNumber *step = [dic objectForKey:KEY_ESM_LIKERT_STEP];
    [slider setMaximumValue: [max floatValue]];
//    [slider setValue:[start floatValue]];
    
    [maxLabel setText:[dic objectForKey:KEY_ESM_LIKERT_MAX_LABEL]];
    [minLabel setText:[dic objectForKey:KEY_ESM_LIKERT_MIN_LABEL]];
    
    maxLabel.textAlignment = UITextAlignmentLeft;
    minLabel.textAlignment = UITextAlignmentRight;
    
    [_mainScrollView addSubview:slider];
    [_mainScrollView addSubview:maxLabel];
    [_mainScrollView addSubview:minLabel];
    
    [self setContentSizeWithAdditionalHeight:31];
    
    [uiElements addObject:slider];
}

// add Quick Answer Element
- (void) addQuickAnswerElement:(NSDictionary *) dic
{
    [self addCommonContents:dic];
    NSMutableArray *elements = [[NSMutableArray alloc] init];
    for (NSString* answers in [dic objectForKey:KEY_ESM_QUICK_ANSWERS]) {
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(mainContentRect.origin.x, totalHight, buttonRect.size.width, buttonRect.size.height)];
        [button setTitle:answers forState:UIControlStateNormal];
        [button setBackgroundColor:[UIColor lightGrayColor]];
        [button addTarget:self action:@selector(pushedQuickAnswerButtons:) forControlEvents:UIControlEventTouchUpInside];
        [_mainScrollView addSubview:button];
        [self setContentSizeWithAdditionalHeight:buttonRect.size.height + 5];
        [elements addObject:button];
    }
    [uiElements addObject:elements];
}

- (void) pushedQuickAnswerButtons:(id) sender
{
    UIButton *resultButton = (UIButton *) sender;
    NSString *title = resultButton.currentTitle;
    
    ESM *esm = [[ESM alloc] initWithSensorName:SENSOR_ESMS];
    for (NSDictionary *esmDic in arrayForJson) {
        int type = [[esmDic objectForKey:KEY_ESM_TYPE] intValue];
        if ( type == 5 ) {
            NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
            NSNumber* unixtime = [NSNumber numberWithDouble:timeStamp];
            NSMutableDictionary *dic = [self getEsmFormatDictionary:(NSMutableDictionary *)esmDic
                                                       withTimesmap:unixtime
                                                            devieId:[esm getDeviceId]];
            [dic setObject:title forKey:KEY_ESM_USER_ANSWER];
            [esm saveData:dic];
            [esm performSelector:@selector(syncAwareDB) withObject:0 afterDelay:5];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Thank for submitting your answer!" message:@"" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
            [self.navigationController popToRootViewControllerAnimated:YES];
            break;
        }
    }
}

//add Scale Element
- (void) addScaleElement:(NSDictionary *) dic
{
    [self addCommonContents:dic];
    UILabel *maxLabel = [[UILabel alloc] initWithFrame:CGRectMake(mainContentRect.origin.x,totalHight, 60, 31)];
    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(mainContentRect.origin.x+60, totalHight, mainContentRect.size.width-120, 31)];
    UILabel *minLabel = [[UILabel alloc] initWithFrame:CGRectMake(mainContentRect.origin.x+mainContentRect.size.width -60, totalHight, 30, 31)];
    
    NSNumber *max = [dic objectForKey:KEY_ESM_SCALE_MAX];
    NSNumber *min = [dic objectForKey:KEY_ESM_SCALE_MIN];
    NSNumber *start = [dic objectForKey:KEY_ESM_SCALE_START];
    [slider setMaximumValue: [max floatValue] ];
    [slider setMinimumValue: [min floatValue] ];
    [slider setValue:[start floatValue]];
    
    [maxLabel setText:[dic objectForKey:KEY_ESM_SCALE_MAX_LABEL]];
    [minLabel setText:[dic objectForKey:KEY_ESM_SCALE_MIN_LABEL]];
    
    maxLabel.textAlignment = UITextAlignmentLeft;
    minLabel.textAlignment = UITextAlignmentRight;
    
    [_mainScrollView addSubview:slider];
    [_mainScrollView addSubview:maxLabel];
    [_mainScrollView addSubview:minLabel];
    
    [self setContentSizeWithAdditionalHeight:31];
    
    [uiElements addObject:slider];
}


- (void) addNullElement
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, totalHight, WIDTH_VIEW, HIGHT_SPACE)];
//    [view setBackgroundColor:[UIColor grayColor]];
    [_mainScrollView addSubview:view];
    [self setContentSizeWithAdditionalHeight:HIGHT_SPACE];
}

- (void) addLineElement
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(lineRect.origin.x, totalHight, lineRect.size.width, lineRect.size.height)];
    [view setBackgroundColor:[UIColor lightTextColor]];
    [_mainScrollView addSubview:view];
    [self setContentSizeWithAdditionalHeight:lineRect.size.height];
}

/**
 * Add common contents in the ESM view
 */
- (void) addCommonContents:(NSDictionary *) dic
{
    //  make each content
    [self addTitleWithText:[dic objectForKey:KEY_ESM_TITLE]];
    [self addInstructionsWithText:[dic objectForKey:KEY_ESM_INSTRUCTIONS]];
}

- (void) addTitleWithText:(NSString *) title
{
//    NSLog(@"%d  %d", WIDTH_VIEW, HIGHT_TITLE);
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(titleRect.origin.x, totalHight, titleRect.size.width, titleRect.size.height)];
    [titleLabel setText:title];
//    [titleLabel setBackgroundColor:[UIColor blueColor]];
    titleLabel.font = [titleLabel.font fontWithSize:25];
    [_mainScrollView addSubview:titleLabel];
    [self setContentSizeWithAdditionalHeight:HIGHT_TITLE];
}

- (void) addInstructionsWithText:(NSString*) text
{
    UILabel *instructionsLabel = [[UILabel alloc] initWithFrame:CGRectMake(instructionRect.origin.x, totalHight, instructionRect.size.width, instructionRect.size.height)];
    [instructionsLabel setText:text];
//    [instructionsLabel setBackgroundColor:[UIColor redColor]];
    instructionsLabel.numberOfLines = 3;
    [_mainScrollView addSubview:instructionsLabel];
    [self setContentSizeWithAdditionalHeight:HIGHT_INSTRUCTION];
}

- (void) addCancelButtonWithText:(NSString*)text
{
    UIButton *cancelBtn = [[UIButton alloc] initWithFrame:CGRectMake(buttonRect.origin.x, totalHight, buttonRect.size.width, buttonRect.size.height)];
    [cancelBtn setTitle:text forState:UIControlStateNormal];
//    [cancelBtn setBackgroundColor:[UIColor grayColor]];
    cancelBtn.layer.borderColor = [UIColor whiteColor].CGColor;
    cancelBtn.layer.borderWidth = 2;
    [_mainScrollView addSubview:cancelBtn];
    [self setContentSizeWithAdditionalHeight:HIGHT_BUTTON];
    [cancelBtn addTarget:self action:@selector(pushedCancelButton:) forControlEvents:UIControlEventTouchUpInside];
}

- (void) pushedSubmitButton:(id) senser
{
    NSLog(@"Submit button was pushed!");
    
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    ESM *esm = [[ESM alloc] initWithSensorName:SENSOR_ESMS];
    NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
    NSNumber* unixtime = [NSNumber numberWithDouble:timeStamp];
    for (int i=0; i<arrayForJson.count; i++) {
        NSDictionary *esmDic = [arrayForJson objectAtIndex:i];
        
        NSMutableDictionary *dic = [self getEsmFormatDictionary:(NSMutableDictionary *)esmDic
                                                   withTimesmap:unixtime
                                                        devieId:[esm getDeviceId]];
        // add common data to dic
        [dic setObject:[esmDic objectForKey:KEY_ESM_TITLE] forKey:KEY_ESM_TITLE];
        [dic setObject:[esmDic objectForKey:KEY_ESM_INSTRUCTIONS] forKey:KEY_ESM_INSTRUCTIONS];
        [dic setObject:[esmDic objectForKey:KEY_ESM_TYPE] forKey:KEY_ESM_TYPE];
        [dic setObject:[esmDic objectForKey:KEY_ESM_EXPIRATION_THRESHOLD] forKey:KEY_ESM_EXPIRATION_THRESHOLD];
        [dic setObject:[esmDic objectForKey:KEY_ESM_TRIGGER] forKey:KEY_ESM_TRIGGER];
//        [dic setObject:[esmDic objectForKey:KEY_ESM_SUBMIT] forKey:KEY_ESM_SUBMIT];
        // add special data to dic from each uielements
        NSNumber* type = [esmDic objectForKey:KEY_ESM_TYPE];
        if ([type isEqualToNumber:@1]) {
            NSLog(@"Get free text data.");
            UITextView *view = [uiElements objectAtIndex:i];
            if (view.text != nil) {
                [dic setObject:view.text forKey:KEY_ESM_USER_ANSWER];
            }
            NSLog(view.text);
        } else if ([type isEqualToNumber:@2]) {
            NSLog(@"Get radio data.");
            UISegmentedControl * radioButton = [uiElements objectAtIndex:i];
            NSUInteger selected =  radioButton.selectedSegmentIndex;
            if (selected != -1) {
                NSArray * buttons = [esmDic objectForKey:KEY_ESM_RADIOS];
                NSString * selecteButtonName = [buttons objectAtIndex:radioButton.selectedSegmentIndex];
                [dic setObject:selecteButtonName forKey:KEY_ESM_USER_ANSWER];
//                NSLog(@"---> The button name is %@", selecteButtonName);
            }
        } else if ([type isEqualToNumber:@3]) {
            NSLog(@"Get check box data.");
            NSArray * checkBoxs = [uiElements objectAtIndex:i];
            NSArray * names = [esmDic objectForKey:KEY_ESM_CHECKBOXES];
//            NSMutableArray *selectedNames = [[NSMutableArray alloc] init];
            NSMutableString* selectedNames = [[NSMutableString alloc] init];
            for (int si=0; si<checkBoxs.count; si++) {
                UISwitch * s = [checkBoxs objectAtIndex:si];
                bool state = s.on;
                if (state) {
                    [selectedNames appendString:[names objectAtIndex:si]];
                    [selectedNames appendString:@","];
                }
            }
            NSRange rangeOfExtraText = [selectedNames rangeOfString:@"," options:NSBackwardsSearch];
            if (rangeOfExtraText.location == NSNotFound) {
                //            NSLog(@"[TAIL] There is no extra text");
            }else{
                //            NSLog(@"[TAIL] There is some extra text!");
                NSRange deleteRange = NSMakeRange(rangeOfExtraText.location, selectedNames.length-rangeOfExtraText.location);
//                NSLog(@"Before: %@", selectedNames);
                [selectedNames deleteCharactersInRange:deleteRange];
//                NSLog(@"After: %@", selectedNames);
            }
            
            [dic setObject:selectedNames forKey:KEY_ESM_USER_ANSWER];
//            NSLog(@"%@", dic);
        } else if ([type isEqualToNumber:@4]) {
            NSLog(@"Get likert data");
            UISlider * slider = [uiElements objectAtIndex:i];
            int value = (int) slider.value;
            [dic setObject:[NSString stringWithFormat:@"%d", value]  forKey:KEY_ESM_USER_ANSWER];
        } else if ([type isEqualToNumber:@5]) {
            NSLog(@"Get Quick button data");
        } else if ([type isEqualToNumber:@6]) {
            NSLog(@"Get Scale data");
            UISlider * slider = [uiElements objectAtIndex:i];
            int value = (int)slider.value;
            [dic setObject:[NSString stringWithFormat:@"%d", value] forKey:KEY_ESM_USER_ANSWER];
        } else {
            
        }
        [array addObject:dic];
    }
    
    bool result = [esm saveDataWithArray:array];
    if ( result ) {
        [esm performSelector:@selector(syncAwareDB) withObject:0 afterDelay:5];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Thank for submitting your answer!" message:@"" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        [self.navigationController popToRootViewControllerAnimated:YES];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"AWARE can not save your answer" message:@"Please push submit button again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}


- (NSMutableDictionary *) getEsmFormatDictionary:(NSMutableDictionary *)originalDic
                                    withTimesmap:(NSNumber *)unixtime
                                         devieId:(NSString*) deviceId{
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setObject:unixtime forKey:@"timestamp"];
    [dic setObject:deviceId forKey:@"device_id"];
    [dic setObject:@0 forKey:KEY_ESM_TYPE];
    [dic setObject:@"" forKey:KEY_ESM_TITLE];
    [dic setObject:@"" forKey:KEY_ESM_SUBMIT];
    [dic setObject:@"" forKey:KEY_ESM_INSTRUCTIONS];
    [dic setObject:@"" forKey:KEY_ESM_RADIOS];
    [dic setObject:@"" forKey:KEY_ESM_CHECKBOXES];
    [dic setObject:@0 forKey:KEY_ESM_LIKERT_MAX];
    [dic setObject:@"" forKey:KEY_ESM_LIKERT_MAX_LABEL];
    [dic setObject:@"" forKey:KEY_ESM_LIKERT_MIN_LABEL];
    [dic setObject:@0 forKey:KEY_ESM_LIKERT_STEP];
    [dic  setObject:@"" forKey:KEY_ESM_QUICK_ANSWERS];
    [dic setObject:@0 forKey:KEY_ESM_EXPIRATION_THRESHOLD];
    [dic setObject:@"" forKey:KEY_ESM_STATUS];
    //        "double_esm_user_answer_timestamp default 0,"
    [dic setObject:unixtime forKey:KEY_DOUBLE_ESM_USER_ANSWER_TIMESTAMP];
    //        "esm_user_answer text default '',"
    [dic setObject:@"" forKey:KEY_ESM_USER_ANSWER];
    [dic setObject:@"" forKey:KEY_ESM_TRIGGER];
    [dic  setObject:@0 forKey:KEY_ESM_SCALE_MIN];
    [dic  setObject:@0 forKey:KEY_ESM_SCALE_MAX];
    [dic  setObject:@0 forKey:KEY_ESM_SCALE_START];
    [dic setObject:@"" forKey:KEY_ESM_SCALE_MAX_LABEL];
    [dic setObject:@"" forKey:KEY_ESM_SCALE_MIN_LABEL];
    [dic setObject:@0 forKey:KEY_ESM_SCALE_STEP];
    
    for (id key in [originalDic keyEnumerator]) {
        NSLog(@"Key: %@ => Value:%@" , key, [originalDic objectForKey:key]);
        if([key isEqualToString:KEY_ESM_RADIOS]){
            [dic setObject:[self convertArrayToCSVFormat:[originalDic objectForKey:key]] forKey:KEY_ESM_RADIOS];
        }else if([key isEqualToString:KEY_ESM_CHECKBOXES]){
            [dic setObject:[self convertArrayToCSVFormat:[originalDic objectForKey:key]] forKey:KEY_ESM_CHECKBOXES];
        }else if([key isEqualToString:KEY_ESM_QUICK_ANSWERS]){
            [dic setObject:[self convertArrayToCSVFormat:[originalDic objectForKey:key]] forKey:KEY_ESM_QUICK_ANSWERS];
        }else{
            [dic setObject:[originalDic objectForKey:key] forKey:key];
        }
    }
    return dic;
}

- (NSString* ) convertArrayToCSVFormat:(NSArray *) array
{
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
    [self.navigationController popToRootViewControllerAnimated:YES];
}


- (void) setContentSizeWithAdditionalHeight:(int) additionalHeight
{
    totalHight += additionalHeight;
    [_mainScrollView setContentSize:CGSizeMake(WIDTH_VIEW, totalHight)];
}


@end
