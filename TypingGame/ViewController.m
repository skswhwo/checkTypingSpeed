//
//  ViewController.m
//  TypingGame
//
//  Created by ChoJaehyun on 2016. 11. 24..
//  Copyright © 2016년 com.classting. All rights reserved.
//

#import "ViewController.h"

typedef enum
{
    SupportLanguageTypeEnglish,
    SupportLanguageTypeKorean
    
}SupportLanguageType;

@interface ViewController ()
<UITextViewDelegate>
{
    NSDate *executionDate;
    dispatch_once_t once;
}
@property (weak, nonatomic) IBOutlet UILabel *displayLabel;
@property (weak, nonatomic) IBOutlet UITextView *inputTextView;
@property (weak, nonatomic) IBOutlet UILabel *resultLabel;

@property (nonatomic, strong) NSArray *words;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initializeUI];
    [self initializeProperties];
    
    [self changeWord];
}

- (void)initializeUI
{
    float padding = self.inputTextView.textContainer.lineFragmentPadding;
    self.inputTextView.textContainerInset = UIEdgeInsetsMake(0, -padding, 0, -padding);
    [self.inputTextView becomeFirstResponder];
    
    self.inputTextView.layer.borderWidth = 1;
    self.inputTextView.layer.borderColor = [[UIColor blackColor] colorWithAlphaComponent:0.2].CGColor;
}

- (void)initializeProperties
{
    _words = [self getStrings:SupportLanguageTypeKorean];
}

#pragma mark - IBAction
- (IBAction)koreanButtonClicked:(id)sender {
    _words = [self getStrings:SupportLanguageTypeKorean];
    [self changeWord];
}

- (IBAction)englishButtonClicked:(id)sender {
    _words = [self getStrings:SupportLanguageTypeEnglish];
    [self changeWord];
}

#pragma mark - Action
- (void)changeWord
{
    [self resetExecutionDate];
    NSInteger rand = arc4random()%self.words.count;
    NSString *word = [self.words objectAtIndex:rand];
    self.displayLabel.text = word;
    self.inputTextView.text = @"";
}

- (void)calculateResult
{
    NSTimeInterval executionTime = [[NSDate date] timeIntervalSinceDate:executionDate];
    
    NSString *originalString = self.displayLabel.text;
    NSString *inputString = self.inputTextView.text;
    if (inputString.length == 0) {
        return;
    }
    
    int correctLength = 0;
    int correctCount = 0;
    for (int i = 0 ; i < inputString.length ; i++) {
        if (originalString.length > i) {
            NSString *origin = [originalString substringWithRange:NSMakeRange(i, 1)];
            NSString *subString = [inputString substringWithRange:NSMakeRange(i, 1)];
            if ([origin isEqualToString:subString]) {
                correctLength += strlen([subString UTF8String]);
                correctCount++;
            }
        } else {
            break;
        }
    }
    NSInteger maxLength = MAX (originalString.length , inputString.length);
    float percentage = (float)correctCount/(float)maxLength*100;
    
    NSInteger maxUTF8Length = MAX (strlen([originalString UTF8String]) , strlen([inputString UTF8String]));
    float adjustTypingLength = (float)correctLength/(float)maxUTF8Length * strlen([inputString UTF8String]);
//    float adjustTypingLength = (float)correctCount/(float)maxLength*inputString.length;
    NSInteger verlocity = adjustTypingLength*60/executionTime;
    
    self.resultLabel.text = [NSString stringWithFormat:@"정확도 %@%%, 속도: %@/분",@((NSInteger)percentage),@(verlocity)];
}

- (void)resetExecutionDate
{
    once = 0;
}

#pragma mark - UITextViewDelegate
- (void)textViewDidChange:(UITextView *)textView
{
    if (textView.text.length == 0) {
        once = 0;
    } else {
        dispatch_once(&once, ^{
            executionDate = [NSDate date];
        });
    }
    
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc]initWithString:self.displayLabel.text];
    [string addAttribute:NSForegroundColorAttributeName
                   value:[UIColor blackColor]
                   range:NSMakeRange(0, string.length)];
    for (int i = 0 ; i < textView.text.length ; i++) {
        if (string.length > i) {
            NSRange range = NSMakeRange(i, 1);
            NSAttributedString *originSubString = [string attributedSubstringFromRange:range];
            NSString *subString = [textView.text substringWithRange:range];
            if ([[originSubString string] isEqualToString:subString]) {
                [string addAttribute:NSForegroundColorAttributeName
                               value:[UIColor blueColor]
                               range:range];
            } else {
                [string addAttribute:NSForegroundColorAttributeName
                               value:[UIColor redColor]
                               range:range];
            }
        }
    }
    self.displayLabel.attributedText = string;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if (text.length > 1) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"반칙" message:@"붙여넣기 금지!" preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* ok = [UIAlertAction
                             actionWithTitle:@"확인"
                             style:UIAlertActionStyleDefault
                             handler:^(UIAlertAction * action)
                             {
                                 [alert dismissViewControllerAnimated:YES completion:nil];
                                 
                             }];
        [alert addAction:ok];
        [self presentViewController:alert animated:YES completion:nil];
        return NO;
    }
    if ([text isEqualToString:@"\n"]) {
        [self calculateResult];
        [self changeWord];
        return NO;
    }
    return YES;
}

#pragma mark - Private
- (NSArray *)getStrings:(SupportLanguageType)type
{
    NSStringEncoding encoding;
    NSString *path = [self getFilePath:type];
    NSString *content = [NSString stringWithContentsOfFile:path  usedEncoding:&encoding  error:NULL];
    return [content componentsSeparatedByString:@"\n"];
}

- (NSString *)getFilePath:(SupportLanguageType)type
{
    switch (type) {
        case SupportLanguageTypeKorean:
            return [[NSBundle mainBundle] pathForResource:@"korean" ofType:@"txt"];
        case SupportLanguageTypeEnglish:
            return [[NSBundle mainBundle] pathForResource:@"english" ofType:@"txt"];
    }
}
@end
