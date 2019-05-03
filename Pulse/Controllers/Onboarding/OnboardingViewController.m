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
#import "ComplexNavigationController.h"
#import "UIColor+Palette.h"
#import "Launcher.h"
#import "NSString+Validation.h"
#import "HAWebService.h"
#import "LargeRoomCardCell.h"
#import "EmojiUtilities.h"
#import "ResetPasswordViewController.h"

@import UserNotifications;
@import Firebase;
@import FirebasePerformance;
#import <RSKImageCropper/RSKImageCropper.h>

#define UIViewParentController(__view) ({ \
    UIResponder *__responder = __view; \
    while ([__responder isKindOfClass:[UIView class]]) \
    __responder = [__responder nextResponder]; \
    (UIViewController *)__responder; \
    })

#define IS_IPHONE        (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)

@interface OnboardingViewController () <RSKImageCropViewControllerDelegate, RSKImageCropViewControllerDataSource> {
    UIEdgeInsets safeAreaInsets;
    NSArray *colors;
    NSMutableDictionary *roomsJoined;
    
}

@property (nonatomic) NSInteger themeColor;
@property (nonatomic) NSInteger currentStep;
@property (nonatomic, strong) NSMutableArray *steps;
@property (nonatomic, strong) ComplexNavigationController *launchNavVC;
@property (nonatomic) CGFloat currentKeyboardHeight;
@property (nonatomic, strong) NSMutableArray *roomSuggestions;

@property (nonatomic) FIRTrace *signInTrace;
@property (nonatomic) FIRTrace *signUpTrace;

@end

@implementation OnboardingViewController

static NSString * const largeCardReuseIdentifier = @"LargeCard";
static NSString * const blankCellIdentifier = @"BlankCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    self.view.tintColor = [UIColor bonfireBlack];
    
    [self addListeners];
    [self setupViews];
    [self setupSteps];
    
    // –––– show the first step ––––
    self.currentStep = -1;
    [self nextStep:false];
    
    if (!self.signInLikely) {
        // track how long it takes to finish sign up flow
        self.signInTrace = [FIRPerformance startTraceWithName:@"Sign In"];
        self.signUpTrace = [FIRPerformance startTraceWithName:@"Sign Up"];
    }
    
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    
    // Google Analytics
    [FIRAnalytics setScreenName:@"Onboarding" screenClass:nil];
}

- (void)addListeners {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillDismiss:) name:UIKeyboardWillHideNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(roomUpdated:) name:@"RoomUpdated" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedNotificationsUpdate:) name:@"NotificationsDidRegister" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedNotificationsUpdate:) name:@"NotificationsDidFailToRegister" object:nil];
}

- (void)requestNotifications {
    [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:(UNAuthorizationOptionAlert|UNAuthorizationOptionSound|UNAuthorizationOptionBadge) completionHandler:^(BOOL granted, NSError * _Nullable error) {
        // 1. check if permisisons granted
        if (granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                // do work here
                [[UIApplication sharedApplication] registerForRemoteNotifications];
            });
        }
    }];
}
- (void)receivedNotificationsUpdate:(NSNotification *)notificaiton {
    [[Launcher sharedInstance] launchLoggedIn:true];
}

- (void)setupViews {
    safeAreaInsets = [UIApplication sharedApplication].delegate.window.safeAreaInsets;
    
    self.closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.closeButton.frame = CGRectMake(self.view.frame.size.width - 44 - 11, safeAreaInsets.top + 2, 44, 44);
    [self.closeButton setImage:[[UIImage imageNamed:@"navCloseIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    self.closeButton.tintColor = [self.view tintColor];
    self.closeButton.adjustsImageWhenHighlighted = false;
    self.closeButton.contentMode = UIViewContentModeCenter;
    [self.closeButton bk_whenTapped:^{
        [self.view endEditing:TRUE];
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    [self.view addSubview:self.closeButton];
    
    self.backButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.backButton.frame = CGRectMake(3, self.closeButton.frame.origin.y, 44, 44);
    self.backButton.titleLabel.font = [UIFont systemFontOfSize:20.f weight:UIFontWeightSemibold];
    [self.backButton setTitleColor:[UIColor bonfireGray] forState:UIControlStateDisabled];
    [self.backButton setImage:[[UIImage imageNamed:@"leftArrowIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    self.backButton.tintColor = self.view.tintColor;
    self.backButton.alpha = 0;
    self.backButton.adjustsImageWhenHighlighted = false;
    [self.backButton bk_whenTapped:^{
        [self previousStep:-1];
    }];
    [self.view addSubview:self.backButton];
    
    self.nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.nextButton.frame = CGRectMake(24, self.view.frame.size.height, self.view.frame.size.width - (24 * 2), 48);
    self.nextButton.backgroundColor = [self.view tintColor];
    self.nextButton.titleLabel.font = [UIFont systemFontOfSize:20.f weight:UIFontWeightSemibold];
    [self.nextButton setTitleColor:[UIColor bonfireGray] forState:UIControlStateDisabled];
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
    
    self.nextBlockerInfoLabel = [[UILabel alloc] initWithFrame:CGRectMake(24, self.view.frame.size.height, self.view.frame.size.width - 48, 0)];
    self.nextBlockerInfoLabel.textAlignment = NSTextAlignmentCenter;
    self.nextBlockerInfoLabel.textColor = [UIColor bonfireGray];
    self.nextBlockerInfoLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightRegular];
    self.nextBlockerInfoLabel.alpha = 0;
    [self.view addSubview:self.nextBlockerInfoLabel];
    
    self.legalDisclosureLabel = [UIButton buttonWithType:UIButtonTypeSystem];
    self.legalDisclosureLabel.frame = CGRectMake(self.view.frame.size.width / 2 - 144, self.view.frame.size.height, 288, 0);
    self.legalDisclosureLabel.alpha = 0;
    self.legalDisclosureLabel.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.legalDisclosureLabel.titleLabel.numberOfLines = 0;
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:@"By continuing, you acknowledge that you have read the Privacy Policy and agree to the Terms of Service." attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:11.f weight:UIFontWeightRegular], NSForegroundColorAttributeName: [UIColor bonfireGray]}];
    [attributedString addAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:11.f weight:UIFontWeightSemibold], NSForegroundColorAttributeName: [UIColor colorWithWhite:0.47 alpha:1]} range:[attributedString.string rangeOfString:@"Privacy Policy"]];
    [attributedString addAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:11.f weight:UIFontWeightSemibold], NSForegroundColorAttributeName: [UIColor colorWithWhite:0.47 alpha:1]} range:[attributedString.string rangeOfString:@"Terms of Service"]];
    [self.legalDisclosureLabel setAttributedTitle:attributedString forState:UIControlStateNormal];
    
    CGSize legalDisclosureSize = [attributedString boundingRectWithSize:CGSizeMake(self.legalDisclosureLabel.frame.size.width, CGFLOAT_MAX) options:(NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin) context:nil].size;
    self.legalDisclosureLabel.frame = CGRectMake(self.legalDisclosureLabel.frame.origin.x, self.view.frame.size.height, self.legalDisclosureLabel.frame.size.width, legalDisclosureSize.height);
    
    [self.legalDisclosureLabel bk_whenTapped:^{
        // confirm action
        UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
        UIAlertAction *privacyPolicy = [UIAlertAction actionWithTitle:@"Privacy Policy" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[Launcher sharedInstance] openURL:@"https://bonfire.camp/privacy"];
        }];
        [actionSheet addAction:privacyPolicy];
        
        UIAlertAction *termsOfService = [UIAlertAction actionWithTitle:@"Terms of Service" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[Launcher sharedInstance] openURL:@"https://bonfire.camp/terms"];
        }];
        [actionSheet addAction:termsOfService];
        
        UIAlertAction *cancelActionSheet = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
        [actionSheet addAction:cancelActionSheet];
        
        [self presentViewController:actionSheet animated:YES completion:nil];
    }];
    
    [self.view addSubview:self.legalDisclosureLabel];
}

- (void)setupSteps {
    CGFloat inputCenterY = (self.view.frame.size.height / 2) - (self.view.frame.size.height * .15);
    self.instructionLabel = [[UILabel alloc] initWithFrame:CGRectMake(24, self.view.frame.size.height, self.view.frame.size.width - 48, 42)];
    self.instructionLabel.center = CGPointMake(self.instructionLabel.center.x, (inputCenterY / 2) + 16);
    self.instructionLabel.textAlignment = NSTextAlignmentCenter;
    self.instructionLabel.text = @"Last step, and it’s a fun one! What’s your favorite color?";
    self.instructionLabel.font = [UIFont systemFontOfSize:18.f weight:UIFontWeightMedium];
    self.instructionLabel.textColor = [UIColor colorWithRed:0.31 green:0.31 blue:0.32 alpha:1.0];
    self.instructionLabel.numberOfLines = 0;
    self.instructionLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [self.view addSubview:self.instructionLabel];
    
    self.steps = [[NSMutableArray alloc] init];
    
    [self.steps addObject:@{@"id": @"user_email", @"skip": [NSNumber numberWithBool:false], @"next": @"Next", @"instruction": (self.signInLikely ? @"Hi again! 👋\nWhat's your email or username?" : @"Welcome to Bonfire!\nWhat’s your email?"), @"placeholder": (self.signInLikely ? @"Email or username" : @"Email Address"), @"sensitive": [NSNumber numberWithBool:false], @"keyboard": (self.signInLikely ? @"text" : @"email"), @"textField": [NSNull null], @"block": [NSNull null]}];
    [self.steps addObject:@{@"id": @"user_password", @"skip": [NSNumber numberWithBool:false], @"next": @"Log In", @"instruction": @"Let's get you logged in!\nPlease enter your password", @"placeholder":@"Your Password", @"sensitive": [NSNumber numberWithBool:true], @"keyboard": @"text", @"textField": [NSNull null], @"block": [NSNull null]}];
    [self.steps addObject:@{@"id": @"user_set_password", @"skip": [NSNumber numberWithBool:false], @"next": @"Next", @"instruction": @"Let’s get you signed up!\nPlease set a password", @"placeholder": @"Password", @"sensitive": [NSNumber numberWithBool:true], @"keyboard": @"text", @"textField": [NSNull null], @"block": [NSNull null]}];
    [self.steps addObject:@{@"id": @"user_confirm_password", @"skip": [NSNumber numberWithBool:false], @"next": @"Confirm", @"instruction": @"Just to be sure... please\nconfirm your password", @"placeholder":@"Confirm Password", @"sensitive": [NSNumber numberWithBool:true], @"keyboard": @"text", @"textField": [NSNull null], @"block": [NSNull null]}];
    [self.steps addObject:@{@"id": @"user_display_name", @"skip": [NSNumber numberWithBool:false], @"next": @"Next", @"instruction": @"What would you like\nyour display name to be?", @"placeholder": @"Your Name", @"sensitive": [NSNumber numberWithBool:false], @"keyboard": @"title", @"textField": [NSNull null], @"block": [NSNull null]}];
    [self.steps addObject:@{@"id": @"user_username", @"skip": [NSNumber numberWithBool:false], @"next": @"Next", @"instruction": @"Help others find you faster\nby setting a @username", @"placeholder": @"Username", @"sensitive": [NSNumber numberWithBool:false], @"keyboard": @"text", @"textField": [NSNull null], @"block": [NSNull null]}];
    [self.steps addObject:@{@"id": @"user_profile_picture", @"skip": [NSNumber numberWithBool:false], @"next": @"Next", @"instruction": @"Set a profile picture\n(optional)", @"block": [NSNull null]}];
    [self.steps addObject:@{@"id": @"user_color", @"skip": [NSNumber numberWithBool:false], @"next": @"Sign Up", @"instruction": @"Last step, and it’s a fun one! What’s your favorite color?", @"block": [NSNull null]}];
    [self.steps addObject:@{@"id": @"user_room_suggestions", @"skip": [NSNumber numberWithBool:false], @"next": @"Next", @"instruction": @"Camps are the conversations you care about, in one place", @"block": [NSNull null]}];
    [self.steps addObject:@{@"id": @"user_push_notifications", @"skip": [NSNumber numberWithBool:false], @"next": [NSNull null], @"instruction": @"", @"block": [NSNull null]}];
    
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
        textField.textColor = [UIColor bonfireBlack];
        textField.backgroundColor = [UIColor colorWithWhite:1 alpha:1];
        textField.layer.cornerRadius = 12.f;
        textField.layer.masksToBounds = false;
        textField.layer.shadowRadius = 2.f;
        textField.layer.shadowOffset = CGSizeMake(0, 1);
        textField.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.1f].CGColor;
        textField.layer.shadowOpacity = 1.f;
        if ([mutatedStep[@"id"] isEqualToString:@"user_email"]) {
            textField.tag = 201;
        }
        else if ([mutatedStep[@"id"] isEqualToString:@"user_password"] ||
                 [mutatedStep[@"id"] isEqualToString:@"user_set_password"] ||
                 [mutatedStep[@"id"] isEqualToString:@"user_confirm_password"]) {
            textField.tag = 202;
        }
        else if ([mutatedStep[@"id"] isEqualToString:@"user_display_name"]) {
            textField.tag = 203;
        }
        else if ([mutatedStep[@"id"] isEqualToString:@"user_username"]) {
            textField.tag = 204;
        }
        
        // set text content types
        if ([mutatedStep[@"id"] isEqualToString:@"user_email"]) {
            textField.textContentType = UITextContentTypeEmailAddress;
        }
        else if ([mutatedStep[@"id"] isEqualToString:@"user_password"]) {
            textField.textContentType = UITextContentTypePassword;
        }
        else if ([mutatedStep[@"id"] isEqualToString:@"user_set_password"] || [mutatedStep[@"id"] isEqualToString:@"user_confirm_password"]) {
            if (@available(iOS 12.0, *)) {
                textField.textContentType = UITextContentTypeNewPassword;
            } else {
                // Fallback on earlier versions
                textField.textContentType = UITextContentTypePassword;
            }
        }
        else if ([mutatedStep[@"id"] isEqualToString:@"user_display_name"]) {
            textField.textContentType = UITextContentTypeName;
        }
        else if ([mutatedStep[@"id"] isEqualToString:@"user_username"]) {
            textField.textContentType = UITextContentTypeUsername;
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
            else if ([mutatedStep[@"id"] isEqualToString:@"user_username"] ||
                     [mutatedStep[@"id"] isEqualToString:@"user_email"]) {
                textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
                textField.autocorrectionType = UITextAutocorrectionTypeNo;
                textField.keyboardType = UIKeyboardTypeASCIICapable;
            }
            else {
                textField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
            }
        }
        
        textField.delegate = self;
        textField.returnKeyType = UIReturnKeyNext;
        textField.font = [UIFont systemFontOfSize:20.f weight:UIFontWeightMedium];
        
        [inputBlock addSubview:textField];
        
        // add left-side spacing
        UIView *leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 20, textField.frame.size.height)];
        leftView.backgroundColor = textField.backgroundColor;
        textField.leftView = leftView;
        textField.rightView = leftView;
        textField.leftViewMode = UITextFieldViewModeAlways;
        textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:([mutatedStep objectForKey:@"placeholder"] ? mutatedStep[@"placeholder"] : @"") attributes:@{NSForegroundColorAttributeName: [UIColor bonfireGray]}];
        [textField addTarget:self action:@selector(textFieldChanged:) forControlEvents:UIControlEventEditingChanged];
        
        if ([mutatedStep[@"sensitive"] boolValue]) {
            textField.secureTextEntry = true;
        }
        else {
            textField.secureTextEntry = false;
        }
        
        inputBlock.alpha = 0;
        inputBlock.transform = CGAffineTransformMakeTranslation(self.view.frame.size.width, 0);
        
        // add a reset password button for password field
        if ([mutatedStep[@"id"] isEqualToString:@"user_password"]) {
            UIButton *forgotYourPassword = [UIButton buttonWithType:UIButtonTypeSystem];
            [forgotYourPassword setTitle:@"Forgot your password?" forState:UIControlStateNormal];
            forgotYourPassword.titleLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightSemibold];
            [forgotYourPassword setTitleColor:[UIColor bonfireGray] forState:UIControlStateNormal];
            forgotYourPassword.frame = CGRectMake(0, textField.frame.origin.y + textField.frame.size.height + 16, self.view.frame.size.width, 32);
            [forgotYourPassword bk_whenTapped:^{
                ResetPasswordViewController *resetPasswordVC = [[ResetPasswordViewController alloc] init];
                
                NSInteger lookupStep = [self getIndexOfStepWithId:@"user_email"];
                UITextField *lookupTextField = self.steps[lookupStep][@"textField"];
                resetPasswordVC.prefillLookup = lookupTextField.text;
                
                resetPasswordVC.transitioningDelegate = [Launcher sharedInstance];
                [[Launcher sharedInstance] present:resetPasswordVC animated:YES];
            }];
            [inputBlock addSubview:forgotYourPassword];
            
            inputBlock.frame = CGRectMake(inputBlock.frame.origin.x, inputBlock.frame.origin.y, inputBlock.frame.size.width, forgotYourPassword.frame.origin.y + forgotYourPassword.frame.size.height);
        }
        
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
        
        colors = @[[UIColor bonfireBlueWithLevel:500],  // 0
                   [UIColor bonfireViolet],  // 1
                   [UIColor bonfireRed],  // 2
                   [UIColor bonfireOrange],  // 3
                   [UIColor colorWithRed:0.16 green:0.72 blue:0.01 alpha:1.00], // cash green
                   [UIColor brownColor],  // 5
                   [UIColor colorWithRed:0.96 green:0.76 blue:0.23 alpha:1.00],  // 6
                   [UIColor bonfireCyanWithLevel:800],  // 7
                   [UIColor bonfireGrayWithLevel:900]]; // 8
        
        self.themeColor = 0 + arc4random() % (colors.count - 1);
                
        for (NSInteger i = 0; i < 9; i++) {
            NSInteger row = i % 3;
            NSInteger column = floorf(i / 3);
                        
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
        [self continuityRadiusForView:userProfilePictureBlock withRadius:userProfilePictureBlock.frame.size.height / 2];
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
    else if ([mutatedStep[@"id"] isEqualToString:@"user_room_suggestions"]) {
        UIView *block = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.width, self.view.frame.size.width, 304)];
        block.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2);
        block.alpha = 0;
        block.transform = CGAffineTransformMakeTranslation(self.view.frame.size.width, 0);
        [self.view addSubview:block];
        
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.minimumLineSpacing = 12.f;
        flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        
        self.loadingRoomSuggestions = true;
        
        self.roomSuggestionsCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 304) collectionViewLayout:flowLayout];
        self.roomSuggestionsCollectionView.delegate = self;
        self.roomSuggestionsCollectionView.dataSource = self;
        self.roomSuggestionsCollectionView.contentInset = UIEdgeInsetsMake(0, 24, 0, 24);
        self.roomSuggestionsCollectionView.showsHorizontalScrollIndicator = false;
        self.roomSuggestionsCollectionView.layer.masksToBounds = false;
        self.roomSuggestionsCollectionView.backgroundColor = [UIColor clearColor];
        
        [self.roomSuggestionsCollectionView registerClass:[LargeRoomCardCell class] forCellWithReuseIdentifier:largeCardReuseIdentifier];
        [self.roomSuggestionsCollectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:blankCellIdentifier];
        
        self.roomSuggestions = [[NSMutableArray alloc] init];
        
        [block addSubview:self.roomSuggestionsCollectionView];
        
        [mutatedStep setObject:block forKey:@"block"];
    }
    else if ([mutatedStep[@"id"] isEqualToString:@"user_push_notifications"]) {
        UIView *arrowContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.width, 270, 216)];
        arrowContainerView.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2);
        arrowContainerView.alpha = 0;
        arrowContainerView.transform = CGAffineTransformMakeTranslation(self.view.frame.size.width, 0);
        [self.view addSubview:arrowContainerView];
        
        [mutatedStep setObject:arrowContainerView forKey:@"block"];
    }
    
    [parentArray replaceObjectAtIndex:stepIndex withObject:mutatedStep];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *newStr = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    /*
     10 - share field
     201 - email
     202 - password
     203 - display name
     204 - username
     */
    
    if (textField.tag == 10) {
        return false; // disable editing for share field
    }
    if (textField.tag == 201) {
        return newStr.length <= MAX_EMAIL_LENGTH ? YES : NO;
    }
    if (textField.tag == 202) {
        return newStr.length <= MAX_PASSWORD_LENGTH ? YES : NO;
    }
    if (textField.tag == 203) {
        return newStr.length <= MAX_USER_DISPLAY_NAME_LENGTH ? YES : NO;
    }
    if (textField.tag == 204) {
        if (newStr.length == 0) return NO;
        
        // prevent spaces
        if ([newStr rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].location != NSNotFound) {
            return NO;
        }
        
        // prevent emojis
        if ([EmojiUtilities containsEmoji:newStr]) {
            return NO;
        }
        
        return newStr.length <= MAX_USER_USERNAME_LENGTH ? YES : NO;
    }
    
    return true;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (self.nextButton.enabled) [self handleNext];
    
    return false;
}

- (void)setColor:(UIView *)sender {
    if (sender.tag != self.themeColor) {
        [HapticHelper generateFeedback:FeedbackType_Selection];
        
        // remove previously selected color
        NSInteger colorStep = [self getIndexOfStepWithId:@"user_color"];
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

- (NSInteger)getIndexOfStepWithId:(NSString *)stepId {
    for (NSInteger i = 0; i < [self.steps count]; i++) {
        if ([self.steps[i][@"id"] isEqualToString:stepId]) {
            return i;
        }
    }
    return 0;
}

- (void)textFieldChanged:(UITextField *)sender {
    if ([self.steps[self.currentStep][@"id"] isEqualToString:@"user_email"]) {
        BOOL valid = ([sender.text validateBonfireEmail] == BFValidationErrorNone);
        
        if (self.signInLikely && !valid) {
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
    
    if ([self.steps[self.currentStep][@"id"] isEqualToString:@"user_password"] ||
        [self.steps[self.currentStep][@"id"] isEqualToString:@"user_set_password"] ||
        [self.steps[self.currentStep][@"id"] isEqualToString:@"user_confirm_password"]) {
        if ([sender.text validateBonfirePassword] == BFValidationErrorNone) {
            // qualifies
            self.nextButton.backgroundColor = self.view.tintColor;
            self.nextButton.enabled = true;
        }
        else {
            [self greyOutNextButton];
        }
    }
    
    if ([self.steps[self.currentStep][@"id"] isEqualToString:@"user_username"]) {
        if ([sender.text validateBonfireUsername] == BFValidationErrorNone) {
            // qualifies
            self.nextButton.backgroundColor = self.view.tintColor;
            self.nextButton.enabled = true;
        }
        else {
            [self greyOutNextButton];
        }
    }
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
        // check if user exists
        UITextField *textField = step[@"textField"];
        
        // determine if we should verify email or continue to sign in using username
        BOOL email = ([textField.text validateBonfireEmail] == BFValidationErrorNone);
        BOOL username = self.signInLikely && ([textField.text validateBonfireUsername] == BFValidationErrorNone || ([textField.text validateBonfireUsername] == BFValidationErrorTooShort && textField.text.length >= 1));

        if (email) {
            // check for similar names
            [self greyOutNextButton];
            [self showSpinnerForStep:self.currentStep];
            
            NSString *url = @"accounts/validate/email"; // sample data
            
            NSLog(@"handleNext / user_email / url: %@", url);
            
            NSLog(@"final url: %@", url);
            [[HAWebService managerWithContentType:kCONTENT_TYPE_URL_ENCODED] GET:url parameters:@{@"email": textField.text} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, NSDictionary *responseObject) {
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
                
                NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                NSLog(@"error: %@", ErrorResponse);
                
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Uh oh!" message:@"We encountered a network error while looking up your account. Check your network settings and try again." preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *gotItAction = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                    [alert dismissViewControllerAnimated:true completion:nil];
                }];
                [alert addAction:gotItAction];
                [self presentViewController:alert animated:YES completion:nil];
            }];
        }
        else if (username) {
            [self prepareForLogin];
            [self nextStep:true];
        }
        else {
            [self shakeInputBlock];
        }
        
    }
    else if ([step[@"id"] isEqualToString:@"user_password"]) {
        // sign in to user
        [self attemptToSignIn];
    }
    else if ([step[@"id"] isEqualToString:@"user_username"]) {
        UITextField *textField = step[@"textField"];
        
        if ([[textField.text stringByReplacingOccurrencesOfString:@"@" withString:@""] isEqualToString:[Session sharedInstance].currentUser.attributes.details.identifier]) {
            // good to go -> they didn't change anything
            [self nextStep:true];
        }
        else {
            // verify username is available
            [self greyOutNextButton];
            [self showSpinnerForStep:self.currentStep];
            
            // check if username exists
            NSString *url = [NSString stringWithFormat:@"accounts/validate/username?username=%@", [textField.text stringByReplacingOccurrencesOfString:@"@" withString:@""]]; // sample data
            
            NSLog(@"url: %@", url);
            [[HAWebService managerWithContentType:kCONTENT_TYPE_URL_ENCODED] GET:url parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, NSDictionary *responseObject) {
                [self removeSpinnerForStep:self.currentStep];
                
                BOOL isValid = [responseObject[@"data"][@"valid"] boolValue];
                BOOL isOccupied = [responseObject[@"data"][@"occupied"] boolValue];
                
                NSLog(@"isValid? %@", (isValid ? @"YES" : @"NO" ));
                NSLog(@"isOccupied? %@", (isOccupied ? @"YES" : @"NO" ));
                
                if (isValid && !isOccupied) {
                    // username is available -> proceed to next step
                    [self enableNextButton];
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
    else if ([step[@"id"] isEqualToString:@"user_set_password"]) {
        [self greyOutNextButton];
        [self nextStep:true];
    }
    else if ([self.steps[self.currentStep][@"id"] isEqualToString:@"user_confirm_password"]) {
        NSInteger passwordStep = [self getIndexOfStepWithId:@"user_set_password"];
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
    else if ([step[@"id"] isEqualToString:@"user_room_suggestions"]) {
        if ([[UIApplication sharedApplication] isRegisteredForRemoteNotifications]) {
            NSLog(@"already registered m8y!");
            // already registered for remote notifications
            [[UIApplication sharedApplication] registerForRemoteNotifications];
        }
        else {
            NSLog(@"not registered yet... let's request notifs");
            [self nextStep:true];
        }
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
    for (NSInteger i = 0; i < self.steps.count; i++) {
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
    for (NSInteger i = 0; i < self.steps.count; i++) {
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
    
    [UIView animateWithDuration:0.25f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.backButton.alpha = 0;
        self.closeButton.alpha = 0;
    } completion:nil];
    
    // check if user exists
    NSInteger emailOrUsernameStep = [self getIndexOfStepWithId:@"user_email"];
    UITextField *emailOrUsernameTextField = self.steps[emailOrUsernameStep][@"textField"];
    NSString *emailOrUsername = emailOrUsernameTextField.text;
    
    NSInteger passwordStep = [self getIndexOfStepWithId:@"user_password"];
    UITextField *passwordTextField = self.steps[passwordStep][@"textField"];
    NSString *password = passwordTextField.text;
    
    NSDictionary *params;
    BOOL email = ([emailOrUsernameTextField.text validateBonfireEmail] == BFValidationErrorNone);
    if (email) {
        params = @{@"email": emailOrUsername, @"password": password, @"grant_type": @"password"};
    }
    else {
        params = @{@"username": emailOrUsername, @"password": password, @"grant_type": @"password"};
    }
    
    [[HAWebService managerWithContentType:kCONTENT_TYPE_URL_ENCODED] POST:@"oauth" parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, NSDictionary *responseObject) {
        [self removeSpinnerForStep:self.currentStep];
        
        [[Session sharedInstance] setAccessToken:responseObject[@"data"]];
        
        // TODO: Open LauncherNavigationViewController
        [BFAPI getUser:^(BOOL success) {
            NSLog(@"success?>? %@", success ? @"YES" : @"NO");
            if (success) {
                self.signUpTrace = nil;
                [self.signInTrace stop];
                [FIRAnalytics logEventWithName:@"onboarding_signed_in"
                                    parameters:@{}];
                
                [self requestNotifications];
            }
            else {
                [UIView animateWithDuration:0.25f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                    self.backButton.alpha = 1;
                    self.closeButton.alpha = 1;
                } completion:nil];
                
                // not long enough –> shake input block
                [self shakeInputBlock];
                
                [self enableNextButton];
            }
        }];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [UIView animateWithDuration:0.25f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.backButton.alpha = 1;
            self.closeButton.alpha = 1;
        } completion:nil];
        
        // not long enough –> shake input block
        [self removeSpinnerForStep:self.currentStep];
        [self shakeInputBlock];
        
        [self enableNextButton];
        
        NSHTTPURLResponse *httpResponse = error.userInfo[AFNetworkingOperationFailingURLResponseErrorKey];
        NSInteger statusCode = httpResponse.statusCode;
        
        NSString *errorTitle = @"Uh oh!";
        NSString *errorMessage = @"We encountered an error while signing you in. Please try again and check back soon for an update.";
        if (statusCode == 412) {
            // invalid request parameter
            // --> invalid password
            errorTitle = @"Please try again";
            errorMessage = @"The username and password you entered did not match our records. Please double-check and try again!";
            
            [FIRAnalytics logEventWithName:@"onboarding_invalid_credentials"
                                parameters:@{}];
        }
        
        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        NSLog(@"error: %@", ErrorResponse);
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:errorTitle message:errorMessage preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *gotItAction = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [alert dismissViewControllerAnimated:true completion:nil];
        }];
        [alert addAction:gotItAction];
        [self presentViewController:alert animated:YES completion:nil];
    }];
}
- (void)attemptToSignUp {
    NSInteger emailStep = [self getIndexOfStepWithId:@"user_email"];
    UITextField *emailTextField = self.steps[emailStep][@"textField"];
    NSString *email = emailTextField.text;
    
    NSInteger passwordStep = [self getIndexOfStepWithId:@"user_set_password"];
    UITextField *passwordTextField = self.steps[passwordStep][@"textField"];
    NSString *password = passwordTextField.text;
    
    NSInteger displayNameStep = [self getIndexOfStepWithId:@"user_display_name"];
    UITextField *displayNameTextField = self.steps[displayNameStep][@"textField"];
    NSString *displayName = displayNameTextField.text;
    
    NSLog(@"params: %@", @{@"email": email, @"password": password, @"display_name": displayName});
    
    [[HAWebService managerWithContentType:kCONTENT_TYPE_URL_ENCODED] POST:@"accounts" parameters:@{@"email": email, @"password": password, @"display_name": displayName} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"responseObject: %@", responseObject);
        
        NSError *error;
        User *user = [[User alloc] initWithDictionary:responseObject[@"data"] error:&error];
        [[Session sharedInstance] updateUser:user];
        if (error) {
            NSLog(@"error creating user object: %@", error);
        }
        
        NSInteger usernameStep = [self getIndexOfStepWithId:@"user_username"];
        UITextField *usernameTextField = self.steps[usernameStep][@"textField"];
        usernameTextField.text = [NSString stringWithFormat:@"@%@", user.attributes.details.identifier];
        
        [FIRAnalytics logEventWithName:@"onboarding_signed_up"
                            parameters:@{}];
        
        // get access token for user
        [[HAWebService managerWithContentType:kCONTENT_TYPE_URL_ENCODED] POST:@"oauth" parameters:@{@"email": email, @"password": password, @"grant_type": @"password"} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, NSDictionary *responseObject) {
            [self removeSpinnerForStep:self.currentStep];
            
            [[Session sharedInstance] setAccessToken:responseObject[@"data"]];
            
            [self enableNextButton];
            
            // move spinner
            [self removeSpinnerForStep:self.currentStep];
            [self nextStep:true];
            
            self.closeButton.userInteractionEnabled = false;
            self.backButton.userInteractionEnabled = false;
            [UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.closeButton.alpha = 0;
                self.backButton.alpha = 0;
            } completion:nil];
            
            // start loading the room suggestions, so they're ready when we need them
            [self getRoomSuggestionsList];
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
    NSInteger usernameStep = [self getIndexOfStepWithId:@"user_username"];
    UITextField *usernameTextField = self.steps[usernameStep][@"textField"];
    NSString *username = [usernameTextField.text stringByReplacingOccurrencesOfString:@"@" withString:@""];
    
    NSInteger profilePictureStep = [self getIndexOfStepWithId:@"user_profile_picture"];
    UIImageView *profilePictureImageView = self.steps[profilePictureStep][@"block"];
    UIImage *profilePicture = profilePictureImageView.image;
    CGImageRef cgref = [profilePicture CGImage];
    CIImage *cim = [profilePicture CIImage];
    BOOL hasProfilePicture = (cim != nil || cgref != NULL) && profilePictureImageView.tag == 1;
    
    NSString *color = [UIColor toHex:colors[self.themeColor]];
    
    void (^errorSaving)(void) = ^() {
        [self removeBigSpinnerForStep:self.currentStep push:false];
        self.nextButton.enabled = true;
        self.nextButton.backgroundColor = [self currentColor];
        self.nextButton.userInteractionEnabled = true;
        [self shakeInputBlock];
    };
    
    void (^saveUser)(NSString *uploadedImage) = ^(NSString *uploadedImage) {
        NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithDictionary:@{@"username": username, @"color": color}];
        if (uploadedImage && uploadedImage.length > 0) {
            [params setObject:uploadedImage forKey:@"profile_pic"];
        }
        NSLog(@"params: %@", params);
        
        [[HAWebService authenticatedManager] PUT:@"users/me" parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            NSLog(@"responseObject: %@", responseObject);
            
            self.nextButton.enabled = true;
            self.nextButton.backgroundColor = [self currentColor];
            
            // move spinner
            [self removeBigSpinnerForStep:self.currentStep push:true];
            
            NSLog(@"all done! successfully saved user!");
            User *updatedUser = [[User alloc] initWithDictionary:responseObject[@"data"] error:nil];
            [[Session sharedInstance] updateUser:updatedUser];
            
            [self nextStep:true];
            [self greyOutNextButton];
            
            [self.signUpTrace stop];
            self.signInTrace = nil;
            [FIRAnalytics logEventWithName:@"onboarding_updated_user"
                                parameters:@{@"color": color}];
            
            self.closeButton.userInteractionEnabled = false;
            self.backButton.userInteractionEnabled = false;
            [UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.closeButton.alpha = 0;
                self.backButton.alpha = 0;
            } completion:nil];
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            NSLog(@"error: %@", error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey]);
            NSString* ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
            NSLog(@"%@",ErrorResponse);
            
            errorSaving();
        }];
    };
    
    if (hasProfilePicture) {
        BFMediaObject *profilePictureObject = [[BFMediaObject alloc] initWithImage:profilePicture];
        
        [BFAPI uploadImage:profilePictureObject copmletion:^(BOOL success, NSString * _Nonnull uploadedImageURL) {
            if (success) {
                saveUser(uploadedImageURL);
            }
            else {
                // save it anyways -- despite the profile picture failing
                saveUser(nil);
            }
        }];
    }
    else {
        saveUser(nil);
    }
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
        
        NSDictionary *nextStep = self.steps[next];
        UIView *nextBlock = nextStep[@"block"];
        
        if (self.backButton.alpha == 0 && ([nextStep[@"id"] isEqualToString:@"user_password"] || [nextStep[@"id"] isEqualToString:@"user_set_password"] || [nextStep[@"id"] isEqualToString:@"user_confirm_password"] || [nextStep[@"id"] isEqualToString:@"user_display_name"])) {
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
        }
        
        if ([nextStep[@"id"] isEqualToString:@"user_room_suggestions"]) {
            self.nextBlockerInfoLabel.text = @"Join at least 1 Room to continue";
        }
        else {
            self.nextBlockerInfoLabel.text = @"";
        }
        
        if ([nextStep[@"id"] isEqualToString:@"user_push_notifications"]) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self requestNotifications];
            });
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
            
            if ([nextStep[@"id"] isEqualToString:@"user_room_suggestions"]) {
                self.nextBlockerInfoLabel.alpha = 1;
            }
            else if ([nextStep[@"id"] isEqualToString:@"user_email"] && !self.signInLikely) {
                // show legal disclosure
                self.legalDisclosureLabel.alpha = 1;
            }
            else {
                self.nextBlockerInfoLabel.alpha = 0;
                self.legalDisclosureLabel.alpha = 0;
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
    
    NSLog(@"currentStep: %li", (long)self.currentStep);
    NSLog(@"previousStep: %li", (long)previous);
    
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
            previousTextField.textColor = [UIColor bonfireBlack];
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

- (void)showSpinnerForStep:(NSInteger)step {
    UIView *block = (UIView *)[[self.steps objectAtIndex:step] objectForKey:@"block"];
    UITextField *textField = (UITextField *)[[self.steps objectAtIndex:step] objectForKey:@"textField"];
    
    UIImageView *miniSpinner = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
    miniSpinner.image = [[UIImage imageNamed:@"miniSpinner"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    miniSpinner.tintColor = self.view.tintColor;
    miniSpinner.center = CGPointMake(block.frame.size.width / 2, textField.frame.size.height / 2);
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
        textField.textColor = [[UIColor bonfireBlack] colorWithAlphaComponent:0];
        if (textField.placeholder != nil) {
            textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:textField.placeholder attributes:@{NSForegroundColorAttributeName: [[UIColor grayColor] colorWithAlphaComponent:0]}];
        }
        textField.tintColor = [UIColor clearColor];
    } completion:nil];
}
- (void)removeSpinnerForStep:(NSInteger)step {
    UIView *block = (UIView *)[[self.steps objectAtIndex:step] objectForKey:@"block"];
    UITextField *textField = (UITextField *)[[self.steps objectAtIndex:step] objectForKey:@"textField"];
    UIImageView *miniSpinner = [block viewWithTag:1111];
    
    [UIView animateWithDuration:0.6f delay:0 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        miniSpinner.alpha = 0;
    } completion:^(BOOL finished) {
        [miniSpinner removeFromSuperview];
        
        [UIView transitionWithView:textField duration:0.3 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            textField.textColor = [UIColor bonfireBlack];
            textField.tintColor = [self.view tintColor];
            if (textField.placeholder != nil) {
                textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:textField.placeholder attributes:@{NSForegroundColorAttributeName: [UIColor bonfireGray]}];
            }
        } completion:nil];
    }];
}

- (void)showBigSpinnerForStep:(NSInteger)step {
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
    }];
    [UIView animateWithDuration:0.3f delay:0.3f options:UIViewAnimationOptionCurveEaseOut animations:^{
        spinner.alpha = 1;
    } completion:nil];
}
- (void)removeBigSpinnerForStep:(NSInteger)step push:(BOOL)push {
    NSDictionary *stepDict = [self.steps objectAtIndex:step];
    UIView *block = (UIView *)[stepDict objectForKey:@"block"];
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
            
            if (self.backButton.alpha == 0 && ([stepDict[@"id"] isEqualToString:@"user_password"] || [stepDict[@"id"] isEqualToString:@"user_set_password"] || [stepDict[@"id"] isEqualToString:@"user_confirm_password"] || [stepDict[@"id"] isEqualToString:@"user_display_name"])) {
                [UIView animateWithDuration:0.3f animations:^{
                    self.backButton.alpha = 1;
                }];
            }
        }];
    }];
}

- (void)keyboardWillChangeFrame:(NSNotification *)notification {
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
    _currentKeyboardHeight = keyboardFrameBeginRect.size.height;
    
    self.nextButton.frame = CGRectMake(self.nextButton.frame.origin.x, (self.view.frame.size.height / self.view.transform.d) - _currentKeyboardHeight - self.nextButton.frame.size.height - self.nextButton.frame.origin.x, self.nextButton.frame.size.width, self.nextButton.frame.size.height);
    self.nextBlockerInfoLabel.frame = CGRectMake(self.nextButton.frame.origin.x, self.nextButton.frame.origin.y - 16 - 21, self.nextButton.frame.size.width, 16);
    self.legalDisclosureLabel.frame = CGRectMake(self.legalDisclosureLabel.frame.origin.x, self.nextButton.frame.origin.y - 16 - self.legalDisclosureLabel.frame.size.height, self.legalDisclosureLabel.frame.size.width, self.legalDisclosureLabel.frame.size.height);
}

- (void)keyboardWillDismiss:(NSNotification *)notification {
    _currentKeyboardHeight = 0;
    
    UIWindow *window = UIApplication.sharedApplication.keyWindow;
    CGFloat bottomPadding = window.safeAreaInsets.bottom + (HAS_ROUNDED_CORNERS ? (self.nextButton.frame.origin.x / 2) : self.nextButton.frame.origin.x);
    
    NSNumber *duration = [notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    [UIView animateWithDuration:[duration floatValue] delay:0 options:[[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue] << 16 animations:^{
        self.nextButton.frame = CGRectMake(self.nextButton.frame.origin.x, (self.view.frame.size.height / self.view.transform.d) - self.nextButton.frame.size.height - bottomPadding, self.nextButton.frame.size.width, self.nextButton.frame.size.height);
        
        self.nextBlockerInfoLabel.frame = CGRectMake(self.nextButton.frame.origin.x, self.nextButton.frame.origin.y - 16 - 21, self.nextButton.frame.size.width, 16);
        self.legalDisclosureLabel.frame = CGRectMake(self.legalDisclosureLabel.frame.origin.x, self.nextButton.frame.origin.y - 16 - self.legalDisclosureLabel.frame.size.height, self.legalDisclosureLabel.frame.size.width, self.legalDisclosureLabel.frame.size.height);
    } completion:nil];
}

- (void)showImagePicker {
    UIAlertController *imagePickerOptions = [UIAlertController alertControllerWithTitle:@"Set Profile Photo" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
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

// Room Suggestions Collection View
// Used in Sign Up flow
- (void)getRoomSuggestionsList {
    // init roomsJoined so we can keep track of how many Rooms have been joined
    roomsJoined = [[NSMutableDictionary alloc] init];
    
    [[HAWebService authenticatedManager] GET:@"users/me/rooms/lists" parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSArray *responseData = responseObject[@"data"];
        
        self.roomSuggestions = [[NSMutableArray alloc] init];
        for (NSInteger i = 0; i < responseData.count; i++) {
            // iterate through each rooms_list
            NSDictionary *rooms_list = responseData[i];
            NSArray *rooms_list_rooms = rooms_list[@"attributes"][@"rooms"];
            
            [self.roomSuggestions addObjectsFromArray:rooms_list_rooms];
        }
        
        if (self.roomSuggestions.count == 0) {
            // skip step entirely
            NSInteger stepIndex = [self getIndexOfStepWithId:@"user_room_suggestions"];
            NSMutableDictionary *step = [[NSMutableDictionary alloc] initWithDictionary:self.steps[stepIndex]];
            [step setObject:[NSNumber numberWithBool:true] forKey:@"skip"];
            [self.steps replaceObjectAtIndex:stepIndex withObject:step];
            
            if (stepIndex == self.currentStep) {
                [self nextStep:true];
            }
        }
        else {
            // randomly sort
            NSInteger count = [self.roomSuggestions count];
            NSLog(@"count: %li", (long)count);
            for (NSInteger i = 0; i < count; ++i) {
                // Select a random element between i and end of array to swap with.
                NSInteger nElements = count - i;
                NSInteger n = (arc4random() % nElements) + i;
                [self.roomSuggestions exchangeObjectAtIndex:i withObjectAtIndex:n];
            }
        }
        
        self.loadingRoomSuggestions = false;
        
        [self.roomSuggestionsCollectionView reloadData];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"‼️ MyRoomsViewController / getLists() - error: %@", error);
        //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        
        self.loadingRoomSuggestions = false;
        
        [self.roomSuggestionsCollectionView reloadData];
        
        NSInteger stepIndex = [self getIndexOfStepWithId:@"user_room_suggestions"];
        NSMutableDictionary *step = [[NSMutableDictionary alloc] initWithDictionary:self.steps[stepIndex]];
        [step setObject:[NSNumber numberWithBool:true] forKey:@"skip"];
        [self.steps replaceObjectAtIndex:stepIndex withObject:step];
        
        if (stepIndex == self.currentStep) {
            [self nextStep:true];
        }
    }];
}
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (self.loadingRoomSuggestions) {
        return 3;
    }
    else {
        return self.roomSuggestions.count;
    }
}
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.loadingRoomSuggestions || self.roomSuggestions.count > 0) {
        LargeRoomCardCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:largeCardReuseIdentifier forIndexPath:indexPath];
        
        cell.loading = self.loadingRoomSuggestions;
        
        if (!cell.loading) {
            NSError *error;
            cell.room = [[Room alloc] initWithDictionary:self.roomSuggestions[indexPath.item] error:&error];
            cell.tintColor = [UIColor fromHex:cell.room.attributes.details.color];
            
            cell.roomHeaderView.backgroundColor = [UIColor fromHex:cell.room.attributes.details.color];
            // set profile pictures
            for (NSInteger i = 0; i < 4; i++) {
                BFAvatarView *avatarView;
                if (i == 0) { avatarView = cell.member1; }
                else if (i == 1) { avatarView = cell.member2; }
                else if (i == 2) { avatarView = cell.member3; }
                else { avatarView = cell.member4; }
                
                if (cell.room.attributes.summaries.members.count > i) {
                    avatarView.superview.hidden = false;
                    
                    NSError *userError;
                    User *userForImageView = [[User alloc] initWithDictionary:(NSDictionary *)cell.room.attributes.summaries.members[i] error:&userError];
                    
                    avatarView.user = userForImageView;
                }
                else {
                    avatarView.superview.hidden = true;
                }
            }
            
            cell.roomTitleLabel.text = cell.room.attributes.details.title;
            cell.roomDescriptionLabel.text = cell.room.attributes.details.theDescription;
            
            cell.profilePicture.tintColor = [UIColor fromHex:cell.room.attributes.details.color];
            
            if (cell.room.attributes.status.isBlocked) {
                [cell.followButton updateStatus:ROOM_STATUS_ROOM_BLOCKED];
            }
            else if (self.loadingRoomSuggestions && cell.room.attributes.context == nil) {
                [cell.followButton updateStatus:ROOM_STATUS_LOADING];
            }
            else {
                [cell.followButton updateStatus:cell.room.attributes.context.status];
            }
            
            DefaultsRoomMembersTitle *membersTitle = [Session sharedInstance].defaults.room.membersTitle;
            if (cell.room.attributes.summaries.counts.members) {
                NSInteger members = cell.room.attributes.summaries.counts.members;
                cell.membersLabel.text = [NSString stringWithFormat:@"%ld %@", members, members == 1 ? [membersTitle.singular lowercaseString] : [membersTitle.plural lowercaseString]];
                cell.membersLabel.alpha = 1;
            }
            else {
                cell.membersLabel.text = [NSString stringWithFormat:@"0 %@", [membersTitle.plural lowercaseString]];
                cell.membersLabel.alpha = 0.5;
            }
            
            if (cell.room.attributes.summaries.counts.posts) {
                NSInteger posts = (long)cell.room.attributes.summaries.counts.posts;
                cell.postsCountLabel.text = [NSString stringWithFormat:@"%ld %@", posts, posts == 1 ? @"post" : @"posts"];
                cell.postsCountLabel.alpha = 1;
            }
            else {
                cell.postsCountLabel.text = @"0 posts";
                cell.postsCountLabel.alpha = 0.5;
            }
            
            [cell layoutSubviews];
        }
        
        return cell;
    }
    
    // if all else fails, return a blank cell
    UICollectionViewCell *blankCell = [collectionView dequeueReusableCellWithReuseIdentifier:blankCellIdentifier forIndexPath:indexPath];
    return blankCell;
}
- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(268, 304);
}
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (!self.loadingRoomSuggestions && self.roomSuggestions.count > 0) {
        // animate the cell user tapped on
        Room *room = [[Room alloc] initWithDictionary:self.roomSuggestions[indexPath.row] error:nil];
        
        [[Launcher sharedInstance] openRoom:room];
    }
}
// Room Updated -> called when a Room has been joined/left
// Determine whether or not the requirement of >= 1 Rooms joined has been met
- (void)roomUpdated:(NSNotification *)notification {
    Room *room = notification.object;
    
    if (room != nil) {
        for (NSInteger i = 0; i < self.roomSuggestions.count; i++) {
            if ([self.roomSuggestions[i][@"id"] isEqualToString:room.identifier]) {
                // same room -> replace it with updated object
                [self.roomSuggestions replaceObjectAtIndex:i withObject:[room toDictionary]];
            }
        }
        [self.roomSuggestionsCollectionView reloadData];
        
        // determine whether the user is a member or not
        BOOL isMember = [room.attributes.context.status isEqualToString:ROOM_STATUS_MEMBER] || [room.attributes.context.status isEqualToString:ROOM_STATUS_REQUESTED];
        
        NSLog(@"isMember? %@", isMember ? @"YES" : @"NO");
        
        if (isMember) {
            [roomsJoined setObject:[NSNumber numberWithBool:true] forKey:room.identifier];
        }
        else {
            [roomsJoined removeObjectForKey:room.identifier];
        }
        
        [self checkRoomsJoinedRequirement];
    }
}
- (void)checkRoomsJoinedRequirement {
    if ([roomsJoined allKeys].count > 0) {
        // good to go!
        [self enableNextButton];
        
        [UIView animateWithDuration:0.3f animations:^{
            self.nextBlockerInfoLabel.alpha = 0;
        }];
    }
    else {
        [self greyOutNextButton];
        
        [UIView animateWithDuration:0.3f animations:^{
            self.nextBlockerInfoLabel.alpha = 1;
        }];
    }
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
    NSInteger profilePictureStep = [self getIndexOfStepWithId:@"user_profile_picture"];
    UIImageView *profilePictureImageView = self.steps[profilePictureStep][@"block"];
    profilePictureImageView.tag = 1;
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
    CGFloat circleRadius = controller.maskRect.size.width * .5;
    
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
