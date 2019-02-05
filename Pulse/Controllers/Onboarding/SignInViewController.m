//
//  SignInViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 12/16/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "SignInViewController.h"
#import "UIColor+Palette.h"
#import "NSString+Validation.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import "OnboardingViewController.h"
#import "Launcher.h"
#import "Session.h"
#import "HAWebService.h"
#import <HapticHelper/HapticHelper.h>
@import UserNotifications;

@interface SignInViewController () {
    int currentColor;
    NSTimer *bgColorTimer;
}

@property (strong, nonatomic) HAWebService *manager;

@end

@implementation SignInViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.content = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.content];
    
    self.darkStatusBar = false;
    self.view.backgroundColor = [UIColor bonfireBrand];
    self.view.tintColor = [UIColor bonfireBrand];
    
    self.manager = [HAWebService manager];
    
    [self setupLaunchLogo];
    [self setupLogo];
    [self setupSignInView];
    [self setupSignUpButton];
    
    self.content.transform = CGAffineTransformMakeScale(1.1, 1.1);
    self.content.alpha = 0;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedNotificationsUpdate:) name:@"NotificationsDidRegister" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedNotificationsUpdate:) name:@"NotificationsDidFailToRegister" object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.view endEditing:YES];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)receivedNotificationsUpdate:(NSNotification *)notificaiton {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[Launcher sharedInstance] launchLoggedIn:true];
    });
}
- (void)requestNotifications {
    NSLog(@"request notifs");
    [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:(UNAuthorizationOptionAlert|UNAuthorizationOptionSound|UNAuthorizationOptionBadge) completionHandler:^(BOOL granted, NSError * _Nullable error) {
        // 1. check if permisisons granted
        if (granted) {
            NSLog(@"granted!");
            dispatch_async(dispatch_get_main_queue(), ^{
                // do work here
                NSLog(@"a suh");
                [[UIApplication sharedApplication] registerForRemoteNotifications];
            });
        }
        else {
            NSLog(@"not granted fam");
        }
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.content.alpha != 1) {
        [UIView animateWithDuration:0.15f delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            // [self setNeedsStatusBarAppearanceUpdate];
            // self.view.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1];
            self.launchLogo.transform = CGAffineTransformMakeScale(0, 0);
            // self.logo.alpha = 0;
        } completion:^(BOOL finished) {
            self.launchLogo.transform = CGAffineTransformIdentity;
            self.launchLogo.frame = CGRectMake(0, 0, 67, 113);
            self.launchLogo.image = [[UIImage imageNamed:@"bonfire_logomark"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            self.launchLogo.tintColor = [UIColor whiteColor];
            self.launchLogo.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2);
            self.launchLogo.transform = CGAffineTransformMakeScale(0.01, 0.01);
            
            [self beginColorBursts];
            
            [UIView animateWithDuration:self.fromLaunch?0.6:0 delay:0 usingSpringWithDamping:0.6f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                // self.logo.alpha = 1;
                self.launchLogo.transform = CGAffineTransformMakeScale(1, 1);
            } completion:nil];
            
            /*
            [UIView animateWithDuration:self.fromLaunch?0.8f:0 delay:self.fromLaunch?1.1f:0 usingSpringWithDamping:0.85f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.signInView.alpha = 1;
                self.signInView.transform = CGAffineTransformMakeScale(1, 1);
                
                self.signUpButton.alpha = 1;
            } completion:nil];*/
        }];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillDismiss:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
}

- (void)beginColorBursts {
    NSArray *colors = @[[UIColor bonfireOrange],
               [UIColor colorWithRed:0.96 green:0.76 blue:0.23 alpha:1.00],
               [UIColor bonfireBrand],
               [UIColor bonfireGrayWithLevel:50]]; // 8
    for (int i = 0; i < colors.count; i++) {
        UIView *bubble = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.height * 1.2, self.view.frame.size.height * 1.2)];
        bubble.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2);
        bubble.backgroundColor = colors[i];
        bubble.layer.cornerRadius = bubble.frame.size.height / 2;
        bubble.layer.masksToBounds = true;
        bubble.layer.shouldRasterize = true;
        bubble.layer.rasterizationScale = [UIScreen mainScreen].scale;
        bubble.transform = CGAffineTransformMakeScale(0.01, 0.01);
        [self.view insertSubview:bubble belowSubview:self.launchLogo];
        
        BOOL lastOne = (i == colors.count - 1);
        
        CGFloat duration = 1.2 + (lastOne ? 0.4f : 0);
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(((duration*.25)*i + (lastOne ? 0.15f : 0)) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [HapticHelper generateFeedback:FeedbackType_Impact_Light];
            [UIView animateWithDuration:duration delay:0 usingSpringWithDamping:0.9f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                bubble.transform = CGAffineTransformMakeScale(1, 1);
                
                if (lastOne) {
                    // last one
                    self.launchLogo.transform = CGAffineTransformMakeScale(25, 25);
                    self.launchLogo.tintColor = bubble.backgroundColor;
                    
                    self.darkStatusBar = true;
                    [self setNeedsStatusBarAppearanceUpdate];
                }
                else {
                    self.launchLogo.transform = CGAffineTransformMakeScale(1 + (i * .05), 1 + (i * .05));
                }
            } completion:^(BOOL finished) {
                self.view.backgroundColor = bubble.backgroundColor;
                [bubble removeFromSuperview];
            }];
            
            if (lastOne) {
                [UIView animateWithDuration:duration delay:0.25f usingSpringWithDamping:0.8 initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                    self.content.transform = CGAffineTransformMakeScale(1, 1);
                    self.content.alpha = 1;
                } completion:nil];
            }
        });
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return self.darkStatusBar ? UIStatusBarStyleDefault : UIStatusBarStyleLightContent;
}
- (void)setupLaunchLogo {
    self.launchLogo = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.frame.size.width / 2 - (204 / 2), self.view.frame.size.height / 2 - (50 / 2), 204, 50)];
    self.launchLogo.image = [[UIImage imageNamed:@"bonfire_wordmark"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.launchLogo.tintColor = [UIColor whiteColor];
    [self.view insertSubview:self.launchLogo belowSubview:self.content];
}
- (void)setupLogo {
    self.logo = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.frame.size.width / 2 - (48 / 2), 100, 48, 82)];
    self.logo.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 4);
    self.logo.image = [[UIImage imageNamed:@"bonfire_logomark"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.logo.tintColor = [UIColor bonfireBrand];
    [self.content addSubview:self.logo];
}
- (void)setupSignInView {
    self.signInView = [[UIView alloc] initWithFrame:CGRectMake(28, self.view.frame.size.height / 2 - (190 / 2), self.view.frame.size.width - (28 * 2), 190)];
    [self.content addSubview:self.signInView];
    
    self.emailTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, self.signInView.frame.size.width, 56)];
    self.emailTextField.placeholder = @"Email or username";
    self.emailTextField.keyboardType = UIKeyboardTypeEmailAddress;
    self.emailTextField.returnKeyType = UIReturnKeyNext;
    self.emailTextField.textContentType = UITextContentTypeUsername;
    [self stylizeSignInTextField:self.emailTextField];
    [self.signInView addSubview:self.emailTextField];
    
    self.passwordTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, self.emailTextField.frame.size.height + 14, self.signInView.frame.size.width, 56)];
    self.passwordTextField.placeholder = @"Password";
    self.passwordTextField.secureTextEntry = true;
    self.passwordTextField.returnKeyType = UIReturnKeyGo;
    self.emailTextField.textContentType = UITextContentTypePassword;
    [self.passwordTextField setClearsOnBeginEditing:YES];
    [self stylizeSignInTextField:self.passwordTextField];
    [self.signInView addSubview:self.passwordTextField];
    
    self.signInButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.signInButton.frame = CGRectMake(0, self.signInView.frame.size.height - 48, self.signInView.frame.size.width, 48);
    self.signInButton.layer.masksToBounds = true;
    self.signInButton.layer.cornerRadius = 12.f;
    self.signInButton.backgroundColor = [UIColor bonfireBrand];
    [self.signInButton setTitle:@"Sign In" forState:UIControlStateNormal];
    [self.signInButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.signInButton.titleLabel.font = [UIFont systemFontOfSize:18.f weight:UIFontWeightSemibold];
    self.signInButton.adjustsImageWhenHighlighted = false;
    [self.signInButton bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.signInButton.transform = CGAffineTransformMakeScale(0.92, 0.92);
        } completion:nil];
    } forControlEvents:UIControlEventTouchDown];
    [self.signInButton bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.signInButton.transform = CGAffineTransformIdentity;
        } completion:nil];
    } forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit)];
    
    [self.signInButton bk_whenTapped:^{
        if ([self checkRequirements]) {
            [self attemptSignIn];
        }
        else {
            [self shakeSignInButton];
        }
    }];
    
    [self.signInView addSubview:self.signInButton];
    
    self.spinner = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 64, 64)];
    self.spinner.image = [[UIImage imageNamed:@"spinner"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.spinner.tintColor = [UIColor bonfireBrand];
    self.spinner.center = self.signInView.center;
    self.spinner.alpha = 0;
    self.spinner.userInteractionEnabled = false;
    [self.content addSubview:self.spinner];
}
- (void)stylizeSignInTextField:(UITextField *)textField {
    textField.delegate = self;
    textField.keyboardAppearance = UIKeyboardAppearanceLight;
    textField.textColor = [UIColor colorWithWhite:0.2f alpha:1];
    textField.backgroundColor = [UIColor colorWithWhite:1 alpha:1];
    textField.layer.cornerRadius = 12.f;
    textField.layer.masksToBounds = false;
    textField.layer.shadowOffset = CGSizeMake(0, 1);
    textField.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.1f].CGColor;
    textField.layer.shadowRadius = 2.f;
    textField.layer.shadowOpacity = 1;
    textField.tintColor = self.view.tintColor;
    textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    textField.autocorrectionType = UITextAutocorrectionTypeNo;
    textField.font = [UIFont systemFontOfSize:20.f weight:UIFontWeightMedium];
    
    UIView *padding = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 20, textField.frame.size.height)];
    textField.leftView = padding;
    textField.leftViewMode = UITextFieldViewModeAlways;
    textField.rightView = padding;
    textField.rightViewMode = UITextFieldViewModeAlways;
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.emailTextField) {
        [self.passwordTextField becomeFirstResponder];
    }
    else if (textField == self.passwordTextField) {
        if ([self checkRequirements]) {
            [self attemptSignIn];
        }
        else {
            [self shakeSignInButton];
        }
    }
    
    return false;
}
- (BOOL)checkRequirements {
    BOOL validEmail = [self.emailTextField.text validateBonfireEmail] == BFValidationErrorNone;
    BOOL validUsername = [self.emailTextField.text validateBonfireUsername] == BFValidationErrorNone;
    BOOL validPassword = [self.passwordTextField.text validateBonfirePassword] == BFValidationErrorNone;
    
    BOOL success = ((validEmail || validUsername) && validPassword);
    
    return success;
}
- (void)setupSignUpButton {
    self.signUpButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.signUpButton.frame = CGRectMake(28, self.view.frame.size.height - [[[UIApplication sharedApplication] delegate] window].safeAreaInsets.bottom - 48 - 24, self.view.frame.size.width - 56, 48);
    self.signUpButton.layer.borderWidth = 1.f;
    self.signUpButton.layer.borderColor = [UIColor colorWithWhite:0 alpha:0.06f].CGColor;
    self.signUpButton.layer.cornerRadius = 12.f;
    [self.signUpButton setTitle:@"Sign Up" forState:UIControlStateNormal];
    [self.signUpButton setTitleColor:[UIColor bonfireGrayWithLevel:800] forState:UIControlStateNormal];
    self.signUpButton.titleLabel.font = [UIFont systemFontOfSize:18.f weight:UIFontWeightSemibold];

    [self.signUpButton bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.signUpButton.transform = CGAffineTransformMakeScale(0.92, 0.92);
        } completion:nil];
    } forControlEvents:UIControlEventTouchDown];
    [self.signUpButton bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.signUpButton.transform = CGAffineTransformIdentity;
        } completion:nil];
    } forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit)];
    [self.signUpButton bk_whenTapped:^{
        [self.view endEditing:YES];
        
        OnboardingViewController *obvc = [[OnboardingViewController alloc] init];
        obvc.transitioningDelegate = [Launcher sharedInstance];
        
        [self presentViewController:obvc animated:YES completion:nil];
    }];
    
    [self.content addSubview:self.signUpButton];
    
    self.signUpLabel = [[UILabel alloc] init];
    self.signUpLabel.frame = CGRectMake(self.signUpButton.frame.origin.x, self.signUpButton.frame.origin.y - 18 - 16, self.signUpButton.frame.size.width, 18);
    self.signUpLabel.textColor = [UIColor bonfireGrayWithLevel:600];
    self.signUpLabel.font = [UIFont systemFontOfSize:15.f weight:UIFontWeightRegular];
    self.signUpLabel.text = @"Don't have an account yet?";
    self.signUpLabel.textAlignment = NSTextAlignmentCenter;
    [self.content addSubview:self.signUpLabel];
}

- (void)shakeSignInButton {
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position"];
    [animation setDuration:0.08];
    [animation setRepeatCount:4];
    [animation setAutoreverses:YES];
    [animation setFromValue:[NSValue valueWithCGPoint:
                             CGPointMake([self.signInButton center].x - 8.f, [self.signInButton center].y)]];
    [animation setToValue:[NSValue valueWithCGPoint:
                           CGPointMake([self.signInButton center].x + 8.f, [self.signInButton center].y)]];
    [[self.signInButton layer] addAnimation:animation forKey:@"position"];
}
- (void)attemptSignIn {
    [self.view endEditing:YES];
    self.signInView.userInteractionEnabled = false;
    
    // run request
    BOOL validEmail = [self.emailTextField.text validateBonfireEmail] == BFValidationErrorNone;
    BOOL validUsername = [self.emailTextField.text validateBonfireUsername] == BFValidationErrorNone;
    
    NSDictionary *params;
    if (validEmail) {
        NSLog(@"valid email");
        params = @{@"email": self.emailTextField.text , @"password": self.passwordTextField.text, @"grant_type": @"password"};
    }
    else if (validUsername) {
        NSLog(@"valid username");
        params = @{@"username": [self.emailTextField.text stringByReplacingOccurrencesOfString:@"@" withString:@""], @"password": self.passwordTextField.text, @"grant_type": @"password"};
    }
    else {
        [self shakeSignInButton];
        return;
    }
    
    self.spinner.alpha = 0;
    self.spinner.transform = CGAffineTransformMakeScale(0.8, 0.8);
    
    // start spinning
    [self.spinner.layer removeAllAnimations];
    CABasicAnimation *rotationAnimation;
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0 /* full rotation*/ * 1 * 1.f ];
    rotationAnimation.duration = 1.f;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = HUGE_VALF;
    [self.spinner.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
    
    [UIView animateWithDuration:0.4f delay:0.25f usingSpringWithDamping:0.8 initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.signInView.transform = CGAffineTransformMakeScale(0.8, 0.8);
        self.signInView.alpha = 0;
        
        self.signUpButton.alpha = 0;
        self.signUpLabel.alpha = 0;
        
        self.spinner.alpha = 1;
        self.spinner.transform = CGAffineTransformMakeScale(1, 1);
    } completion:nil];
    
    NSLog(@"self.manager.http headers: %@", self.manager.requestSerializer.HTTPRequestHeaders);
    
    NSString *url = [NSString stringWithFormat:@"%@/%@/oauth", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"]]; // sample data
    
    NSLog(@"url: %@", url);
    NSLog(@"params: %@", params);
    NSLog(@"self.manager: %@", self.manager);
    
    [self.manager POST:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, NSDictionary *responseObject) {
        [[Session sharedInstance] setAccessToken:responseObject[@"data"]];
        
        NSLog(@"lez get dat user now");
        // TODO: Open LauncherNavigationViewController
        [[Session sharedInstance] fetchUser:^(BOOL success) {
            if (success) {
                [self requestNotifications];
            }
            else {
                NSLog(@"hello");
            }
        }];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        NSLog(@"no can do");
        NSLog(@"error: %@", ErrorResponse);
        
        // not long enough –> shake input block
        [self shakeSignInButton];
        
        self.signInView.userInteractionEnabled = true;
        [self.passwordTextField becomeFirstResponder];
        
        [UIView animateWithDuration:0.4f delay:0.25f usingSpringWithDamping:0.8 initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.signInView.transform = CGAffineTransformMakeScale(1, 1);
            self.signInView.alpha = 1;
            
            self.signUpButton.alpha = 1;
            self.signUpLabel.alpha = 0;
            
            self.spinner.alpha = 0;
            self.spinner.transform = CGAffineTransformMakeScale(0.8, 0.8);
        } completion:nil];
        
        NSData *errorData = [ErrorResponse dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *errorDict = [NSJSONSerialization JSONObjectWithData:errorData options:0 error:nil];
        
        NSLog(@"error Dict: %@", errorDict);
        
        NSString *title = @"Uh oh!";
        NSString *message = @"We encountered an error while signing you in. Please check your password and try again.";
        
        if ([errorDict objectForKey:@"error"]) {
            if (errorDict[@"error"][@"code"] &&
                [errorDict[@"error"][@"code"] integerValue] == 64) {
                title = @"Couldn't Sign In";
                message = @"The username and password you entered did not match our records. Please double-check and try again.";
            }
        }
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *gotItAction = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [alert dismissViewControllerAnimated:true completion:nil];
        }];
        [alert addAction:gotItAction];
        [self presentViewController:alert animated:YES completion:nil];
    }];
}


- (void)keyboardWillChangeFrame:(NSNotification *)notification {
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
    _currentKeyboardHeight = keyboardFrameBeginRect.size.height;
    
    // self.signUpButton.frame = CGRectMake(self.signUpButton.frame.origin.x, self.view.frame.size.height - _currentKeyboardHeight - self.signUpButton.frame.size.height - 24, self.signUpButton.frame.size.width, self.signUpButton.frame.size.height);
}
- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
    self.currentKeyboardHeight = keyboardFrameBeginRect.size.height;
    NSLog(@"keyboard height: %f", self.currentKeyboardHeight);
    
    NSNumber *duration = [notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    [UIView animateWithDuration:[duration floatValue] delay:0 options:[[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue] << 16 animations:^{
        self.logo.frame = CGRectMake(self.view.frame.size.width / 2 - (29 / 2), [[[UIApplication sharedApplication] delegate] window].safeAreaInsets.top + 16, 29, 48);
        
        self.signUpLabel.alpha = 0;
        self.signUpButton.frame = CGRectMake(self.signUpButton.frame.origin.x, self.view.frame.size.height - self.currentKeyboardHeight - self.signUpButton.frame.size.height - 24, self.signUpButton.frame.size.width, self.signUpButton.frame.size.height);
        
        CGFloat a = self.logo.frame.origin.y + self.logo.frame.size.height;
        CGFloat b = self.signUpButton.frame.origin.y;
        self.signInView.center = CGPointMake((self.view.frame.size.width / self.view.transform.a) / 2, a + ((b - a) / 2));
        self.spinner.center = self.signInView.center;
    } completion:nil];
}
- (void)keyboardWillDismiss:(NSNotification *)notification {
    _currentKeyboardHeight = 0;
    
    NSNumber *duration = [notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    [UIView animateWithDuration:[duration floatValue] delay:0 options:[[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue] << 16 animations:^{
        self.logo.frame = CGRectMake(self.view.frame.size.width / 2 - (48 / 2), 100, 48, 82);
        self.logo.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 4);
        
        self.signUpLabel.alpha = 1;
        self.signUpButton.frame = CGRectMake(self.signUpButton.frame.origin.x, self.view.frame.size.height - [[[UIApplication sharedApplication] delegate] window].safeAreaInsets.bottom - self.signUpButton.frame.size.height - 16, self.signUpButton.frame.size.width, self.signUpButton.frame.size.height);
        
        self.signInView.center = CGPointMake((self.view.frame.size.width / self.view.transform.a) / 2, (self.view.frame.size.height / self.view.transform.d) / 2);
        self.spinner.center = self.signInView.center;
    } completion:nil];
}

@end
