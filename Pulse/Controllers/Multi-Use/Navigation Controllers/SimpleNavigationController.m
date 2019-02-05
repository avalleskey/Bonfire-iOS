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
#import "RoomViewController.h"
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
        
        [self updateBarColor:currentTheme];
    }
}

- (void)setupNavigationBar {
    // setup items
    [self.navigationBar setTitleTextAttributes:
     @{NSForegroundColorAttributeName:[UIColor colorWithWhite:0.07f alpha:1],
       NSFontAttributeName:[UIFont systemFontOfSize:17.f weight:UIFontWeightBold]}];
}

- (UIBarButtonItem *)createBarButtonItemForType:(SNActionType)actionType {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    
    BOOL includeAction = false;
    
    if (actionType == SNActionTypeCancel) {
        includeAction = true;
        [button setTitle:@"Cancel" forState:UIControlStateNormal];
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
        [button setTitle:@"Share" forState:UIControlStateNormal];
    }
    if (actionType == SNActionTypeDone) {
        includeAction = true;
        [button setTitle:@"Done" forState:UIControlStateNormal];
    }
    if (actionType == SNActionTypeSettings) {
        includeAction = true;
        [button setImage:[[UIImage imageNamed:@"navSettingsIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    }
    
    if (button.currentTitle.length > 0) {
        if (actionType == SNActionTypeShare || actionType == SNActionTypeDone) {
            [button.titleLabel setFont:[UIFont systemFontOfSize:17.f weight:UIFontWeightBold]];
        }
        else {
            [button.titleLabel setFont:[UIFont systemFontOfSize:17.f weight:UIFontWeightMedium]];
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
                case SNActionTypeDone:
                    [self dismissViewControllerAnimated:YES completion:nil];
                    break;
                case SNActionTypeCompose:
                    [[Launcher sharedInstance] openComposePost:nil inReplyTo:nil withMessage:nil media:nil];
                    break;
                case SNActionTypeMore: {
                    if ([self.viewControllers[self.viewControllers.count-1] isKindOfClass:[RoomViewController class]]) {
                        RoomViewController *activeRoom = self.viewControllers[self.viewControllers.count-1];
                        [activeRoom openRoomActions];
                    }
                    else if ([self.viewControllers[self.viewControllers.count-1] isKindOfClass:[ProfileViewController class]]) {
                        ProfileViewController *activeProfile = self.viewControllers[self.viewControllers.count-1];
                        [activeProfile openProfileActions];
                    }
                    else if ([self.viewControllers[self.viewControllers.count-1] isKindOfClass:[PostViewController class]]) {
                        PostViewController *activePost = self.viewControllers[self.viewControllers.count-1];
                        [activePost openPostActions];
                    }
                    break;
                }
                case SNActionTypeInvite:
                    [[Launcher sharedInstance] openInviteFriends:self];
                    break;
                case SNActionTypeAdd:
                    [[Launcher sharedInstance] openCreateRoom];
                    break;
                case SNActionTypeBack: {
                    
                    break;
                }
                case SNActionTypeSettings:
                    [[Launcher sharedInstance] openSettings];
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
    if (actionType != self.visibleViewController.navigationItem.leftBarButtonItem.tag) {
        if (actionType == SNActionTypeNone) {
            self.visibleViewController.navigationItem.leftBarButtonItem = nil;
        }
        else {
            self.visibleViewController.navigationItem.leftBarButtonItem = [self createBarButtonItemForType:actionType];
            self.visibleViewController.navigationItem.leftMargin = 0;
        }
        self.visibleViewController.navigationItem.leftBarButtonItem.tag = actionType;
    }
}
- (void)setRightAction:(SNActionType)actionType {
    if (actionType != self.visibleViewController.navigationItem.rightBarButtonItem.tag) {
        if (actionType == SNActionTypeNone) {
            self.visibleViewController.navigationItem.rightBarButtonItem = nil;
        }
        else {
            self.visibleViewController.navigationItem.rightBarButtonItem = [self createBarButtonItemForType:actionType];
            self.visibleViewController.navigationItem.rightMargin = 0;
        }
        self.visibleViewController.navigationItem.rightBarButtonItem.tag = actionType;
    }
}

// theming
- (void)setShadowVisibility:(BOOL)visible withAnimation:(BOOL)animation {
    if (visible) [self showBottomHairline];
    else [self hideBottomHairline];
}
- (void)hideBottomHairline {
    UIImageView *navBarHairlineImageView = [self findHairlineImageViewUnder:self.navigationBar];
    navBarHairlineImageView.hidden = YES;
}
- (void)showBottomHairline {
    // Show 1px hairline of translucent nav bar
    UIImageView *navBarHairlineImageView = [self findHairlineImageViewUnder:self.navigationBar];
    navBarHairlineImageView.hidden = NO;
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
    self.navigationBar.backgroundColor = [UIColor clearColor];
    self.navigationBar.shadowImage = [self imageWithColor:[UIColor colorWithWhite:0 alpha:0.12f]];    // Hides the hairline
}
- (void)makeDefault {
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

- (void)updateBarColor:(id)background {
    if ([background isKindOfClass:[NSString class]]) {
        background = [UIColor fromHex:background];
    }

    // generate foreground based on background
    if (background == [UIColor clearColor]) {
        [self makeTransparent];
    }
    else {
        [self makeDefault];
    }
    self.navigationBar.translucent = (background == [UIColor clearColor]);
    
    UIColor *foreground;
    if (background == nil || background == [UIColor whiteColor] || background == [UIColor clearColor]) {
        if (background == nil || background == [UIColor clearColor]) {
            background = [UIColor colorWithRed:0.98 green:0.98 blue:0.99 alpha:1.00];
        }
        foreground = [UIColor bonfireBrand];
    }
    else if ([UIColor useWhiteForegroundForColor:background]) {
        foreground = [UIColor whiteColor];
        self.navigationBar.barStyle = UIBarStyleBlack;
    }
    else {
        foreground = [UIColor colorWithWhite:0.07f alpha:1];
        self.navigationBar.barStyle = UIBarStyleDefault;
    }
    [self setNeedsStatusBarAppearanceUpdate];
    
    self.navigationBar.tintColor = foreground;
    self.navigationBar.barTintColor = background;
    
    if ([UIColor useWhiteForegroundForColor:background]) {
        [self.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName: foreground, NSFontAttributeName: [UIFont systemFontOfSize:17.f weight:UIFontWeightBold]}];
        [self.navigationBar setLargeTitleTextAttributes:@{NSForegroundColorAttributeName: foreground, NSFontAttributeName: [UIFont systemFontOfSize:34.f weight:UIFontWeightHeavy]}];
    }
    else {
        [self.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:0.07f alpha:1], NSFontAttributeName: [UIFont systemFontOfSize:17.f weight:UIFontWeightBold]}];
        [self.navigationBar setLargeTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:0.07f alpha:1], NSFontAttributeName: [UIFont systemFontOfSize:34.f weight:UIFontWeightHeavy]}];
    }
}

@end
