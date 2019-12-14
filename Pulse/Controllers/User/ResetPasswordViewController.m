//
//  ResetPasswordViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 10/5/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "ResetPasswordViewController.h"
#import <BlocksKit/BlocksKit+UIKit.h>
#import <HapticHelper/HapticHelper.h>
#import "Session.h"
#import "Camp.h"
#import "Launcher.h"
#import "UIColor+Palette.h"
#import "NSString+Validation.h"
#import "HAWebService.h"
#import "BFAlertController.h"

#import <JGProgressHUD/JGProgressHUD.h>
#import <HapticHelper/HapticHelper.h>
@import Firebase;

#define UIViewParentController(__view) ({ \
UIResponder *__responder = __view; \
while ([__responder isKindOfClass:[UIView class]]) \
__responder = [__responder nextResponder]; \
(UIViewController *)__responder; \
})

#define IS_IPHONE        (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)

@interface ResetPasswordViewController () {
    UIEdgeInsets safeAreaInsets;
    NSArray *colors;
}

@property (nonatomic) NSInteger themeColor;
@property (nonatomic) NSInteger currentStep;
@property (strong, nonatomic) NSMutableArray *steps;
@property (nonatomic) CGFloat currentKeyboardHeight;

@end

@implementation ResetPasswordViewController

static NSInteger const LOOKUP_FIELD = 201;
static NSInteger const RESET_CODE_FIELD = 202;
static NSInteger const NEW_PASSWORD_FIELD = 203;
static NSInteger const CONFIRM_NEW_PASSWORD_FIELD = 204;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor contentBackgroundColor];
    self.view.tintColor = [UIColor bonfireBrand];
    
    if (self.prefillLookup.length == 0 && [Session sharedInstance].currentUser) {
        self.prefillLookup = [Session sharedInstance].currentUser.attributes.email;
    }
    
    [self addListeners];
    [self setupViews];
    [self setupSteps];
    
    // –––– show the first step ––––
    self.currentStep = -1;
    [self nextStep:false];
    if (self.prefillCode.length > 0 && self.prefillLookup.length > 0) {
        self.currentStep = 0;
        [self nextStep:false];
        self.currentStep = 1;
        [self nextStep:false];
    }
    
    safeAreaInsets.top = 1; // set to 1 so we only set it once in viewWillAppear
    
    // Google Analytics
    [FIRAnalytics setScreenName:@"Reset Password" screenClass:nil];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (safeAreaInsets.top == 1) {
        safeAreaInsets = [UIApplication sharedApplication].keyWindow.safeAreaInsets;
        [self updateWithSafeAreaInsets];
    }
}

- (void)setPrefillCode:(NSString *)prefillCode {
    if (![prefillCode isEqualToString:_prefillCode]) {
        _prefillCode = prefillCode;
    }
    
    // fill in the text field (if possible)
    NSInteger codeStep = [self getIndexOfStepWithId:@"reset_code"];
    if (prefillCode.length > 0 && self.steps.count > codeStep) {
        UITextField *codeTextField = self.steps[codeStep][@"textField"];
        codeTextField.text = self.prefillCode;
        [self textFieldChanged:codeTextField];
    }
}

- (void)updateWithSafeAreaInsets {
    self.closeButton.frame = CGRectMake(self.view.frame.size.width - 44 - 11, safeAreaInsets.top, 44, 44);
}

- (BOOL)hasExistingLookup {
    return [Session sharedInstance].currentUser.attributes.email && [[Session sharedInstance].currentUser.attributes.email validateBonfireEmail] == BFValidationErrorNone;
}

- (void)addListeners {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillDismiss:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)setupViews {
    self.closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.closeButton setImage:[[UIImage imageNamed:@"navCloseIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    self.closeButton.tintColor = self.view.tintColor;
    self.closeButton.contentMode = UIViewContentModeCenter;
    self.closeButton.adjustsImageWhenHighlighted = false;
    [self.closeButton bk_whenTapped:^{
        [self.view endEditing:TRUE];
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    [self.view addSubview:self.closeButton];
    
    self.backButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.backButton.frame = CGRectMake(3, self.closeButton.frame.origin.y, 44, 44);
    self.backButton.titleLabel.font = [UIFont systemFontOfSize:20.f weight:UIFontWeightSemibold];
    [self.backButton setTitleColor:[UIColor bonfireSecondaryColor] forState:UIControlStateDisabled];
    [self.backButton setImage:[[UIImage imageNamed:@"leftArrowIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    self.backButton.tintColor = self.view.tintColor;
    self.backButton.alpha = 0;
    self.backButton.adjustsImageWhenHighlighted = false;
    self.backButton.transform = CGAffineTransformMakeRotation(M_PI_2);
    [self.backButton bk_whenTapped:^{
        [self previousStep:-1];
    }];
    [self.view addSubview:self.backButton];
    
    self.nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.nextButton.frame = CGRectMake(24, self.view.frame.size.height, self.view.frame.size.width - (24 * 2), 48);
    self.nextButton.backgroundColor = [self.view tintColor];
    self.nextButton.titleLabel.font = [UIFont systemFontOfSize:20.f weight:UIFontWeightSemibold];
    [self.nextButton setTitleColor:[UIColor bonfireSecondaryColor] forState:UIControlStateDisabled];
    [self continuityRadiusForView:self.nextButton withRadius:14.f];
    [self.nextButton setTitle:@"Next" forState:UIControlStateNormal];
    [self.view addSubview:self.nextButton];
    [self greyOutNextButton];
    
    [self.nextButton bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.nextButton.alpha = 0.8;
            self.nextButton.transform = CGAffineTransformMakeScale(0.8, 0.8);
        } completion:nil];
    } forControlEvents:UIControlEventTouchDown];
    
    [self.nextButton bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.nextButton.alpha = 1;
            self.nextButton.transform = CGAffineTransformMakeScale(1, 1);
        } completion:nil];
    } forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit)];
    
    [self.nextButton bk_whenTapped:^{
        [self handleNext];
    }];
}

- (void)setupSteps {
    self.instructionLabel = [self instructionLabelWithText:@""];
    [self.view addSubview:self.instructionLabel];
    
    self.steps = [[NSMutableArray alloc] init];
    
    [self.steps addObject:@{@"id": @"reset_lookup", @"skip": [NSNumber numberWithBool:false], @"next": @"Next", @"instruction": [self hasExistingLookup] ? @"Tap Next to send a password reset code to your email" : @"Let’s reset your password!\nWhat’s your email or username?", @"placeholder": @"Email or username", @"sensitive": [NSNumber numberWithBool:false], @"keyboard": @"text", @"answer": [NSNull null], @"textField": [NSNull null], @"block": [NSNull null]}];
    [self.steps addObject:@{@"id": @"reset_code", @"skip": [NSNumber numberWithBool:false], @"next": @"Next", @"instruction": @"Please enter the 6 digit code\nwe sent to your email", @"placeholder":@"6 digit code", @"sensitive": [NSNumber numberWithBool:false], @"keyboard": @"number", @"answer": [NSNull null], @"textField": [NSNull null], @"block": [NSNull null]}];
    [self.steps addObject:@{@"id": @"reset_new_password", @"skip": [NSNumber numberWithBool:false], @"next": @"Next", @"instruction": [NSString stringWithFormat:@"Set a new password that’s at least %i characters", MIN_PASSWORD_LENGTH], @"placeholder":@"New Password", @"sensitive": [NSNumber numberWithBool:true], @"keyboard": @"text", @"answer": [NSNull null], @"textField": [NSNull null], @"block": [NSNull null]}];
    [self.steps addObject:@{@"id": @"reset_confirm_new_password", @"skip": [NSNumber numberWithBool:false], @"next": @"Confirm", @"instruction": @"Please confirm your\nnew password", @"placeholder":@"Confirm New Password", @"sensitive": [NSNumber numberWithBool:true], @"keyboard": @"text", @"answer": [NSNull null], @"textField": [NSNull null], @"block": [NSNull null]}];
    
    for (NSInteger i = 0; i < [self.steps count]; i++) {
        // add each step to the right
        [self addStep:i usingArray:self.steps];
    }
}

- (void)addStep:(NSInteger)stepIndex usingArray:(NSMutableArray *)parentArray {
    NSMutableDictionary *mutatedStep = [[NSMutableDictionary alloc] initWithDictionary:parentArray[stepIndex]];
    
    if ([mutatedStep objectForKey:@"textField"] && ![mutatedStep[@"textfield"] isEqual:[NSNull null]]) {
        UIView *inputBlock = [[UIView alloc] initWithFrame:CGRectMake(0, (self.view.frame.size.height / 2) - (56 / 2) - (self.view.frame.size.height * .15), self.view.frame.size.width, 56)];
        [self.view addSubview:inputBlock];
        
        UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(24, 0, self.view.frame.size.width - (24 * 2), 56)];
        textField.textColor = [UIColor bonfirePrimaryColor];
        textField.backgroundColor = [UIColor cardBackgroundColor];
        textField.layer.cornerRadius = 14.f;
        textField.layer.masksToBounds = false;
        textField.layer.shadowRadius = 2.f;
        textField.layer.shadowOffset = CGSizeMake(0, 1);
        textField.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.1f].CGColor;
        textField.layer.shadowOpacity = 1.f;
//        textField.keyboardAppearance = UIKeyboardAppearanceLight;
        
        if ([mutatedStep[@"id"] isEqualToString:@"reset_lookup"]) {
            textField.tag = LOOKUP_FIELD;
            textField.text = self.prefillLookup;
            if (self.prefillLookup.length > 0) {
                [self textFieldChanged:textField];
            }
            
            // autofill with user email if already logged in
            if ([self hasExistingLookup]) {
                textField.text = [Session sharedInstance].currentUser.attributes.email;
                textField.textColor = [UIColor bonfireSecondaryColor];
                textField.enabled = false;
                
                self.nextButton.enabled = true;
                self.nextButton.backgroundColor = self.view.tintColor;
                self.nextButton.userInteractionEnabled = true;
                
                [self keyboardWillDismiss:nil];
            }
        }
        else if ([mutatedStep[@"id"] isEqualToString:@"reset_code"]) {
            textField.tag = RESET_CODE_FIELD;
            textField.text = self.prefillCode;
            if (self.prefillCode.length > 0) {
                [self textFieldChanged:textField];
                
                [self greyOutNextButton];
            }
        }
        else if ([mutatedStep[@"id"] isEqualToString:@"reset_new_password"]) {
            textField.tag = NEW_PASSWORD_FIELD;
        }
        else if ([mutatedStep[@"id"] isEqualToString:@"reset_confirm_new_password"]) {
            textField.tag = CONFIRM_NEW_PASSWORD_FIELD;
        }
        
        // set text content types
        if ([mutatedStep[@"id"] isEqualToString:@"reset_lookup"]) {
            textField.textContentType = UITextContentTypeEmailAddress;
        }
        else if ([mutatedStep[@"id"] isEqualToString:@"reset_code"]) {
            if (@available(iOS 12.0, *)) {
                textField.textContentType = UITextContentTypeOneTimeCode;
            }
        }
        
        if ([mutatedStep objectForKey:@"keyboard"] && [mutatedStep[@"keyboard"] isEqualToString:@"email"]) {
            textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            textField.keyboardType = UIKeyboardTypeEmailAddress;
            textField.autocorrectionType = UITextAutocorrectionTypeNo;
        }
        else if ([mutatedStep objectForKey:@"keyboard"] && [mutatedStep[@"keyboard"] isEqualToString:@"number"]) {
            textField.keyboardType = UIKeyboardTypeNumberPad;
        }
        else {
            textField.keyboardType = UIKeyboardTypeDefault;
            
            if ([mutatedStep objectForKey:@"keyboard"] && [mutatedStep[@"keyboard"] isEqualToString:@"title"]) {
                textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
            }
            else if ([mutatedStep[@"id"] isEqualToString:@"reset_lookup"]) {
                textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
                textField.autocorrectionType = UITextAutocorrectionTypeNo;
                textField.keyboardType = UIKeyboardTypeDefault;
            }
            else {
                textField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
            }
        }
        
        textField.delegate = self;
        textField.returnKeyType = UIReturnKeyNext;
        // textField.autocorrectionType = UITextAutocorrectionTypeNo;
        textField.font = [UIFont systemFontOfSize:20.f weight:UIFontWeightMedium];
        
        [inputBlock addSubview:textField];
        
        // add left-side spacing
        UIView *leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 20, textField.frame.size.height)];
        leftView.backgroundColor = [UIColor clearColor];
        textField.leftView = leftView;
        textField.rightView = leftView;
        textField.leftViewMode = UITextFieldViewModeAlways;
        textField.rightViewMode = UITextFieldViewModeAlways;
        textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:([mutatedStep objectForKey:@"placeholder"] ? mutatedStep[@"placeholder"] : @"") attributes:@{NSForegroundColorAttributeName: [UIColor bonfireSecondaryColor]}];
        [textField addTarget:self action:@selector(textFieldChanged:) forControlEvents:UIControlEventEditingChanged];
        
        
        if ([mutatedStep[@"sensitive"] boolValue]) {
            textField.secureTextEntry = true;
        }
        else {
            textField.secureTextEntry = false;
        }
        
        inputBlock.alpha = 0;
        inputBlock.transform = CGAffineTransformMakeTranslation(self.view.frame.size.width, 0);
        
        [mutatedStep setObject:inputBlock forKey:@"block"];
        [mutatedStep setObject:textField forKey:@"textField"];
    }
    
    [parentArray replaceObjectAtIndex:stepIndex withObject:mutatedStep];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *newStr = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    if (textField.tag == LOOKUP_FIELD) {
        return newStr.length <= MAX_EMAIL_LENGTH ? YES : NO;
    }
    else if (textField.tag == RESET_CODE_FIELD) {
        return newStr.length <= 6 ? YES : NO;
    }
    else if (textField.tag == NEW_PASSWORD_FIELD) {
        return newStr.length <= MAX_PASSWORD_LENGTH ? YES : NO;
    }
    else if (textField.tag == CONFIRM_NEW_PASSWORD_FIELD) {
        return newStr.length <= MAX_PASSWORD_LENGTH ? YES : NO;
    }
    
    return YES;
}

- (NSInteger)getIndexOfStepWithId:(NSString *)stepId {
    for (NSInteger i = 0; i < [self.steps count]; i++) {
        if ([self.steps[i][@"id"] isEqualToString:stepId]) {
            return i;
        }
    }
    return 0;
}

- (void)textFieldChanged:(UITextField *)sender {
    if ([self.steps[self.currentStep][@"id"] isEqualToString:@"reset_lookup"]) {
        BOOL valid = ([sender.text validateBonfireEmail] == BFValidationErrorNone);
        
        if (!valid) {
            // also allow username
            valid = ([sender.text validateBonfireUsername] == BFValidationErrorNone || ([sender.text validateBonfireUsername] == BFValidationErrorTooShort && sender.text.length >= 1));
        }
        
        if (valid) {
            // qualifies
            self.nextButton.backgroundColor = self.view.tintColor;
            self.nextButton.enabled = true;
        }
        else {
            [self greyOutNextButton];
        }
    }
    
    if ([self.steps[self.currentStep][@"id"] isEqualToString:@"reset_code"]) {
        BOOL valid = (sender.text.length == 6);
        
        if (valid) {
            // qualifies
            self.nextButton.backgroundColor = self.view.tintColor;
            self.nextButton.enabled = true;
        }
        else {
            [self greyOutNextButton];
        }
    }
    
    if ([self.steps[self.currentStep][@"id"] isEqualToString:@"reset_new_password"] ||
        [self.steps[self.currentStep][@"id"] isEqualToString:@"reset_confirm_new_password"]) {
        if ([sender.text validateBonfirePassword] == BFValidationErrorNone) {
            // qualifies
            self.nextButton.backgroundColor = self.view.tintColor;
            self.nextButton.enabled = true;
        }
        else {
            [self greyOutNextButton];
        }
    }
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (self.nextButton.enabled) [self handleNext];
    
    return false;
}

- (void)greyOutNextButton {
    self.nextButton.enabled = false;
    self.nextButton.backgroundColor = [UIColor bonfireDisabledColor];
}

- (void)handleNext {
    NSDictionary *step = self.steps[self.currentStep];
    
    // disable next button at the beginning of all steps
    [self greyOutNextButton];
    
    // sign in to school
    if ([step[@"id"] isEqualToString:@"reset_lookup"]) {
        // perform action before next step
        [self requestEmailVerification];
    }
    else if ([step[@"id"] isEqualToString:@"reset_code"]) {
        // perform action before next step
        [self nextStep:true];
    }
    else if ([step[@"id"] isEqualToString:@"reset_new_password"]) {
        // perform action before next step
        [self nextStep:true];
    }
    else if ([step[@"id"] isEqualToString:@"reset_confirm_new_password"]) {
        // perform action before next step
        NSInteger passwordStep = [self getIndexOfStepWithId:@"reset_new_password"];
        UITextField *passwordTextField = self.steps[passwordStep][@"textField"];
        NSString *password = passwordTextField.text;
        
        UITextField *confirmPasswordTextField = self.steps[self.currentStep][@"textField"];
        NSString *confirmPassword = confirmPasswordTextField.text;
        
        if ([password isEqualToString:confirmPassword]) {
            // save new password!
            [self confirmPasswordReset];
        }
        else {
            // not long enough –> shake input block
            [self shakeInputBlock];
            
            self.nextButton.enabled = true;
            self.nextButton.backgroundColor = self.view.tintColor;
            self.nextButton.userInteractionEnabled = true;
            
            BFAlertController *alert = [BFAlertController alertControllerWithTitle:@"Password Doesn't Match" message:@"The passwords you provided don't match. Please try again or go back to set a new one." preferredStyle:BFAlertControllerStyleAlert];
            BFAlertAction *gotItAction = [BFAlertAction actionWithTitle:@"Okay" style:BFAlertActionStyleCancel handler:nil];
            [alert addAction:gotItAction];
            [self presentViewController:alert animated:true completion:nil];
        }
    }
}
- (UILabel *)instructionLabelWithText:(NSString *)text {
    CGFloat inputCenterY = (self.view.frame.size.height / 2) - (self.view.frame.size.height * .15);
    
    UILabel *instructionLabel = [[UILabel alloc] initWithFrame:CGRectMake(24, self.view.frame.size.height, self.view.frame.size.width - 48, 42)];
    instructionLabel.center = CGPointMake(instructionLabel.center.x, (inputCenterY / 2) + 16);
    instructionLabel.textAlignment = NSTextAlignmentCenter;
    instructionLabel.text = text;
    instructionLabel.font = [UIFont systemFontOfSize:18.f weight:UIFontWeightMedium];
    instructionLabel.textColor = [UIColor bonfirePrimaryColor];
    instructionLabel.numberOfLines = 0;
    instructionLabel.lineBreakMode = NSLineBreakByWordWrapping;
    return instructionLabel;
}
- (void)nextStep:(BOOL)withAnimation {
    /*
     
     NEXT STEP
     –––––––––
     purpose: show next part of the flow. in most cases, this means animating the next step in and the current step out.
     
     */
    
    // defaults
    float animationDuration = 0.9f;
    if (!withAnimation) {
        animationDuration = 0;
    }
    
    NSInteger next = self.currentStep;
    
    BOOL isComplete = true; // true until proven false
    for (NSInteger i = self.currentStep + 1; i < [self.steps count]; i++) {
        // steps to the right of the currentStep
        if (i >= [self.steps count]) {
            // does not have a next step // this should never happen
            NSLog(@"Could not find a next step.");
            next = self.currentStep + 1;
        }
        else {
            NSDictionary *step = self.steps[i];
            if (![step[@"skip"] boolValue]) {
                next = i;
            }
            else {
                // skip step
            }
        }
        if (next != self.currentStep && i < [self.steps count]) {
            NSDictionary *step = self.steps[i];
            // we found the next step
            // now we need to find if there are any remaining steps (that have skip='false')
            if (![step[@"skip"] boolValue]) {
                isComplete = false;
                next = i;
                break;
            }
        }
    }
    DLog(@"next step :%ld", (long)next);
    
    if (isComplete) {
        [self.view endEditing:YES];
    }
    else if (next < [self.steps count]) {
        NSDictionary *activeStep;
        UIView *activeBlock = nil;
        if (self.currentStep >= 0) {
            activeStep = self.steps[self.currentStep];
            activeBlock = activeStep[@"block"];
        }
        
        NSDictionary *nextStep = self.steps[next];
        UIView *nextBlock = nextStep[@"block"];
        
        if ([nextStep objectForKey:@"textField"] && ![nextStep[@"textField"] isEqual:[NSNull null]]) {
            UITextField *nextTextField = nextStep[@"textField"];
            
            CGFloat delay = self.currentStep == -1 ? 0.01f : 0;
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [nextTextField becomeFirstResponder];
            });
        }
        else {
            NSLog(@"end editing");
            [self.view endEditing:TRUE];
        }
        
        // show next step in the flow
        if (nextBlock != nil) {
            nextBlock.alpha = 0;
            nextBlock.transform = CGAffineTransformMakeTranslation(self.view.frame.size.width, 0);
        }
        [UIView animateWithDuration:animationDuration delay:0 usingSpringWithDamping:0.8f initialSpringVelocity:0.4f options:UIViewAnimationOptionCurveEaseIn animations:^{
            if (nextBlock != nil) {
                nextBlock.transform = CGAffineTransformMakeTranslation(0, 0);
                nextBlock.alpha = 1;
            }
            if (activeBlock != nil) {
                activeBlock.transform = CGAffineTransformMakeTranslation(- 1 * self.view.frame.size.width, 0);
                activeBlock.alpha = 0;
            }
        } completion:^(BOOL finished) {
            self.nextButton.userInteractionEnabled = true;
        }];
        
        // make any instruction changes as needed
        if (![nextStep[@"instruction"] isEqualToString:activeStep[@"instruction"]]) {
            // title change
            NSString *nextStepTitle = nextStep[@"instruction"];
            DLog(@"Next step title: %@", nextStepTitle);
            
            CGRect instructionsDynamicFrame = [nextStepTitle boundingRectWithSize:CGSizeMake(self.instructionLabel.frame.size.width, 100) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:self.instructionLabel.font} context:nil];
            CGPoint instructionLabelCenter = self.instructionLabel.center;
            
            if (withAnimation) {
                UILabel *instructionCopy = [self instructionLabelWithText:nextStepTitle];
                instructionCopy.alpha = 0;
                
                SetHeight(instructionCopy, ceilf(instructionsDynamicFrame.size.height));
                instructionCopy.center = CGPointMake(self.view.frame.size.width / 2, instructionLabelCenter.y);
                instructionCopy.transform = CGAffineTransformMakeTranslation(self.view.frame.size.width, 0);
                [self.view addSubview:instructionCopy];
                
                [UIView animateWithDuration:animationDuration delay:0 usingSpringWithDamping:0.8f initialSpringVelocity:0.4f options:UIViewAnimationOptionCurveEaseIn animations:^{
                    instructionCopy.transform = CGAffineTransformMakeTranslation(0, 0);
                    instructionCopy.alpha = 1;
                    
                    self.instructionLabel.transform = CGAffineTransformMakeTranslation(-1 * self.view.frame.size.width, 0);
                    self.instructionLabel.alpha = 0;
                } completion:^(BOOL finished) {
                    // save copy as the original mainNavLabel
                    [self.instructionLabel removeFromSuperview];
                    self.instructionLabel = instructionCopy;
                }];
            }
            else {
                self.instructionLabel.text = nextStepTitle;
                SetHeight(self.instructionLabel, ceilf(instructionsDynamicFrame.size.height));
                self.instructionLabel.center = CGPointMake(self.view.frame.size.width / 2, instructionLabelCenter.y);
            }
        }
        
        if ([nextStep[@"next"] isEqual:[NSNull null]]) {
            [self.nextButton setTitle:@"" forState:UIControlStateNormal];
            [self.nextButton setHidden:true];
        }
        else {
            [self.nextButton setTitle:nextStep[@"next"] forState:UIControlStateNormal];
            [self.nextButton setHidden:false];
        }
        
        self.currentStep = next;
    }
    else if (next == [self.steps count]) {
        // loading
        // [self showLoading];
    }
    else {
        // not sure how this got called.
        
    }
}
- (void)previousStep:(NSInteger)previous {
    /*
     
     PREVIOUS STEP
     –––––––––
     purpose: show the previous step in the flow. in most cases, this means animating the previous step in and the current step out.
     
     */
    
    if (previous == -1) {
        previous = self.currentStep;
        for (NSInteger i = self.currentStep - 1; i >= 0; i--) {
            // steps to the right of the currentStep
            if (i < 0) {
                // does not have a previous step // this should never happen
                NSLog(@"Could not find a previous step.");
                previous = 0;
            }
            else {
                NSDictionary *step = self.steps[i];
                if (![step[@"skip"] boolValue]) {
                    NSLog(@"this is the previous step");
                    previous = i;
                    break;
                }
                else {
                    NSLog(@"skip step");
                }
            }
        }
    }
    
    if (previous < 0) {
        // prevent negative steps
    }
    else if (previous < self.currentStep) {
        // remove previous step's answer
        // save answer
        NSMutableDictionary *mutablePreviousStep = [[NSMutableDictionary alloc] initWithDictionary:self.steps[self.currentStep]];
        [mutablePreviousStep setObject:[NSNull null] forKey:@"answer"];
        [self.steps replaceObjectAtIndex:self.currentStep withObject:mutablePreviousStep];
        
        NSDictionary *previousStep = self.steps[previous];
        UIView *previousBlock = previousStep[@"block"];
        UITextField *previousTextField = previousStep[@"textField"];
        
        if ([previousTextField.tintColor isEqual:[UIColor clearColor]]) {
            // change the tint color back to blue
            self.backButton.tintColor = [self.view tintColor];
            previousTextField.tintColor = [self.view tintColor];
            previousTextField.textColor = [UIColor bonfirePrimaryColor];
        }
        
        NSDictionary *activeStep = self.steps[self.currentStep];
        UIView *activeBlock = activeStep[@"block"];
        UITextField *activeTextField = activeStep[@"textField"];
        
        float animationDuration = 0.9f;
        
        // focus keyboard on previous text field
        [previousTextField becomeFirstResponder];
        
        // show previous input block in the flow
        if (previousBlock != nil) {
            previousBlock.alpha = 0;
            previousBlock.transform = CGAffineTransformMakeTranslation(-1 * self.view.frame.size.width, 0);
        }
        [UIView animateWithDuration:animationDuration delay:0 usingSpringWithDamping:0.8f initialSpringVelocity:0.4f options:UIViewAnimationOptionCurveEaseIn animations:^{
            if (activeBlock != nil) {
                activeBlock.transform = CGAffineTransformMakeTranslation(self.view.frame.size.width, 0);
                activeBlock.alpha = 0;
            }
            if (previousBlock != nil) {
                previousBlock.transform = CGAffineTransformMakeTranslation(0, 0);
                previousBlock.alpha = 1;
            }
        } completion:^(BOOL finished) {
            activeTextField.text = @"";
        }];
        
        // make any title changes as needed
        if (![previousStep[@"instruction"] isEqualToString:activeStep[@"instruction"]]) {
            // title change
            NSData *tempTitleArchive = [NSKeyedArchiver archivedDataWithRootObject:self.instructionLabel];
            UILabel *titleCopy = [NSKeyedUnarchiver unarchiveObjectWithData:tempTitleArchive];
            titleCopy.transform = CGAffineTransformMakeTranslation(-1 * self.view.frame.size.width, 0);
            titleCopy.alpha = 0;
            titleCopy.text = previousStep[@"instruction"];
            [self.view addSubview:titleCopy];
            
            [UIView animateWithDuration:animationDuration delay:0 usingSpringWithDamping:0.8f initialSpringVelocity:0.4f options:UIViewAnimationOptionCurveEaseIn animations:^{
                self.instructionLabel.transform = CGAffineTransformMakeTranslation(self.view.frame.size.width, 0);
                self.instructionLabel.alpha = 0;
                
                titleCopy.transform = CGAffineTransformMakeTranslation(0, 0);
                titleCopy.alpha = 1;
            } completion:^(BOOL finished) {
                // save copy as the original mainNavLabel
                [self.instructionLabel removeFromSuperview];
                self.instructionLabel = titleCopy;
            }];
        }
        
        // animation block simply used to mimic the exact timing of the title/description changes above
        [UIView animateWithDuration:animationDuration delay:0 usingSpringWithDamping:0.8f initialSpringVelocity:0.4f options:UIViewAnimationOptionCurveEaseIn animations:^{
        } completion:^(BOOL finished) {
            // save copy as the original mainNavLabel
            self.nextButton.userInteractionEnabled = true;
            self.backButton.userInteractionEnabled = true;
        }];
        
        // step specific actions
        if (previous <= 0) {
            [UIView animateWithDuration:0.3f animations:^{
                self.backButton.alpha = 0;
            }];
        }
        if ([previousStep[@"next"] isEqual:[NSNull null]]) {
            [self.nextButton setTitle:@"" forState:UIControlStateNormal];
            [self.nextButton setHidden:true];
        }
        else {
            [self.nextButton setTitle:previousStep[@"next"] forState:UIControlStateNormal];
            self.nextButton.backgroundColor = self.view.tintColor;
            self.nextButton.enabled = true;
            [self.nextButton setHidden:false];
        }
        
        self.currentStep = previous;
    }
}
- (UIColor *)currentColor {
    return colors[self.themeColor];
}
- (void)requestEmailVerification {
    NSInteger lookupStep = [self getIndexOfStepWithId:@"reset_lookup"];
    UITextField *lookupTextField = self.steps[lookupStep][@"textField"];
    NSString *lookup = lookupTextField.text;
    
    NSLog(@"params: %@", @{@"lookup": lookup});
    
    [self showSpinnerForStep:lookupStep];
    
    [[HAWebService managerWithContentType:kCONTENT_TYPE_URL_ENCODED] POST:@"accounts/recoveries/email" parameters:@{@"lookup": lookup} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        // move spinner
        [self removeSpinnerForStep:lookupStep];
        [self nextStep:true];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"error: %@", error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey]);
        NSString* ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        NSLog(@"%@",ErrorResponse);
        
        [self removeSpinnerForStep:lookupStep];
        self.nextButton.enabled = true;
        self.nextButton.backgroundColor = self.view.tintColor;
        self.nextButton.userInteractionEnabled = true;
        [self shakeInputBlock];
    }];
}
- (void)confirmPasswordReset {
    NSInteger lookupStep = [self getIndexOfStepWithId:@"reset_lookup"];
    UITextField *lookupTextField = self.steps[lookupStep][@"textField"];
    NSString *lookup = lookupTextField.text;
    
    NSInteger codeStep = [self getIndexOfStepWithId:@"reset_code"];
    UITextField *codeTextField = self.steps[codeStep][@"textField"];
    NSString *code = codeTextField.text;
    
    NSInteger newPasswordStep = [self getIndexOfStepWithId:@"reset_new_password"];
    UITextField *newPasswordTextField = self.steps[newPasswordStep][@"textField"];
    NSString *newPassword = newPasswordTextField.text;
    
    NSLog(@"params: %@", @{@"lookup": lookup, @"code": code, @"password": newPassword});
    
    [self showSpinnerForStep:newPasswordStep];
    
    [[HAWebService managerWithContentType:kCONTENT_TYPE_URL_ENCODED] POST:@"accounts/recoveries/email/confirm" parameters:@{@"lookup": lookup, @"code": code, @"password": newPassword} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        // move spinner
        [self removeSpinnerForStep:newPasswordStep];
        
        JGProgressHUD *HUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleExtraLight];
        HUD.textLabel.text = @"Saved!";
        HUD.vibrancyEnabled = false;
        HUD.animation = [[JGProgressHUDFadeZoomAnimation alloc] init];
        HUD.textLabel.textColor = [UIColor colorWithWhite:0 alpha:0.6f];
        HUD.backgroundColor = [UIColor colorWithWhite:0 alpha:0.1f];
        HUD.indicatorView = [[JGProgressHUDSuccessIndicatorView alloc] init];
        HUD.indicatorView.tintColor = HUD.textLabel.textColor;
        
        [self dismissViewControllerAnimated:YES completion:^{
            [HapticHelper generateFeedback:FeedbackType_Notification_Success];
            [HUD showInView:[Launcher activeViewController].view animated:YES];
            [HUD dismissAfterDelay:1.5f];
        }];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"error: %@", error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey]);
        NSString* ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        NSLog(@"%@",ErrorResponse);
        
        [self removeSpinnerForStep:newPasswordStep];
        self.nextButton.enabled = true;
        self.nextButton.backgroundColor = self.view.tintColor;
        self.nextButton.userInteractionEnabled = true;
        [self shakeInputBlock];
    }];
}

- (void)shakeInputBlock {
    UIView *currentBlock = self.steps[self.currentStep][@"block"];
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position"];
    [animation setDuration:0.08];
    [animation setRepeatCount:4];
    [animation setAutoreverses:YES];
    [animation setFromValue:[NSValue valueWithCGPoint:
                             CGPointMake([currentBlock center].x - 8.f, [currentBlock center].y)]];
    [animation setToValue:[NSValue valueWithCGPoint:
                           CGPointMake([currentBlock center].x + 8.f, [currentBlock center].y)]];
    [[currentBlock layer] addAnimation:animation forKey:@"position"];
}

- (void)showSpinnerForStep:(NSInteger)step {
    UIView *block = (UIView *)[[self.steps objectAtIndex:step] objectForKey:@"block"];
    UITextField *textField = (UITextField *)[[self.steps objectAtIndex:step] objectForKey:@"textField"];
    
    UIImageView *miniSpinner = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
    miniSpinner.image = [[UIImage imageNamed:@"miniSpinner"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    miniSpinner.tintColor = self.view.tintColor;
    miniSpinner.center = CGPointMake(block.frame.size.width / 2, textField.frame.size.height / 2);
    miniSpinner.alpha = 0;
    miniSpinner.tag = 112;
    
    CABasicAnimation *rotationAnimation;
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0 /* full rotation*/ * 1 * 1.f ];
    rotationAnimation.duration = 1.f;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = HUGE_VALF;
    
    [miniSpinner.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
    
    [block addSubview:miniSpinner];
    
    [UIView animateWithDuration:0.9f delay:0 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        miniSpinner.alpha = 1;
    } completion:nil];
    [UIView transitionWithView:textField duration:0.3 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        textField.textColor = [[UIColor bonfirePrimaryColor] colorWithAlphaComponent:0];
        if (textField.placeholder != nil) {
            textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:textField.placeholder attributes:@{NSForegroundColorAttributeName: [[UIColor bonfireSecondaryColor] colorWithAlphaComponent:0]}];
        }
        textField.tintColor = [UIColor clearColor];
    } completion:nil];
}
- (void)removeSpinnerForStep:(NSInteger)step {
    UIView *block = (UIView *)[[self.steps objectAtIndex:step] objectForKey:@"block"];
    UITextField *textField = (UITextField *)[[self.steps objectAtIndex:step] objectForKey:@"textField"];
    UIImageView *miniSpinner = [block viewWithTag:112];
    
    [UIView animateWithDuration:0.6f delay:0 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        miniSpinner.alpha = 0;
    } completion:^(BOOL finished) {
        [miniSpinner removeFromSuperview];
        
        [UIView transitionWithView:textField duration:0.3 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            textField.textColor = [UIColor bonfirePrimaryColor];
            textField.tintColor = [self.view tintColor];
            if (textField.placeholder != nil) {
                textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:textField.placeholder attributes:@{NSForegroundColorAttributeName: [UIColor bonfireSecondaryColor]}];
            }
        } completion:nil];
    }];
}

- (void)keyboardWillChangeFrame:(NSNotification *)notification {
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
    _currentKeyboardHeight = keyboardFrameBeginRect.size.height;
    
    self.nextButton.frame = CGRectMake(self.nextButton.frame.origin.x, (self.view.frame.size.height / self.view.transform.d) - _currentKeyboardHeight - self.nextButton.frame.size.height - self.nextButton.frame.origin.x, self.nextButton.frame.size.width, self.nextButton.frame.size.height);
}

- (void)keyboardWillDismiss:(NSNotification *)notification {
    _currentKeyboardHeight = 0;
    
    UIWindow *window = UIApplication.sharedApplication.keyWindow;
    CGFloat bottomPadding = window.safeAreaInsets.bottom + (HAS_ROUNDED_CORNERS ? (self.nextButton.frame.origin.x / 2) : self.nextButton.frame.origin.x);
    
    NSNumber *duration = [notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    [UIView animateWithDuration:[duration floatValue] delay:0 options:[[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue] << 16 animations:^{
        self.nextButton.frame = CGRectMake(self.nextButton.frame.origin.x, self.view.frame.size.height - self.nextButton.frame.size.height - (self.nextButton.frame.origin.x / 2) - bottomPadding, self.nextButton.frame.size.width, self.nextButton.frame.size.height);
    } completion:nil];
}

- (void)continuityRadiusForView:(UIView *)sender withRadius:(CGFloat)radius {
    CAShapeLayer * maskLayer = [CAShapeLayer layer];
    maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:sender.bounds
                                           byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight|UIRectCornerTopLeft|UIRectCornerTopRight
                                                 cornerRadii:CGSizeMake(radius, radius)].CGPath;
    
    sender.layer.mask = maskLayer;
}

@end
