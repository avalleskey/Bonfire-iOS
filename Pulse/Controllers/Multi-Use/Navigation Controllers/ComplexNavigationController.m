//
//  LauncherNavigationViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 9/27/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "ComplexNavigationController.h"
#import "HAWebService.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import <HapticHelper/HapticHelper.h>
#import "SearchResultCell.h"
#import "CreateCampViewController.h"
#import "NSArray+Clean.h"
#import "Launcher.h"

// Views it can open
#import "CampViewController.h"
#import "CampMembersViewController.h"
#import "ProfileViewController.h"
#import "PostViewController.h"
#import "SearchTableViewController.h"
#import "OnboardingViewController.h"
#import "EditProfileViewController.h"
#import "CampStoreTableViewController.h"
#import "HomeTableViewController.h"
#import <UIImageView+WebCache.h>
#import "UIColor+Palette.h"
#import "UINavigationItem+Margin.h"
#import "ProfileCampsListViewController.h"
#import "BFAlertController.h"
#import "ProfileFollowingListViewController.h"

#define barColorUpdateDuration 0.6

@interface ComplexNavigationController ()

@end

@implementation ComplexNavigationController

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController {
    if (self = [super initWithRootViewController:rootViewController]) {
        [self initDefaultsWithRootViewController:rootViewController];
    }
    
    return self;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    // support dark mode
    [self updateBarColor:self.navigationBackgroundView.backgroundColor animated:NO];
}

- (void)initDefaultsWithRootViewController:(UIViewController *)rootViewController {
    self.onScrollLowerBound = 12;
    self.transparentOnLoad = false;
    self.opaqueOnScroll = true;
    self.shadowOnScroll = false;
    
    if ([rootViewController isKindOfClass:[ProfileViewController class]] ||
        [rootViewController isKindOfClass:[CampViewController class]]) {
        self.transparentOnLoad = true;
        self.opaqueOnScroll = false;
        self.shadowOnScroll = true;
    }
    else if ([rootViewController isKindOfClass:[PostViewController class]]) {
        self.opaqueOnScroll = false;
        self.shadowOnScroll = true;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.swiper = [[SloppySwiper alloc] initWithNavigationController:self];
    self.swiper.delegate = self;
    self.delegate = self.swiper;
    
    self.view.backgroundColor = [UIColor tableViewBackgroundColor];
    
    // remove hairline
    [self.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    [self.navigationBar setShadowImage:[UIImage new]];
    
    // set background color
    [self.navigationBar setTranslucent:true];
    [self.navigationBar setBarTintColor:[UIColor clearColor]];
    self.navigationItem.titleView = nil;
    self.navigationItem.title = nil;
    self.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName:[UIColor clearColor]};
    
    // add background color view
    self.navigationBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, [[[UIApplication sharedApplication] delegate] window].safeAreaInsets.top + self.navigationBar.frame.size.height)];
    self.navigationBackgroundView.backgroundColor = [UIColor tableViewBackgroundColor];
    self.navigationBackgroundView.layer.masksToBounds = false;
    self.navigationBackgroundView.layer.shadowRadius = 2;
    self.navigationBackgroundView.layer.shadowOffset = CGSizeMake(0, 1);
    self.navigationBackgroundView.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.12].CGColor;
    self.navigationBackgroundView.layer.shadowOpacity = 0;
    [self.view insertSubview:self.navigationBackgroundView belowSubview:self.navigationBar];
    
    self.bottomHairline = [[UIView alloc] initWithFrame:CGRectMake(0, self.navigationBar.frame.size.height, self.view.frame.size.width, (1 / [UIScreen mainScreen].scale))];
    self.bottomHairline.backgroundColor = [UIColor tableViewSeparatorColor];
    [self.navigationBar addSubview:self.bottomHairline];
    
    [self setupNavigationBarItems];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    for (UIViewController *viewController in self.viewControllers) {
        [[NSNotificationCenter defaultCenter] removeObserver:viewController];
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

- (UIViewController*)childViewControllerForStatusBarStyle {
    if (self.presentedViewController) {
        return self.presentedViewController.childViewControllerForStatusBarStyle;
    }
    
    return [super childViewControllerForStatusBarStyle];
}

- (void)didFinishSwiping {
    [self goBack];
}

- (void)goBack {
    UIColor *nextTheme = [UIColor whiteColor];
    
    if ([self.viewControllers lastObject].navigationController.tabBarController != nil) {
        [self.searchView updateSearchText:@""];
        nextTheme = [UIColor whiteColor];
    }
    else {
        UIViewController *previousVC = [self.viewControllers lastObject];
        
        BOOL showSearchIcon = true;
        [self.searchView updateSearchText:previousVC.title];
        
        if ([[self.viewControllers lastObject] isKindOfClass:[CampViewController class]]) {
            CampViewController *previousCamp = [self.viewControllers lastObject];
            nextTheme = previousCamp.theme;
        }
        else if ([[self.viewControllers lastObject] isKindOfClass:[ProfileViewController class]]) {
            ProfileViewController *previousProfile = [self.viewControllers lastObject];
            nextTheme = previousProfile.theme;
        }
        else if ([[self.viewControllers lastObject] isKindOfClass:[PostViewController class]]) {
            PostViewController *previousPost = [self.viewControllers lastObject];
            showSearchIcon = false;

            nextTheme = previousPost.theme;
        }
        else if ([[self.viewControllers lastObject] isKindOfClass:[CampMembersViewController class]]) {
            CampMembersViewController *previousMembersView = [self.viewControllers lastObject];
            showSearchIcon = false;
            nextTheme = previousMembersView.theme;
        }
        else if ([[self.viewControllers lastObject] isKindOfClass:[ProfileCampsListViewController class]]) {
            ProfileCampsListViewController *previousProfileCampsListView = [self.viewControllers lastObject];
            showSearchIcon = false;
            nextTheme = previousProfileCampsListView.theme;
        }
        else if ([[self.viewControllers lastObject] isKindOfClass:[ProfileFollowingListViewController class]]) {
            ProfileFollowingListViewController *previousProfileFollowingListView = [self.viewControllers lastObject];
            showSearchIcon = false;
            nextTheme = previousProfileFollowingListView.theme;
        }
        
        if (showSearchIcon) {
            [self.searchView updateSearchText:previousVC.title];
        }
        else {
            self.searchView.textField.text = previousVC.title;
            [self.searchView hideSearchIcon:false];
        }
    }
    [self updateBarColor:nextTheme animated:false];
        
    [self updateNavigationBarItemsWithAnimation:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)setShadowVisibility:(BOOL)visible withAnimation:(BOOL)animated {
    [UIView animateWithDuration:animated?(visible?0.2f:0.4f):0 animations:^{
        if (visible) [self showBottomHairline];
        else [self hideBottomHairline];
    }];
}
- (void)hideBottomHairline {
    if (self.bottomHairline.alpha == 1) {
        [self.bottomHairline.layer removeAllAnimations];
    }
    self.bottomHairline.alpha = 0;
}
- (void)showBottomHairline {
    // Show 1px hairline of translucent nav bar
    if (self.bottomHairline.alpha != 1) {
        [self.bottomHairline.layer removeAllAnimations];
    }
    self.bottomHairline.alpha = 1;
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

/*
- (void)updateBarColor:(id)newColor withAnimation:(int)animationType statusBarUpdateDelay:(CGFloat)statusBarUpdateDelay {
    if ([newColor isKindOfClass:[NSString class]]) {
        newColor = [UIColor fromHex:newColor];
    }
    self.currentTheme = newColor;
    
    CGFloat diameter = self.navigationBackgroundView.frame.size.width * 1.2;
    CGFloat beforeDiameter = 0.02 * diameter;
    
    UIView *newColorView = [[UIView alloc] init];
    if (animationType == 0 || animationType == 1) {
        // fade
        newColorView.frame = CGRectMake(0, 0, self.navigationBackgroundView.frame.size.width, self.navigationBackgroundView.frame.size.height);;
        newColorView.layer.cornerRadius = 0;
        newColorView.alpha = animationType == 0 ? 1 : 0;
        newColorView.backgroundColor = newColor;
    }
    else {
        // bubble burst
        newColorView.frame = CGRectMake(self.navigationBackgroundView.frame.size.width / 2 - (diameter / 2), self.navigationBackgroundView.frame.size.height + 40, diameter, diameter);
        newColorView.center = CGPointMake(self.navigationBackgroundView.frame.size.width / 2, self.navigationBackgroundView.frame.size.height + (beforeDiameter / 2));
        newColorView.layer.cornerRadius = newColorView.frame.size.width / 2;
        
        if (animationType == 2) {
            newColorView.backgroundColor = newColor;
            newColorView.transform = CGAffineTransformMakeScale(0.02, 0.02);
        }
        else if (animationType == 3) {
            newColorView.backgroundColor = self.navigationBackgroundView.backgroundColor;
            newColorView.transform = CGAffineTransformMakeScale(1, 1);
            self.navigationBackgroundView.backgroundColor = newColor;
        }
    }
    newColorView.layer.masksToBounds = true;
    newColorView.layer.shouldRasterize = true;
    newColorView.layer.rasterizationScale = [UIScreen mainScreen].scale;
    [self.navigationBackgroundView addSubview:newColorView];
    
    [UIView animateWithDuration:(animationType == 0 ? 0 : barColorUpdateDuration) delay:0 usingSpringWithDamping:0.75f initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
        // foreground items
        if (animationType == 1) {
            // fade
            newColorView.alpha = 1;
        }
        else if (animationType == 2) {
            // bubble burst
            // newColorView.center = CGPointMake(self.navigationBackgroundView.frame.size.width / 2, self.navigationBackgroundView.frame.size.height / 2);
            newColorView.transform = CGAffineTransformMakeScale(1, 1);
        }
        else if (animationType == 3) {
            // bubble roll back da burst
            // newColorView.center = CGPointMake(self.navigationBackgroundView.frame.size.width / 2, self.navigationBackgroundView.frame.size.height + (beforeDiameter / 2));
            newColorView.transform = CGAffineTransformMakeScale(0.02, 0.02);
        }
        
        UIImageView *searchIcon = self.searchView.searchIcon;
        
        if ([UIColor useWhiteForegroundForColor:newColor]) {
            self.searchView.textField.textColor = [UIColor whiteColor];
            self.searchView.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.searchView.textField.placeholder attributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:1 alpha:0.75]}];
            
            self.searchView.textField.tintColor =
            self.leftActionButton.tintColor =
            self.rightActionButton.tintColor = [UIColor whiteColor];
            
            searchIcon.alpha = 0.75;
        }
        else if ([newColor isEqual:[UIColor whiteColor]]) {
            // searchViewBackgroundColor = [UIColor bonfireTextFieldBackgroundOnWhite];
            self.searchView.textField.textColor = [UIColor colorWithWhite:0.07f alpha:1];
            self.searchView.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.searchView.textField.placeholder attributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:0 alpha:0.25]}];
            
            UIColor *tintColor = [UIColor bonfirePrimaryColor];
            self.searchView.textField.tintColor =
            self.leftActionButton.tintColor =
            self.rightActionButton.tintColor = tintColor;
            
            searchIcon.alpha = 0.25f;
        }
        else {
            self.searchView.textField.textColor = [UIColor colorWithWhite:0.07f alpha:1];
            self.searchView.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.searchView.textField.placeholder attributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:0 alpha:0.25]}];
            
            self.shadowView.alpha = 0;
            
            self.searchView.textField.tintColor =
            self.leftActionButton.tintColor =
            self.rightActionButton.tintColor = [UIColor colorWithWhite:0.07f alpha:1];
            
            searchIcon.alpha = 0.25f;
        }
        
        if (self.searchView.searchIcon.isHidden) {
            self.searchView.backgroundColor = [UIColor clearColor];
        }
        else {
            if ([UIColor useWhiteForegroundForColor:self.currentTheme]) {
                self.searchView.theme = BFTextFieldThemeLight;
            }
            else if ([self.currentTheme isEqual:[UIColor whiteColor]] ||
                     [self.topViewController isKindOfClass:[DiscoverViewController class]]) {
                self.searchView.theme = BFTextFieldThemeDark;
            }
            else {
                self.searchView.theme = BFTextFieldThemeExtraDark;
            }
        }
        
        [self setNeedsStatusBarAppearanceUpdate];
        
        searchIcon.tintColor = self.searchView.textField.textColor;
    } completion:^(BOOL finished) {
        if (self.currentTheme == newColor && animationType != 3) {
            self.navigationBackgroundView.backgroundColor = newColor;
        }
        
        if (self.currentTheme != newColor) {
            // fade it out
            [UIView animateWit  hDuration:0.25f animations:^{
                newColorView.alpha = 0;
            } completion:^(BOOL finished) {
                [newColorView removeFromSuperview];
            }];
        }
        else {
            [newColorView removeFromSuperview];
        }
    }];
}*/

- (void)updateBarColor:(id)background animated:(BOOL)animated {    
    if ([background isKindOfClass:[NSString class]]) {
        background = [UIColor fromHex:background adjustForOptimalContrast:false];
    }
    self.currentTheme = background;
    
    UIColor *foreground;
    UIColor *action;
    BOOL useLightForeground = [UIColor useWhiteForegroundForColor:background];
    if (background == [UIColor clearColor]) {
        [self setShadowVisibility:true withAnimation:false];
                
        foreground = [UIColor bonfirePrimaryColor];
        action = [UIColor bonfirePrimaryColor]; //[UIColor fromHex:[Session sharedInstance].currentUser.attributes.color];
        background = [UIColor colorNamed:@"Navigation_ClearBackgroundColor"];
        
        self.shadowOnScroll = false;
    }
    else {
        [self setShadowVisibility:false withAnimation:false];
        
        if (background == nil) {
            action = [UIColor fromHex:[UIColor toHex:self.view.tintColor] adjustForOptimalContrast:true];
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
    }
    
    UIImageView *searchIcon = self.searchView.searchIcon;
    
    self.searchView.textField.textColor = foreground;
    self.searchView.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.searchView.textField.placeholder attributes:@{NSForegroundColorAttributeName:[foreground colorWithAlphaComponent:0.5]}];
    
    self.searchView.textField.tintColor = foreground;
    self.leftActionButton.tintColor =
    self.rightActionButton.tintColor = action;
    
    searchIcon.alpha = 0.5f;
    
    if (self.searchView.searchIcon.isHidden) {
        self.searchView.backgroundColor = [UIColor clearColor];
    }
    else {
        if (useLightForeground) {
            self.searchView.theme = BFTextFieldThemeLight;
        }
        else {
            self.searchView.theme = BFTextFieldThemeDark;
        }
    }
    
    [UIView animateWithDuration:animated?0.4f:0 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.navigationBackgroundView.backgroundColor = background;
        self.navigationBar.tintColor = action;
        [self.navigationBar layoutIfNeeded];
        [self setNeedsStatusBarAppearanceUpdate];
        self.progressView.backgroundColor = [action colorWithAlphaComponent:0.5];
    } completion:nil];
}

- (void)setupNavigationBarItems {
    CGFloat searchViewWidth = self.view.frame.size.width - (56 * 2);
    searchViewWidth = searchViewWidth > IPAD_CONTENT_MAX_WIDTH ? IPAD_CONTENT_MAX_WIDTH : searchViewWidth;
    
    // create smart text field
    self.searchView = [[BFSearchView alloc] initWithFrame:CGRectMake(0, 0, searchViewWidth, 36)];
    self.searchView.textField.delegate = self;
    [self.searchView.textField bk_addEventHandler:^(id sender) {
        if ([self.topViewController isKindOfClass:[SearchTableViewController class]]) {
            SearchTableViewController *topSearchController = (SearchTableViewController *)self.topViewController;
            if ([self.topViewController isKindOfClass:[SearchTableViewController class]]) {
                [topSearchController searchFieldDidChange];
            }
        }
    } forControlEvents:UIControlEventEditingChanged];
    self.searchView.openSearchControllerOntap = true;
    self.searchView.center = CGPointMake(self.navigationBar.frame.size.width / 2, self.navigationBar.frame.size.height / 2);
    self.searchView.textField.userInteractionEnabled = false;
    
    // add progress view inside of the saerch view
    self.progressView = [UIView new];
    self.progressView.frame = CGRectMake(0, self.searchView.frame.size.height - 3, 0, 3);
    [self.searchView addSubview:self.progressView];
    
    [self.navigationBar addSubview:self.searchView];
    
    self.navigationItem.backBarButtonItem = nil;
    
    self.navigationController.interactivePopGestureRecognizer.delegate = self;
    self.navigationController.interactivePopGestureRecognizer.enabled = true;
}

- (void)updateNavigationBarItemsWithAnimation:(BOOL)animated {
    // determine items based on active view controller
    if ([self.topViewController isKindOfClass:[SearchTableViewController class]]) {
        [self setLeftAction:LNActionTypeNone];
    }
    else {
        [self setLeftAction:LNActionTypeBack];
    }
    
    if ([self.topViewController isKindOfClass:[CampViewController class]]) {
        CampViewController *campViewController = (CampViewController *)self.topViewController;
        
        if ([campViewController.camp.attributes.context.camp.membership.role.type isEqualToString:CAMP_ROLE_ADMIN]) {
            [self setRightAction:LNActionTypeDirector];
        }
        else if ([campViewController.camp.attributes.context.camp.membership.role.type isEqualToString:CAMP_ROLE_MODERATOR]) {
            [self setRightAction:LNActionTypeManager];
        }
        else {
            [self setRightAction:LNActionTypeShare];
        }
        
        if (campViewController.camp.identifier && campViewController.camp.identifier.length > 0) {
            // hide the more button
            self.rightActionButton.alpha = 1;
        }
        else {
            self.rightActionButton.alpha = 0;
        }
    }
    else if ([self.topViewController isKindOfClass:[PostViewController class]]) {
        [self setRightAction:LNActionTypeNone];
    }
    else if ([self.topViewController isKindOfClass:[CampMembersViewController class]]) {
        [self setRightAction:LNActionTypeNone];
    }
    else if ([self.topViewController isKindOfClass:[ProfileViewController class]]) {
        if ([((ProfileViewController *)self.topViewController).user isCurrentIdentity]) {
            [self setRightAction:LNActionTypeSettings];
        }
        else {
            [self setRightAction:LNActionTypeInfo];
        }
        
        ProfileViewController *profileViewController = (ProfileViewController *)self.topViewController;
        if (profileViewController.user.identifier && profileViewController.user.identifier.length > 0) {
            // hide the more button
            self.rightActionButton.alpha = 1;
        }
        else {
            self.rightActionButton.alpha = 0;
        }
    }
    else if ([self.topViewController isKindOfClass:[SearchTableViewController class]]) {
        [self setRightAction:LNActionTypeCancel];
    }
    else {
        [self setRightAction:LNActionTypeNone];
    }
    
    [UIView animateWithDuration:(animated?barColorUpdateDuration:0) delay:0 usingSpringWithDamping:0.75f initialSpringVelocity:0.5 options:(UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionAllowUserInteraction) animations:^{
        if (self.leftActionButton.tag == LNActionTypeBack) {
            if (self.viewControllers.count == 1) {
                self.leftActionButton.transform = CGAffineTransformMakeRotation(0);
            }
            else if (self.viewControllers.count > 1) {
                self.leftActionButton.transform = CGAffineTransformMakeRotation(0);
            }
        }
        
        if ([self.topViewController isKindOfClass:[SearchTableViewController class]]) {
            self.searchView.frame = CGRectMake(12, self.searchView.frame.origin.y, self.view.frame.size.width - 12 - 90, self.searchView.frame.size.height);
            [self.searchView setPosition:BFSearchTextPositionLeft];
        }
        else {
            CGFloat searchViewWidth = self.view.frame.size.width - (52 * 2);
            searchViewWidth = searchViewWidth > IPAD_CONTENT_MAX_WIDTH ? IPAD_CONTENT_MAX_WIDTH : searchViewWidth;
            
            self.searchView.frame = CGRectMake(self.view.frame.size.width / 2 - searchViewWidth / 2, self.searchView.frame.origin.y, searchViewWidth, self.searchView.frame.size.height);
            [self.searchView setPosition:BFSearchTextPositionCenter];
        }
    } completion:^(BOOL finished) {
        
    }];
    
    self.navigationItem.backBarButtonItem = nil;
    
    self.navigationController.interactivePopGestureRecognizer.delegate = self;
    self.navigationController.interactivePopGestureRecognizer.enabled = true;
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

- (void)continuityRadiusForView:(UIView *)sender withRadius:(CGFloat)radius {
    CAShapeLayer * maskLayer = [CAShapeLayer layer];
    maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:sender.bounds
                                           byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight|UIRectCornerTopLeft|UIRectCornerTopRight
                                                 cornerRadii:CGSizeMake(radius, radius)].CGPath;
    
    sender.layer.mask = maskLayer;
}

- (UIButton *)createActionButtonForType:(LNActionType)actionType {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    
    if (actionType == LNActionTypeCancel) {
        [button setTitle:@"Cancel" forState:UIControlStateNormal];
    }
    else if (actionType == LNActionTypeCompose) {
        [button setImage:[[UIImage imageNamed:@"composeIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [button setImageEdgeInsets:UIEdgeInsetsMake(-2, 0, 0, -3)];
    }
    else if (actionType == LNActionTypeMore) {
        [button setImage:[[UIImage imageNamed:@"navMoreIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    }
    else if (actionType == LNActionTypeInvite) {
        [button setImage:[[UIImage imageNamed:@"inviteFriendIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    }
    else if (actionType == LNActionTypeAdd) {
        [button setImage:[[UIImage imageNamed:@"navPlusIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    }
    else if (actionType == LNActionTypeShare) {
        [button setImage:[[UIImage imageNamed:@"navShareIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    }
    else if (actionType == LNActionTypeBack) {
        [button setImage:[[UIImage imageNamed:@"leftArrowIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [button setImageEdgeInsets:UIEdgeInsetsMake(0, 12, 0, 0)];
    }
    else if (actionType == LNActionTypeInfo) {
        [button setImage:[[UIImage imageNamed:@"navInfoIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    }
    else if (actionType == LNActionTypeSettings) {
        [button setImage:[[UIImage imageNamed:@"navSettingsIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    }
    else if (actionType == LNActionTypeManager) {
        [button setImage:[[UIImage imageNamed:@"navManagerIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
//        [button setImageEdgeInsets:UIEdgeInsetsMake(0, 12, 0, 0)];
    }
    else if (actionType == LNActionTypeDirector) {
        [button setImage:[[UIImage imageNamed:@"navDirectorIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
//        [button setImageEdgeInsets:UIEdgeInsetsMake(0, 12, 0, 0)];
    }
    
    if (button.currentTitle.length > 0) {
        [button.titleLabel setFont:[UIFont systemFontOfSize:18.f weight:UIFontWeightMedium]];
    }
    
    if (self.navigationBackgroundView.backgroundColor == [UIColor contentBackgroundColor]) {
        button.tintColor = self.view.tintColor;
    }
    else if ([UIColor useWhiteForegroundForColor:self.navigationBackgroundView.backgroundColor]) {
        button.tintColor = [UIColor whiteColor];
    }
    else {
        button.tintColor = [UIColor blackColor];
    }
    
    CGFloat padding = 16;
    button.frame = CGRectMake(0, 0, button.intrinsicContentSize.width + (padding * 2), self.navigationBar.frame.size.height);
    
    [button bk_whenTapped:^{
        switch (actionType) {
            case LNActionTypeCancel:
                if (self.viewControllers.count == 1) {
                    // VC is the top most view controller
                    [self.searchView.textField resignFirstResponder];
                    
                    [self dismissViewControllerAnimated:YES completion:nil];
                }
                else {
                    [self.searchView.textField resignFirstResponder];
                    
                    CATransition* transition = [CATransition animation];
                    transition.duration = 0.25f;
                    transition.type = kCATransitionFade;
                    [self.navigationController.view.layer addAnimation:transition forKey:nil];
                    [self popViewControllerAnimated:NO];
                    
                    [self goBack];
                }
                break;
            case LNActionTypeCompose:
                [Launcher openComposePost:nil inReplyTo:nil withMessage:nil media:nil quotedObject:nil];
                break;
            case LNActionTypeMore: {
                if ([self.viewControllers[self.viewControllers.count-1] isKindOfClass:[PostViewController class]]) {
                    PostViewController *activePost = self.viewControllers[self.viewControllers.count-1];
                    [Launcher openActionsForPost:activePost.post];
                }
                break;
            }
            case LNActionTypeInvite:
                if ([self.viewControllers[self.viewControllers.count-1] isKindOfClass:[CampViewController class]]) {
                    CampViewController *activeCamp = self.viewControllers[self.viewControllers.count-1];
                    [activeCamp openCampActions];
                }
                else {
                    [Launcher openInviteFriends:self];
                }
                break;
            case LNActionTypeShare:
                if ([self.viewControllers[self.viewControllers.count-1] isKindOfClass:[CampViewController class]]) {
                    CampViewController *activeCamp = self.viewControllers[self.viewControllers.count-1];
                    [activeCamp openCampActions];
                }
                else {
                    [Launcher openInviteFriends:self];
                }
                break;
            case LNActionTypeAdd:
                break;
            case LNActionTypeBack: {
                if (self.searchResultsTableView.alpha != 1 || self.searchResultsTableView.isHidden) {
                    if (self.viewControllers.count == 1) {
                        // VC is the top most view controller
                        [self.view endEditing:YES];
                        
                        [self dismissViewControllerAnimated:YES completion:nil];
                    }
                    else {
                        [self popViewControllerAnimated:YES];
                        
                        [self goBack];
                    }
                }
                else {
                    [self.searchView.textField resignFirstResponder];
                    
                    self.searchView.textField.placeholder = [NSString stringWithFormat:@"Search in %@", self.topViewController.title];
                    [self.searchView updateSearchText:self.topViewController.title];
                    
                    [self updateNavigationBarItemsWithAnimation:YES];
                }
                break;
            }
            case LNActionTypeInfo: {
                if ([self.viewControllers[self.viewControllers.count-1] isKindOfClass:[CampViewController class]]) {
                    CampViewController *activeCamp = self.viewControllers[self.viewControllers.count-1];
                    [activeCamp openCampActions];
                }
                else if ([self.viewControllers[self.viewControllers.count-1] isKindOfClass:[ProfileViewController class]]) {
                    ProfileViewController *activeProfile = self.viewControllers[self.viewControllers.count-1];
                    [activeProfile openProfileActions];
                }
                
                break;
            }
            case LNActionTypeSettings: {
                [Launcher openSettings];
                break;
            }
            case LNActionTypeManager: {
                if ([self.viewControllers[self.viewControllers.count-1] isKindOfClass:[CampViewController class]]) {
                    Camp *activeCamp = ((CampViewController *)self.viewControllers[self.viewControllers.count-1]).camp;
                    
                    BFAlertController *actionSheet = [BFAlertController alertControllerWithTitle:@"Manager" message:@"You can accept new member requests, block members, remove posts, and more." preferredStyle:BFAlertControllerStyleActionSheet];
                    
                    BFAlertAction *cta = [BFAlertAction actionWithTitle:@"Manage Members" style:BFAlertActionStyleDefault handler:^{
                        [Launcher openCampMembersForCamp:activeCamp];
                    }];
                    [actionSheet addAction:cta];
                    
                    BFAlertAction *cta2 = [BFAlertAction actionWithTitle:@"Moderate Posts" style:BFAlertActionStyleDefault handler:^{
                        [Launcher openCampModerateForCamp:activeCamp];
                    }];
                    [actionSheet addAction:cta2];
                    
                    BFAlertAction *cancelActionSheet = [BFAlertAction actionWithTitle:@"Close" style:BFAlertActionStyleCancel handler:nil];
                    [actionSheet addAction:cancelActionSheet];
                    
                    [actionSheet show];
                }
            }
            case LNActionTypeDirector: {
                if ([self.viewControllers[self.viewControllers.count-1] isKindOfClass:[CampViewController class]]) {
                    Camp *activeCamp = ((CampViewController *)self.viewControllers[self.viewControllers.count-1]).camp;
                    
                    BFAlertController *actionSheet = [BFAlertController alertControllerWithTitle:@"Director" message:@"You can customize the Camp settings, accept new member requests, block members, remove posts, and more." preferredStyle:BFAlertControllerStyleActionSheet];
                    
                    BFAlertAction *cta = [BFAlertAction actionWithTitle:@"Edit Camp" style:BFAlertActionStyleDefault handler:^{
                        [Launcher openEditCamp:activeCamp];
                    }];
                    [actionSheet addAction:cta];
                    
                    BFAlertAction *cta2 = [BFAlertAction actionWithTitle:@"Manage Members" style:BFAlertActionStyleDefault handler:^{
                        [Launcher openCampMembersForCamp:activeCamp];
                    }];
                    [actionSheet addAction:cta2];
                    
                    BFAlertAction *cta3 = [BFAlertAction actionWithTitle:@"Moderate Posts" style:BFAlertActionStyleDefault handler:^{
                        [Launcher openCampModerateForCamp:activeCamp];
                    }];
                    [actionSheet addAction:cta3];
                    
                    BFAlertAction *cancelActionSheet = [BFAlertAction actionWithTitle:@"Close" style:BFAlertActionStyleCancel handler:nil];
                    [actionSheet addAction:cancelActionSheet];
                    
                    [actionSheet show];
                }
            }
                
            default:
                break;
        }
    }];
    
    if (LNActionTypeBack) {
        UILongPressGestureRecognizer *longPressToGoHome = [[UILongPressGestureRecognizer alloc] bk_initWithHandler:^(UIGestureRecognizer *sender, UIGestureRecognizerState state, CGPoint location) {
            switch (actionType) {
                case LNActionTypeBack: {
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
    
    [self.navigationBar addSubview:button];
    
    return button;
}
- (void)setLeftAction:(LNActionType)actionType {
    if ((NSInteger)actionType != self.leftActionButton.tag) {
        [self.leftActionButton removeFromSuperview];
        if (actionType == LNActionTypeNone) {
            self.leftActionButton = nil;
        }
        else {
            self.leftActionButton = [self createActionButtonForType:actionType];
            self.leftActionButton.frame = CGRectMake(0, self.leftActionButton.frame.origin.y, self.leftActionButton.frame.size.width, self.leftActionButton.frame.size.height);
            
            self.leftActionButton.tag = actionType;
        }
    }
}
- (void)setRightAction:(LNActionType)actionType {
    [self setRightAction:actionType animated:false];
}
- (void)setRightAction:(LNActionType)actionType animated:(BOOL)animated {
    if ((NSInteger)actionType != self.rightActionButton.tag) {
        UIButton *newButton;
        if (actionType != LNActionTypeNone) {
            newButton = [self createActionButtonForType:actionType];
            newButton.frame = CGRectMake(self.navigationBar.frame.size.width - newButton.frame.size.width, newButton.frame.origin.y, newButton.frame.size.width, newButton.frame.size.height);
        }
        
        if (self.rightActionButton && animated) {
            UIButton *oldButton = self.rightActionButton;
            
            // animate out the old button
            [UIView animateWithDuration:0.2f delay:0 usingSpringWithDamping:0.8f initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
                oldButton.transform = CGAffineTransformMakeScale(0.01, 0.01);
                oldButton.alpha = 0;
            } completion:^(BOOL finished) {
                [oldButton removeFromSuperview];
            }];
            
            if (newButton) {
                // animate in the new button
                self.rightActionButton = newButton;
                self.rightActionButton.alpha = 0;
                self.rightActionButton.transform = CGAffineTransformMakeScale(0.01, 0.01);
                self.rightActionButton.tag = actionType;
                [UIView animateWithDuration:0.3f delay:0.15f usingSpringWithDamping:0.8f initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
                    self.rightActionButton.transform = CGAffineTransformMakeScale(1, 1);
                    self.rightActionButton.alpha = 1;
                } completion:nil];
            }
            else {
                self.rightActionButton = nil;
            }
        }
        else {
            // replace without animation
            if (self.rightActionButton) {
                // existing button that needs to be removed
                [self.rightActionButton removeFromSuperview];
            }
            
            if (newButton) {
                self.rightActionButton = newButton;
                self.rightActionButton.tag = actionType;
                self.rightActionButton.transform = CGAffineTransformMakeScale(1, 1);
                self.rightActionButton.alpha = 1;
            }
            else {
                self.rightActionButton = nil;
            }
        }
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField == self.searchView.textField) {
        self.searchView.textField.userInteractionEnabled = false;
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
        self.navigationBackgroundView.layer.shadowOpacity = p;
    }
    
    if (!self.opaqueOnScroll) {
        self.navigationBackgroundView.alpha = p;
    }
    else if (self.navigationBackgroundView.alpha != 1) {
        self.navigationBackgroundView.alpha = 1;
    }
}

@end
