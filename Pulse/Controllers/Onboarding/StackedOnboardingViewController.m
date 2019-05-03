//
//  StackedOnboardingViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 12/16/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "StackedOnboardingViewController.h"
#import "UIColor+Palette.h"
#import "NSString+Validation.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import "OnboardingViewController.h"
#import "Launcher.h"
#import "Session.h"
#import <HapticHelper/HapticHelper.h>
@import Firebase;
@import UserNotifications;

#define SLIDE_COLOR_1 [UIColor bonfireBlack] // orange
#define SLIDE_COLOR_2 [UIColor colorWithDisplayP3Red:0 green:0.46 blue:1.0 alpha:1] // blue
#define SLIDE_COLOR_3 [UIColor colorWithDisplayP3Red:0.16 green:0.76 blue:0.31 alpha:1] // green

@interface StackedOnboardingViewController () <UICollisionBehaviorDelegate> {
    NSInteger currentPage;
}

@property (nonatomic, strong) UIDynamicAnimator *animator;
@property (nonatomic, strong) UIPushBehavior *pusher;
@property (nonatomic, strong) UICollisionBehavior *collider;
@property (nonatomic, strong) UIDynamicItemBehavior *emojiDynamicProperties;

@end

@implementation StackedOnboardingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.view.tintColor = [UIColor bonfireBlack];
    
    currentPage = 0;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedNotificationsUpdate:) name:@"NotificationsDidRegister" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedNotificationsUpdate:) name:@"NotificationsDidFailToRegister" object:nil];
    
    // Google Analytics
    [FIRAnalytics setScreenName:@"Welcome" screenClass:nil];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    if (self.signUpButton == nil) {
        [self setupFunEmojis];
        [self setupSignUpButton];
        [self setupSplash];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.view endEditing:YES];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // prepare for animations
    if (self.view.tag != 1) {
        self.view.tag = 1;
        self.signInButton.alpha = 0;
        self.signUpButton.alpha = 0;
        
        // perform animations
        [UIView animateWithDuration:0.9f delay:0.5f usingSpringWithDamping:0.75f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.middleView.layer.cornerRadius = HAS_ROUNDED_CORNERS ? 16.f : 6.f;
            self.middleView.frame = CGRectMake(self.view.frame.size.width / 2 - 82.5, self.view.frame.size.height / 2 - 156 - (IS_IPHONE_5 ? 10 : 29), 165, 312);
            self.middleView.layer.shadowOpacity = 1;
            
            self.middleViewContainer.frame = self.middleView.bounds;
            self.middleViewContainer.layer.cornerRadius = self.middleView.layer.cornerRadius;
            
            self.middleViewImage.frame = CGRectMake(0, self.middleViewContainer.frame.size.height, self.middleViewContainer.frame.size.width, self.middleViewContainer.frame.size.height);
            self.middleViewImage.layer.cornerRadius = self.middleViewContainer.layer.cornerRadius;
            
            self.launchLogo.frame = CGRectMake(self.middleViewContainer.frame.size.width / 2 - 41, self.middleViewContainer.frame.size.height / 2 - 10, 82, 20);
        } completion:^(BOOL finished) {
            self.leftView.center = self.middleView.center;
            self.rightView.center = self.middleView.center;
            
            self.welcomeLabel.frame = CGRectMake(self.welcomeLabel.frame.origin.x, self.middleView.frame.origin.y / 2, self.welcomeLabel.frame.size.width, self.welcomeLabel.frame.size.height);
            self.welcomeLabel.transform = CGAffineTransformMakeTranslation(0, 10);
            
            CGFloat wchYPoint = self.middleView.frame.origin.y + self.middleView.frame.size.height;
            wchYPoint = wchYPoint + ((self.signInButton.frame.origin.y - wchYPoint) / 2) - (self.whereConversationsHappenLabel.frame.size.height / 2);
            self.whereConversationsHappenLabel.frame = CGRectMake(self.whereConversationsHappenLabel.frame.origin.x, wchYPoint, self.whereConversationsHappenLabel.frame.size.width, self.whereConversationsHappenLabel.frame.size.height);
            self.whereConversationsHappenLabel.transform = CGAffineTransformMakeTranslation(0, 10);
            
            CGFloat secondaryScreenshotOffset = [[UIScreen mainScreen] bounds].size.width > 375 ? 24 : 16;
            
            [UIView animateWithDuration:1.3f delay:0 usingSpringWithDamping:0.9f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.welcomeLabel.transform = CGAffineTransformIdentity;
                self.welcomeLabel.alpha = 1;
                
                self.signInButton.alpha = 1;
                self.signUpButton.alpha = 1;
                
                self.middleView.backgroundColor = [UIColor headerBackgroundColor];
                self.middleViewImage.frame = CGRectMake(0, 0, self.middleViewContainer.frame.size.width, self.middleViewContainer.frame.size.height);
                
                self.launchLogo.transform = CGAffineTransformMakeScale(0.2, 0.2);
                self.launchLogo.alpha = 0;
            } completion:^(BOOL finished) {
                
            }];
            
            [UIView animateWithDuration:1.6f delay:1.1f usingSpringWithDamping:0.8f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                // bounce out the secondary views
                self.leftView.frame = CGRectMake(self.middleView.frame.origin.x - self.leftView.frame.size.width - secondaryScreenshotOffset, self.leftView.frame.origin.y, self.leftView.frame.size.width, self.leftView.frame.size.height);
                self.rightView.frame = CGRectMake(self.middleView.frame.origin.x + self.middleView.frame.size.width + secondaryScreenshotOffset, self.rightView.frame.origin.y, self.rightView.frame.size.width, self.rightView.frame.size.height);
                self.leftView.alpha = 1;
                self.rightView.alpha = 1;
            } completion:nil];
            
            /*
            [UIView animateWithDuration:1.6 delay:1.f usingSpringWithDamping:0.92 initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.welcomeLabel.transform = CGAffineTransformIdentity;
                self.welcomeLabel.alpha = 1;
                
                self.signInButton.alpha = 1;
                self.signUpButton.alpha = 1;
            } completion:^(BOOL finished) {
                
            }];*/
            
            [UIView animateWithDuration:0.8f delay:2.3f usingSpringWithDamping:0.8f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.whereConversationsHappenLabel.transform = CGAffineTransformIdentity;
                self.whereConversationsHappenLabel.alpha = 1;
            } completion:nil];
        }];
    }
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

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}

- (void)setupFunEmojis {
    self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    
    UILabel *emojiLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width / 2 - 50, -80, 80, 80)];
    emojiLabel.text = @"🔥";
    emojiLabel.font = [UIFont systemFontOfSize:44.f];
    emojiLabel.textAlignment = NSTextAlignmentCenter;
    emojiLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.05];
    [self.view addSubview:emojiLabel];
    
    // Start ball off with a push
    self.pusher = [[UIPushBehavior alloc] initWithItems:@[emojiLabel]
                                                   mode:UIPushBehaviorModeInstantaneous];
    self.pusher.pushDirection = CGVectorMake(0, 1.0);
    self.pusher.active = YES; // Because push is instantaneous, it will only happen once
    [self.animator addBehavior:self.pusher];
    
    // Step 1: Add collisions
    self.collider = [[UICollisionBehavior alloc] initWithItems:@[emojiLabel]];
    self.collider.collisionDelegate = self;
    self.collider.collisionMode = UICollisionBehaviorModeEverything;
    self.collider.translatesReferenceBoundsIntoBoundary = YES;
    [self.animator addBehavior:self.collider];
    
    // Step 3: Heavy paddle
    self.emojiDynamicProperties.density = 1000.0f;
    
    // Step 4: Better collisions, no friction
    self.emojiDynamicProperties.elasticity = 1.0;
    self.emojiDynamicProperties.friction = 0.0;
    self.emojiDynamicProperties.resistance = 0.0;
}

- (void)setupSignUpButton {
    self.signUpButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.signUpButton.frame = CGRectMake(24, self.view.frame.size.height - UIApplication.sharedApplication.keyWindow.safeAreaInsets.bottom - 64, self.view.frame.size.width - 48, 64);
    self.signUpButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:@"Are you new? Join the Bonfire" attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:14.f weight:UIFontWeightRegular], NSForegroundColorAttributeName: [UIColor colorWithWhite:0.47 alpha:1]}];
    [attributedString addAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:14.f weight:UIFontWeightSemibold]} range:[attributedString.string rangeOfString:@"Join the Bonfire"]];
    [self.signUpButton setAttributedTitle:attributedString forState:UIControlStateNormal];
    
    [self.signUpButton bk_whenTapped:^{
        OnboardingViewController *obvc = [[OnboardingViewController alloc] init];
        obvc.transitioningDelegate = [Launcher sharedInstance];
        obvc.signInLikely = false;
        
        [self presentViewController:obvc animated:YES completion:nil];
    }];
    
    [self.view addSubview:self.signUpButton];
    
    self.signInButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.signInButton.frame = CGRectMake(24, self.signUpButton.frame.origin.y - 48, self.view.frame.size.width - 48, 48);
    self.signInButton.layer.masksToBounds = true;
    self.signInButton.layer.cornerRadius = 12.f;
    self.signInButton.backgroundColor = [UIColor bonfireBrand];
    [self.signInButton setTitle:@"Log In" forState:UIControlStateNormal];
    [self.signInButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.signInButton.titleLabel.font = [UIFont systemFontOfSize:20.f weight:UIFontWeightSemibold];
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
        OnboardingViewController *obvc = [[OnboardingViewController alloc] init];
        obvc.transitioningDelegate = [Launcher sharedInstance];
        obvc.signInLikely = true;
        
        [self presentViewController:obvc animated:YES completion:nil];
        
        /*
        if ([self checkRequirements]) {
            [self attemptSignIn];
        }
        else {
            [self shakeSignInButton];
        }*/
    }];
    
    UIImageView *signInButtonBg = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.signInButton.frame.size.width, self.signInButton.frame.size.width * 3)];
    signInButtonBg.image = [UIImage imageNamed:@"gradient"];
    signInButtonBg.contentMode = UIViewContentModeScaleToFill;
    CGPoint oldCenter = signInButtonBg.center;
    [UIView animateWithDuration:5.f
                          delay:0
                        options:(UIViewAnimationOptionRepeat|UIViewAnimationOptionAutoreverse)
                     animations: ^{ signInButtonBg.center = CGPointMake(oldCenter.x, -(signInButtonBg.frame.size.height / 2) + oldCenter.y); }
                     completion: ^(BOOL finished) { signInButtonBg.center = oldCenter; }];
    
    //[self.signInButton insertSubview:signInButtonBg atIndex:0];
    
    [self.view addSubview:self.signInButton];
}

- (void)setupSplash {
    self.middleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    self.middleView.backgroundColor = [UIColor whiteColor];
    self.middleView.layer.cornerRadius = HAS_ROUNDED_CORNERS ? 38.5 : 8.f;
    self.middleView.layer.shadowOpacity = 0;
    self.middleView.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.12].CGColor;
    self.middleView.layer.shadowOffset = CGSizeMake(0, 1);
    self.middleView.layer.shadowRadius = 2.f;
    [self.view addSubview:self.middleView];
    
    self.middleViewContainer = [[UIView alloc] initWithFrame:self.middleView.bounds];
    self.middleViewContainer.layer.cornerRadius = self.middleView.layer.cornerRadius;
    self.middleViewContainer.layer.masksToBounds = true;
    [self.middleView addSubview:self.middleViewContainer];
    
    self.launchLogo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bonfire_wordmark_black"]];
    self.launchLogo.frame = CGRectMake(self.view.frame.size.width / 2 - 102, self.view.frame.size.height / 2 - 25, 204, 50);
    [self.middleViewContainer addSubview:self.launchLogo];
    
    self.middleViewImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, self.middleViewContainer.frame.size.height, self.middleViewContainer.frame.size.width, self.middleViewContainer.frame.size.height)];
    self.middleViewImage.image = [UIImage imageNamed:@"onboardingMiddleImage"];
    self.middleViewImage.contentMode = UIViewContentModeScaleAspectFill;
    self.middleViewImage.backgroundColor = [UIColor redColor];
    self.middleViewImage.layer.cornerRadius = self.middleViewContainer.layer.cornerRadius;
    self.middleViewImage.layer.masksToBounds = true;
    [self.middleViewContainer addSubview:self.middleViewImage];
    
    self.welcomeLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 114, self.view.frame.size.width - 24, 40)];
    self.welcomeLabel.textAlignment = NSTextAlignmentCenter;
    self.welcomeLabel.font = [UIFont systemFontOfSize:34.f weight:UIFontWeightMedium];
    self.welcomeLabel.textColor = [UIColor bonfireBlack];
    self.welcomeLabel.text = @"Hello";
    self.welcomeLabel.alpha = 0;
    [self.view addSubview:self.welcomeLabel];
    
    self.whereConversationsHappenLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 576, self.view.frame.size.width - 24, 44)];
    self.whereConversationsHappenLabel.textAlignment = NSTextAlignmentCenter;
    self.whereConversationsHappenLabel.font = [UIFont systemFontOfSize:18.f weight:UIFontWeightMedium];
    self.whereConversationsHappenLabel.textColor = [UIColor bonfireBlack];
    self.whereConversationsHappenLabel.text = @"Bonfire is where\nconversations happen";
    self.whereConversationsHappenLabel.alpha = 0;
    self.whereConversationsHappenLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.whereConversationsHappenLabel.numberOfLines = 2;
    if (!IS_IPHONE_5) {
        [self.view addSubview:self.whereConversationsHappenLabel];
    }
    
    CGFloat secondaryScreenshotCornerRadius = HAS_ROUNDED_CORNERS?10.f:6.f;
    
    self.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 106, 200)];
    self.leftView.backgroundColor = [UIColor whiteColor];
    self.leftView.layer.cornerRadius = secondaryScreenshotCornerRadius;
    self.leftView.layer.shadowOpacity = 1;
    self.leftView.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.12].CGColor;
    self.leftView.layer.shadowOffset = CGSizeMake(0, 1);
    self.leftView.layer.shadowRadius = 2.f;
    self.leftView.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.leftView.bounds cornerRadius:secondaryScreenshotCornerRadius].CGPath;
    self.leftView.alpha = 0;
    
    UIImageView *leftImageView = [[UIImageView alloc] initWithFrame:self.leftView.bounds];
    leftImageView.image = [UIImage imageNamed:@"onboardingLeftImage"];
    leftImageView.layer.cornerRadius = secondaryScreenshotCornerRadius;
    leftImageView.layer.masksToBounds = true;
    [self.leftView addSubview:leftImageView];
    
    [self.view insertSubview:self.leftView belowSubview:self.middleView];
    
    self.rightView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 106, 200)];
    self.rightView.backgroundColor = [UIColor whiteColor];
    self.rightView.layer.cornerRadius = secondaryScreenshotCornerRadius;
    self.rightView.layer.shadowOpacity = 1;
    self.rightView.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.12].CGColor;
    self.rightView.layer.shadowOffset = CGSizeMake(0, 1);
    self.rightView.layer.shadowRadius = 2.f;
    self.rightView.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.rightView.bounds cornerRadius:secondaryScreenshotCornerRadius].CGPath;
    self.rightView.alpha = 0;
    
    UIImageView *rightImageView = [[UIImageView alloc] initWithFrame:self.rightView.bounds];
    rightImageView.image = [UIImage imageNamed:@"onboardingRightImage"];
    rightImageView.layer.cornerRadius = secondaryScreenshotCornerRadius;
    rightImageView.layer.masksToBounds = true;
    [self.rightView addSubview:rightImageView];
    
    [self.view insertSubview:self.rightView belowSubview:self.middleView];
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
/*
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
    
    NSLog(@"self.manager.http headers: %@", self.manager.requestSerializer.HTTPRequestHeaders);
    
    NSString *url = @"oauth";
    
    NSLog(@"url: %@", url);
    NSLog(@"params: %@", params);
    NSLog(@"self.manager: %@", self.manager);
    
    [self.manager POST:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, NSDictionary *responseObject) {
        [[Session sharedInstance] setAccessToken:responseObject[@"data"]];
        
        NSLog(@"lez get dat user now");
        // TODO: Open LauncherNavigationViewController
        [BFAPI getUser:^(BOOL success) {
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
    
    NSNumber *duration = [notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    [UIView animateWithDuration:[duration floatValue] delay:0 options:[[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue] << 16 animations:^{
        self.aboutScrollView.alpha = 0.8;
    } completion:nil];
    
    [UIView animateWithDuration:0.6f delay:([duration floatValue]/2) usingSpringWithDamping:0.8f initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.signInViewCloseButton.alpha = 1;
        self.signInViewCloseButton.transform = CGAffineTransformMakeScale(1, 1);
    } completion:nil];
}
- (void)keyboardWillDismiss:(NSNotification *)notification {
    _currentKeyboardHeight = 0;
    
    NSNumber *duration = [notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    [UIView animateWithDuration:[duration floatValue] delay:0 options:[[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue] << 16 animations:^{
        self.aboutScrollView.alpha = 1;
    } completion:nil];
    
    [UIView animateWithDuration:0.6f delay:0 usingSpringWithDamping:0.8f initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.signInViewCloseButton.alpha = 0;
        self.signInViewCloseButton.transform = CGAffineTransformMakeScale(0.2, 0.2);
    } completion:nil];
}
*/
- (void)createRoundedCornersForView:(UIView*)parentView tl:(BOOL)tl tr:(BOOL)tr br:(BOOL)br bl:(BOOL)bl {
    parentView.layer.cornerRadius = 0;
    CAShapeLayer * maskLayer = [CAShapeLayer layer];
    UIRectCorner corners = 0;
    if (bl) {
        corners |= UIRectCornerBottomLeft;
    }
    if (br) {
        corners |= UIRectCornerBottomRight;
    }
    if (tl) {
        corners |= UIRectCornerTopLeft;
    }
    if (tr) {
        corners |= UIRectCornerTopRight;
    }
    maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:parentView.bounds
                                           byRoundingCorners:corners
                                                 cornerRadii:CGSizeMake(26, 26)].CGPath;
    
    parentView.layer.mask = maskLayer;
}

- (void)continuityRadiusForView:(UIView *)sender withRadius:(CGFloat)radius {
    CAShapeLayer * maskLayer = [CAShapeLayer layer];
    maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:sender.bounds
                                           byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight|UIRectCornerTopLeft|UIRectCornerTopRight
                                                 cornerRadii:CGSizeMake(radius, radius)].CGPath;
    
    sender.layer.mask = maskLayer;
}

@end
