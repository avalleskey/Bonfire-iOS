//
//  SimpleNavigationController.m
//  Pulse
//
//  Created by Austin Valleskey on 11/29/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "SimpleNavigationController.h"
#import "Session.h"
#import "Launcher.h"
#import "UIColor+Palette.h"
#import "UINavigationItem+Margin.h"
#import "ProfileViewController.h"
#import "CampViewController.h"
#import "PostViewController.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>

@interface SimpleNavigationController ()

@end

@implementation SimpleNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupNavigationBar];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userUpdated:) name:@"UserUpdated" object:nil];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if ([self isBeingPresented] || [self isMovingToParentViewController]) {
        if (self.currentTheme == nil) {
            self.currentTheme = [UIColor clearColor];
        }
        
        // Perform an action that will only be done once
        if (self.view.tag == VIEW_CONTROLLER_PUSH_TAG) {
            self.swiper = [[SloppySwiper alloc] initWithNavigationController:self];
            self.swiper.delegate = self;
            self.delegate = self.swiper;
        }
    }
}

- (void)userUpdated:(NSNotification *)notification {
    if ([self.navigationBar isTranslucent]) {
        //UIColor *actionColor = [UIColor fromHex:[Session sharedInstance].currentUser.attributes.details.color];
        //self.navigationBar.tintColor = actionColor;
//        self.navigationItem.leftBarButtonItem.customView.tintColor = actionColor;
//        self.navigationItem.rightBarButtonItem.customView.tintColor = actionColor;
//        self.leftActionButton.tintColor = actionColor;
//        self.rightActionButton.tintColor = actionColor;
    }
}

- (void)setCurrentTheme:(UIColor *)currentTheme {
    if (currentTheme != _currentTheme) {
        _currentTheme = currentTheme;
        
        [self updateBarColor:currentTheme animated:YES];
    }
}

- (void)setupNavigationBar {
    self.navigationItem.leftMargin = 12;
    self.navigationItem.rightMargin = 12;
//    // setup items
    [self.navigationBar setTitleTextAttributes:
     @{NSForegroundColorAttributeName:[UIColor blackColor],
       NSFontAttributeName:[UIFont systemFontOfSize:18.f weight:UIFontWeightBold]}];
    
//    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.navigationBar.frame.size.width - (72 * 2), self.navigationBar.frame.size.height)];
//    self.titleLabel.textColor = [UIColor bonfirePrimaryColor];
//    self.titleLabel.font = [UIFont systemFontOfSize:20.f weight:UIFontWeightBold];
//    self.titleLabel.textAlignment = NSTextAlignmentLeft;
//    [self.navigationItem setTitleView:self.titleLabel];
    
    self.navigationBar.barStyle = UIBarStyleDefault;
    self.navigationBar.shadowImage = [self imageWithColor:[UIColor clearColor]];
    
    self.bottomHairline = [[UIView alloc] initWithFrame:CGRectMake(0, self.navigationBar.frame.size.height, self.view.frame.size.width, (1 / [UIScreen mainScreen].scale))];
    self.bottomHairline.backgroundColor = [UIColor colorNamed:@"FullContrastColor"];
    self.bottomHairline.alpha = 0.12;
    [self.navigationBar addSubview:self.bottomHairline];
}

/*
- (void)setTitle:(NSString *)title {
    [super setTitle:title];
        
    self.titleLabel.text = title;
    [self.navigationItem setTitleView:self.titleLabel];
}*/

- (UIButton *)createActionButtonForType:(SNActionType)actionType {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    
    BOOL includeAction = false;
    
    if (actionType == SNActionTypeCancel) {
        includeAction = true;
        [button setTitle:@"Cancel" forState:UIControlStateNormal];
    }
    else if (actionType == SNActionTypeProfile) {
        includeAction = true;
        BFAvatarView *userAvatar = [[BFAvatarView alloc] initWithFrame:CGRectMake(12, self.navigationBar.frame.size.height / 2 - 16, 32, 32)];
        userAvatar.user = [[Session sharedInstance] currentUser];
        userAvatar.dimsViewOnTap = true;
        userAvatar.tag = 10;
        button.frame = userAvatar.frame;
        [button addSubview:userAvatar];
        
        [[NSNotificationCenter defaultCenter] addObserver:userAvatar selector:@selector(userUpdated:) name:@"UserUpdated" object:nil];
    }
    else if (actionType == SNActionTypeCompose) {
        includeAction = true;
        [button setImage:[[UIImage imageNamed:@"composeIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [button setImageEdgeInsets:UIEdgeInsetsMake(-2, 0, 0, -3)];
    }
    else if (actionType == SNActionTypeMore) {
        includeAction = true;
        [button setImage:[[UIImage imageNamed:@"navMoreIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    }
    else if (actionType == SNActionTypeInvite) {
        includeAction = true;
        [button setImage:[[UIImage imageNamed:@"inviteFriendIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    }
    else if (actionType == SNActionTypeAdd || actionType == SNActionTypeCreateCamp) {
        includeAction = true;
        [button setImage:[[UIImage imageNamed:@"navPlusIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    }
    else if (actionType == SNActionTypeShare) {
        [button setTitle:@"Post" forState:UIControlStateNormal];
    }
    else if (actionType == SNActionTypeDone) {
        includeAction = true;
        [button setTitle:@"Done" forState:UIControlStateNormal];
    }
    else if (actionType == SNActionTypeSettings) {
        includeAction = true;
        [button setImage:[[UIImage imageNamed:@"navSettingsIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    }
    else if (actionType == SNActionTypeSearch) {
        includeAction = true;
        [button setImage:[[UIImage imageNamed:@"navSearchIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    }
    else if (actionType == SNActionTypeBack) {
        includeAction = true;
        [button setImage:[[UIImage imageNamed:@"leftArrowIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    }
    else if (actionType == SNActionTypeCamptag) {
        [button setImage:[[UIImage imageNamed:@"navCamptagIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    }
    
    if (actionType == SNActionTypeShare || actionType == SNActionTypeDone) {
        [button.titleLabel setFont:[UIFont systemFontOfSize:18.f weight:UIFontWeightBold]];
    }
    else {
        [button.titleLabel setFont:[UIFont systemFontOfSize:18.f weight:UIFontWeightMedium]];
    }
    
    CGFloat padding = 16;
    button.frame = CGRectMake(0, 0, button.intrinsicContentSize.width + (padding * 2), self.navigationBar.frame.size.height);
    
    if (includeAction) {
        [button bk_whenTapped:^{
            switch (actionType) {
                case SNActionTypeCancel:
                    [self dismissViewControllerAnimated:YES completion:nil];
                    break;
                case SNActionTypeProfile:
                    [Launcher openProfile:[[Session sharedInstance] currentUser]];
                    break;
                case SNActionTypeDone:
                    [self dismissViewControllerAnimated:YES completion:nil];
                    break;
                case SNActionTypeCompose:
                    [Launcher openComposePost:nil inReplyTo:nil withMessage:nil media:nil];
                    break;
                case SNActionTypeMore: {
                    if ([self.viewControllers[self.viewControllers.count-1] isKindOfClass:[CampViewController class]]) {
                        CampViewController *activeCamp = self.viewControllers[self.viewControllers.count-1];
                        [activeCamp openCampActions];
                    }
                    else if ([self.viewControllers[self.viewControllers.count-1] isKindOfClass:[ProfileViewController class]]) {
                        ProfileViewController *activeProfile = self.viewControllers[self.viewControllers.count-1];
                        [activeProfile openProfileActions];
                    }
                    else if ([self.viewControllers[self.viewControllers.count-1] isKindOfClass:[PostViewController class]]) {
                        PostViewController *activePost = self.viewControllers[self.viewControllers.count-1];
                        [Launcher openActionsForPost:activePost.post];
                    }
                    break;
                }
                case SNActionTypeInvite:
                    [Launcher openInviteFriends:self];
                    break;
                case SNActionTypeAdd:
                    
                    break;
                case SNActionTypeCreateCamp:
                    [Launcher openCreateCamp];
                    break;
                case SNActionTypeBack: {
                    if (self.viewControllers.count == 1) {
                        // VC is the top most view controller
                        [self.view endEditing:YES];
                        
                        [self dismissViewControllerAnimated:YES completion:nil];
                    }
                    else {
                        [self popViewControllerAnimated:YES];
                    }
                    break;
                }
                case SNActionTypeSettings:
                    [Launcher openSettings];
                    break;
                case SNActionTypeSearch:
                    [Launcher openSearch];
                    break;
                    
                default:
                    break;
            }
        }];
    }
    
    if (SNActionTypeBack) {
        UILongPressGestureRecognizer *longPressToGoHome = [[UILongPressGestureRecognizer alloc] bk_initWithHandler:^(UIGestureRecognizer *sender, UIGestureRecognizerState state, CGPoint location) {
            switch (actionType) {
                case SNActionTypeBack: {
                    if (state == UIGestureRecognizerStateBegan) {
                        [self setEditing:false];
                        
                        [self dismissViewControllerAnimated:YES completion:nil];
                    }
                    break;
                }
                    
                default:
                    break;
            }
        }];
        [button addGestureRecognizer:longPressToGoHome];
    }
    
    return button;
}
- (void)setLeftAction:(SNActionType)actionType {
    if (actionType == SNActionTypeNone) {
        self.leftActionView = [UIButton new];
        self.navigationItem.leftBarButtonItem = nil;
    }
    else {
        self.leftActionView = [self createActionButtonForType:actionType];
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:self.leftActionView];
        self.visibleViewController.navigationItem.leftBarButtonItem = item;
        self.visibleViewController.navigationItem.leftMargin = 0;
        
        self.leftActionView.tag = actionType;
    }
}
- (void)setRightAction:(SNActionType)actionType {
    if ((NSInteger)actionType != self.rightActionView.tag) {
        [self.rightActionView removeFromSuperview];
        if (actionType == SNActionTypeNone) {
            self.rightActionView = [UIButton new];
            self.navigationItem.rightBarButtonItem = nil;
        }
        else {
            self.rightActionView = [self createActionButtonForType:actionType];
            UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:self.rightActionView];
            self.visibleViewController.navigationItem.rightBarButtonItem = item;
            self.visibleViewController.navigationItem.rightMargin = 0;
            
            self.rightActionView.tag = actionType;
        }
    }
}

// theming
- (void)setShadowVisibility:(BOOL)visible withAnimation:(BOOL)animated {
    [UIView animateWithDuration:animated?(visible?0.2f:0.4f):0 animations:^{
        if (visible) [self showBottomHairline];
        else [self hideBottomHairline];
    }];
}
- (void)hideBottomHairline {
    if (self.bottomHairline.alpha == 0.12) {
        [self.bottomHairline.layer removeAllAnimations];
    }
    self.bottomHairline.alpha = 0;
}
- (void)showBottomHairline {
    // Show 1px hairline of translucent nav bar
    if (self.bottomHairline.alpha != 0.12) {
        [self.bottomHairline.layer removeAllAnimations];
    }
    self.bottomHairline.alpha = 0.12;
}

- (void)makeTransparent {
    self.navigationBar.translucent = true;
    self.navigationBar.backgroundColor = [UIColor clearColor];
    [self setShadowVisibility:true withAnimation:false];
}
- (void)makeDefault {
    self.navigationBar.translucent = false;
    self.navigationBar.backgroundColor = nil;
    [self setShadowVisibility:false withAnimation:false];
}
- (UIImage *)imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 0.5);
    const CGFloat alpha = CGColorGetAlpha(color.CGColor);
    const BOOL opaque = alpha == 1;
    UIGraphicsBeginImageContextWithOptions(rect.size, opaque, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (void)updateBarColor:(id)background animated:(BOOL)animated {
    if ([background isKindOfClass:[NSString class]]) {
        background = [UIColor fromHex:background adjustForDarkMode:false];
    }

    UIColor *foreground;
    UIColor *action;
    if (background == nil || background == [UIColor clearColor]) {
        foreground = [UIColor bonfirePrimaryColor];
        action = [UIColor bonfirePrimaryColor]; //[UIColor fromHex:[Session sharedInstance].currentUser.attributes.details.color];
        background = [UIColor colorNamed:@"Navigation_ClearBackgroundColor"];
        [self makeTransparent];
    }
    else {
        if ([UIColor useWhiteForegroundForColor:background]) {
            action =
            foreground = [UIColor whiteColor];
        }
        else {
            action =
            foreground = [UIColor bonfirePrimaryColor];
        }
        [self makeDefault];
    }
    
    [self.navigationBar setTitleTextAttributes:
    @{NSForegroundColorAttributeName:foreground,
      NSFontAttributeName:[UIFont systemFontOfSize:18.f weight:UIFontWeightBold]}];
    
    [UIView animateWithDuration:animated?0.5f:0 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.navigationBar.barTintColor = background;
        self.navigationBar.tintColor = action;
        self.leftActionView.tintColor = action;
        self.rightActionView.tintColor = action;
        self.navigationItem.leftBarButtonItem.customView.tintColor = action;
        self.navigationItem.rightBarButtonItem.customView.tintColor = action;
        [self.navigationBar layoutIfNeeded];
        [self setNeedsStatusBarAppearanceUpdate];
    } completion:nil];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    if ([UIColor useWhiteForegroundForColor:self.navigationBar.barTintColor]) {
        return UIStatusBarStyleLightContent;
    }
    else {
        return UIStatusBarStyleDefault;
        
        /*
        if (@available(iOS 13.0, *)) {
            return UIStatusBarStyleDarkContent;
        } else {
            // Fallback on earlier versions
            return UIStatusBarStyleDefault;
        }*/
    }
}

@end
