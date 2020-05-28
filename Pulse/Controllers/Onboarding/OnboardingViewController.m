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
#import "Camp.h"
#import "ComplexNavigationController.h"
#import "UIColor+Palette.h"
#import "Launcher.h"
#import "NSString+Validation.h"
#import "HAWebService.h"
#import "SmallMediumCampCardCell.h"
#import <NSString+EMOEmoji.h>
#import "ResetPasswordViewController.h"
#import "BFAlertController.h"
#import <PINCache/PINCache.h>
#import <libPhoneNumber-iOS/NBPhoneNumberUtil.h>
#import <Lockbox/Lockbox.h>

@import UserNotifications;
@import Firebase;
#import <RSKImageCropper/RSKImageCropper.h>

#define IS_IPHONE        (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)

@interface OnboardingViewController () <RSKImageCropViewControllerDelegate, RSKImageCropViewControllerDataSource, ResetPasswordViewControllerDelegate> {
    UIEdgeInsets safeAreaInsets;
    NSMutableDictionary *campsJoined;
}

@property (nonatomic) NSArray *colors;
@property (nonatomic) NSInteger themeColor;

@property (nonatomic) NSInteger currentStep;
@property (nonatomic, strong) NSMutableArray *steps;
@property (nonatomic, strong) ComplexNavigationController *launchNavVC;
@property (nonatomic) CGFloat currentKeyboardHeight;

@property (nonatomic) BOOL phoneNumberSignUpAllowed;
@property (nonatomic) BOOL preventNewAccountCreation;

typedef enum {
    BFSignUpMethodEmailAddress,
    BFSignUpMethodPhoneNumber
} BFSignUpMethod;
@property (nonatomic) BFSignUpMethod signUpMethod;

@property (nonatomic) BOOL requiresRegistration;

@property (nonatomic) int secondsRemaining;
@property (nonatomic, strong) NSTimer *phoneOneTimeCodeResendTimer;

@property (nonatomic, strong) NSMutableArray <Camp *> *campSuggestions;

#define kOnboardingTextFieldTag_Email 201
#define kOnboardingTextFieldTag_OneTimeCode 202
#define kOnboardingTextFieldTag_Password 203
#define kOnboardingTextFieldTag_DisplayName 204
#define kOnboardingTextFieldTag_Username 205

@end

@implementation OnboardingViewController

static NSString * const smallMediumCardReuseIdentifier = @"CampCard";
static NSString * const blankCellIdentifier = @"BlankCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor contentBackgroundColor];
    self.view.tintColor = [UIColor bonfireBrand];
    
    self.phoneNumberSignUpAllowed = [[NSLocale currentLocale].countryCode isEqualToString:@"US"];
    
    // rate limit to 2 sign ups / day
    self.preventNewAccountCreation = ![Session canCreateNewAccount];
    //
    
    [self setupViews];
    [self setupSteps];
    
    // –––– show the first step ––––
    self.currentStep = -1;
    [self nextStep:false];
        
    // Google Analytics
    [FIRAnalytics setScreenName:@"Onboarding" screenClass:nil];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self addListeners];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}
- (void)addListeners {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillDismiss:) name:UIKeyboardWillHideNotification object:nil];
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)requestNotifications {
    [self.view endEditing:true];
    
    [[UNUserNotificationCenter currentNotificationCenter] getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
        if (settings.authorizationStatus == UNAuthorizationStatusNotDetermined && ![[NSUserDefaults standardUserDefaults] objectForKey:@"push_notifications_last_requested"]) {
            BFAlertController *accessRequest = [BFAlertController alertControllerWithIcon:[UIImage imageNamed:@"alert_icon_notifications"] title:@"Receive Instant Updates" message:@"Turn on Push Notifications to get instant updates from Bonfire" preferredStyle:BFAlertControllerStyleAlert];
            
            BFAlertAction *okAction = [BFAlertAction actionWithTitle:@"Okay" style:BFAlertActionStyleDefault handler:^{
                [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:(UNAuthorizationOptionAlert|UNAuthorizationOptionSound|UNAuthorizationOptionBadge) completionHandler:^(BOOL granted, NSError * _Nullable error) {
                    // 1. check if permisisons granted
                    [self receivedNotificationsUpdate:nil];
                    
                    if (granted) {
                        // do work here
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSLog(@"inside dispatch async block main thread from main thread");
                            [[UIApplication sharedApplication] registerForRemoteNotifications];
                        });
                    }
                }];
            }];
            [accessRequest addAction:okAction];
            
            BFAlertAction *notNowAction = [BFAlertAction actionWithTitle:@"Not Now" style:BFAlertActionStyleCancel handler:^{
                [self receivedNotificationsUpdate:nil];
            }];
            [accessRequest addAction:notNowAction];
            
            accessRequest.preferredAction = okAction;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"inside dispatch async block main thread from main thread");
                [[NSUserDefaults standardUserDefaults] setObject:[NSDate new] forKey:@"push_notifications_last_requested"];
                
                [accessRequest show];
            });
        }
        else if (settings.authorizationStatus != UNAuthorizationStatusDenied) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"inside dispatch async block main thread from main thread");
                [[UIApplication sharedApplication] registerForRemoteNotifications];
            });
            [self receivedNotificationsUpdate:nil];
        }
        else {
            [self receivedNotificationsUpdate:nil];
        }
    }];
}
- (void)receivedNotificationsUpdate:(NSNotification *)notificaiton {
    [[PINCache sharedCache] removeAllObjects];
    [[Session tempCache] removeAllObjects];
    
    // last step: download defaults, then launch
    [[Session sharedInstance] initDefaultsWithCompletion:^(BOOL success) {
        NSLog(@"success fetching defaults ? %@", success ? @"YES" : @"NO");
        
        [Launcher launchLoggedIn:true replaceRootViewController:false];
    }];
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
    [self.backButton setTitleColor:[UIColor bonfireSecondaryColor] forState:UIControlStateDisabled];
    [self.backButton setImage:[[UIImage imageNamed:@"leftArrowIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    self.backButton.tintColor = self.view.tintColor;
    self.backButton.alpha = 0;
    self.backButton.adjustsImageWhenHighlighted = false;
    [self.backButton bk_whenTapped:^{
        [self previousStep:-1];
    }];
    [self.view addSubview:self.backButton];
    
    CGFloat buttonWidth = self.view.frame.size.width - 48;
    buttonWidth = buttonWidth > IPAD_CONTENT_MAX_WIDTH ? IPAD_CONTENT_MAX_WIDTH : buttonWidth;
    
    self.nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.nextButton.frame = CGRectMake(self.view.frame.size.width / 2 - buttonWidth / 2, self.view.frame.size.height - 48 - (HAS_ROUNDED_CORNERS ? [[UIApplication sharedApplication] keyWindow].safeAreaInsets.bottom + 12 : 24), buttonWidth, 48);
    self.nextButton.backgroundColor = [self.view tintColor];
    self.nextButton.titleLabel.font = [UIFont systemFontOfSize:20.f weight:UIFontWeightSemibold];
    [self.nextButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.nextButton setTitleColor:[UIColor bonfireSecondaryColor] forState:UIControlStateDisabled];
    [self continuityRadiusForView:self.nextButton withRadius:14.f];
    [self.nextButton setTitle:@"Next" forState:UIControlStateNormal];
    [self.view addSubview:self.nextButton];
    [self greyOutNextButton];
    
    [self.nextButton bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.nextButton.alpha = 0.8;
            self.nextButton.transform = CGAffineTransformMakeScale(0.92, 0.92);
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
    self.nextBlockerInfoLabel.textColor = [UIColor bonfireSecondaryColor];
    self.nextBlockerInfoLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightRegular];
    self.nextBlockerInfoLabel.alpha = 0;
    [self.view addSubview:self.nextBlockerInfoLabel];
    
    self.legalDisclosureLabel = [UIButton buttonWithType:UIButtonTypeSystem];
    self.legalDisclosureLabel.frame = CGRectMake(self.view.frame.size.width / 2 - 144, self.view.frame.size.height, 288, 0);
    self.legalDisclosureLabel.alpha = 0;
    self.legalDisclosureLabel.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.legalDisclosureLabel.titleLabel.numberOfLines = 0;
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:@"By continuing, you acknowledge that you have read the Privacy Policy and agree to the Terms of Service." attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:11.f weight:UIFontWeightRegular], NSForegroundColorAttributeName: [UIColor bonfireSecondaryColor]}];
    [attributedString addAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:11.f weight:UIFontWeightSemibold], NSForegroundColorAttributeName: [UIColor bonfirePrimaryColor]} range:[attributedString.string rangeOfString:@"Privacy Policy"]];
    [attributedString addAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:11.f weight:UIFontWeightSemibold], NSForegroundColorAttributeName: [UIColor bonfirePrimaryColor]} range:[attributedString.string rangeOfString:@"Terms of Service"]];
    [self.legalDisclosureLabel setAttributedTitle:attributedString forState:UIControlStateNormal];
    
    CGSize legalDisclosureSize = [attributedString boundingRectWithSize:CGSizeMake(self.legalDisclosureLabel.frame.size.width, CGFLOAT_MAX) options:(NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin) context:nil].size;
    self.legalDisclosureLabel.frame = CGRectMake(self.legalDisclosureLabel.frame.origin.x, self.view.frame.size.height, self.legalDisclosureLabel.frame.size.width, legalDisclosureSize.height);
    
    [self.legalDisclosureLabel bk_whenTapped:^{
        // confirm action
        BFAlertController *actionSheet = [BFAlertController alertControllerWithTitle:nil message:nil preferredStyle:BFAlertControllerStyleActionSheet];
        
        BFAlertAction *privacyPolicy = [BFAlertAction actionWithTitle:@"Privacy Policy" style:BFAlertActionStyleDefault handler:^{
            [Launcher openURL:@"https://bonfire.camp/legal/privacy"];
        }];
        [actionSheet addAction:privacyPolicy];
        
        BFAlertAction *termsOfService = [BFAlertAction actionWithTitle:@"Terms of Service" style:BFAlertActionStyleDefault handler:^{
            [Launcher openURL:@"https://bonfire.camp/legal/terms"];
        }];
        [actionSheet addAction:termsOfService];
        
        BFAlertAction *cancelActionSheet = [BFAlertAction actionWithTitle:@"Cancel" style:BFAlertActionStyleCancel handler:nil];
        [actionSheet addAction:cancelActionSheet];
        
        [actionSheet show];
    }];
    
    [self.view addSubview:self.legalDisclosureLabel];
}

- (void)setupSteps {
    CGFloat inputCenterY = (self.view.frame.size.height / 2) - (self.view.frame.size.height * .15);
    self.instructionLabel = [[UILabel alloc] initWithFrame:CGRectMake(24, self.view.frame.size.height, self.view.frame.size.width - 48, 42)];
    self.instructionLabel.center = CGPointMake(self.instructionLabel.center.x, (inputCenterY / 2) + 16);
    self.instructionLabel.textAlignment = NSTextAlignmentCenter;
    self.instructionLabel.text = @"Last step, and it’s a fun one!\nhat’s your favorite color?";
    self.instructionLabel.font = [UIFont systemFontOfSize:18.f weight:UIFontWeightMedium];
    self.instructionLabel.textColor = [UIColor bonfirePrimaryColor];
    self.instructionLabel.numberOfLines = 0;
    self.instructionLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [self.view addSubview:self.instructionLabel];
    
    self.steps = [[NSMutableArray alloc] init];
    
    NSString *identificationInstruction;
    NSString *identificationPlaceholder;
    NSString *identificationKeyboardTypeString;
    
    if (self.signInLikely) {
        identificationInstruction = @"Hi again! 👋\nPlease sign in below";
        identificationPlaceholder = @"Phone, email, or username";
        identificationKeyboardTypeString = @"text";
    }
    else {
        if (self.phoneNumberSignUpAllowed) {
            identificationInstruction = @"Welcome to Bonfire!\nWhat’s your phone or email?";
        }
        else {
            identificationInstruction = @"Welcome to Bonfire!\nWhat’s your email address?";
        }
        identificationPlaceholder = @"Email Address";
        identificationKeyboardTypeString = @"email";
    }
    
    [self.steps addObject:@{@"id": @"user_identification", @"skip": [NSNumber numberWithBool:false], @"next": @"Next", @"instruction": identificationInstruction, @"placeholder": identificationPlaceholder, @"sensitive": [NSNumber numberWithBool:false], @"keyboard": identificationKeyboardTypeString, @"textField": [NSNull null], @"block": [NSNull null]}];
    
    [self.steps addObject:@{@"id": @"user_phone_code", @"skip": [NSNumber numberWithBool:false], @"next": @"Confirm", @"instruction": @"We just texted you a code!\nPlease confirm the code below", @"placeholder":@"Code", @"sensitive": [NSNumber numberWithBool:false], @"keyboard": @"number", @"textField": [NSNull null], @"block": [NSNull null]}];
    [self.steps addObject:@{@"id": @"user_password", @"skip": [NSNumber numberWithBool:false], @"next": @"Sign In", @"instruction": @"Let's get you signed in!\nPlease enter your password", @"placeholder":@"Your Password", @"sensitive": [NSNumber numberWithBool:true], @"keyboard": @"text", @"textField": [NSNull null], @"block": [NSNull null]}];
    [self.steps addObject:@{@"id": @"user_set_password", @"skip": [NSNumber numberWithBool:false], @"next": @"Next", @"instruction": @"Let’s get you signed up!\nPlease set a password", @"placeholder": @"Password", @"sensitive": [NSNumber numberWithBool:true], @"keyboard": @"text", @"textField": [NSNull null], @"block": [NSNull null]}];
//    [self.steps addObject:@{@"id": @"user_confirm_password", @"skip": [NSNumber numberWithBool:false], @"next": @"Confirm", @"instruction": @"Just to be sure... please\nconfirm your password", @"placeholder":@"Confirm Password", @"sensitive": [NSNumber numberWithBool:true], @"keyboard": @"text", @"textField": [NSNull null], @"block": [NSNull null]}];
    [self.steps addObject:@{@"id": @"user_dob", @"skip": [NSNumber numberWithBool:false], @"next": @"Next", @"instruction": @"What's your birthday?", @"block": [NSNull null]}];
    [self.steps addObject:@{@"id": @"user_display_name", @"skip": [NSNumber numberWithBool:false], @"next": @"Next", @"instruction": @"What's your full name?\n(or nickname!)", @"placeholder": @"Full Name", @"sensitive": [NSNumber numberWithBool:false], @"keyboard": @"title", @"textField": [NSNull null], @"block": [NSNull null]}];
    [self.steps addObject:@{@"id": @"user_username", @"skip": [NSNumber numberWithBool:false], @"next": @"Next", @"instruction": @"Help others find you faster\nby setting a @username", @"placeholder": @"Username", @"sensitive": [NSNumber numberWithBool:false], @"keyboard": @"text", @"textField": [NSNull null], @"block": [NSNull null]}];
    [self.steps addObject:@{@"id": @"user_profile_picture", @"skip": [NSNumber numberWithBool:false], @"next": @"Next", @"instruction": @"Set a profile picture\n(optional)", @"block": [NSNull null]}];
    [self.steps addObject:@{@"id": @"user_color", @"skip": [NSNumber numberWithBool:false], @"next": @"Sign Up", @"instruction": @"Last step, and it’s a fun one!\nWhat’s your favorite color?", @"block": [NSNull null]}];
    [self.steps addObject:@{@"id": @"user_camp_suggestions", @"skip": [NSNumber numberWithBool:false], @"next": @"Next", @"instruction": @"Camps are the conversations\nyou care about, in one place", @"block": [NSNull null]}];
    
    for (NSInteger i = 0; i < [self.steps count]; i++) {
        // add each step to the right
        [self addStep:i];
    }
}
- (void)addStep:(NSInteger)stepIndex {
    NSMutableDictionary *mutatedStep = [[NSMutableDictionary alloc] initWithDictionary:self.steps[stepIndex]];
    
    if ([mutatedStep objectForKey:@"textField"] && ![mutatedStep[@"textfield"] isEqual:[NSNull null]]) {
        UIView *inputBlock = [[UIView alloc] initWithFrame:CGRectMake(0, (self.view.frame.size.height / 2) - (56 / 2) - (self.view.frame.size.height * .15), self.view.frame.size.width, 56)];
        [self.view addSubview:inputBlock];
        
        CGFloat textFieldWidth = self.view.frame.size.width - 48;
        textFieldWidth = textFieldWidth > IPAD_CONTENT_MAX_WIDTH ? IPAD_CONTENT_MAX_WIDTH : textFieldWidth;
        
        UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(self.view.frame.size.width / 2 - textFieldWidth / 2, 0, textFieldWidth, 56)];
        textField.textColor = [UIColor bonfirePrimaryColor];
        textField.backgroundColor = [UIColor cardBackgroundColor];
        textField.layer.cornerRadius = 14.f;
        textField.layer.masksToBounds = false;
        textField.layer.shadowRadius = 2.f;
        textField.layer.shadowOffset = CGSizeMake(0, 1);
        textField.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.1f].CGColor;
        textField.layer.shadowOpacity = 1.f;
        
        // add left-side spacing
        UIView *leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 20, textField.frame.size.height)];
        leftView.backgroundColor = [UIColor clearColor];
        textField.leftView = leftView;
        textField.rightView = leftView;
        textField.leftViewMode = UITextFieldViewModeAlways;
        textField.rightViewMode = UITextFieldViewModeAlways;
        
        if ([mutatedStep[@"id"] isEqualToString:@"user_identification"]) {
            textField.tag = kOnboardingTextFieldTag_Email;
        }
        else if ([mutatedStep[@"id"] isEqualToString:@"user_phone_code"]) {
            textField.tag = kOnboardingTextFieldTag_OneTimeCode;
        }
        else if ([mutatedStep[@"id"] isEqualToString:@"user_password"] ||
                 [mutatedStep[@"id"] isEqualToString:@"user_set_password"]) {
            textField.tag = kOnboardingTextFieldTag_Password;
        }
        else if ([mutatedStep[@"id"] isEqualToString:@"user_display_name"]) {
            textField.tag = kOnboardingTextFieldTag_DisplayName;
        }
        else if ([mutatedStep[@"id"] isEqualToString:@"user_username"]) {
            textField.tag = kOnboardingTextFieldTag_Username;
        }
        
        // set the keyboard type
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
                     [mutatedStep[@"id"] isEqualToString:@"user_identification"]) {
                textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
                textField.autocorrectionType = UITextAutocorrectionTypeNo;
                textField.keyboardType = UIKeyboardTypeDefault;
            }
            else {
                textField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
            }
        }
        
        // set text content types
        if ([mutatedStep[@"id"] isEqualToString:@"user_identification"]) {
            textField.textContentType = UITextContentTypeUsername;
        }
        else if ([mutatedStep[@"id"] isEqualToString:@"user_password"]) {
            textField.textContentType = UITextContentTypePassword;
        }
        else if ([mutatedStep[@"id"] isEqualToString:@"user_set_password"]) {
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
        else if ([mutatedStep[@"id"] isEqualToString:@"user_phone_code"]) {
            if (@available(iOS 12.0, *)) {
                textField.textContentType = UITextContentTypeOneTimeCode;
            }
        }
        
        textField.delegate = self;
        textField.returnKeyType = UIReturnKeyNext;
        textField.font = [UIFont systemFontOfSize:20.f weight:UIFontWeightMedium];
        
        [inputBlock addSubview:textField];
        
        textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:([mutatedStep objectForKey:@"placeholder"] ? mutatedStep[@"placeholder"] : @"") attributes:@{NSForegroundColorAttributeName: [UIColor bonfireSecondaryColor]}];
        [textField addTarget:self action:@selector(textFieldChanged:) forControlEvents:UIControlEventEditingChanged];
        
        if ([mutatedStep[@"sensitive"] boolValue]) {
            textField.secureTextEntry = true;
            
            UIButton *sensitivityToggle = [UIButton buttonWithType:UIButtonTypeSystem];
            [sensitivityToggle setTitleColor:[UIColor bonfirePrimaryColor] forState:UIControlStateNormal];
            sensitivityToggle.frame = CGRectMake(0, 0, 100, textField.frame.size.height);
            [sensitivityToggle setTitle:@"Show" forState:UIControlStateNormal];
            sensitivityToggle.titleLabel.font = [UIFont systemFontOfSize:20.f weight:UIFontWeightBold];
            sensitivityToggle.backgroundColor = [UIColor clearColor];
            sensitivityToggle.contentEdgeInsets = UIEdgeInsetsMake(0, 20, 0, 20);
            sensitivityToggle.frame = CGRectMake(0, 0, sensitivityToggle.intrinsicContentSize.width, textField.frame.size.height);
            textField.rightView = sensitivityToggle;
            [sensitivityToggle bk_whenTapped:^{
                if (![textField isSecureTextEntry]) {
                    // already shown -> hide it
                    textField.secureTextEntry = true;
                    
                    [sensitivityToggle setTitle:@"Show" forState:UIControlStateNormal];
                    sensitivityToggle.frame = CGRectMake(0, 0, sensitivityToggle.intrinsicContentSize.width, textField.frame.size.height);
                    
                }
                else {
                    // hidden -> show it
                    textField.secureTextEntry = false;
                    
                    [sensitivityToggle setTitle:@"Hide" forState:UIControlStateNormal];
                    sensitivityToggle.frame = CGRectMake(0, 0, sensitivityToggle.intrinsicContentSize.width, textField.frame.size.height);
                }
            }];
        }
        else {
            textField.secureTextEntry = false;
        }
        
        inputBlock.alpha = 0;
        inputBlock.transform = CGAffineTransformMakeTranslation(self.view.frame.size.width, 0);
        
        // add a reset password button for password field
        if ([mutatedStep[@"id"] isEqualToString:@"user_password"]) {
            UIButton *forgotYourPassword = [UIButton buttonWithType:UIButtonTypeSystem];
            forgotYourPassword.tag = 10;
            [forgotYourPassword setTitle:@"Forgot your password?" forState:UIControlStateNormal];
            forgotYourPassword.titleLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightSemibold];
            [forgotYourPassword setTitleColor:[UIColor bonfireSecondaryColor] forState:UIControlStateNormal];
            forgotYourPassword.frame = CGRectMake(0, textField.frame.origin.y + textField.frame.size.height + 16, self.view.frame.size.width, 32);
            [forgotYourPassword bk_whenTapped:^{
                ResetPasswordViewController *resetPasswordVC = [[ResetPasswordViewController alloc] init];
                resetPasswordVC.delegate = self;
                
                NSInteger lookupStep = [self getIndexOfStepWithId:@"user_identification"];
                UITextField *lookupTextField = self.steps[lookupStep][@"textField"];
                resetPasswordVC.prefillLookup = lookupTextField.text;
                
                resetPasswordVC.transitioningDelegate = [Launcher sharedInstance];
                [Launcher present:resetPasswordVC animated:YES];
            }];
            [inputBlock addSubview:forgotYourPassword];
            
            inputBlock.frame = CGRectMake(inputBlock.frame.origin.x, inputBlock.frame.origin.y, inputBlock.frame.size.width, forgotYourPassword.frame.origin.y + forgotYourPassword.frame.size.height);
        }
        else if ([mutatedStep[@"id"] isEqualToString:@"user_phone_code"]) {
            UIButton *resendButton = [UIButton buttonWithType:UIButtonTypeSystem];
            resendButton.tag = 10;
            [resendButton setTitle:@"Send new code in 30" forState:UIControlStateNormal];
            resendButton.titleLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightRegular];
            [resendButton setTitleColor:[UIColor bonfireSecondaryColor] forState:UIControlStateNormal];
            resendButton.frame = CGRectMake(0, textField.frame.origin.y + textField.frame.size.height + 16, self.view.frame.size.width, 32);
            [resendButton bk_whenTapped:^{
                [resendButton setTitle:@"Sending..." forState:UIControlStateNormal];
                
                resendButton.alpha = 0.75;
                resendButton.userInteractionEnabled = false;
                [resendButton.titleLabel setFont:[UIFont systemFontOfSize:resendButton.titleLabel.font.pointSize weight:UIFontWeightRegular]];
                
                [self sendPhoneVerificationCode:nil];
            }];
            [inputBlock addSubview:resendButton];
            
            inputBlock.frame = CGRectMake(inputBlock.frame.origin.x, inputBlock.frame.origin.y, inputBlock.frame.size.width, resendButton.frame.origin.y + resendButton.frame.size.height);
        }
        else if (!self.signInLikely && [mutatedStep[@"id"] isEqualToString:@"user_identification"] && self.phoneNumberSignUpAllowed) {
            UIButton *switchSignUpMethodButton = [UIButton buttonWithType:UIButtonTypeSystem];
            switchSignUpMethodButton.tag = 10;
            [switchSignUpMethodButton setTitle:@"Use phone instead" forState:UIControlStateNormal];
            switchSignUpMethodButton.titleLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightSemibold];
            [switchSignUpMethodButton setTitleColor:[UIColor bonfireSecondaryColor] forState:UIControlStateNormal];
            switchSignUpMethodButton.frame = CGRectMake(0, textField.frame.origin.y + textField.frame.size.height + 16, self.view.frame.size.width, 32);
            [switchSignUpMethodButton bk_whenTapped:^{
                textField.text = @"";
                
                if (textField.keyboardType == UIKeyboardTypeEmailAddress) {
                    // switch to phone
                    self.signUpMethod = BFSignUpMethodPhoneNumber;
                    
                    [switchSignUpMethodButton setTitle:@"Use email instead" forState:UIControlStateNormal];
                    textField.placeholder = @"Phone Number";
                    textField.keyboardType = UIKeyboardTypePhonePad;
                    textField.textContentType = UITextContentTypeTelephoneNumber;
                }
                else {
                    // switch to email
                    self.signUpMethod = BFSignUpMethodEmailAddress;
                    
                    [switchSignUpMethodButton setTitle:@"Use phone instead" forState:UIControlStateNormal];
                    textField.placeholder = @"Email Address";
                    textField.keyboardType = UIKeyboardTypeEmailAddress;
                    textField.textContentType = UITextContentTypeEmailAddress;
                }
                [textField reloadInputViews];
            }];
            [inputBlock addSubview:switchSignUpMethodButton];
            
            inputBlock.frame = CGRectMake(inputBlock.frame.origin.x, inputBlock.frame.origin.y, inputBlock.frame.size.width, switchSignUpMethodButton.frame.origin.y + switchSignUpMethodButton.frame.size.height);
        }
        
        [mutatedStep setObject:inputBlock forKey:@"block"];
        [mutatedStep setObject:textField forKey:@"textField"];
    }
    else if ([mutatedStep[@"id"] isEqualToString:@"user_dob"]) {
        UIView *dobBlock = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.width, self.nextButton.frame.size.width, 228)];
        dobBlock.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2);
        dobBlock.layer.cornerRadius = 10.f;
        dobBlock.alpha = 0;
        dobBlock.transform = CGAffineTransformMakeTranslation(self.view.frame.size.width, 0);
        dobBlock.layer.masksToBounds = false;
        dobBlock.layer.shadowRadius = 2.f;
        dobBlock.layer.shadowOffset = CGSizeMake(0, 1);
        dobBlock.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.1f].CGColor;
        dobBlock.layer.shadowOpacity = 1.f;
        dobBlock.backgroundColor = [UIColor cardBackgroundColor];
        [self.view addSubview:dobBlock];
        
        UIDatePicker *datePicker = [[UIDatePicker alloc] initWithFrame:dobBlock.bounds];
        datePicker.tag = 301;
        datePicker.date = [NSDate date];
        datePicker.datePickerMode = UIDatePickerModeDate;
        datePicker.layer.cornerRadius = dobBlock.layer.cornerRadius;
        datePicker.layer.masksToBounds = true;
        [dobBlock addSubview:datePicker];
        
        [mutatedStep setObject:dobBlock forKey:@"block"];
        [mutatedStep setObject:datePicker forKey:@"datePicker"];
    }
    else if ([mutatedStep[@"id"] isEqualToString:@"user_color"]) {
        UIView *colorBlock = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.width, 216, 216)];
        colorBlock.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2);
        colorBlock.layer.cornerRadius = 10.f;
        colorBlock.alpha = 0;
        colorBlock.transform = CGAffineTransformMakeTranslation(self.view.frame.size.width, 0);
        [self.view addSubview:colorBlock];
        
        self.colors = @[[UIColor bonfireBlue],  // 0
                        [UIColor bonfireViolet],  // 1
                        [UIColor bonfireRed],  // 2
                        [UIColor bonfireOrange],  // 3
                        [UIColor colorWithRed:0.16 green:0.72 blue:0.01 alpha:1.00], // cash green
                        [UIColor fromHex:@"#8F683C"],  // 5
                        [UIColor colorWithRed:0.96 green:0.76 blue:0.23 alpha:1.00],  // 6
                        [UIColor bonfireCyanWithLevel:800],  // 7
                        [UIColor bonfireGrayWithLevel:900]]; // 8
        
        self.themeColor = 0 + arc4random() % (self.colors.count - 1);
                
        for (NSInteger i = 0; i < 9; i++) {
            NSInteger row = i % 3;
            NSInteger column = floorf(i / 3);
                        
            UIView *colorOption = [[UIView alloc] initWithFrame:CGRectMake(column * 80, row * 80, 56, 56)];
            colorOption.layer.cornerRadius = colorOption.frame.size.height / 2;
            colorOption.backgroundColor = self.colors[i];
            colorOption.tag = i;
            [colorBlock addSubview:colorOption];
            
            if (i == (int)self.themeColor) {
                // add check image view
                UIImageView *checkView = [[UIImageView alloc] initWithFrame:CGRectMake(-6, -6, colorOption.frame.size.width + 12, colorOption.frame.size.height + 12)];
                checkView.contentMode = UIViewContentModeCenter;
                checkView.image = [UIImage imageNamed:@"selectedColorCheck"];
                checkView.tag = 999;
                checkView.layer.cornerRadius = checkView.frame.size.height / 2;
                checkView.layer.borderColor = [colorOption.backgroundColor colorWithAlphaComponent:0.25f].CGColor;
                checkView.layer.borderWidth = 7.f;
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
        UIView *userProfilePictureContainerBlock = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.width, 160, 160)];
        userProfilePictureContainerBlock.layer.cornerRadius = userProfilePictureContainerBlock.frame.size.width / 2;
        userProfilePictureContainerBlock.layer.masksToBounds = false;
        userProfilePictureContainerBlock.layer.shadowRadius = 2.f;
        userProfilePictureContainerBlock.layer.shadowOffset = CGSizeMake(0, 1);
        userProfilePictureContainerBlock.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.1f].CGColor;
        userProfilePictureContainerBlock.layer.shadowOpacity = 1.f;
        userProfilePictureContainerBlock.backgroundColor = [UIColor cardBackgroundColor];
        userProfilePictureContainerBlock.alpha = 0;
        userProfilePictureContainerBlock.center = CGPointMake(self.view.frame.size.width / 2, (self.view.frame.size.height / self.view.transform.d) / 2);
        userProfilePictureContainerBlock.transform = CGAffineTransformMakeTranslation(self.view.frame.size.width, 0);
        userProfilePictureContainerBlock.userInteractionEnabled = true;
        [self.view addSubview:userProfilePictureContainerBlock];
        
        [userProfilePictureContainerBlock bk_whenTapped:^{
            // open camp share
            [self showImagePicker];
        }];
        
        UIImageView *userProfilePictureBlock = [[UIImageView alloc] initWithFrame:userProfilePictureContainerBlock.bounds];
        userProfilePictureBlock.tag = 10;
        userProfilePictureBlock.layer.cornerRadius = userProfilePictureBlock.frame.size.width / 2;
        userProfilePictureBlock.layer.masksToBounds = true;
        userProfilePictureBlock.image = [UIImage imageNamed:@"addProfilePicture"];
        userProfilePictureBlock.contentMode = UIViewContentModeScaleAspectFill;
        [userProfilePictureContainerBlock addSubview:userProfilePictureBlock];
        
        [mutatedStep setObject:userProfilePictureContainerBlock forKey:@"block"];
    }
    else if ([mutatedStep[@"id"] isEqualToString:@"user_camp_suggestions"]) {
        UIView *block = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.width, self.view.frame.size.width, SMALL_MEDIUM_CARD_HEIGHT)];
        block.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2);
        block.alpha = 0;
        block.transform = CGAffineTransformMakeTranslation(self.view.frame.size.width, 0);
        [self.view addSubview:block];
        
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.minimumLineSpacing = 12.f;
        flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        
        self.loadingCampSuggestions = true;
        
        self.campSuggestionsCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, SMALL_MEDIUM_CARD_HEIGHT) collectionViewLayout:flowLayout];
        self.campSuggestionsCollectionView.delegate = self;
        self.campSuggestionsCollectionView.dataSource = self;
        self.campSuggestionsCollectionView.contentInset = UIEdgeInsetsMake(0, 24, 0, 24);
        self.campSuggestionsCollectionView.showsHorizontalScrollIndicator = false;
        self.campSuggestionsCollectionView.layer.masksToBounds = false;
        self.campSuggestionsCollectionView.backgroundColor = [UIColor clearColor];
        
        [self.campSuggestionsCollectionView registerClass:[SmallMediumCampCardCell class] forCellWithReuseIdentifier:smallMediumCardReuseIdentifier];
        [self.campSuggestionsCollectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:blankCellIdentifier];
        
        self.campSuggestions = [[NSMutableArray<Camp *> alloc] init];
        
        [block addSubview:self.campSuggestionsCollectionView];
        
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
    else if ([mutatedStep[@"id"] isEqualToString:@"user_dob"]) {
        UIView *spotInLineBlock = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.width, self.nextButton.frame.size.width, 288)];
        spotInLineBlock.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2);
        [self.view addSubview:spotInLineBlock];
        
        [mutatedStep setObject:spotInLineBlock forKey:@"block"];
    }
    
    [self.steps replaceObjectAtIndex:stepIndex withObject:mutatedStep];
}
- (void)prepareForSignIn {
    // skip everything except email and password
    for (NSInteger i = 0; i < self.steps.count; i++) {
        NSMutableDictionary *step = [[NSMutableDictionary alloc] initWithDictionary:self.steps[i]];
        if (self.signUpMethod == BFSignUpMethodPhoneNumber &&
            [step[@"id"] isEqualToString:@"user_phone_code"]) {
            // phone sign up
            [step setObject:[NSNumber numberWithBool:false] forKey:@"skip"];
        }
        else if (self.signUpMethod == BFSignUpMethodEmailAddress &&
                 [step[@"id"] isEqualToString:@"user_password"])  {
            // email sign up
            [step setObject:[NSNumber numberWithBool:false] forKey:@"skip"];
        }
        else {
            [step setObject:[NSNumber numberWithBool:true] forKey:@"skip"];
        }
        [self.steps replaceObjectAtIndex:i withObject:step];
    }
    [self greyOutNextButton];
}
- (void)prepareForSignUp {
    self.signInLikely = false;
    // only skip password
    for (NSInteger i = 0; i < self.steps.count; i++) {
        NSMutableDictionary *step = [[NSMutableDictionary alloc] initWithDictionary:self.steps[i]];
        if (self.signUpMethod == BFSignUpMethodPhoneNumber &&
            ([step[@"id"] isEqualToString:@"user_password"] ||
            [step[@"id"] isEqualToString:@"user_set_password"])) {
            // phone sign up
            [step setObject:[NSNumber numberWithBool:true] forKey:@"skip"];
        }
        else if (self.signUpMethod == BFSignUpMethodEmailAddress &&
                 ([step[@"id"] isEqualToString:@"user_phone_code"] ||
                 [step[@"id"] isEqualToString:@"user_password"]))  {
            // email sign up
            [step setObject:[NSNumber numberWithBool:true] forKey:@"skip"];
        }
        else {
            [step setObject:[NSNumber numberWithBool:false] forKey:@"skip"];
        }
        
        [self.steps replaceObjectAtIndex:i withObject:step];
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
        
        if (self.backButton.alpha == 0 && ([nextStep[@"id"] isEqualToString:@"user_phone_code"] || [nextStep[@"id"] isEqualToString:@"user_password"] || [nextStep[@"id"] isEqualToString:@"user_set_password"] || [nextStep[@"id"] isEqualToString:@"user_display_name"])) {
            [UIView animateWithDuration:0.3f animations:^{
                self.backButton.alpha = 1;
            }];
        }
        
        if ([nextStep[@"id"] isEqualToString:@"user_color"]) {
            [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.nextButton.backgroundColor = [self currentColor];
                [self.nextButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                self.closeButton.tintColor = [self currentColor];
            } completion:nil];
        }
        if ([nextStep[@"id"] isEqualToString:@"user_profile_picture"]) {
            
        }
        
        if ([nextStep[@"id"] isEqualToString:@"user_camp_suggestions"]) {
            self.nextBlockerInfoLabel.text = @"Tap at least 1 Camp to continue";
        }
        else {
            self.nextBlockerInfoLabel.text = @"";
        }
        
        if ([nextStep objectForKey:@"textField"] && ![nextStep[@"textfield"] isEqual:[NSNull null]]) {
            UITextField *previousTextField = activeStep[@"textField"];
            UITextField *nextTextField = nextStep[@"textField"];
            
            CGFloat delay = 0;
            if (!previousTextField) {
                if (self.currentStep == -1) {
                    // first step
                    delay = 0.01f;
                }
                else {
                    delay = 0.4f;
                }
            }
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [nextTextField becomeFirstResponder];
            });
        }
        else {
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
            
            if ([nextStep[@"id"] isEqualToString:@"user_camp_suggestions"]) {
                self.nextBlockerInfoLabel.alpha = 1;
            }
            else if ([nextStep[@"id"] isEqualToString:@"user_dob"] && !self.signInLikely) {
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
                    previous = i;
                    break;
                }
                else if (i == 0) {
                    previous = 0;
                    break;
                }
                else {
                    // NSLog(@"skip step");
                }
            }
            
        }
    }
    
//    NSLog(@"currentStep: %li", (long)self.currentStep);
//    NSLog(@"previousStep: %li", (long)previous);
    
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
        if (previousTextField) {
            [previousTextField becomeFirstResponder];
        }
        else {
            [self.view endEditing:TRUE];
        }
        
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
            [self.nextButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            self.nextButton.enabled = true;
            [self.nextButton setHidden:false];
        }
        
        self.currentStep = previous;
    }
}

- (NSString *)formatPhoneNumber:(NSString *)string {
    NSLog(@"input string: %@", string);
    
    NBPhoneNumberUtil *phoneUtil = [[NBPhoneNumberUtil alloc] init];
    NSError *anError = nil;
    
    NSLocale *currentLocale = [NSLocale currentLocale];  // get the current locale.
    NSString *countryCode = [currentLocale objectForKey:NSLocaleCountryCode];
    NBPhoneNumber *myNumber = [phoneUtil parse:string
                                 defaultRegion:countryCode error:&anError];
    
    NSString *formatted = [phoneUtil format:myNumber
         numberFormat:NBEPhoneNumberFormatINTERNATIONAL
                error:&anError];
    
    formatted = [formatted stringByReplacingOccurrencesOfString:@"+" withString:@""];
    formatted = [formatted stringByReplacingOccurrencesOfString:@"-" withString:@""];
    
    NSLog(@"output string: %@", formatted);
    
    if (anError) {
        return @"";
    }
    else {
        return formatted;
    }
}

- (void)startPhoneVerificationCodeTimer  {
    [self invalidatePhoneVerificationCodeTimer];
    
    self.phoneOneTimeCodeResendTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timerFired) userInfo:nil repeats:YES];
}
-(void)timerFired
{
    self.secondsRemaining -= 1;
}
- (void)invalidatePhoneVerificationCodeTimer {
    [self.phoneOneTimeCodeResendTimer invalidate];
    self.phoneOneTimeCodeResendTimer = nil;
}
- (void)setSecondsRemaining:(int)secondsRemaining {
    if (secondsRemaining != _secondsRemaining) {
        _secondsRemaining = secondsRemaining;
        
        UIView *phoneCodeBlock = self.steps[[self getIndexOfStepWithId:@"user_phone_code"]][@"block"];
        UIButton *resendButton = (UIButton *)[phoneCodeBlock viewWithTag:10];
        
        [UIView setAnimationsEnabled:NO];
        if (_secondsRemaining > 0) {
            [resendButton setTitle:[NSString stringWithFormat:@"Send new code in %i", self.secondsRemaining] forState:UIControlStateNormal];
            
            resendButton.alpha = 0.75;
            resendButton.userInteractionEnabled = false;
            [resendButton.titleLabel setFont:[UIFont systemFontOfSize:resendButton.titleLabel.font.pointSize weight:UIFontWeightRegular]];
        }
        else {
            [resendButton setTitle:[NSString stringWithFormat:@"Resend Code"] forState:UIControlStateNormal];
            
            resendButton.alpha = 1;
            resendButton.userInteractionEnabled = true;
            [resendButton.titleLabel setFont:[UIFont systemFontOfSize:resendButton.titleLabel.font.pointSize weight:UIFontWeightSemibold]];
        }
        [resendButton layoutIfNeeded];
        [UIView setAnimationsEnabled:YES];
        
        if (self.secondsRemaining <= 0) {
            [self invalidatePhoneVerificationCodeTimer];
        }
    }
}

- (void)sendPhoneVerificationCode:(void (^ _Nullable)(BOOL success, id _Nullable responseObject))completion {
    NSDictionary *step = self.steps[[self getIndexOfStepWithId:@"user_identification"]];
    UITextField *textField = step[@"textField"];
    
    NSString *url = @"oauth"; // sample data
    
    [[HAWebService manager] POST:url parameters:@{@"phone": [self formatPhoneNumber:textField.text], @"grant_type": @"password"} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        self.secondsRemaining = 30;
        [self startPhoneVerificationCodeTimer];
        
        if (completion) {
            completion(true, responseObject);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (completion) {
            completion(false, error);
        }
    }];
}

- (void)showAccountCreationCapAlert {
    BFAlertController *alert = [BFAlertController alertControllerWithTitle:@"Let's Consider Others" message:@"You've hit the maximum amount of sign ups per day. Please consider others and refrain from registering accounts you don't intend on using." preferredStyle:BFAlertControllerStyleAlert];
    
    BFAlertAction *gotItAction = [BFAlertAction actionWithTitle:@"Okay" style:BFAlertActionStyleCancel handler:nil];
    [alert addAction:gotItAction];
    
    [alert show];
}

- (void)handleNext {
    NSDictionary *step = self.steps[self.currentStep];
    
    self.nextButton.userInteractionEnabled = false;
    
    if ([step[@"id"] isEqualToString:@"user_identification"]) {
        // check if user exists
        UITextField *textField = step[@"textField"];
        
        // determine if we should verify email or continue to sign in using username
        if ([textField.text validateBonfirePhoneNumber] == BFValidationErrorNone) {
            self.signUpMethod = BFSignUpMethodPhoneNumber;
            
            // check for similar names
            [self greyOutNextButton];
            [self showSpinnerForStep:self.currentStep];
            
            [self sendPhoneVerificationCode:^(BOOL success, id _Nullable responseObject) {
                if (success) {
                    [self removeSpinnerForStep:self.currentStep];
                    
                    if (responseObject) {
                        self.requiresRegistration = [responseObject[@"data"][@"requires_registration"] boolValue];
                    }
                    
                    if (self.requiresRegistration) {
                        if (self.preventNewAccountCreation) {
                            [self showAccountCreationCapAlert];
                        }
                        else {
                            [self prepareForSignUp];
                            [self nextStep:true];
                        }
                    }
                    else {
                        [self prepareForSignIn];
                        [self nextStep:true];
                    }
                }
                else  {
                    [self removeSpinnerForStep:self.currentStep];
                    [self shakeInputBlock];
                    [self enableNextButton];
                    
                    NSString *errorTitle;
                    NSString *errorDescription;
                    
                    if ([responseObject isKindOfClass:[NSError class]] &&
                        [(NSError *)responseObject bonfireErrorCode] == PHONE_AUTHCODE_THRESHOLD) {
                        errorTitle = @"Please wait 30 seconds";
                        errorDescription = @"To ensure the safety of your account, please wait 30 seconds then try again.";
                    }
                    else {
                        errorTitle = @"Uh oh!";
                        errorDescription = @"We encountered a network error while looking up your account. Check your network settings and try again.";
                    }
                    
                    BFAlertController *alert = [BFAlertController alertControllerWithTitle:errorTitle message:errorDescription preferredStyle:BFAlertControllerStyleAlert];
                    BFAlertAction *gotItAction = [BFAlertAction actionWithTitle:@"Okay" style:BFAlertActionStyleCancel handler:nil];
                    [alert addAction:gotItAction];
                    
                    [alert show];
                }
            }];
        }
        else if ([textField.text validateBonfireEmail] == BFValidationErrorNone) {
            self.signUpMethod = BFSignUpMethodEmailAddress;
            
            // check for similar names
            [self greyOutNextButton];
            [self showSpinnerForStep:self.currentStep];
            
            NSString *url = @"accounts/validate/email"; // sample data
            
            [[HAWebService managerWithContentType:kCONTENT_TYPE_URL_ENCODED] GET:url parameters:@{@"email": textField.text} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, NSDictionary *responseObject) {
                [self removeSpinnerForStep:self.currentStep];
                
                BOOL isValid = [responseObject[@"data"][@"valid"] boolValue];
                BOOL isOccupied = [responseObject[@"data"][@"occupied"] boolValue];
                
                NSLog(@"isValid? %@", (isValid ? @"YES" : @"NO" ));
                NSLog(@"isOccupied? %@", (isOccupied ? @"YES" : @"NO" ));
                
                if (isValid) {
                    self.requiresRegistration = !isOccupied;
                    
                    if (self.requiresRegistration) {
                        if (self.preventNewAccountCreation) {
                            [self showAccountCreationCapAlert];
                        }
                        else {
                            [self prepareForSignUp];
                            [self nextStep:true];
                        }
                    }
                    else {
                        [self prepareForSignIn];
                        [self nextStep:true];
                    }
                }
                else {
                    [self showEmailAddressNotValid];
                }
                
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                // not long enough –> shake input block
                [self removeSpinnerForStep:self.currentStep];
                [self shakeInputBlock];
                [self enableNextButton];
                
                BFAlertController *alert = [BFAlertController alertControllerWithTitle:@"Uh oh!" message:@"We encountered a network error while looking up your account. Check your network settings and try again." preferredStyle:BFAlertControllerStyleAlert];
                BFAlertAction *gotItAction = [BFAlertAction actionWithTitle:@"Okay" style:BFAlertActionStyleCancel handler:nil];
                [alert addAction:gotItAction];
                
                [alert show];
            }];
        }
        else if (self.signInLikely && textField.text.length > 0) {
            // proceed anyways !
            [self prepareForSignIn];
            [self nextStep:true];
        }
        else {
            // unknown case
            [self removeSpinnerForStep:self.currentStep];
            [self shakeInputBlock];
            [self enableNextButton];
        }
    }
    else if ([step[@"id"] isEqualToString:@"user_phone_code"]) {
        [self attemptToSignIn];
    }
    else if ([step[@"id"] isEqualToString:@"user_password"]) {
        // sign in to user
        [self attemptToSignIn];
    }
    else if ([step[@"id"] isEqualToString:@"user_set_password"]) {
        [self enableNextButton];
        [self nextStep:true];
    }
    else if ([step[@"id"] isEqualToString:@"user_dob"]) {
        NSInteger dobStep = [self getIndexOfStepWithId:@"user_dob"];
        UIDatePicker *dobDatePicker = self.steps[dobStep][@"datePicker"];
        
        NSDate* now = [NSDate date];
        NSDateComponents* ageComponents = [[NSCalendar currentCalendar]
                                           components:NSCalendarUnitYear
                                           fromDate:dobDatePicker.date
                                           toDate:now
                                           options:0];
        NSInteger age = [ageComponents year];

        if (age >= 13) {
            // sign in to user
            [self greyOutNextButton];
            [self nextStep:true];
        }
        else {
            // not allowed
            BFAlertController *ageBlockerAlert = [BFAlertController alertControllerWithTitle:@"Must be 13 or older" message:@"Come back to Bonfire when you're old enough!" preferredStyle:BFAlertControllerStyleAlert];
            
            BFAlertAction *okayAction = [BFAlertAction actionWithTitle:@"Okay" style:BFAlertActionStyleDefault handler:^{
                [ageBlockerAlert dismissViewControllerAnimated:YES completion:nil];
            }];
            [ageBlockerAlert addAction:okayAction];
            
            [ageBlockerAlert show];
            
            [self enableNextButton];
        }
    }
    else if ([step[@"id"] isEqualToString:@"user_display_name"]) {
        // sign in to user
        [self greyOutNextButton];
        [self showSpinnerForStep:self.currentStep];
        
        // fetch username options using first word of display name
        NSString *url = @"accounts/validate/username"; // validate username before continuing
                            
        // update the username text field with the prefill username
        NSInteger displayNameStep = [self getIndexOfStepWithId:@"user_display_name"];
        UITextField *displayNameTextField = self.steps[displayNameStep][@"textField"];
        NSString *displayName = displayNameTextField.text;

        NSString *username = [displayName componentsSeparatedByString:@" "].count > 0 ? [[displayName componentsSeparatedByString:@" "] firstObject] : displayName;
        [[HAWebService managerWithContentType:kCONTENT_TYPE_URL_ENCODED] GET:url parameters:@{@"username": username} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, NSDictionary *responseObject) {
            [self removeSpinnerForStep:self.currentStep];
            
            BOOL isValid = [responseObject[@"data"][@"valid"] boolValue];
            BOOL isOccupied = [responseObject[@"data"][@"occupied"] boolValue];
            NSArray *suggestions = responseObject[@"data"][@"suggestions"];
            
            NSLog(@"isValid? %@", (isValid ? @"YES" : @"NO" ));
            NSLog(@"isOccupied? %@", (isOccupied ? @"YES" : @"NO" ));
                        
            NSString *preFillUsername = @"";
            if (isValid) {
                if (isOccupied) {
                    // username already taken
                    
                    // use first suggestion
                    if (suggestions.count > 0) {
                        preFillUsername = [suggestions firstObject];
                    }
                }
                else {
                    preFillUsername = [username lowercaseString];
                }
            }
            else {
                // use first suggestion
                if (suggestions.count > 0) {
                    preFillUsername = [suggestions firstObject];
                }
            }
            
            // update the username text field with the prefill username
            NSInteger usernameStep = [self getIndexOfStepWithId:@"user_username"];
            UITextField *usernameTextField = self.steps[usernameStep][@"textField"];
            usernameTextField.text = [@"@" stringByAppendingString:preFillUsername];
            
            [self enableNextButton];
            [self nextStep:true];
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            // error generating valid username, proceed anyways
            [self removeSpinnerForStep:self.currentStep];
            [self enableNextButton];
            [self nextStep:true];
        }];
    }
    else if ([step[@"id"] isEqualToString:@"user_username"]) {
        UITextField *textField = step[@"textField"];
        NSString *username = [textField.text stringByReplacingOccurrencesOfString:@"@" withString:@""];
        BFValidationError error = [username validateBonfireUsername];
        
        if (error != BFValidationErrorNone) {
            // username not valid
            [self shakeInputBlock];
            [self enableNextButton];
            
            NSString *title = @"";
            NSString *message = @"";
            switch (error) {
                case BFValidationErrorTooShort:
                    title = @"Username Too Short";
                    message = @"Your username must at least 3 characters long";
                    break;
                case BFValidationErrorTooLong:
                    title = @"Username Too Long";
                    message = [NSString stringWithFormat:@"Your username cannot be longer than 15 characters"];
                    break;
                case BFValidationErrorContainsInvalidCharacters:
                    title = @"Username Cannot Contain Special Characters";
                    message = [NSString stringWithFormat:@"Your username can only contain alphanumeric characters (letters A-Z, numbers 0-9) with the exception of underscores and must include at least one non-number character"];
                    break;
                case BFValidationErrorContainsInvalidWords:
                    title = @"Username Cannot Contain Certain Words";
                    message = [NSString stringWithFormat:@"To protect our community, your username cannot contain the words Bonfire, Admin, or Moderator"];
                    break;
                    
                default:
                    title = @"Unexpected Username Error";
                    message = [NSString stringWithFormat:@"Please ensure that your display name is between 1 and 40 characters long"];
                    break;
            }
            
            BFAlertController *alert = [BFAlertController alertControllerWithTitle:title message:message preferredStyle:BFAlertControllerStyleAlert];
            BFAlertAction *gotItAction = [BFAlertAction actionWithTitle:@"Okay" style:BFAlertActionStyleCancel handler:nil];
            [alert addAction:gotItAction];
            
            [alert show];
        }
        else {
            // verify username is available
            [self greyOutNextButton];
            [UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.closeButton.alpha = 0;
                self.backButton.alpha = 0;
            } completion:nil];
            [self showSpinnerForStep:self.currentStep];
            
            // validate username is available and sign up if it is :)
            NSString *url = @"accounts/validate/username"; // validate username before continuing
            
            [[HAWebService managerWithContentType:kCONTENT_TYPE_URL_ENCODED] GET:url parameters:@{@"username": username} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, NSDictionary *responseObject) {
                BOOL isValid = [responseObject[@"data"][@"valid"] boolValue];
                BOOL isOccupied = [responseObject[@"data"][@"occupied"] boolValue];
                
                NSLog(@"isValid? %@", (isValid ? @"YES" : @"NO" ));
                NSLog(@"isOccupied? %@", (isOccupied ? @"YES" : @"NO" ));
                
                if (isValid) {
                    if (isOccupied) {
                        // username already taken
                        [self removeSpinnerForStep:self.currentStep];
                        [self shakeInputBlock];
                        [self enableNextButton];
                        
                        BFAlertController *alert = [BFAlertController alertControllerWithTitle:@"Username Not Available" message:@"Uh oh! Looks like someone already has that username. Please try another one!" preferredStyle:BFAlertControllerStyleAlert];
                        BFAlertAction *gotItAction = [BFAlertAction actionWithTitle:@"Okay" style:BFAlertActionStyleCancel handler:nil];
                        [alert addAction:gotItAction];
                        
                        [alert show];
                    }
                    else {
                        if ([Session sharedInstance].currentUser) {
                            // user already exists
                            [self attemptToUpdateUser:@{@"dob": [self dobValue], @"display_name": [self displayNameValue], @"username": [self usernameValue]} completion:^(BOOL success) {
                                if (success) {
                                    // next step is profile pic
                                    [self enableNextButton];
                                }
                            }];
                        }
                        else {
                            [self attemptEmailSignUp];
                        }
                    }
                }
                else {
                    // email not valid
                    [self removeSpinnerForStep:self.currentStep];
                    [self shakeInputBlock];
                    [self enableNextButton];
                    
                    BFAlertController *alert = [BFAlertController alertControllerWithTitle:@"Username Not Valid" message:@"We had an issue verifying your username. Please try again or choose a different username!" preferredStyle:BFAlertControllerStyleAlert];
                    BFAlertAction *gotItAction = [BFAlertAction actionWithTitle:@"Okay" style:BFAlertActionStyleCancel handler:nil];
                    [alert addAction:gotItAction];
                    
                    [alert show];
                }
                
                [UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                    self.closeButton.alpha = 1;
                    self.backButton.alpha = 1;
                } completion:nil];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                // not long enough –> shake input block
                [self removeSpinnerForStep:self.currentStep];
                [self shakeInputBlock];
                [self enableNextButton];

                [UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                    self.closeButton.alpha = 1;
                    self.backButton.alpha = 1;
                } completion:nil];
                
                NSInteger code = 0;
                
                NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                NSLog(@"erorr repsonse: %@", ErrorResponse);
                NSData *errorData = [ErrorResponse dataUsingEncoding:NSUTF8StringEncoding];
                NSDictionary *errorDict = [NSJSONSerialization JSONObjectWithData:errorData options:0 error:nil];
                if ([errorDict objectForKey:@"error"]) {
                    if (errorDict[@"error"][@"code"]) {
                        code = [errorDict[@"error"][@"code"] integerValue];
                    }
                }
                
                if (code == USER_USERNAME_TAKEN) {
                    BFAlertController *alert = [BFAlertController alertControllerWithTitle:@"Username Not Available" message:@"Uh oh! Looks like someone already has that username. Please try another one!" preferredStyle:BFAlertControllerStyleAlert];
                    BFAlertAction *gotItAction = [BFAlertAction actionWithTitle:@"Okay" style:BFAlertActionStyleCancel handler:nil];
                    [alert addAction:gotItAction];
                    
                    [alert show];
                }
                else {
                    BFAlertController *alert = [BFAlertController alertControllerWithTitle:@"Uh oh!" message:@"We encountered a network error while looking up your account. Check your network settings and try again." preferredStyle:BFAlertControllerStyleAlert];
                    BFAlertAction *gotItAction = [BFAlertAction actionWithTitle:@"Okay" style:BFAlertActionStyleCancel handler:nil];
                    [alert addAction:gotItAction];
                    
                    [alert show];
                }
            }];
        }
    }
    else if ([step[@"id"] isEqualToString:@"user_color"]) {
        [self greyOutNextButton];
        [self showBigSpinnerForStep:self.currentStep];
        
        // save profile picture and color
        [self uploadProfilePicture:^(BOOL success, NSString *profilePictureURL) {
            NSMutableDictionary *updateParams = [[NSMutableDictionary alloc] initWithDictionary:@{@"color": [UIColor toHex:self.colors[self.themeColor]]}];
            
            if (profilePictureURL && profilePictureURL.length > 0) {
                [updateParams setObject:profilePictureURL forKey:@"avatar"];
            }
            
            [self attemptToUpdateUser:updateParams completion:^(BOOL success) {
                NSLog(@"successfully updated: %@", [updateParams allKeys]);
            }];
        }];
    }
    else if ([step[@"id"] isEqualToString:@"user_camp_suggestions"]) {
        [self greyOutNextButton];
        [UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.closeButton.alpha = 0;
            self.backButton.alpha = 0;
        } completion:nil];
        
        [self followSelectedCamps];
    }
    else {
        [self nextStep:true];
    }
}

- (void)showEmailAddressNotValid {
    // email not valid
    [self removeSpinnerForStep:self.currentStep];
    [self shakeInputBlock];
    
    [self enableNextButton];
    
    BFAlertController *alert = [BFAlertController alertControllerWithTitle:@"Email Not Valid" message:@"We had an issue verifying your email. Please make sure there aren't any typos in the email provided." preferredStyle:BFAlertControllerStyleAlert];
    BFAlertAction *gotItAction = [BFAlertAction actionWithTitle:@"Okay" style:BFAlertActionStyleCancel handler:nil];
    [alert addAction:gotItAction];
    
    [alert show];
}
- (void)showPhoneNumberNotValid {
    // phone not valid
    [self removeSpinnerForStep:self.currentStep];
    [self shakeInputBlock];
    
    [self enableNextButton];
    
    BFAlertController *alert = [BFAlertController alertControllerWithTitle:@"Invalid Phone Number" message:@"Please make sure you entered a valid phone number" preferredStyle:BFAlertControllerStyleAlert];
    BFAlertAction *gotItAction = [BFAlertAction actionWithTitle:@"Okay" style:BFAlertActionStyleCancel handler:nil];
    [alert addAction:gotItAction];
    
    [alert show];
}

- (void)attemptToSignIn {
    // check if user exists
    NSInteger emailOrUsernameStep = [self getIndexOfStepWithId:@"user_identification"];
    UITextField *emailOrUsernameTextField = self.steps[emailOrUsernameStep][@"textField"];
    NSString *emailOrUsername = emailOrUsernameTextField.text;
    
    NSDictionary *params;
    
    NSMutableArray *viewsToHide = [NSMutableArray new];
    
    if ([emailOrUsernameTextField.text validateBonfirePhoneNumber] == BFValidationErrorNone) {
        [self invalidatePhoneVerificationCodeTimer];
        
        NSInteger phoneCodeStep = [self getIndexOfStepWithId:@"user_phone_code"];
        UIView *phoneCodeBlock = self.steps[phoneCodeStep][@"block"];
        UIButton *resendButton = (UIButton *)[phoneCodeBlock viewWithTag:10];
        [viewsToHide addObject:resendButton];
        UITextField *phoneCodeTextField = self.steps[phoneCodeStep][@"textField"];
        NSString *phoneCode = phoneCodeTextField.text;
        
        params = @{@"phone": [self formatPhoneNumber:emailOrUsername], @"code": phoneCode, @"grant_type": @"password"};
    }
    else {
        NSInteger passwordStep = [self getIndexOfStepWithId:@"user_password"];
        UIView *passwordBlock = self.steps[passwordStep][@"block"];
        UIButton *forgotPasswordButton = (UIButton *)[passwordBlock viewWithTag:10];
        [viewsToHide addObject:forgotPasswordButton];
        UITextField *passwordTextField = self.steps[passwordStep][@"textField"];
        NSString *password = passwordTextField.text;
        
        if ([emailOrUsernameTextField.text validateBonfireEmail] == BFValidationErrorNone) {
            params = @{@"email": emailOrUsername, @"password": password, @"grant_type": @"password"};
        }
        else {
            params = @{@"username": emailOrUsername, @"password": password, @"grant_type": @"password"};
        }
    }
    
    // fade out actions
    [self showSpinnerForStep:self.currentStep];
    [self greyOutNextButton];
    [UIView animateWithDuration:0.25f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.backButton.alpha = 0;
        self.closeButton.alpha = 0;
        for (UIView *view in viewsToHide) {
            view.alpha = 0;
        }
    } completion:nil];
    
    [[HAWebService managerWithContentType:kCONTENT_TYPE_URL_ENCODED] POST:@"oauth" parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, NSDictionary *responseObject) {
        [[Session sharedInstance] setAccessToken:responseObject[@"data"]];

        // TODO: Open LauncherNavigationViewController
        [BFAPI getUser:^(BOOL success) {
            if (success) {
                if (self.requiresRegistration) {
                    // handle as if a user just registered
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
                    
                    // start loading the camp suggestions, so they're ready when we need them
                    [self getCampSuggestionsList];
                }
                else {
                    [FIRAnalytics logEventWithName:@"onboarding_signed_in"
                                        parameters:@{}];

                    [self requestNotifications];
                }
            }
            else {
                [UIView animateWithDuration:0.25f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                    self.backButton.alpha = 1;
                    self.closeButton.alpha = 1;
                    for (UIView *view in viewsToHide) {
                        view.alpha = 1;
                    }
                } completion:nil];

                [self removeSpinnerForStep:self.currentStep];
                [self shakeInputBlock];

                [self enableNextButton];
            }
        }];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSHTTPURLResponse *httpResponse = error.userInfo[AFNetworkingOperationFailingURLResponseErrorKey];
        NSInteger statusCode = httpResponse.statusCode;
        NSInteger bonfireErrorCode = [error bonfireErrorCode];
        
        // not long enough –> shake input block
        [self removeSpinnerForStep:self.currentStep];
        [self enableNextButton];
        [self startPhoneVerificationCodeTimer];
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.25f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.backButton.alpha = 1;
                self.closeButton.alpha = 1;
                for (UIView *view in viewsToHide) {
                    view.alpha = 1;
                }
            } completion:nil];
        });
        
        if (bonfireErrorCode == USER_PASSWORD_REQ_RESET) {
            // user requires a password reset
            ResetPasswordViewController *setNewPasswordVC = [[ResetPasswordViewController alloc] init];
            setNewPasswordVC.delegate = self;
            setNewPasswordVC.contextType = ResetPasswordContextTypeRequired;
            
            NSInteger lookupStep = [self getIndexOfStepWithId:@"user_identification"];
            UITextField *lookupTextField = self.steps[lookupStep][@"textField"];
            setNewPasswordVC.prefillLookup = lookupTextField.text;
            
            setNewPasswordVC.transitioningDelegate = [Launcher sharedInstance];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [Launcher present:setNewPasswordVC animated:YES];
            });
        }
        else {
            [self shakeInputBlock];
            dispatch_async(dispatch_get_main_queue(), ^{
                UIView *currentTextField = (UITextField *)[self.steps[self.currentStep] objectForKey:@"textField"];
                [currentTextField becomeFirstResponder];
            });
            
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
            
            BFAlertController *alert = [BFAlertController alertControllerWithTitle:errorTitle message:errorMessage preferredStyle:BFAlertControllerStyleAlert];
            BFAlertAction *gotItAction = [BFAlertAction actionWithTitle:@"Okay" style:BFAlertActionStyleCancel handler:nil];
            [alert addAction:gotItAction];
            
            [alert show];
        }
    }];
}
- (void)passwordDidChange:(NSString *)newPassword {
    if (!newPassword || newPassword.length == 0) return;
    
    NSInteger passwordStep = [self getIndexOfStepWithId:@"user_password"];
    UITextField *passwordTextField = self.steps[passwordStep][@"textField"];
    passwordTextField.text = newPassword;
    [self textFieldChanged:passwordTextField];
    
    [self attemptToSignIn];
}
- (NSString *)identificationValue {
    NSInteger identificationStep = [self getIndexOfStepWithId:@"user_identification"];
    UITextField *identificationTextField = self.steps[identificationStep][@"textField"];
    
    return identificationTextField.text;
}
- (NSString *)passwordValue {
    NSInteger passwordStep = [self getIndexOfStepWithId:@"user_set_password"];
    UITextField *passwordTextField = self.steps[passwordStep][@"textField"];
    
    return passwordTextField.text;
}
- (NSString *)displayNameValue {
    NSInteger displayNameStep = [self getIndexOfStepWithId:@"user_display_name"];
    UITextField *displayNameTextField = self.steps[displayNameStep][@"textField"];
    
    return displayNameTextField.text;
}
- (NSString *)usernameValue {
    NSInteger usernameStep = [self getIndexOfStepWithId:@"user_username"];
    UITextField *usernameTextField = self.steps[usernameStep][@"textField"];
    
    return [[usernameTextField.text stringByReplacingOccurrencesOfString:@"@" withString:@""] stringByReplacingOccurrencesOfString:@" " withString:@""];
}
- (NSString *)dobValue {
    NSInteger dobStep = [self getIndexOfStepWithId:@"user_dob"];
    UIDatePicker *dobDatePicker = self.steps[dobStep][@"datePicker"];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    
    return [dateFormatter stringFromDate:dobDatePicker.date];
}
- (void)attemptEmailSignUp {
    NSDictionary *params = @{
        @"email": [self identificationValue],
        @"password": [self passwordValue],
        @"username": [self usernameValue],
        @"display_name": [self displayNameValue],
        @"dob": [self dobValue]
    };
        
    [[HAWebService managerWithContentType:kCONTENT_TYPE_URL_ENCODED] POST:@"accounts" parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSError *error;
        User *user = [[User alloc] initWithDictionary:responseObject[@"data"] error:&error];
        [[Session sharedInstance] updateUser:user];
        
        // rate limit to 2 sign ups / day
        NSArray *deviceSignUps = [Lockbox unarchiveObjectForKey:@"device_sign_ups"];
        NSMutableArray *newSignUps;
        if (deviceSignUps) {
            newSignUps = [[NSMutableArray alloc] initWithArray:deviceSignUps];
        }
        else {
            newSignUps = [NSMutableArray new];
        }
        [newSignUps addObject:@{@"id": user.identifier, @"created_at": user.attributes.createdAt}];
        [Lockbox archiveObject:newSignUps forKey:@"device_sign_ups"];
        //
        
        [FIRAnalytics logEventWithName:@"onboarding_signed_up"
                            parameters:@{}];
        
        // get access token for user
        [[HAWebService managerWithContentType:kCONTENT_TYPE_URL_ENCODED] POST:@"oauth" parameters:@{@"email": params[@"email"], @"password": params[@"password"], @"grant_type": @"password"} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, NSDictionary *responseObject) {
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
            
            // start loading the camp suggestions, so they're ready when we need them
            [self getCampSuggestionsList];
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            // not long enough –> shake input block
            [self removeSpinnerForStep:self.currentStep];
            [self shakeInputBlock];
            
            [self enableNextButton];
            
            BFAlertController *alert = [BFAlertController alertControllerWithTitle:@"Uh oh!" message:@"We encountered an error while signing you up. Check your network settings and try again." preferredStyle:BFAlertControllerStyleAlert];
            BFAlertAction *gotItAction = [BFAlertAction actionWithTitle:@"Okay" style:BFAlertActionStyleCancel handler:nil];
            [alert addAction:gotItAction];
            
            [alert show];
        }];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        // email not valid
        [self removeSpinnerForStep:self.currentStep];
        [self shakeInputBlock];
        
        [self enableNextButton];
        
        BFAlertController *alert = [BFAlertController alertControllerWithTitle:@"Unexpected Error" message:@"We had an issue verifying your account. Check your network settings and try again." preferredStyle:BFAlertControllerStyleAlert];
        BFAlertAction *gotItAction = [BFAlertAction actionWithTitle:@"Okay" style:BFAlertActionStyleCancel handler:nil];
        [alert addAction:gotItAction];
        
        [alert show];
    }];
}

- (void)uploadProfilePicture:(void (^ _Nullable)(BOOL success, NSString * _Nullable profilePictureURL))handler {
    NSInteger profilePictureStep = [self getIndexOfStepWithId:@"user_profile_picture"];
    UIView *profilePictureView = self.steps[profilePictureStep][@"block"];
    UIImageView *profilePictureImageView = [profilePictureView viewWithTag:10];
    UIImage *profilePicture = profilePictureImageView.image;
    CGImageRef cgref = [profilePicture CGImage];
    CIImage *cim = [profilePicture CIImage];
    BOOL hasProfilePicture = (cim != nil || cgref != NULL) && profilePictureView.tag == 1;
        
    if (hasProfilePicture) {
        BFMediaObject *profilePictureObject = [[BFMediaObject alloc] initWithImage:profilePicture];
        
        [BFAPI uploadImage:profilePictureObject copmletion:^(BOOL success, NSString * _Nonnull uploadedImageURL) {
            if (success) {
                // @"avatar"
                handler(true, uploadedImageURL);
            }
            else {
                handler(true, nil);
            }
        }];
    }
    else {
        handler(true, nil);
    };
}
- (void)attemptToUpdateUser:(NSDictionary *)params completion:(void (^ _Nullable)(BOOL success))completion {
    [[HAWebService authenticatedManager] PUT:@"users/me" parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"/users/me responseObject: %@", responseObject);
        
        // move spinner
        [self removeSpinnerForStep:self.currentStep];
        [self removeBigSpinnerForStep:self.currentStep push:true];
        
        User *updatedUser = [[User alloc] initWithDictionary:responseObject[@"data"] error:nil];
        [[Session sharedInstance] updateUser:updatedUser];
        
        [self greyOutNextButton];
        
        // default - hide buttons
        self.closeButton.userInteractionEnabled = false;
        self.backButton.userInteractionEnabled = false;
        [UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.closeButton.alpha = 0;
            self.backButton.alpha = 0;
        } completion:nil];
        
        [self nextStep:true];
        
        [FIRAnalytics logEventWithName:@"onboarding_updated_user"
                            parameters:params];
        
        completion(true);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self removeBigSpinnerForStep:self.currentStep push:false];
        [self removeSpinnerForStep:self.currentStep];
        [self shakeInputBlock];
        
        [self enableNextButton];
        
        completion(false);
    }];
}


#pragma mark - Theme Color
- (void)setColor:(UIView *)sender {
    if (sender.tag != self.themeColor) {
        [HapticHelper generateFeedback:FeedbackType_Selection];
        
        // remove previously selected color
        NSInteger colorStep = [self getIndexOfStepWithId:@"user_color"];
        UIView *colorBlock = self.steps[colorStep][@"block"];
                
        UIView *previousColorView;
        for (UIView *subview in colorBlock.subviews) {
            if (subview.tag == self.themeColor) {
                previousColorView = subview;
                break;
            }
        }

        for (UIImageView *imageView in previousColorView.subviews) {
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
        
        self.themeColor = sender.tag;
        
        // add check image view
        UIImageView *checkView = [[UIImageView alloc] initWithFrame:CGRectMake(-6, -6, sender.frame.size.width + 12, sender.frame.size.height + 12)];
        checkView.contentMode = UIViewContentModeCenter;
        checkView.image = [UIImage imageNamed:@"selectedColorCheck"];
        checkView.tag = 999;
        checkView.layer.cornerRadius = checkView.frame.size.height / 2;
        checkView.layer.borderColor = [sender.backgroundColor colorWithAlphaComponent:0.25f].CGColor;
        checkView.layer.borderWidth = 7.f;
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
- (UIColor *)currentColor {
    return self.colors[self.themeColor];
}

#pragma mark - UITeextFieldDelegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *newStr = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    if (textField.tag == kOnboardingTextFieldTag_Email) {
        return newStr.length <= MAX_EMAIL_LENGTH ? YES : NO;
    }
    if (textField.tag == kOnboardingTextFieldTag_OneTimeCode) {
        return newStr.length <= 6;
    }
    if (textField.tag == kOnboardingTextFieldTag_Password) {
        return newStr.length <= MAX_PASSWORD_LENGTH ? YES : NO;
    }
    if (textField.tag == kOnboardingTextFieldTag_DisplayName) {
        return newStr.length <= MAX_USER_DISPLAY_NAME_LENGTH ? YES : NO;
    }
    if (textField.tag == kOnboardingTextFieldTag_Username) {
        if (newStr.length == 0) return NO;
        
        // prevent spaces
        if ([newStr rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].location != NSNotFound) {
            return NO;
        }
        
        // prevent emojis
        if ([newStr emo_containsEmoji]) {
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
#pragma mark UITextField Notifications
- (void)textFieldChanged:(UITextField *)sender {
    if ([self.steps[self.currentStep][@"id"] isEqualToString:@"user_identification"]) {
        BOOL valid = false;
        if ([sender.text validateBonfireEmail] == BFValidationErrorNone) {
            valid = true;
        }
        else if ([sender.text validateBonfirePhoneNumber] == BFValidationErrorNone) {
            valid = true;
        }
        else if (self.signInLikely && sender.text.length > 0) {
            valid = true;
        }
                
        if (valid) {
            // qualifies
            [self enableNextButton];
        }
        else {
            [self greyOutNextButton];
        }
    }
    else if ([self.steps[self.currentStep][@"id"] isEqualToString:@"user_phone_code"]) {
        UITextField *textField = (UITextField *)[[self.steps objectAtIndex:self.currentStep] objectForKey:@"textField"];
        if (textField.text.length == 6) {
            [self handleNext];
        }
    }
    else if ([self.steps[self.currentStep][@"id"] isEqualToString:@"user_password"] ||
        [self.steps[self.currentStep][@"id"] isEqualToString:@"user_set_password"]) {
        if ([sender.text validateBonfirePassword] == BFValidationErrorNone) {
            // qualifies
            [self enableNextButton];
        }
        else {
            [self greyOutNextButton];
        }
    }
    else if ([self.steps[self.currentStep][@"id"] isEqualToString:@"user_username"]) {
        if ([sender.text validateBonfireUsername] == BFValidationErrorNone) {
            // qualifies
            [self enableNextButton];
        }
        else {
            [self greyOutNextButton];
        }
    }
    else if ([self.steps[self.currentStep][@"id"] isEqualToString:@"user_display_name"]) {
        if ([sender.text validateBonfireDisplayName] == BFValidationErrorNone) {
            // qualifies
            [self enableNextButton];
        }
        else {
            [self greyOutNextButton];
        }
    }
}

#pragma mark - Step Status Indicators
- (void)shakeInputBlock {
    dispatch_async(dispatch_get_main_queue(), ^{
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
    });
}
- (void)greyOutNextButton {
    self.nextButton.enabled = false;
    self.nextButton.backgroundColor = [UIColor bonfireDisabledColor];
}
- (void)enableNextButton {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.nextButton.enabled = true;
        self.nextButton.backgroundColor = self.view.tintColor;
        [self.nextButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.nextButton.userInteractionEnabled = true;
    });
}

#pragma mark Input Spinner
- (void)showSpinnerForStep:(NSInteger)step {
    UIView *block = (UIView *)[[self.steps objectAtIndex:step] objectForKey:@"block"];
    UITextField *textField = (UITextField *)[[self.steps objectAtIndex:step] objectForKey:@"textField"];
    [textField resignFirstResponder];
    
    UIImageView *miniSpinner = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
    miniSpinner.image = [[UIImage imageNamed:@"miniSpinner"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    miniSpinner.tintColor = self.view.tintColor;
    miniSpinner.center = CGPointMake(block.frame.size.width / 2, textField.frame.size.height / 2);
    miniSpinner.alpha = 0;
    miniSpinner.tag = 1111;
    
    CABasicAnimation *rotationAnimation;
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0 /* full rotation*/ * 1 * 1.f ];
    rotationAnimation.duration = 0.75f;
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
            textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:textField.placeholder attributes:@{NSForegroundColorAttributeName: [[UIColor grayColor] colorWithAlphaComponent:0]}];
        }
        textField.tintColor = [UIColor clearColor];
        textField.leftView.alpha = 0;
        textField.rightView.alpha = 0;
    } completion:nil];
}
- (void)removeSpinnerForStep:(NSInteger)step {
    UIView *block = (UIView *)[[self.steps objectAtIndex:step] objectForKey:@"block"];
    UITextField *textField = (UITextField *)[[self.steps objectAtIndex:step] objectForKey:@"textField"];
    UIImageView *miniSpinner = [block viewWithTag:1111];
    
    dispatch_async(dispatch_get_main_queue(), ^{
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
                textField.leftView.alpha = 1;
                textField.rightView.alpha = 1;
            } completion:nil];
        }];
    });
}

#pragma mark Big Spinner
- (void)showBigSpinnerForStep:(NSInteger)step {
    UIView *block = (UIView *)[[self.steps objectAtIndex:step] objectForKey:@"block"];
    
    UIImageView *spinner = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 42, 42)];
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
            
            if (self.backButton.alpha == 0 && ([stepDict[@"id"] isEqualToString:@"user_password"] || [stepDict[@"id"] isEqualToString:@"user_set_password"] || [stepDict[@"id"] isEqualToString:@"user_display_name"])) {
                [UIView animateWithDuration:0.3f animations:^{
                    self.backButton.alpha = 1;
                }];
            }
        }];
    }];
}

#pragma mark - Keyboard NSNotifications
- (void)keyboardWillChangeFrame:(NSNotification *)notification {
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
    _currentKeyboardHeight = keyboardFrameBeginRect.size.height;
    
    self.nextButton.frame = CGRectMake(self.nextButton.frame.origin.x, (self.view.frame.size.height / self.view.transform.d) - _currentKeyboardHeight - self.nextButton.frame.size.height - 24, self.nextButton.frame.size.width, self.nextButton.frame.size.height);
    self.nextBlockerInfoLabel.frame = CGRectMake(self.nextButton.frame.origin.x, self.nextButton.frame.origin.y - 16 - 21, self.nextButton.frame.size.width, 16);
    self.legalDisclosureLabel.frame = CGRectMake(self.legalDisclosureLabel.frame.origin.x, self.nextButton.frame.origin.y - 16 - self.legalDisclosureLabel.frame.size.height, self.legalDisclosureLabel.frame.size.width, self.legalDisclosureLabel.frame.size.height);
}
- (void)keyboardWillDismiss:(NSNotification *)notification {
    _currentKeyboardHeight = 0;
    
    UIWindow *window = UIApplication.sharedApplication.keyWindow;
    CGFloat bottomPadding = (HAS_ROUNDED_CORNERS ? window.safeAreaInsets.bottom + 12 : 24);
    
    NSNumber *duration = [notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    [UIView animateWithDuration:[duration floatValue] delay:0 options:[[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue] << 16 animations:^{
        self.nextButton.frame = CGRectMake(self.nextButton.frame.origin.x, (self.view.frame.size.height / self.view.transform.d) - self.nextButton.frame.size.height - bottomPadding, self.nextButton.frame.size.width, self.nextButton.frame.size.height);
        
        self.nextBlockerInfoLabel.frame = CGRectMake(self.nextButton.frame.origin.x, self.nextButton.frame.origin.y - 24 - 21, self.nextButton.frame.size.width, 16);
        self.legalDisclosureLabel.frame = CGRectMake(self.legalDisclosureLabel.frame.origin.x, self.nextButton.frame.origin.y - 24 - self.legalDisclosureLabel.frame.size.height, self.legalDisclosureLabel.frame.size.width, self.legalDisclosureLabel.frame.size.height);
    } completion:nil];
}

#pragma mark - Profile Picture Image Picker
- (void)showImagePicker {
    BFAlertController *imagePickerOptions = [BFAlertController alertControllerWithTitle:@"Set Profile Picture" message:nil preferredStyle:BFAlertControllerStyleActionSheet];
    
    BFAlertAction *takePhoto = [BFAlertAction actionWithTitle:@"Take Photo" style:BFAlertActionStyleDefault handler:^{
        [self takePhotoForProfilePicture:nil];
    }];
    [imagePickerOptions addAction:takePhoto];
    
    BFAlertAction *chooseFromLibrary = [BFAlertAction actionWithTitle:@"Choose from Library" style:BFAlertActionStyleDefault handler:^{
        [self chooseFromLibraryForProfilePicture:nil];
    }];
    [imagePickerOptions addAction:chooseFromLibrary];
    
    BFAlertAction *cancel = [BFAlertAction actionWithTitle:@"Cancel" style:BFAlertActionStyleCancel handler:nil];
    [imagePickerOptions addAction:cancel];
    
    [imagePickerOptions show];
}
- (void)takePhotoForProfilePicture:(id)sender {
    NSString *mediaType = AVMediaTypeVideo;
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    if (authStatus == AVAuthorizationStatusAuthorized) {
        [self openCamera];
    }
    else if (authStatus == AVAuthorizationStatusDenied ||
             authStatus == AVAuthorizationStatusRestricted) {
        // denied
        [self showNoCameraAccess];
    }
    else if (authStatus == AVAuthorizationStatusNotDetermined) {
        // not determined?!
        [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
            if (granted){
                // NSLog(@"Granted access to %@", mediaType);
                [self openCamera];
            }
            else {
                // NSLog(@"Not granted access to %@", mediaType);
                [self showNoCameraAccess];
            }
        }];
    }
}
- (void)openCamera {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = NO;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    picker.cameraDevice = UIImagePickerControllerCameraDeviceFront;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[Launcher topMostViewController] presentViewController:picker animated:YES completion:nil];
    });
}
- (void)showNoCameraAccess {
    BFAlertController *actionSheet = [BFAlertController alertControllerWithTitle:@"Allow Bonfire to access your camera" message:@"To allow Bonfire to access your camera, go to Settings > Privacy > Camera > Set Bonfire to ON" preferredStyle:BFAlertControllerStyleAlert];

    BFAlertAction *openSettingsAction = [BFAlertAction actionWithTitle:@"Open Settings" style:BFAlertActionStyleDefault handler:^{
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
    }];
    [actionSheet addAction:openSettingsAction];

    BFAlertAction *closeAction = [BFAlertAction actionWithTitle:@"Close" style:BFAlertActionStyleCancel handler:nil];
    [actionSheet addAction:closeAction];
    
    [actionSheet show];
}
- (void)chooseFromLibraryForProfilePicture:(id)sender {
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        switch (status) {
            case PHAuthorizationStatusAuthorized: {
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
                    picker.delegate = self;
                    picker.allowsEditing = NO;
                    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                    [[Launcher topMostViewController] presentViewController:picker animated:YES completion:nil];
                });
                
                break;
            }
            case PHAuthorizationStatusDenied:
            case PHAuthorizationStatusNotDetermined:
            {
                // confirm action
                dispatch_async(dispatch_get_main_queue(), ^{
                    BFAlertController *actionSheet = [BFAlertController alertControllerWithTitle:@"Allow Bonfire to access your phtoos" message:@"To allow Bonfire to access your photos, go to Settings > Privacy > Camera > Set Bonfire to ON" preferredStyle:BFAlertControllerStyleAlert];

                    BFAlertAction *openSettingsAction = [BFAlertAction actionWithTitle:@"Open Settings" style:BFAlertActionStyleDefault handler:^{
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
                    }];
                    [actionSheet addAction:openSettingsAction];
                
                    BFAlertAction *closeAction = [BFAlertAction actionWithTitle:@"Close" style:BFAlertActionStyleCancel handler:nil];
                    [actionSheet addAction:closeAction];
                    
                    [actionSheet show];
                });

                break;
            }
            case PHAuthorizationStatusRestricted: {
                break;
            }
        }
    }];
}
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
        // NSLog(@"Compressed to: %.2f MB with Factor: %.2f",(float)imageData.length/1024.0f/1024.0f, compression);
    }
    // NSLog(@"Final Image Size: %.2f MB",(float)imageData.length/1024.0f/1024.0f);
    return imageData;
}
// Ancillary method to scale an image based on a CGSize
- (UIImage *)imageWithImage:(UIImage*)originalImage scaledToSize:(CGSize)newSize;
{
    @synchronized(self)
    {
        UIGraphicsBeginImageContext(newSize);
        [originalImage drawInRect:CGRectMake(0,0,floorf(newSize.width), floorf(newSize.height))];
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return newImage;
    }
    return nil;
}

#pragma mark - Camp Suggestions
// Camp Suggestions Collection View
// Used in Sign Up flow
- (void)getCampSuggestionsList {
    // init campsJoined so we can keep track of how many Camps have been joined
    campsJoined = [[NSMutableDictionary alloc] init];
    
    [[HAWebService authenticatedManager] GET:@"users/me/camps/lists/suggested" parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSArray *responseData = responseObject[@"data"];
        
        if ([responseData isKindOfClass:[NSArray class]]) {
            self.campSuggestions = [[NSMutableArray<Camp *> alloc] init];
            for (NSInteger i = 0; i < responseData.count; i++) {
                if ([responseData[i] isKindOfClass:[NSDictionary class]]) {
                    Camp *camp = [[Camp alloc] initWithDictionary:responseData[i] error:nil];
                    [self.campSuggestions addObject:camp];
                }
            }
        }
        
        if (self.campSuggestions.count == 0) {
            // skip step entirely
            NSInteger stepIndex = [self getIndexOfStepWithId:@"user_camp_suggestions"];
            NSMutableDictionary *step = [[NSMutableDictionary alloc] initWithDictionary:self.steps[stepIndex]];
            [step setObject:[NSNumber numberWithBool:true] forKey:@"skip"];
            [self.steps replaceObjectAtIndex:stepIndex withObject:step];
            
            if (stepIndex == self.currentStep) {
                [self nextStep:true];
            }
        }
        
        self.loadingCampSuggestions = false;
        
        [self.campSuggestionsCollectionView reloadData];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        // NSLog(@"‼️ MyCampsViewController / getLists() - error: %@", error);
        self.loadingCampSuggestions = false;
        
        [self.campSuggestionsCollectionView reloadData];
        
        NSInteger stepIndex = [self getIndexOfStepWithId:@"user_camp_suggestions"];
        NSMutableDictionary *step = [[NSMutableDictionary alloc] initWithDictionary:self.steps[stepIndex]];
        [step setObject:[NSNumber numberWithBool:true] forKey:@"skip"];
        [self.steps replaceObjectAtIndex:stepIndex withObject:step];
        
        if (stepIndex == self.currentStep) {
            [self nextStep:true];
        }
    }];
}
- (void)followSelectedCamps {
    NSArray *campKeys = [campsJoined allKeys];
    NSMutableArray *remainingCampKeys = campKeys.mutableCopy;
    
    void (^checkCompletion)(void) = ^(void) {
        if (remainingCampKeys.count == 0) {
            // all done following selected camps :)
            // --> let's move onto the next step, which is requesting notifications
            [self requestNotifications];
        }
    };
    
    for (NSString *campId in campKeys) {
        // follow the camp
        if (campId.length > 0) {
            // join camp
            Camp *camp = [[Camp alloc] init];
            camp.identifier = campId;
            
            [BFAPI followCamp:camp completion:^(BOOL success, id  _Nullable responseObject) {
                [remainingCampKeys removeObject:campId];
                checkCompletion();
            }];
        }
        else {
            [remainingCampKeys removeObject:campId];
            checkCompletion();
        }
    }
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (self.loadingCampSuggestions) {
        return 3;
    }
    else {
        return self.campSuggestions.count;
    }
}
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item < self.campSuggestions.count) {
        SmallMediumCampCardCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:smallMediumCardReuseIdentifier forIndexPath:indexPath];
        
        if (!cell) {
            cell = [[SmallMediumCampCardCell alloc] init];
        }
        
        cell.tapToJoin = true;
                
        cell.camp = self.campSuggestions[indexPath.item];
        [cell layoutSubviews];
        
        [cell setJoined:[campsJoined objectForKey:cell.camp.identifier] animated:false];
        
        return cell;
    }
    
    // if all else fails, return a blank cell
    UICollectionViewCell *blankCell = [collectionView dequeueReusableCellWithReuseIdentifier:blankCellIdentifier forIndexPath:indexPath];
    return blankCell;
}
- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(148, SMALL_MEDIUM_CARD_HEIGHT);
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.campSuggestions.count) {
        // animate the cell user tapped on
        Camp *camp = self.campSuggestions[indexPath.row];
                
        SmallMediumCampCardCell *cell = (SmallMediumCampCardCell *)[self.campSuggestionsCollectionView cellForItemAtIndexPath:indexPath];
        [cell setJoined:!cell.joined animated:true];
        
        if (cell.joined) {
            [campsJoined setObject:[NSNumber numberWithBool:true] forKey:camp.identifier];
        }
        else {
            [campsJoined removeObjectForKey:camp.identifier];
        }
        
        [self checkCampsJoinedRequirement];
    }
}

#pragma mark - Misc. Helper Methods
// Camp Updated -> called when a Camp has been joined/left
// Determine whether or not the requirement of >= 1 Camps joined has been met
- (void)checkCampsJoinedRequirement {
    if ([campsJoined allKeys].count > 0) {
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
- (NSInteger)getIndexOfStepWithId:(NSString *)stepId {
    for (NSInteger i = 0; i < [self.steps count]; i++) {
        if ([self.steps[i][@"id"] isEqualToString:stepId]) {
            return i;
        }
    }
    return 0;
}
- (void)continuityRadiusForView:(UIView *)sender withRadius:(CGFloat)radius {
    CAShapeLayer * maskLayer = [CAShapeLayer layer];
    maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:sender.bounds
                                           byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight|UIRectCornerTopLeft|UIRectCornerTopRight
                                                 cornerRadii:CGSizeMake(radius, radius)].CGPath;
    
    sender.layer.mask = maskLayer;
}

#pragma mark - RSKImageCropViewControllerDelegate
// Crop image has been canceled.
- (void)imageCropViewControllerDidCancelCrop:(RSKImageCropViewController *)controller
{
    [controller.navigationController dismissViewControllerAnimated:YES completion:nil];
    [self takePhotoForProfilePicture:nil];
}

// The original image has been cropped. Additionally provides a rotation angle used to produce image.
- (void)imageCropViewController:(RSKImageCropViewController *)controller
                   didCropImage:(UIImage *)croppedImage
                  usingCropRect:(CGRect)cropRect
                  rotationAngle:(CGFloat)rotationAngle
{
    // userProfilePictureContainerBlock
    
    NSInteger profilePictureStep = [self getIndexOfStepWithId:@"user_profile_picture"];
    UIView *profilePictureView = self.steps[profilePictureStep][@"block"];
    profilePictureView.tag = 1;
    
    UIImageView *profilePictureImageView = [profilePictureView viewWithTag:10];
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
    
    // NSLog(@"maskSize(%f, %f)", maskSize.width, maskSize.height);
    
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

@end
