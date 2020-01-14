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

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController {
    if (self = [super initWithRootViewController:rootViewController]) {
        [self initDefaults];
        
        if ([rootViewController isKindOfClass:[ProfileViewController class]] ||
            [rootViewController isKindOfClass:[CampViewController class]]) {
            self.transparentOnLoad = true;
            self.opaqueOnScroll = false;
        }
        if ([rootViewController isKindOfClass:[PostViewController class]]) {
            self.opaqueOnScroll = true;
        }
    }
    
    return self;
}

- (void)initDefaults {
    self.onScrollLowerBound = 12;
    self.transparentOnLoad = false;
    self.opaqueOnScroll = true;
    self.shadowOnScroll = true;
    self.foregroundBeforeScroll = nil;;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupNavigationBar];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if ([self isBeingPresented] || [self isMovingToParentViewController]) {
        // Perform an action that will only be done once
        if (self.view.tag == VIEW_CONTROLLER_PUSH_TAG) {
            self.swiper = [[SloppySwiper alloc] initWithNavigationController:self];
            self.swiper.delegate = self;
            self.delegate = self.swiper;
        }
    }
}

- (void)setCurrentTheme:(UIColor *)currentTheme {
    if (currentTheme != _currentTheme) {
        _currentTheme = currentTheme;
        
        [self updateBarColor:currentTheme animated:YES];
    }
}

- (void)setupNavigationBar {
    self.navigationItem.leftMargin = 0;
    self.navigationItem.rightMargin = 0;
    
    // setup items
    [self.navigationBar setTitleTextAttributes:
     @{NSForegroundColorAttributeName:[UIColor blackColor],
       NSFontAttributeName:[UIFont systemFontOfSize:18.f weight:UIFontWeightBold]}];
    
    // remove hairline
    [self.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    [self.navigationBar setShadowImage:[UIImage new]];
    
    // set background color
    [self.navigationBar setTranslucent:true];
    [self.navigationBar setBarTintColor:[UIColor clearColor]];
    
    // add background color view
    self.navigationBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, [[[UIApplication sharedApplication] delegate] window].safeAreaInsets.top + self.navigationBar.frame.size.height)];
    self.navigationBackgroundView.backgroundColor = [UIColor contentBackgroundColor];
    self.navigationBackgroundView.layer.masksToBounds = false;
    self.navigationBackgroundView.layer.shadowRadius = 2;
    self.navigationBackgroundView.layer.shadowOffset = CGSizeMake(0, 1);
    self.navigationBackgroundView.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.12].CGColor;
    self.navigationBackgroundView.layer.shadowOpacity = 0;
    [self.view insertSubview:self.navigationBackgroundView belowSubview:self.navigationBar];
    
    UIView *containerView = [[UIView alloc] initWithFrame:self.navigationBackgroundView.bounds];
    containerView.clipsToBounds = true;
    [self.navigationBackgroundView addSubview:containerView];
    
    self.bottomHairline = [[UIView alloc] initWithFrame:CGRectMake(0, self.navigationBar.frame.size.height, self.view.frame.size.width, (1 / [UIScreen mainScreen].scale))];
    self.bottomHairline.backgroundColor = [UIColor colorNamed:@"FullContrastColor"];
    self.bottomHairline.alpha = 0.12;
    [self.navigationBar addSubview:self.bottomHairline];
    
    // add progress view inside of the saerch view
    self.progressView = [UIView new];
    self.progressView.frame = CGRectMake(0, self.navigationBar.frame.size.height - 2, 0, 2);
    [self.navigationBar addSubview:self.progressView];
    
    if (self.currentTheme == nil) {
        self.currentTheme = [UIColor clearColor];
    }
}

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
//        [button setTitle:@"Post" forState:UIControlStateNormal];
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
    else if (actionType == SNActionTypeSidebar) {
        [button setImage:[[UIImage imageNamed:@"navSidebarIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    }
    
    if (actionType == SNActionTypeShare || actionType == SNActionTypeDone) {
        [button.titleLabel setFont:[UIFont systemFontOfSize:18.f weight:UIFontWeightBold]];
    }
    else {
        [button.titleLabel setFont:[UIFont systemFontOfSize:18.f weight:UIFontWeightMedium]];
    }
    
    button.frame = CGRectMake(0, 0, button.intrinsicContentSize.width + 32, self.navigationBar.frame.size.height);
    
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
                    [Launcher openComposePost:nil inReplyTo:nil withMessage:nil media:nil quotedObject:nil];
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
        self.navigationItem.leftMargin = 0;
        
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
            self.navigationItem.rightMargin = 0;
            
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

- (void)updateBarColor:(id _Nullable)background animated:(BOOL)animated {
    if ([background isKindOfClass:[NSString class]]) {
        background = [UIColor fromHex:background adjustForOptimalContrast:false];
    }

    UIColor *foreground;
    UIColor *action;
    UIColor *progressBar;
    
    if (background == [UIColor clearColor]) {
        [self setShadowVisibility:true withAnimation:false];
                
        foreground = [UIColor bonfirePrimaryColor];
        action = [UIColor bonfirePrimaryColor]; //[UIColor fromHex:[Session sharedInstance].currentUser.attributes.color];
        background = [UIColor colorNamed:@"Navigation_ClearBackgroundColor"];
        progressBar = [[UIColor bonfirePrimaryColor] colorWithAlphaComponent:0.1];
    }
    else {
        [self setShadowVisibility:false withAnimation:false];
        
        BOOL useLightForeground = [UIColor useWhiteForegroundForColor:background];
        if (background == nil || background == [UIColor whiteColor]) {
            background = [UIColor contentBackgroundColor];
            action = [UIColor bonfirePrimaryColor]; //[UIColor fromHex:[UIColor toHex:self.view.tintColor] adjustForOptimalContrast:true];
            foreground = [UIColor bonfirePrimaryColor];
        }
        else if (useLightForeground) {
            action =
            foreground = [UIColor whiteColor];
        }
        else {
            action =
            foreground = [UIColor blackColor];
        }
        
        progressBar = [action colorWithAlphaComponent:0.5];
    }
    
    [UIView animateWithDuration:animated?0.5f:0 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        [self.navigationBar setTitleTextAttributes:
        @{NSForegroundColorAttributeName:foreground,
          NSFontAttributeName:[UIFont systemFontOfSize:18.f weight:UIFontWeightBold]}];
        self.navigationBackgroundView.backgroundColor = background;
        self.navigationBar.tintColor = action;
        self.leftActionView.tintColor = action;
        self.rightActionView.tintColor = action;
        self.navigationItem.leftBarButtonItem.tintColor = action;
        self.navigationItem.rightBarButtonItem.tintColor = action;
        self.visibleViewController.navigationItem.leftBarButtonItem.tintColor = action;
        self.visibleViewController.navigationItem.rightBarButtonItem.tintColor = action;
        self.navigationItem.leftBarButtonItem.customView.tintColor = action;
        self.navigationItem.rightBarButtonItem.customView.tintColor = action;
//        [self.navigationBar layoutIfNeeded];
        [self setNeedsStatusBarAppearanceUpdate];
        
        self.progressView.backgroundColor = progressBar;
    } completion:^(BOOL finished) {
        [self setNeedsStatusBarAppearanceUpdate];
    }];
}

- (void)setProgress:(CGFloat)progress {
    [self setProgress:progress animated:false hideOnCompletion:false];
}
- (void)setProgress:(CGFloat)progress animated:(BOOL)animated {
    [self setProgress:progress animated:animated hideOnCompletion:false];
}
- (void)setProgress:(CGFloat)progress animated:(BOOL)animated hideOnCompletion:(BOOL)hideOnCompletion {
    if (progress != _progress) {
        // show progress view if needed
        if (progress > 0) {
            [UIView animateWithDuration:(self.progressView.frame.size.width > 0 ? 0.25f : 0) delay:0.1f options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.progressView.alpha = 1;
            } completion:nil];
        }
        
        CGFloat progressDiff = (_progress - progress);
        
        _progress = progress;
        
        CGFloat duration = (animated ? 0.15f + (fabs(progressDiff) * 0.5f) : 0);
        [UIView animateWithDuration:duration delay:0 options:(UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionBeginFromCurrentState) animations:^{
            self.progressView.frame = CGRectMake(self.progressView.frame.origin.x, self.progressView.frame.origin.y, roundf(self.progressView.superview.frame.size.width * progress), self.progressView.frame.size.height);
        } completion:^(BOOL finished) {
            if (hideOnCompletion) {
                [UIView animateWithDuration:0.25f delay:0.1f options:UIViewAnimationOptionCurveEaseOut animations:^{
                    self.progressView.alpha = 0;
                } completion:^(BOOL finished) {
                    [self setProgress:0];
                }];
            }
        }];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    if ([UIColor useWhiteForegroundForColor:self.navigationBackgroundView.backgroundColor]) {
        return UIStatusBarStyleLightContent;
    }
    else {
        if (@available(iOS 13.0, *)) {
            return UIStatusBarStyleDarkContent;
        } else {
            // Fallback on earlier versions
            return UIStatusBarStyleDefault;
        }
    }
}

- (void)childTableViewDidScroll:(UITableView *)tableView {        
    CGFloat y = tableView.contentOffset.y + tableView.adjustedContentInset.top;
    
    CGFloat a = 0;
    CGFloat b = self.onScrollLowerBound;
        
    CGFloat p = b < a ? 1 : (y - a) / (b - a);
    if (p > 1) p = 1;
    if (p < 0) p = 0;
    
    if (self.shadowOnScroll) {
        self.navigationBackgroundView.layer.shadowOpacity = p * 0.8;
    }
    
    if (!self.opaqueOnScroll) {
        self.navigationBackgroundView.alpha = p;
    }
    else if (self.navigationBackgroundView.alpha != 1) {
        self.navigationBackgroundView.alpha = 1;
    }
}

@end
