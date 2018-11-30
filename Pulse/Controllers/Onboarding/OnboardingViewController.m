//
//  OnboardingViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 10/5/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "OnboardingViewController.h"
#import <BlocksKit/BlocksKit+UIKit.h>
#import <HapticHelper/HapticHelper.h>
#import "Session.h"
#import "Room.h"
#import "LauncherNavigationViewController.h"
#import "UIColor+Palette.h"
#import "Launcher.h"

#import <RSKImageCropper/RSKImageCropper.h>

#define envConfig [[[NSUserDefaults standardUserDefaults] objectForKey:@"config"] objectForKey:[[NSUserDefaults standardUserDefaults] stringForKey:@"environment"]]

#define UIViewParentController(__view) ({ \
    UIResponder *__responder = __view; \
    while ([__responder isKindOfClass:[UIView class]]) \
    __responder = [__responder nextResponder]; \
    (UIViewController *)__responder; \
    })

#define IS_IPHONE        (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define IS_IPHONE_5 ([[UIScreen mainScreen] bounds].size.height == 568.0)
#define IS_TINY ([[UIScreen mainScreen] bounds].size.height == 480)

@interface OnboardingViewController () <RSKImageCropViewControllerDelegate, RSKImageCropViewControllerDataSource> {
    UIEdgeInsets safeAreaInsets;
    NSArray *colors;
}

@property (nonatomic) NSInteger themeColor;
@property (nonatomic) int currentStep;
@property (strong, nonatomic) NSMutableArray *steps;
@property (strong, nonatomic) LauncherNavigationViewController *launchNavVC;
@property (nonatomic) CGFloat currentKeyboardHeight;

@end

@implementation OnboardingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.manager = [HAWebService manager];
    
    [self addListeners];
    [self setupViews];
    [self setupSteps];
    
    // –––– show the first step ––––
    self.currentStep = -1;
    [self nextStep:false];
    
    safeAreaInsets.top = 1; // set to 1 so we only set it once in viewWillAppear
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self updateSafeAreaInsets];
    });
}

- (void)updateSafeAreaInsets {
    safeAreaInsets = [UIApplication sharedApplication].keyWindow.safeAreaInsets;
    
    self.closeButton.frame = CGRectMake(self.view.frame.size.width - 44 - 11, safeAreaInsets.top, 60, 60);
    self.backButton.frame = CGRectMake(0, self.closeButton.frame.origin.y, 44, 44);
}

- (void)addListeners {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillDismiss:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)setupViews {
    self.closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.closeButton.hidden = true;
    [self.closeButton setImage:[[UIImage imageNamed:@"navCloseIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    self.closeButton.tintColor = [self.view tintColor];
    self.closeButton.contentMode = UIViewContentModeCenter;
    [self.closeButton bk_whenTapped:^{
        [self.view endEditing:TRUE];
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    [self.view addSubview:self.closeButton];
    
    self.backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.backButton.titleLabel.font = [UIFont systemFontOfSize:20.f weight:UIFontWeightSemibold];
    [self.backButton setTitleColor:[UIColor colorWithWhite:0.6f alpha:1] forState:UIControlStateDisabled];
    [self.backButton setImage:[[UIImage imageNamed:@"leftArrowIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    self.backButton.tintColor = self.view.tintColor;
    self.backButton.alpha = 0;
    [self.backButton bk_whenTapped:^{
        [self previousStep:-1];
    }];
    [self.view addSubview:self.backButton];
    
    self.nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.nextButton.frame = CGRectMake(24, self.view.frame.size.height, self.view.frame.size.width - (24 * 2), 48);
    self.nextButton.backgroundColor = [self.view tintColor];
    self.nextButton.titleLabel.font = [UIFont systemFontOfSize:20.f weight:UIFontWeightSemibold];
    [self.nextButton setTitleColor:[UIColor colorWithWhite:0.6f alpha:1] forState:UIControlStateDisabled];
    [self continuityRadiusForView:self.nextButton withRadius:12.f];
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
    CGFloat inputCenterY = (self.view.frame.size.height / 2) - (self.view.frame.size.height * .15);
    self.instructionLabel = [[UILabel alloc] initWithFrame:CGRectMake(48, 129, self.view.frame.size.width - 96, 42)];
    self.instructionLabel.center = CGPointMake(self.instructionLabel.center.x, (inputCenterY / 2) + 16);
    self.instructionLabel.textAlignment = NSTextAlignmentCenter;
    self.instructionLabel.text = @"Last step, and it’s a fun one! What’s your favorite color?";
    self.instructionLabel.font = [UIFont systemFontOfSize:18.f weight:UIFontWeightMedium];
    self.instructionLabel.textColor = [UIColor colorWithWhite:0.2f alpha:1];
    self.instructionLabel.numberOfLines = 0;
    self.instructionLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [self.view addSubview:self.instructionLabel];
    
    self.steps = [[NSMutableArray alloc] init];
    
    [self.steps addObject:@{@"id": @"user_email", @"skip": [NSNumber numberWithBool:false], @"next": @"Next", @"instruction": @"Welcome to Bonfire!\nWhat’s your email?", @"placeholder": @"Email Address", @"sensitive": [NSNumber numberWithBool:false], @"keyboard": @"email", @"textField": [NSNull null], @"block": [NSNull null]}];
    [self.steps addObject:@{@"id": @"user_password", @"skip": [NSNumber numberWithBool:false], @"next": @"Next", @"instruction": @"Hi again! 👋\nEnter your password to login", @"placeholder":@"Password", @"sensitive": [NSNumber numberWithBool:true], @"keyboard": @"text", @"textField": [NSNull null], @"block": [NSNull null]}];
    [self.steps addObject:@{@"id": @"user_set_password", @"skip": [NSNumber numberWithBool:false], @"next": @"Next", @"instruction": @"Let’s get you signed up!\nPlease set a password", @"placeholder": @"Password", @"sensitive": [NSNumber numberWithBool:true], @"keyboard": @"text", @"textField": [NSNull null], @"block": [NSNull null]}];
    [self.steps addObject:@{@"id": @"user_confirm_password", @"skip": [NSNumber numberWithBool:false], @"next": @"Confirm", @"instruction": @"Just to be sure... please confirm your password!", @"placeholder":@"Confirm Password", @"sensitive": [NSNumber numberWithBool:true], @"keyboard": @"text", @"textField": [NSNull null], @"block": [NSNull null]}];
    [self.steps addObject:@{@"id": @"user_display_name", @"skip": [NSNumber numberWithBool:false], @"next": @"Next", @"instruction": @"What would you like your display name to be?", @"placeholder": @"Your Name", @"sensitive": [NSNumber numberWithBool:false], @"keyboard": @"text", @"textField": [NSNull null], @"block": [NSNull null]}];
    [self.steps addObject:@{@"id": @"user_username", @"skip": [NSNumber numberWithBool:false], @"next": @"Next", @"instruction": @"Help others find you faster by setting a @username", @"placeholder": @"Username", @"sensitive": [NSNumber numberWithBool:false], @"keyboard": @"text", @"textField": [NSNull null], @"block": [NSNull null]}];
    [self.steps addObject:@{@"id": @"user_profile_picture", @"skip": [NSNumber numberWithBool:false], @"next": @"Next", @"instruction": @"Set a profile picture\n(optional)", @"block": [NSNull null]}];
    [self.steps addObject:@{@"id": @"user_color", @"skip": [NSNumber numberWithBool:false], @"next": @"Sign Up", @"instruction": @"Last step, and it’s a fun one! What’s your favorite color?", @"block": [NSNull null]}];
    
    for (int i = 0; i < [self.steps count]; i++) {
        // add each step to the right
        [self addStep:i usingArray:self.steps];
    }
}

- (void)addStep:(int)stepIndex usingArray:(NSMutableArray *)parentArray {
    NSMutableDictionary *mutatedStep = [[NSMutableDictionary alloc] initWithDictionary:parentArray[stepIndex]];
    
    if ([mutatedStep objectForKey:@"textField"] && ![mutatedStep[@"textfield"] isEqual:[NSNull null]]) {
        UIView *inputBlock = [[UIView alloc] initWithFrame:CGRectMake(0, (self.view.frame.size.height / 2) - (56 / 2) - (self.view.frame.size.height * .15), self.view.frame.size.width, 56)];
        [self.view addSubview:inputBlock];
        
        UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(24, 0, self.view.frame.size.width - (24 * 2), 56)];
        textField.textColor = [UIColor colorWithWhite:0.2f alpha:1];
        textField.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1];
        textField.tintColor = self.view.tintColor;
        [self continuityRadiusForView:textField withRadius:12.f];
        
        
        if ([mutatedStep objectForKey:@"keyboard"] && [mutatedStep[@"keyboard"] isEqualToString:@"email"]) {
            textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            textField.keyboardType = UIKeyboardTypeEmailAddress;
            textField.autocorrectionType = UITextAutocorrectionTypeNo;
            textField.tag = 101;
        }
        else if ([mutatedStep objectForKey:@"keyboard"] && [mutatedStep[@"keyboard"] isEqualToString:@"number"]) {
            textField.tag = 102;
            
            textField.keyboardType = UIKeyboardTypeNumberPad;
            NSLog(@"keyboard number");
        }
        else {
            textField.keyboardType = UIKeyboardTypeDefault;
            
            if ([mutatedStep objectForKey:@"keyboard"] && [mutatedStep[@"keyboard"] isEqualToString:@"title"]) {
                textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
            }
            else if ([mutatedStep[@"id"] isEqualToString:@"user_username"]) {
                textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
                textField.autocorrectionType = UITextAutocorrectionTypeNo;
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
        leftView.backgroundColor = textField.backgroundColor;
        textField.leftView = leftView;
        textField.rightView = leftView;
        textField.leftViewMode = UITextFieldViewModeAlways;
        textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:([mutatedStep objectForKey:@"placeholder"] ? mutatedStep[@"placeholder"] : @"") attributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:0.2f alpha:0.25]}];
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
    else if ([mutatedStep[@"id"] isEqualToString:@"user_color"]) {
        UIView *colorBlock = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.width, 216, 216)];
        colorBlock.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2);
        colorBlock.layer.cornerRadius = 10.f;
        colorBlock.alpha = 0;
        colorBlock.transform = CGAffineTransformMakeTranslation(self.view.frame.size.width, 0);
        [self.view addSubview:colorBlock];
        
        colors = @[[UIColor bonfireBlue],  // 0
                   [UIColor bonfireViolet],  // 1
                   [UIColor bonfireRed],  // 2
                   [UIColor bonfireOrange],  // 3
                   [UIColor bonfireGreenWithLevel:700],  // 4
                   [UIColor brownColor],  // 5
                   [UIColor bonfireYellow],  // 6
                   [UIColor bonfireCyanWithLevel:800],  // 7
                   [UIColor bonfireGrayWithLevel:900]]; // 8
        
        self.themeColor = 0 + arc4random() % (colors.count - 1);
        
        NSLog(@"self.themeColor: %li", (long)self.themeColor);
        
        for (int i = 0; i < 9; i++) {
            int row = i % 3;
            int column = floorf(i / 3);
            
            NSLog(@"r: %i / c: %i", row, column);
            
            UIView *colorOption = [[UIView alloc] initWithFrame:CGRectMake(column * 80, row * 80, 56, 56)];
            colorOption.layer.cornerRadius = colorOption.frame.size.height / 2;
            colorOption.backgroundColor = colors[i];
            colorOption.tag = i;
            [colorBlock addSubview:colorOption];
            
            if (i == (int)self.themeColor) {
                // add check image view
                UIImageView *checkView = [[UIImageView alloc] initWithFrame:CGRectMake(-6, -6, colorOption.frame.size.width + 12, colorOption.frame.size.height + 12)];
                checkView.contentMode = UIViewContentModeCenter;
                checkView.image = [UIImage imageNamed:@"selectedColorCheck"];
                checkView.tag = 999;
                checkView.layer.cornerRadius = checkView.frame.size.height / 2;
                checkView.layer.borderColor = colorOption.backgroundColor.CGColor;
                checkView.layer.borderWidth = 3.f;
                checkView.backgroundColor = [UIColor clearColor];
                [colorOption addSubview:checkView];
            }
            
            [colorOption bk_whenTapped:^{
                [self setColor:colorOption];
            }];
        }
        
        [mutatedStep setObject:colorBlock forKey:@"block"];
    }
    else if ([mutatedStep[@"id"] isEqualToString:@"user_profile_picture"]) {
        UIImageView *userProfilePictureBlock = [[UIImageView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.width, 160, 160)];
        [self continuityRadiusForView:userProfilePictureBlock withRadius:32.f];
        userProfilePictureBlock.image = [UIImage imageNamed:@"addProfilePicture"];
        userProfilePictureBlock.center = CGPointMake(self.view.frame.size.width / 2, (self.view.frame.size.height / self.view.transform.d) / 2);
        userProfilePictureBlock.alpha = 0;
        userProfilePictureBlock.transform = CGAffineTransformMakeTranslation(self.view.frame.size.width, 0);
        userProfilePictureBlock.contentMode = UIViewContentModeScaleAspectFill;
        userProfilePictureBlock.userInteractionEnabled = true;
        [self.view addSubview:userProfilePictureBlock];
        
        [userProfilePictureBlock bk_whenTapped:^{
            // open room share
            [self showImagePicker];
        }];
        
        [mutatedStep setObject:userProfilePictureBlock forKey:@"block"];
    }
    
    [parentArray replaceObjectAtIndex:stepIndex withObject:mutatedStep];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField.tag == 10) {
        return false; // disable editing for share field
    }
    
    return true;
}

- (void)setColor:(UIView *)sender {
    if (sender.tag != self.themeColor) {
        [HapticHelper generateFeedback:FeedbackType_Selection];
        
        // remove previously selected color
        int colorStep = [self getIndexOfStepWithId:@"user_color"];
        UIView *colorBlock = self.steps[colorStep][@"block"];
        
        NSLog(@"previous color: %li", (long)self.themeColor);
        
        UIView *previousColorView;
        for (UIView *subview in colorBlock.subviews) {
            if (subview.tag == self.themeColor) {
                previousColorView = subview;
                break;
            }
        }
        NSLog(@"previousColorView: %@", previousColorView);
        for (UIImageView *imageView in previousColorView.subviews) {
            NSLog(@"imageView unda: %@", imageView);
            if (imageView.tag == 999) {
                [UIView animateWithDuration:0.25f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                    imageView.transform = CGAffineTransformMakeScale(0.1, 0.1);
                    imageView.alpha = 0;
                } completion:^(BOOL finished) {
                    [imageView removeFromSuperview];
                }];
                break;
            }
        }
        
        NSLog(@"new color: %li", (long)sender.tag);
        self.themeColor = sender.tag;
        
        // add check image view
        UIImageView *checkView = [[UIImageView alloc] initWithFrame:CGRectMake(-6, -6, sender.frame.size.width + 12, sender.frame.size.height + 12)];
        checkView.contentMode = UIViewContentModeCenter;
        checkView.image = [UIImage imageNamed:@"selectedColorCheck"];
        checkView.tag = 999;
        checkView.layer.cornerRadius = checkView.frame.size.height / 2;
        checkView.layer.borderColor = sender.backgroundColor.CGColor;
        checkView.layer.borderWidth = 3.f;
        checkView.backgroundColor = [UIColor clearColor];
        [sender addSubview:checkView];
        
        checkView.transform = CGAffineTransformMakeScale(0.8, 0.8);
        checkView.alpha = 0;
        
        [UIView animateWithDuration:0.6f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.nextButton.backgroundColor = sender.backgroundColor;
            self.closeButton.tintColor = sender.backgroundColor;
            self.backButton.tintColor = sender.backgroundColor;
            
            checkView.transform = CGAffineTransformMakeScale(1, 1);
            checkView.alpha = 1;
        } completion:nil];
    }
    
}

- (int)getIndexOfStepWithId:(NSString *)stepId {
    for (int i = 0; i < [self.steps count]; i++) {
        if ([self.steps[i][@"id"] isEqualToString:stepId]) {
            return i;
        }
    }
    return 0;
}

- (void)textFieldChanged:(UITextField *)sender {
    if ([self.steps[self.currentStep][@"id"] isEqualToString:@"user_email"]) {
        if ([self isValidEmail:sender.text]) {
            // qualifies
            self.nextButton.backgroundColor = self.view.tintColor;
            self.nextButton.enabled = true;
        }
        else {
            [self greyOutNextButton];
        }
    }
    
    if ([self.steps[self.currentStep][@"id"] isEqualToString:@"user_password"] ||
        [self.steps[self.currentStep][@"id"] isEqualToString:@"user_set_password"] ||
        [self.steps[self.currentStep][@"id"] isEqualToString:@"user_confirm_password"]) {
        if ([self isValidPassword:sender.text]) {
            // qualifies
            self.nextButton.backgroundColor = self.view.tintColor;
            self.nextButton.enabled = true;
        }
        else {
            [self greyOutNextButton];
        }
    }
}
- (BOOL)isValidEmail:(NSString *)checkString
{
    BOOL stricterFilter = NO; // Discussion http://blog.logichigh.com/2010/09/02/validating-an-e-mail-address/
    NSString *stricterFilterString = @"^[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}$";
    NSString *laxString = @"^.+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2}[A-Za-z]*$";
    NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:checkString];
}
- (BOOL)isValidPassword:(NSString *)passwordString {
    return [passwordString lengthOfBytesUsingEncoding:NSUTF8StringEncoding] >= 6;
}

- (void)greyOutNextButton {
    self.nextButton.enabled = false;
    self.nextButton.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1];
}

- (void)handleNext {
    NSDictionary *step = self.steps[self.currentStep];
    
    self.nextButton.userInteractionEnabled = false;
    
    // sign in to school
    if ([step[@"id"] isEqualToString:@"user_email"]) {
        // check for similar names
        [self greyOutNextButton];
        [self showSpinnerForStep:self.currentStep];
        
        // check if user exists
        UITextField *textField = step[@"textField"];
        NSString *url = [NSString stringWithFormat:@"%@/%@/accounts/validate/email", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"]]; // sample data
        [self.manager GET:url parameters:@{@"email": textField.text} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, NSDictionary *responseObject) {
            [self removeSpinnerForStep:self.currentStep];
            
            BOOL isValid = [responseObject[@"data"][@"valid"] boolValue];
            BOOL isOccupied = [responseObject[@"data"][@"occupied"] boolValue];
            
            NSLog(@"isValid? %@", (isValid ? @"YES" : @"NO" ));
            NSLog(@"isOccupied? %@", (isOccupied ? @"YES" : @"NO" ));
            
            if (isValid) {
                if (isOccupied) {
                    // proceed to login
                    [self prepareForLogin];
                }
                else {
                    // proceed to sign up
                    [self prepareForSignUp];
                }
                
                [self nextStep:true];
            }
            else {
                // email not valid
                [self removeSpinnerForStep:self.currentStep];
                [self shakeInputBlock];
                
                [self enableNextButton];
                
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Email Not Valid" message:@"We had an issue verifying your email. Please make sure there aren't any typos in the email provided." preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *gotItAction = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                    [alert dismissViewControllerAnimated:true completion:nil];
                }];
                [alert addAction:gotItAction];
                [self presentViewController:alert animated:YES completion:nil];
            }
            
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            // not long enough –> shake input block
            [self removeSpinnerForStep:self.currentStep];
            [self shakeInputBlock];
            
            self.nextButton.enabled = true;
            self.nextButton.backgroundColor = self.view.tintColor;
            self.nextButton.userInteractionEnabled = true;
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Uh oh!" message:@"We encountered a network error while looking up your account. Check your network settings and try again." preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *gotItAction = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                [alert dismissViewControllerAnimated:true completion:nil];
            }];
            [alert addAction:gotItAction];
            [self presentViewController:alert animated:YES completion:nil];
        }];
    }
    else if ([step[@"id"] isEqualToString:@"user_password"]) {
        // sign in to user
        [self attemptToSignIn];
    }
    else if ([step[@"id"] isEqualToString:@"user_username"]) {
        UITextField *textField = step[@"textField"];
        
        if ([textField.text isEqualToString:[Session sharedInstance].currentUser.identifier]) {
            // good to go -> they didn't change anything
            [self nextStep:true];
        }
        else {
            // verify username is available
            [self greyOutNextButton];
            [self showSpinnerForStep:self.currentStep];
            
            // check if user exists
            NSString *url = [NSString stringWithFormat:@"%@/%@/accounts/validate/username", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"]]; // sample data
            [self.manager GET:url parameters:@{@"username": [textField.text stringByReplacingOccurrencesOfString:@"@" withString:@""]} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, NSDictionary *responseObject) {
                [self removeSpinnerForStep:self.currentStep];
                
                BOOL isValid = [responseObject[@"data"][@"valid"] boolValue];
                BOOL isOccupied = [responseObject[@"data"][@"occupied"] boolValue];
                
                NSLog(@"isValid? %@", (isValid ? @"YES" : @"NO" ));
                NSLog(@"isOccupied? %@", (isOccupied ? @"YES" : @"NO" ));
                
                if (isValid && !isOccupied) {
                    // username is available -> proceed to next step
                    [self nextStep:true];
                }
                else if (!isValid) {
                    // email not valid
                    [self shakeInputBlock];
                    
                    [self enableNextButton];
                    
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Username Not Valid" message:@"Please ensure the username you provided is at least 3 characters and only contains letters, numbers, and underscores (_)." preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *gotItAction = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                        [alert dismissViewControllerAnimated:true completion:nil];
                    }];
                    [alert addAction:gotItAction];
                    [self presentViewController:alert animated:YES completion:nil];
                }
                else {
                    // email not valid
                    [self shakeInputBlock];
                    
                    [self enableNextButton];
                    
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Username Not Available" message:@"The username you provided is not available, please try another one!" preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *gotItAction = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                        [alert dismissViewControllerAnimated:true completion:nil];
                    }];
                    [alert addAction:gotItAction];
                    [self presentViewController:alert animated:YES completion:nil];
                }
                
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                // not long enough –> shake input block
                [self removeSpinnerForStep:self.currentStep];
                [self shakeInputBlock];
                
                self.nextButton.enabled = true;
                self.nextButton.backgroundColor = self.view.tintColor;
                self.nextButton.userInteractionEnabled = true;
                
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Uh oh!" message:@"We encountered a network error while verifying the provided username is available. Check your network settings and try again." preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *gotItAction = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                    [alert dismissViewControllerAnimated:true completion:nil];
                }];
                [alert addAction:gotItAction];
                [self presentViewController:alert animated:YES completion:nil];
            }];
        }
    }
    else if ([self.steps[self.currentStep][@"id"] isEqualToString:@"user_confirm_password"]) {
        int passwordStep = [self getIndexOfStepWithId:@"user_set_password"];
        UITextField *passwordTextField = self.steps[passwordStep][@"textField"];
        NSString *password = passwordTextField.text;
        
        UITextField *confirmPasswordTextField = self.steps[self.currentStep][@"textField"];
        NSString *confirmPassword = confirmPasswordTextField.text;
        
        if ([password isEqualToString:confirmPassword]) {
            [self nextStep:true];
        }
        else {
            // not long enough –> shake input block
            [self shakeInputBlock];
            
            self.nextButton.enabled = true;
            self.nextButton.backgroundColor = self.view.tintColor;
            self.nextButton.userInteractionEnabled = true;
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Password Doesn't Match" message:@"The passwords you provided don't match. Please try again or go back to set a new one." preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *gotItAction = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                [alert dismissViewControllerAnimated:true completion:nil];
            }];
            [alert addAction:gotItAction];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }
    else if ([step[@"id"] isEqualToString:@"user_display_name"]) {
        // sign in to user
        [self greyOutNextButton];
        [self showSpinnerForStep:self.currentStep];
        
        [self attemptToSignUp];
    }
    else if ([step[@"id"] isEqualToString:@"user_color"]) {
        [self greyOutNextButton];
        [self showBigSpinnerForStep:self.currentStep];
        
        [self attemptToSaveUser];
    }
    else {
        [self nextStep:true];
    }
}
- (void)enableNextButton {
    self.nextButton.enabled = true;
    self.nextButton.backgroundColor = self.view.tintColor;
    self.nextButton.userInteractionEnabled = true;
}
- (void)prepareForLogin {
    // skip everything except email and password
    for (int i = 0; i < self.steps.count; i++) {
        NSMutableDictionary *step = [[NSMutableDictionary alloc] initWithDictionary:self.steps[i]];
        if ([step[@"id"] isEqualToString:@"user_email"] || [step[@"id"] isEqualToString:@"user_password"]) {
            [step setObject:[NSNumber numberWithBool:false] forKey:@"skip"];
        }
        else {
            [step setObject:[NSNumber numberWithBool:true] forKey:@"skip"];
        }
        [self.steps replaceObjectAtIndex:i withObject:step];
    }
}
- (void)prepareForSignUp {
    // only skip password
    for (int i = 0; i < self.steps.count; i++) {
        NSMutableDictionary *step = [[NSMutableDictionary alloc] initWithDictionary:self.steps[i]];
        if ([step[@"id"] isEqualToString:@"user_password"]) {
            [step setObject:[NSNumber numberWithBool:true] forKey:@"skip"];
        }
        else {
            [step setObject:[NSNumber numberWithBool:false] forKey:@"skip"];
        }
        [self.steps replaceObjectAtIndex:i withObject:step];
    }
}
- (void)attemptToSignIn {
    [self greyOutNextButton];
    [self showSpinnerForStep:self.currentStep];
    
    // check if user exists
    int emailStep = [self getIndexOfStepWithId:@"user_email"];
    UITextField *emailTextField = self.steps[emailStep][@"textField"];
    NSString *email = emailTextField.text;
    
    int passwordStep = [self getIndexOfStepWithId:@"user_password"];
    UITextField *passwordTextField = self.steps[passwordStep][@"textField"];
    NSString *password = passwordTextField.text;
    
    NSString *url = [NSString stringWithFormat:@"%@/%@/oauth", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"]]; // sample data
    [self.manager POST:url parameters:@{@"email": email, @"password": password, @"grant_type": @"password"} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, NSDictionary *responseObject) {
        [self removeSpinnerForStep:self.currentStep];
        
        [[Session sharedInstance] setAccessToken:responseObject[@"data"]];
        
        NSLog(@"responseObject: %@", responseObject);
        
        NSLog(@"all done! successfully logged in!");
        
        // TODO: Open LauncherNavigationViewController
        [[Session sharedInstance] fetchUser:^(BOOL success) {
            if (success) {
                [self openHome];
            }
        }];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        // not long enough –> shake input block
        [self removeSpinnerForStep:self.currentStep];
        [self shakeInputBlock];
        
        [self enableNextButton];
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Uh oh!" message:@"We encountered an error while signing you in. Please try again and check back soon for an update." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *gotItAction = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [alert dismissViewControllerAnimated:true completion:nil];
        }];
        [alert addAction:gotItAction];
        [self presentViewController:alert animated:YES completion:nil];
    }];
}
- (void)attemptToSignUp {
    NSString *url = [NSString stringWithFormat:@"%@/%@/accounts", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"]];
    
    int emailStep = [self getIndexOfStepWithId:@"user_email"];
    UITextField *emailTextField = self.steps[emailStep][@"textField"];
    NSString *email = emailTextField.text;
    
    int passwordStep = [self getIndexOfStepWithId:@"user_set_password"];
    UITextField *passwordTextField = self.steps[passwordStep][@"textField"];
    NSString *password = passwordTextField.text;
    
    int displayNameStep = [self getIndexOfStepWithId:@"user_display_name"];
    UITextField *displayNameTextField = self.steps[displayNameStep][@"textField"];
    NSString *displayName = displayNameTextField.text;
    
    NSLog(@"params: %@", @{@"email": email, @"password": password, @"display_name": displayName});
    
    [self.manager.requestSerializer setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [self.manager POST:url parameters:@{@"email": email, @"password": password, @"display_name": displayName} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"responseObject: %@", responseObject);
        
        NSError *error;
        User *user = [[User alloc] initWithDictionary:responseObject[@"data"] error:&error];
        [[Session sharedInstance] updateUser:user];
        if (error) {
            NSLog(@"error creating user object: %@", error);
        }
        
        int usernameStep = [self getIndexOfStepWithId:@"user_username"];
        UITextField *usernameTextField = self.steps[usernameStep][@"textField"];
        usernameTextField.text = [NSString stringWithFormat:@"@%@", user.attributes.details.identifier];
        
        // get access token for user
        NSString *oauthURL = [NSString stringWithFormat:@"%@/%@/oauth", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"]]; // sample data
        [self.manager POST:oauthURL parameters:@{@"email": email, @"password": password, @"grant_type": @"password"} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, NSDictionary *responseObject) {
            [self removeSpinnerForStep:self.currentStep];
            
            [[Session sharedInstance] setAccessToken:responseObject[@"data"]];
            
            NSLog(@"responseObject: %@", responseObject);
            
            NSLog(@"all done! successfully logged in!");
            
            [self enableNextButton];
            
            // move spinner
            [self removeSpinnerForStep:self.currentStep];
            [self nextStep:true];
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            // not long enough –> shake input block
            [self removeSpinnerForStep:self.currentStep];
            [self shakeInputBlock];
            
            [self enableNextButton];
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Uh oh!" message:@"We encountered an error while signing you up. Check your network settings and try again." preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *gotItAction = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                [alert dismissViewControllerAnimated:true completion:nil];
            }];
            [alert addAction:gotItAction];
            [self presentViewController:alert animated:YES completion:nil];
        }];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        NSLog(@"error: %@", error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey]);
        NSString* ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        NSLog(@"%@",ErrorResponse);
        
        // email not valid
        [self removeSpinnerForStep:self.currentStep];
        [self shakeInputBlock];
        
        [self enableNextButton];
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Unexpected Error" message:@"We had an issue verifying your account. Check your network settings and try again." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *gotItAction = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [alert dismissViewControllerAnimated:true completion:nil];
        }];
        [alert addAction:gotItAction];
        [self presentViewController:alert animated:YES completion:nil];
    }];
}
- (void)attemptToSaveUser {
    NSString *url;// = [NSString stringWithFormat:@"%@/%@/schools/%@/channels/%@", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"], @"2", @"default"];
    url = [NSString stringWithFormat:@"%@/%@/rooms", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"]]; // sample data
    
    int usernameStep = [self getIndexOfStepWithId:@"user_username"];
    UITextField *usernameTextField = self.steps[usernameStep][@"textField"];
    NSString *username = [usernameTextField.text stringByReplacingOccurrencesOfString:@"@" withString:@""];
    
    int profilePictureStep = [self getIndexOfStepWithId:@"user_profile_picture"];
    UIImageView *profilePictureImageView = self.steps[profilePictureStep][@"block"];
    UIImage *profilePicture = profilePictureImageView.image;
    
    NSString *color = [UIColor toHex:colors[self.themeColor]];
    
    NSLog(@"params: %@", @{@"username": username, @"color": color});
    
    [self uploadProfilePicture:profilePicture copmletion:^(BOOL success, NSString *img) {
        [self.manager.requestSerializer setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        [[Session sharedInstance] authenticate:^(BOOL success, NSString *token) {
            if (success) {
                [self.manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
                [self.manager POST:url parameters:@{@"username": username, @"color": color} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                    NSLog(@"responseObject: %@", responseObject);
                    
                    self.nextButton.enabled = true;
                    self.nextButton.backgroundColor = [self currentColor];
                    
                    // move spinner
                    [self removeBigSpinnerForStep:self.currentStep push:true];
                    
                    NSLog(@"all done! successfully saved user!");
                    
                    // TODO: Open LauncherNavigationViewController
                    [self openHome];
                } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                    
                    NSLog(@"error: %@", error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey]);
                    NSString* ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                    NSLog(@"%@",ErrorResponse);
                    
                    [self removeBigSpinnerForStep:self.currentStep push:false];
                    self.nextButton.enabled = true;
                    self.nextButton.backgroundColor = [self currentColor];
                    self.nextButton.userInteractionEnabled = true;
                    [self shakeInputBlock];
                }];
            }
        }];
    }];
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
    
    int next = self.currentStep;

    BOOL isComplete = true; // true until proven false
    for (int i = self.currentStep + 1; i < [self.steps count]; i++) {
        // steps to the right of the currentStep
        if (i >= [self.steps count]) {
            // does not have a next step // this should never happen
            NSLog(@"Could not find a next step.");
            next = self.currentStep + 1;
        }
        else {
            NSDictionary *step = self.steps[i];
            if (![step[@"skip"] boolValue]) {
                NSLog(@"this is the next step");
                next = i;
            }
            else {
                NSLog(@"skip step");
            }
        }
        if (next != self.currentStep && i < [self.steps count]) {
            NSDictionary *step = self.steps[i];
            // we found the next step
            // now we need to find if there are any remaining steps (that have skip='false')
            if (![step[@"skip"] boolValue]) {
                isComplete = false;
                break;
            }
        }
    }
    
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
        NSLog(@"activeBlock: %@", activeBlock);
        
        NSDictionary *nextStep = self.steps[next];
        UIView *nextBlock = nextStep[@"block"];
        
        NSLog(@"next step: %@", [nextStep objectForKey:@"textField"]);
        
        if (self.backButton.alpha == 0 && next > 0) {
            [UIView animateWithDuration:0.3f animations:^{
                self.backButton.alpha = 1;
            }];
        }
        
        if ([nextStep[@"id"] isEqualToString:@"user_color"]) {
            [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.nextButton.backgroundColor = [self currentColor];
                self.closeButton.tintColor = [self currentColor];
            } completion:nil];
        }
        if ([nextStep[@"id"] isEqualToString:@"user_profile_picture"]) {
            // remove previously selected color
            UIButton *shareField = [nextBlock viewWithTag:10];
            UIButton *shareRoomButton = [nextBlock viewWithTag:11];
            shareRoomButton.tintColor = [self currentColor];
            [shareRoomButton setTitleColor:[self currentColor] forState:UIControlStateNormal];
            shareRoomButton.layer.borderColor = [[self currentColor] colorWithAlphaComponent:0.2f].CGColor;
            [shareField setTitle:@"blah blah blah" forState:UIControlStateNormal];
            
//            self.closeButton.userInteractionEnabled = false;
//            [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
//                self.closeButton.alpha = 0;
//            } completion:nil];
        }
        
        if ([nextStep objectForKey:@"textField"] && ![nextStep[@"textfield"] isEqual:[NSNull null]]) {
            UITextField *nextTextField = nextStep[@"textField"];
            
            CGFloat delay = self.currentStep == -1 ? 0.4f : 0;
            
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
            NSData *tempInstructionArchive = [NSKeyedArchiver archivedDataWithRootObject:self.instructionLabel];
            UILabel *instructionCopy = [NSKeyedUnarchiver unarchiveObjectWithData:tempInstructionArchive];
            instructionCopy.alpha = 0;
            
            NSString *nextStepTitle = nextStep[@"instruction"];
            instructionCopy.text = nextStepTitle;
            
            CGRect instructionsDynamicFrame = [instructionCopy.text boundingRectWithSize:CGSizeMake(self.instructionLabel.frame.size.width, 100) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:instructionCopy.font} context:nil];
            instructionCopy.frame = CGRectMake(self.instructionLabel.frame.origin.x, self.instructionLabel.frame.origin.y, self.instructionLabel.frame.size.width, instructionsDynamicFrame.size.height);
            
            instructionCopy.transform = CGAffineTransformMakeTranslation(self.view.frame.size.width, 0);
            
            [self.view addSubview:instructionCopy];
            
            [UIView animateWithDuration:animationDuration delay:0 usingSpringWithDamping:0.8f initialSpringVelocity:0.4f options:UIViewAnimationOptionCurveEaseIn animations:^{
                self.instructionLabel.transform = CGAffineTransformMakeTranslation(-1 * self.view.frame.size.width, 0);
                self.instructionLabel.alpha = 0;
                
                instructionCopy.transform = CGAffineTransformMakeTranslation(0, 0);
                instructionCopy.alpha = 1;
            } completion:^(BOOL finished) {
                // save copy as the original mainNavLabel
                [self.instructionLabel removeFromSuperview];
                self.instructionLabel = instructionCopy;
            }];
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
- (void)previousStep:(int)previous {
    /*
     
     PREVIOUS STEP
     –––––––––
     purpose: show the previous step in the flow. in most cases, this means animating the previous step in and the current step out.
     
     */
    
    if (previous == -1) {
        previous = self.currentStep;
        for (int i = self.currentStep - 1; i >= 0; i--) {
            // steps to the right of the currentStep
            if (i <= 0) {
                // does not have a previous step // this should never happen
                NSLog(@"Could not find a previous step.");
                previous = self.currentStep - 1;
            }
            else {
                NSDictionary *step = self.steps[i];
                if (![step[@"skip"] boolValue]) {
                    NSLog(@"this is the previous step");
                    previous = i;
                }
                else {
                    NSLog(@"skip step");
                }
            }
        }
    }
    
    NSLog(@"currentStep: %i", self.currentStep);
    NSLog(@"previousStep: %i", previous);
    
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
            previousTextField.textColor = [UIColor colorWithWhite:0.2f alpha:1];
        }
        
        NSDictionary *activeStep = self.steps[self.currentStep];
        UIView *activeBlock = activeStep[@"block"];
        UITextField *activeTextField = activeStep[@"textField"];
        
        NSLog(@"activeBlock: %@", activeBlock);
        
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

- (void)uploadProfilePicture:(UIImage *)profilePicture copmletion:(void (^)(BOOL success, NSString *img))handler {
    CGImageRef cgref = [profilePicture CGImage];
    CIImage *cim = [profilePicture CIImage];
    
    if (profilePicture && (cim != nil || cgref != NULL) && [profilePicture isKindOfClass:[UIImage class]]) {
        // has images
        NSLog(@"has profile picture to upload -> upload them then continue");
        
        NSString *url = [NSString stringWithFormat:@"%@/%@/upload", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"]];
        NSLog(@"POST /images url: %@", url);
        
        [[Session sharedInstance] authenticate:^(BOOL success, NSString *token) {
            if (success) {
                AFHTTPSessionManager *localManager = [AFHTTPSessionManager manager];
                [localManager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
                [localManager.requestSerializer setValue:envConfig[@"API_KEY"] forHTTPHeaderField:@"x-hallway-apikey"];
                [localManager.requestSerializer setValue:[NSString stringWithFormat:@"iosClient/%@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]] forHTTPHeaderField:@"x-hallway-client"];
                [localManager.requestSerializer setValue:@"https://hallway.app" forHTTPHeaderField:@"origin"];
                [localManager.requestSerializer setValue:nil forHTTPHeaderField:@"Origin"];
                
                [localManager POST:url parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
                    NSData *imageData = [self compressAndEncodeToData:profilePicture];
                    [formData appendPartWithFileData:imageData name:@"img" fileName:@"image.jpg" mimeType:@"image/jpeg"];
                } progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                    NSLog(@"--------");
                    NSLog(@"response object:");
                    NSLog(@"%@", responseObject);
                    NSLog(@"--------");
                    
                    if (responseObject[@"data"] && responseObject[@"data"] != [NSNull null] && [responseObject[@"data"] count] > 0) {
                        handler(true, [NSString stringWithFormat:@"%@", responseObject[@"data"][0][@"id"]]);
                    }
                    else {
                        handler(false, nil);
                    }
                } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                    NSLog(@"error: %@", error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey]);
                    NSString* ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                    NSLog(@"%@",ErrorResponse);
                    NSLog(@"%@", error);
                    NSLog(@"idk: %@", task.response);
                    
                    handler(false, nil);
                }];
            }
            else {
                handler(false, nil);
            }
        }];
    }
    else {
        NSLog(@"does not have profile picture -> proceed to create account");
        handler(true, nil);
    }
}

// Image compressions -> images should never be > 2mb
- (NSData *)compressAndEncodeToData:(UIImage *)image
{
    //Scale Image to some width (xFinal)
    float ratio = image.size.width/image.size.height;
    float xFinal = image.size.width;
    if (image.size.width > 1125) {
        xFinal = 1125; //Desired max image width
    }
    float yFinal = xFinal/ratio;
    UIImage *scaledImage = [self imageWithImage:image scaledToSize:CGSizeMake(xFinal, yFinal)];
    
    //Compress the image iteratively until either the maximum compression threshold (maxCompression) is reached or the maximum file size requirement is satisfied (maxSize)
    CGFloat compression = 1.0f;
    CGFloat maxCompression = 0.1f;
    float maxSize = 2*1024*1024; //specified in bytes
    
    NSData *imageData = UIImageJPEGRepresentation(scaledImage, compression);
    while ([imageData length] > maxSize && compression > maxCompression) {
        compression -= 0.10;
        imageData = UIImageJPEGRepresentation(scaledImage, compression);
        NSLog(@"Compressed to: %.2f MB with Factor: %.2f",(float)imageData.length/1024.0f/1024.0f, compression);
    }
    NSLog(@"Final Image Size: %.2f MB",(float)imageData.length/1024.0f/1024.0f);
    return imageData;
}
// Ancillary method to scale an image based on a CGSize
- (UIImage *)imageWithImage:(UIImage*)originalImage scaledToSize:(CGSize)newSize;
{
    @synchronized(self)
    {
        UIGraphicsBeginImageContext(newSize);
        [originalImage drawInRect:CGRectMake(0,0,newSize.width, newSize.height)];
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return newImage;
    }
    return nil;
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

- (void)showSpinnerForStep:(int)step {
    UIView *block = (UIView *)[[self.steps objectAtIndex:step] objectForKey:@"block"];
    UITextField *textField = (UITextField *)[[self.steps objectAtIndex:step] objectForKey:@"textField"];
    
    UIImageView *miniSpinner = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
    miniSpinner.image = [[UIImage imageNamed:@"miniSpinner"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    miniSpinner.tintColor = [UIColor colorWithWhite:0.2f alpha:1];
    miniSpinner.center = CGPointMake(block.frame.size.width / 2, block.frame.size.height / 2);
    miniSpinner.alpha = 0;
    miniSpinner.tag = 1111;
    
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
        textField.textColor = [UIColor colorWithWhite:0.2f alpha:0];
        if (textField.placeholder != nil) {
            textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:textField.placeholder attributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:0.2f alpha:0]}];
        }
        textField.tintColor = [UIColor clearColor];
    } completion:nil];
}
- (void)removeSpinnerForStep:(int)step {
    UIView *block = (UIView *)[[self.steps objectAtIndex:step] objectForKey:@"block"];
    UITextField *textField = (UITextField *)[[self.steps objectAtIndex:step] objectForKey:@"textField"];
    UIImageView *miniSpinner = [block viewWithTag:1111];
    
    NSLog(@"textField: %@", textField);
    
    [UIView animateWithDuration:0.6f delay:0 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        miniSpinner.alpha = 0;
    } completion:^(BOOL finished) {
        [miniSpinner removeFromSuperview];
        
        NSLog(@"hola: %@", textField);
        
        [UIView transitionWithView:textField duration:0.3 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            textField.textColor = [UIColor colorWithWhite:0.2f alpha:1];
            textField.tintColor = [self.view tintColor];
            if (textField.placeholder != nil) {
                textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:textField.placeholder attributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:0.2f alpha:0.25]}];
            }
        } completion:^(BOOL finished) {
            NSLog(@"we finished something!!: %@", textField.textColor);
        }];
    }];
}

- (void)showBigSpinnerForStep:(int)step {
    UIView *block = (UIView *)[[self.steps objectAtIndex:step] objectForKey:@"block"];
    
    UIImageView *spinner = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 64, 64)];
    spinner.image = [[UIImage imageNamed:@"spinner"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    spinner.tintColor = [self currentColor];
    spinner.center = self.view.center;
    spinner.alpha = 0;
    spinner.tag = 1111;
    
    CABasicAnimation *rotationAnimation;
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0 /* full rotation*/ * 1 * 1.f ];
    rotationAnimation.duration = 1.f;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = HUGE_VALF;
    
    [spinner.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
    
    [self.view addSubview:spinner];
    
    [UIView animateWithDuration:0.3f animations:^{
        block.alpha = 0;
        self.backButton.alpha = 0;
        self.closeButton.alpha = 0;
    }];
    [UIView animateWithDuration:0.3f delay:0.3f options:UIViewAnimationOptionCurveEaseOut animations:^{
        spinner.alpha = 1;
    } completion:nil];
}
- (void)removeBigSpinnerForStep:(int)step push:(BOOL)push {
    UIView *block = (UIView *)[[self.steps objectAtIndex:step] objectForKey:@"block"];
    UIImageView *spinner = [self.view viewWithTag:1111];
    
    [UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        spinner.alpha = 0;
        
        if (push) {
            spinner.center = CGPointMake(-0.5 * self.view.frame.size.width, spinner.center.y);
        }
    } completion:^(BOOL finished) {
        [spinner removeFromSuperview];
        
        [UIView animateWithDuration:0.3f animations:^{
            block.alpha = 1;
            self.backButton.alpha = 1;
            self.closeButton.alpha = 1;
        }];
    }];
}

- (void)openHome {
    [[Launcher sharedInstance] launchLoggedIn:true];
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
    CGFloat bottomPadding = window.safeAreaInsets.bottom;
    
    NSNumber *duration = [notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    [UIView animateWithDuration:[duration floatValue] delay:0 options:[[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue] << 16 animations:^{
        self.nextButton.frame = CGRectMake(self.nextButton.frame.origin.x, (self.view.frame.size.height / self.view.transform.d) - self.nextButton.frame.size.height - (self.nextButton.frame.origin.x / 2) - bottomPadding, self.nextButton.frame.size.width, self.nextButton.frame.size.height);
    } completion:nil];
}

- (void)showImagePicker {
    UIAlertController *imagePickerOptions = [UIAlertController alertControllerWithTitle:@"Set Profile Photo" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    imagePickerOptions.view.tintColor = [UIColor colorWithWhite:0.2 alpha:1];
    
    UIAlertAction *takePhoto = [UIAlertAction actionWithTitle:@"Take Photo" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self takePhotoForProfilePicture:nil];
    }];
    [imagePickerOptions addAction:takePhoto];
    
    UIAlertAction *chooseFromLibrary = [UIAlertAction actionWithTitle:@"Choose from Library" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self chooseFromLibraryForProfilePicture:nil];
    }];
    [imagePickerOptions addAction:chooseFromLibrary];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }];
    [cancel setValue:self.closeButton.tintColor forKey:@"titleTextColor"];
    [imagePickerOptions addAction:cancel];
    
    [self presentViewController:imagePickerOptions animated:YES completion:nil];
}


- (void)takePhotoForProfilePicture:(id)sender {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = NO;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    [self presentViewController:picker animated:YES completion:nil];
}
- (void)chooseFromLibraryForProfilePicture:(id)sender {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = NO;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:picker animated:YES completion:nil];
}


// Crop image has been canceled.
- (void)imageCropViewControllerDidCancelCrop:(RSKImageCropViewController *)controller
{
    [controller.navigationController popViewControllerAnimated:YES];
}

// The original image has been cropped. Additionally provides a rotation angle used to produce image.
- (void)imageCropViewController:(RSKImageCropViewController *)controller
                   didCropImage:(UIImage *)croppedImage
                  usingCropRect:(CGRect)cropRect
                  rotationAngle:(CGFloat)rotationAngle
{
    int profilePictureStep = [self getIndexOfStepWithId:@"user_profile_picture"];
    UIImageView *profilePictureImageView = self.steps[profilePictureStep][@"block"];
    
    profilePictureImageView.image = croppedImage;
    
    [controller.navigationController dismissViewControllerAnimated:YES completion:nil];
    
    [self enableNextButton];
    
    
    [controller.navigationController dismissViewControllerAnimated:YES completion:nil];
}

// The original image will be cropped.
- (void)imageCropViewController:(RSKImageCropViewController *)controller
                  willCropImage:(UIImage *)originalImage
{
    // Use when `applyMaskToCroppedImage` set to YES.
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    // output image
    UIImage *chosenImage = info[UIImagePickerControllerOriginalImage];
    
    RSKImageCropViewController *imageCropVC = [[RSKImageCropViewController alloc] initWithImage:chosenImage];
    imageCropVC.delegate = self;
    imageCropVC.dataSource = self;
    imageCropVC.cropMode = RSKImageCropModeCustom;
    
    // move the cancel and choose buttons up
    UIEdgeInsets safeAreaInsets = [UIApplication sharedApplication].keyWindow.safeAreaInsets;
    imageCropVC.cancelButton.transform = CGAffineTransformMakeTranslation(0, -1 * safeAreaInsets.bottom);
    imageCropVC.chooseButton.transform = CGAffineTransformMakeTranslation(0, -1 * safeAreaInsets.bottom);
    
    [picker pushViewController:imageCropVC animated:YES];
}
- (CGRect)imageCropViewControllerCustomMaskRect:(RSKImageCropViewController *)controller
{
    CGSize aspectRatio = CGSizeMake(1, 1);
    
    CGFloat viewWidth = CGRectGetWidth(controller.view.frame);
    CGFloat viewHeight = CGRectGetHeight(controller.view.frame);
    
    CGFloat maskWidth;
    if ([controller isPortraitInterfaceOrientation]) {
        maskWidth = viewWidth;
    } else {
        maskWidth = viewHeight;
    }
    
    CGFloat maskHeight;
    do {
        maskHeight = maskWidth * aspectRatio.height / aspectRatio.width;
        maskWidth -= 1.0f;
    } while (maskHeight != floor(maskHeight));
    maskWidth += 1.0f;
    
    CGSize maskSize = CGSizeMake(maskWidth * .75f, maskHeight * .75);
    
    NSLog(@"maskSize(%f, %f)", maskSize.width, maskSize.height);
    
    CGRect maskRect = CGRectMake((viewWidth - maskSize.width) * 0.5f,
                                 (viewHeight - maskSize.height) * 0.5f,
                                 maskSize.width,
                                 maskSize.height);
    
    return maskRect;
}
- (UIBezierPath *)imageCropViewControllerCustomMaskPath:(RSKImageCropViewController *)controller {
    CGFloat circleRadius = controller.maskRect.size.width * .25;
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:controller.maskRect
                                               byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight|UIRectCornerTopLeft|UIRectCornerTopRight
                                                     cornerRadii:CGSizeMake(circleRadius, circleRadius)];
    return path;
}
// Returns a custom rect in which the image can be moved.
- (CGRect)imageCropViewControllerCustomMovementRect:(RSKImageCropViewController *)controller
{
    if (controller.rotationAngle == 0) {
        return controller.maskRect;
    } else {
        CGRect maskRect = controller.maskRect;
        CGFloat rotationAngle = controller.rotationAngle;
        
        CGRect movementRect = CGRectZero;
        
        movementRect.size.width = CGRectGetWidth(maskRect) * fabs(cos(rotationAngle)) + CGRectGetHeight(maskRect) * fabs(sin(rotationAngle));
        movementRect.size.height = CGRectGetHeight(maskRect) * fabs(cos(rotationAngle)) + CGRectGetWidth(maskRect) * fabs(sin(rotationAngle));
        
        movementRect.origin.x = CGRectGetMinX(maskRect) + (CGRectGetWidth(maskRect) - CGRectGetWidth(movementRect)) * 0.5f;
        movementRect.origin.y = CGRectGetMinY(maskRect) + (CGRectGetHeight(maskRect) - CGRectGetHeight(movementRect)) * 0.5f;
        
        movementRect.origin.x = floor(CGRectGetMinX(movementRect));
        movementRect.origin.y = floor(CGRectGetMinY(movementRect));
        movementRect = CGRectIntegral(movementRect);
        
        return movementRect;
    }
}

- (void)continuityRadiusForView:(UIView *)sender withRadius:(CGFloat)radius {
    CAShapeLayer * maskLayer = [CAShapeLayer layer];
    maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:sender.bounds
                                           byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight|UIRectCornerTopLeft|UIRectCornerTopRight
                                                 cornerRadii:CGSizeMake(radius, radius)].CGPath;
    
    sender.layer.mask = maskLayer;
}

// MODAL TRANSITION
- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting
                                                                      sourceController:(UIViewController *)source
{
    id<UIViewControllerAnimatedTransitioning> animationController;
    
    SOLOptionsTransitionAnimator *animator = [[SOLOptionsTransitionAnimator alloc] init];
    animator.appearing = YES;
    animator.duration = 0.3;
    animationController = animator;
    
    return animationController;
}
/*
 Called when dismissing a view controller that has a transitioningDelegate
 */
- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    id<UIViewControllerAnimatedTransitioning> animationController;
    
    SOLOptionsTransitionAnimator *animator = [[SOLOptionsTransitionAnimator alloc] init];
    animator.appearing = NO;
    animator.duration = 0.3;
    animationController = animator;
    
    return animationController;
}

@end
