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
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.currentTheme == nil) {
        self.currentTheme = [UIColor clearColor];
    }
}

- (void)setCurrentTheme:(UIColor *)currentTheme {
    if (currentTheme != _currentTheme) {
        _currentTheme = currentTheme;
        
        [self updateBarColor:currentTheme animated:YES];
    }
}

- (void)setupNavigationBar {
//    // setup items
    [self.navigationBar setTitleTextAttributes:
     @{NSForegroundColorAttributeName:[UIColor blackColor],
       NSFontAttributeName:[UIFont systemFontOfSize:18.f weight:UIFontWeightBold]}];
    
    self.navigationBar.barStyle = UIBarStyleDefault;
    
//    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.navigationBar.frame.size.width - (72 * 2), self.navigationBar.frame.size.height)];
//    self.titleLabel.textColor = [UIColor bonfireBlack];
//    self.titleLabel.font = [UIFont systemFontOfSize:20.f weight:UIFontWeightBold];
//    self.titleLabel.textAlignment = NSTextAlignmentLeft;
//    [self.navigationItem setTitleView:self.titleLabel];
}

/*
- (void)setTitle:(NSString *)title {
    [super setTitle:title];
        
    self.titleLabel.text = title;
    [self.navigationItem setTitleView:self.titleLabel];
}*/

- (UIBarButtonItem *)createBarButtonItemForType:(SNActionType)actionType {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    
    BOOL includeAction = false;
    
    if (actionType == SNActionTypeCancel) {
        includeAction = true;
        [button setTitle:@"Cancel" forState:UIControlStateNormal];
    }
    if (actionType == SNActionTypeProfile) {
        includeAction = true;
        BFAvatarView *userAvatar = [[BFAvatarView alloc] initWithFrame:CGRectMake(12, self.navigationBar.frame.size.height / 2 - 16, 32, 32)];
        userAvatar.user = [[Session sharedInstance] currentUser];
        userAvatar.dimsViewOnTap = true;
        userAvatar.tag = 10;
        button.frame = userAvatar.frame;
        [button addSubview:userAvatar];
        
        [[NSNotificationCenter defaultCenter] addObserver:userAvatar selector:@selector(userUpdated:) name:@"UserUpdated" object:nil];
    }
    if (actionType == SNActionTypeCompose) {
        includeAction = true;
        [button setImage:[[UIImage imageNamed:@"composeIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [button setImageEdgeInsets:UIEdgeInsetsMake(-2, 0, 0, -3)];
    }
    if (actionType == SNActionTypeMore) {
        includeAction = true;
        [button setImage:[[UIImage imageNamed:@"navMoreIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    }
    if (actionType == SNActionTypeInvite) {
        includeAction = true;
        [button setImage:[[UIImage imageNamed:@"inviteFriendIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    }
    if (actionType == SNActionTypeAdd) {
        includeAction = true;
        [button setImage:[[UIImage imageNamed:@"navPlusIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    }
    if (actionType == SNActionTypeShare) {
        [button setTitle:@"Post" forState:UIControlStateNormal];
    }
    if (actionType == SNActionTypeDone) {
        includeAction = true;
        [button setTitle:@"Done" forState:UIControlStateNormal];
    }
    if (actionType == SNActionTypeSettings) {
        includeAction = true;
        [button setImage:[[UIImage imageNamed:@"navSettingsIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    }
    if (actionType == SNActionTypeSearch) {
        includeAction = true;
        [button setImage:[[UIImage imageNamed:@"navSearchIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    }
    
    if (button.currentTitle.length > 0) {
        if (actionType == SNActionTypeShare || actionType == SNActionTypeDone) {
            [button.titleLabel setFont:[UIFont systemFontOfSize:18.f weight:UIFontWeightBold]];
        }
        else {
            [button.titleLabel setFont:[UIFont systemFontOfSize:18.f weight:UIFontWeightMedium]];
        }
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
                    [Launcher openCreateCamp];
                    break;
                case SNActionTypeBack: {
                    
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
    
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:button];
    
    return item;
}
- (void)setLeftAction:(SNActionType)actionType {
    NSLog(@"set left action !!");
    if (actionType != self.visibleViewController.navigationItem.leftBarButtonItem.customView.tag) {
        NSLog(@"let's create it !");
        if (actionType == SNActionTypeNone) {
            self.visibleViewController.navigationItem.leftBarButtonItem = nil;
        }
        else {
            self.visibleViewController.navigationItem.leftBarButtonItem = [self createBarButtonItemForType:actionType];
            self.visibleViewController.navigationItem.leftMargin = 0;
        }
    }
}
- (void)setRightAction:(SNActionType)actionType {
    if (actionType != self.visibleViewController.navigationItem.rightBarButtonItem.customView.tag) {
        if (actionType == SNActionTypeNone) {
            self.visibleViewController.navigationItem.rightBarButtonItem = nil;
        }
        else {
            self.visibleViewController.navigationItem.rightBarButtonItem = [self createBarButtonItemForType:actionType];
            self.visibleViewController.navigationItem.rightMargin = 0;
        }
        self.visibleViewController.navigationItem.rightBarButtonItem.tag = actionType;
        self.visibleViewController.navigationItem.rightBarButtonItem.tag = actionType;
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
    UIImageView *navBarHairlineImageView = [self findHairlineImageViewUnder:self.navigationBar];
    if (navBarHairlineImageView.alpha == 1) {
        [navBarHairlineImageView.layer removeAllAnimations];
    }
    navBarHairlineImageView.alpha = 0;
}
- (void)showBottomHairline {
    // Show 1px hairline of translucent nav bar
    UIImageView *navBarHairlineImageView = [self findHairlineImageViewUnder:self.navigationBar];

    if (navBarHairlineImageView.alpha != 1) {
        [navBarHairlineImageView.layer removeAllAnimations];
    }
    navBarHairlineImageView.alpha = 1;
}
- (UIImageView *)findHairlineImageViewUnder:(UIView *)view {
    if ([view isKindOfClass:UIImageView.class] && view.bounds.size.height <= 1.0) {
        return (UIImageView *)view;
    }
    for (UIView *subview in view.subviews) {
        UIImageView *imageView = [self findHairlineImageViewUnder:subview];
        if (imageView) {
            return imageView;
        }
    }
    return nil;
}

- (void)makeTransparent {
    self.navigationBar.translucent = true;
    self.navigationBar.backgroundColor = [UIColor clearColor];
    self.navigationBar.shadowImage = [self imageWithColor:[UIColor colorWithWhite:0 alpha:0.1]];    // Hides the hairline
}
- (void)makeDefault {
    self.navigationBar.translucent = false;
    self.navigationBar.backgroundColor = nil;
    self.navigationBar.shadowImage = [self imageWithColor:[UIColor clearColor]];    // Hides the hairline
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
    NSLog(@"og background: %@", background);
    if ([background isKindOfClass:[NSString class]]) {
        background = [UIColor fromHex:background];
    }
    NSLog(@"background after if: %@", background);

    UIColor *foreground;
    if (background == nil || background == [UIColor clearColor]) {
        foreground = [UIColor bonfireBlack];
        background = [UIColor colorWithRed:0.98 green:0.98 blue:0.99 alpha:1];
        [self makeTransparent];
    }
    else {
        if ([UIColor useWhiteForegroundForColor:background]) {
            foreground = [UIColor whiteColor];
        }
        else {
            foreground = [UIColor bonfireBlack];
        }
        [self makeDefault];
    }
    
    [UIView animateWithDuration:animated?0.5f:0 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.navigationBar.barTintColor = background;
        self.navigationBar.tintColor = foreground;
        self.navigationItem.leftBarButtonItem.customView.tintColor = foreground;
        self.navigationItem.rightBarButtonItem.customView.tintColor = foreground;
        [self.navigationBar setTitleTextAttributes:
         @{NSForegroundColorAttributeName:foreground,
           NSFontAttributeName:[UIFont systemFontOfSize:18.f weight:UIFontWeightBold]}];
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
