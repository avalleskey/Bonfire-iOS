//
//  StackedOnboardingViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 12/16/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "HelloViewController.h"
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

#define SLIDE_COLOR_1 [UIColor bonfirePrimaryColor] // orange
#define SLIDE_COLOR_2 [UIColor colorWithDisplayP3Red:0 green:0.46 blue:1.0 alpha:1] // blue
#define SLIDE_COLOR_3 [UIColor colorWithDisplayP3Red:0.16 green:0.76 blue:0.31 alpha:1] // green

@interface HelloViewController () <UICollisionBehaviorDelegate> {
    NSInteger currentPage;
}

@property (nonatomic, strong) UIDynamicAnimator *animator;
@property (nonatomic, strong) UIPushBehavior *pusher;
@property (nonatomic, strong) UICollisionBehavior *collider;
@property (nonatomic, strong) UIDynamicItemBehavior *emojiDynamicProperties;

@end

@implementation HelloViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor contentBackgroundColor];
    self.view.tintColor = [UIColor bonfirePrimaryColor];
    
    currentPage = 0;
    
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    
    // Google Analytics
    [FIRAnalytics setScreenName:@"Hello" screenClass:nil];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    if (self.signInButton == nil) {
        [self setupFunEmojis];
        [self setupSignUpButton];
        [self setupSplash];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.view endEditing:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // prepare for animations
    if (self.view.tag != 1) {
        self.view.tag = 1;
        
        self.signUpButton.alpha = 0;
        self.signInButton.alpha = 0;
        
        // perform animations
        [UIView animateWithDuration:0.9f delay:0.5f usingSpringWithDamping:0.75f initialSpringVelocity:0.5f options:(UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionAllowUserInteraction) animations:^{
            self.middleView.layer.cornerRadius = HAS_ROUNDED_CORNERS ? 16.f : 6.f;
            self.middleView.frame = CGRectMake(self.view.frame.size.width / 2 - 82.5, self.view.frame.size.height / 2 - 156 - (IS_IPHONE_5 ? 10 : 29), 165, 312);
            self.middleView.layer.shadowOpacity = 1;
            
            self.middleViewContainer.frame = self.middleView.bounds;
            self.middleViewContainer.layer.cornerRadius = self.middleView.layer.cornerRadius;
            
            self.middleViewImage.frame = CGRectMake(0, self.middleViewContainer.frame.size.height, self.middleViewContainer.frame.size.width, self.middleViewContainer.frame.size.height);
            self.middleViewImage.layer.cornerRadius = self.middleViewContainer.layer.cornerRadius;
            
            self.launchLogo.frame = CGRectMake(self.middleViewContainer.frame.size.width / 2 - 32, self.middleViewContainer.frame.size.height / 2 - 32, 64, 64);
        } completion:^(BOOL finished) {
            self.leftView.center = self.middleView.center;
            self.rightView.center = self.middleView.center;
            
            self.welcomeLabel.frame = CGRectMake(self.welcomeLabel.frame.origin.x, self.middleView.frame.origin.y / 2, self.welcomeLabel.frame.size.width, self.welcomeLabel.frame.size.height);
            self.welcomeLabel.transform = CGAffineTransformMakeTranslation(0, 10);
            
            CGFloat wchYPoint = self.middleView.frame.origin.y + self.middleView.frame.size.height;
            wchYPoint = wchYPoint + ((self.signUpButton.frame.origin.y - wchYPoint) / 2) - (self.whereConversationsHappenLabel.frame.size.height / 2);
            self.whereConversationsHappenLabel.frame = CGRectMake(self.whereConversationsHappenLabel.frame.origin.x, wchYPoint, self.whereConversationsHappenLabel.frame.size.width, self.whereConversationsHappenLabel.frame.size.height);
            self.whereConversationsHappenLabel.transform = CGAffineTransformMakeTranslation(0, 10);
            
            CGFloat secondaryScreenshotOffset = [[UIScreen mainScreen] bounds].size.width > 375 ? 24 : 16;
            
            [UIView animateWithDuration:1.3f delay:0 usingSpringWithDamping:0.9f initialSpringVelocity:0.5f options:(UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionAllowUserInteraction) animations:^{
                self.welcomeLabel.transform = CGAffineTransformIdentity;
                self.welcomeLabel.alpha = 1;
                
                self.signUpButton.alpha = 1;
                self.signInButton.alpha = 1;
                
                self.middleView.backgroundColor = [UIColor tableViewBackgroundColor];
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

- (UIStatusBarStyle)preferredStatusBarStyle
{
    /*
    if (@available(iOS 13.0, *)) {
        return UIStatusBarStyleDarkContent;
    } else {
        // Fallback on earlier versions
        return UIStatusBarStyleDefault;
    }*/
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
    self.signInButton = [UIButton buttonWithType:UIButtonTypeSystem];
    
    CGFloat buttonWidth = self.view.frame.size.width - 48;
    buttonWidth = buttonWidth > IPAD_CONTENT_MAX_WIDTH ? IPAD_CONTENT_MAX_WIDTH : buttonWidth;
    
    self.signInButton.frame = CGRectMake(self.view.frame.size.width / 2 - buttonWidth / 2, self.view.frame.size.height - UIApplication.sharedApplication.keyWindow.safeAreaInsets.bottom - 64, buttonWidth, 64);
    self.signInButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:@"Already have an account? Sign In" attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:14.f weight:UIFontWeightRegular], NSForegroundColorAttributeName: [UIColor bonfireSecondaryColor]}];
    [attributedString addAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:14.f weight:UIFontWeightSemibold]} range:[attributedString.string rangeOfString:@"Sign In"]];
    [self.signInButton setAttributedTitle:attributedString forState:UIControlStateNormal];
    
    [self.signInButton bk_whenTapped:^{
        OnboardingViewController *obvc = [[OnboardingViewController alloc] init];
        obvc.transitioningDelegate = [Launcher sharedInstance];
        obvc.modalPresentationStyle = UIModalPresentationFullScreen;
        obvc.signInLikely = true;
        
        [self presentViewController:obvc animated:YES completion:nil];
    }];
    
    [self.view addSubview:self.signInButton];
    
    self.signUpButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.signUpButton.frame = CGRectMake(self.view.frame.size.width / 2 - buttonWidth / 2, self.signInButton.frame.origin.y - 48, buttonWidth, 48);
    self.signUpButton.layer.masksToBounds = true;
    self.signUpButton.layer.cornerRadius = 14.f;
    self.signUpButton.backgroundColor = [UIColor bonfireBrand];
    [self.signUpButton setTitle:@"Sign Up" forState:UIControlStateNormal];
    [self.signUpButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.signUpButton.titleLabel.font = [UIFont systemFontOfSize:20.f weight:UIFontWeightSemibold];
    self.signUpButton.adjustsImageWhenHighlighted = false;
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
        OnboardingViewController *obvc = [[OnboardingViewController alloc] init];
        obvc.transitioningDelegate = [Launcher sharedInstance];
        obvc.modalPresentationStyle = UIModalPresentationFullScreen;
        obvc.signInLikely = false;
        
        [self presentViewController:obvc animated:YES completion:nil];
    }];
    
    UIImageView *signInButtonBg = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.signUpButton.frame.size.width, self.signUpButton.frame.size.width * 3)];
    signInButtonBg.image = [UIImage imageNamed:@"gradient"];
    signInButtonBg.contentMode = UIViewContentModeScaleToFill;
    CGPoint oldCenter = signInButtonBg.center;
    [UIView animateWithDuration:5.f
                          delay:0
                        options:(UIViewAnimationOptionRepeat|UIViewAnimationOptionAutoreverse)
                     animations: ^{ signInButtonBg.center = CGPointMake(oldCenter.x, -(signInButtonBg.frame.size.height / 2) + oldCenter.y); }
                     completion: ^(BOOL finished) { signInButtonBg.center = oldCenter; }];
    
    //[self.signInButton insertSubview:signInButtonBg atIndex:0];
    
    [self.view addSubview:self.signUpButton];
}

- (void)setupSplash {
    self.middleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    self.middleView.backgroundColor = [UIColor contentBackgroundColor];
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
    
    self.launchLogo = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"LaunchLogo"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    self.launchLogo.tintColor = [UIColor bonfireSecondaryColor];
    self.launchLogo.frame = CGRectMake(self.view.frame.size.width / 2 - 64, self.view.frame.size.height / 2 - 64, 128, 128);
    [self.middleViewContainer addSubview:self.launchLogo];
    
    self.middleViewImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, self.middleViewContainer.frame.size.height, self.middleViewContainer.frame.size.width, self.middleViewContainer.frame.size.height)];
    self.middleViewImage.image = [UIImage imageNamed:@"onboardingMiddleImage"];
    self.middleViewImage.contentMode = UIViewContentModeScaleAspectFill;
    self.middleViewImage.backgroundColor = [UIColor cardBackgroundColor];
    self.middleViewImage.layer.cornerRadius = self.middleViewContainer.layer.cornerRadius;
    self.middleViewImage.layer.masksToBounds = true;
    [self.middleViewContainer addSubview:self.middleViewImage];
    
    self.welcomeLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 114, self.view.frame.size.width - 24, 40)];
    self.welcomeLabel.textAlignment = NSTextAlignmentCenter;
    self.welcomeLabel.font = [UIFont systemFontOfSize:34.f weight:UIFontWeightMedium];
    self.welcomeLabel.textColor = [UIColor bonfirePrimaryColor];
    self.welcomeLabel.text = @"Hello";
    self.welcomeLabel.alpha = 0;
    [self.view addSubview:self.welcomeLabel];
    
    self.whereConversationsHappenLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 576, self.view.frame.size.width - 24, 44)];
    self.whereConversationsHappenLabel.textAlignment = NSTextAlignmentCenter;
    self.whereConversationsHappenLabel.font = [UIFont systemFontOfSize:18.f weight:UIFontWeightMedium];
    self.whereConversationsHappenLabel.textColor = [UIColor bonfirePrimaryColor];
    self.whereConversationsHappenLabel.text = @"Bonfire is where\nconversations happen";
    self.whereConversationsHappenLabel.alpha = 0;
    self.whereConversationsHappenLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.whereConversationsHappenLabel.numberOfLines = 2;
    if (!IS_IPHONE_5) {
        [self.view addSubview:self.whereConversationsHappenLabel];
    }
    
    CGFloat secondaryScreenshotCornerRadius = HAS_ROUNDED_CORNERS?10.f:6.f;
    
    self.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 106, 200)];
    self.leftView.backgroundColor = [UIColor cardBackgroundColor];
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
    self.rightView.backgroundColor = [UIColor cardBackgroundColor];
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
                             CGPointMake([self.signUpButton center].x - 8.f, [self.signUpButton center].y)]];
    [animation setToValue:[NSValue valueWithCGPoint:
                           CGPointMake([self.signUpButton center].x + 8.f, [self.signUpButton center].y)]];
    [[self.signUpButton layer] addAnimation:animation forKey:@"position"];
}

- (void)continuityRadiusForView:(UIView *)sender withRadius:(CGFloat)radius {
    CAShapeLayer * maskLayer = [CAShapeLayer layer];
    maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:sender.bounds
                                           byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight|UIRectCornerTopLeft|UIRectCornerTopRight
                                                 cornerRadii:CGSizeMake(radius, radius)].CGPath;
    
    sender.layer.mask = maskLayer;
}

@end
