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
    
    [self setupTitleLabel];
    [self setupNavigationBar];
}
- (void)viewWillAppear:(BOOL)animated {
    if (self.currentTheme == nil) {
        self.currentTheme = [UIColor clearColor];
    }
}
- (void)viewDidAppear:(BOOL)animated {
    self.navigationBackgroundView.frame = CGRectMake(0, 0, self.navigationBar.frame.size.width, self.navigationBar.frame.origin.y + self.navigationBar.frame.size.height);
    self.blurView.frame = self.navigationBackgroundView.bounds;
}

- (void)setCurrentTheme:(UIColor *)currentTheme {
    if (currentTheme != _currentTheme) {
        _currentTheme = currentTheme;
        
        if ([self.visibleViewController isKindOfClass:[ProfileViewController class]]) {
            NSLog(@"set profiel vc theme: %@", currentTheme);
        }
        else {
            NSLog(@"set other vc theme: %@", currentTheme);
        }
        
        [self updateBarColor:currentTheme withAnimation:0 statusBarUpdateDelay:0];
    }
}

- (void)setupTitleLabel {
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.navigationBar.frame.size.width - (56 * 2), self.navigationBar.frame.size.height)];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.center = CGPointMake(self.navigationBar.frame.size.width / 2, self.navigationBar.frame.size.height / 2);
    self.titleLabel.font = [UIFont systemFontOfSize:17.f weight:UIFontWeightBold];
    self.titleLabel.textColor = [UIColor colorWithWhite:0.07f alpha:1];
    self.titleLabel.text = self.visibleViewController.title;
    [self.navigationBar addSubview:self.titleLabel];
}
- (void)setTitle:(NSString *)title {
    [super setTitle:title];
    if (![title isEqualToString:self.titleLabel.text]) {
        [UIView transitionWithView:self.titleLabel duration:0.3f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.titleLabel.text = title;
        } completion:nil];
    }
}
- (void)setupNavigationBar {
    // setup items
    [self.navigationBar setTitleTextAttributes:
     @{NSForegroundColorAttributeName:[UIColor clearColor],
       NSFontAttributeName:[UIFont systemFontOfSize:1.f]}];
    
    // add blur view background
    self.navigationBackgroundView = [[UIView alloc] init];
    [self.view insertSubview:self.navigationBackgroundView belowSubview:self.navigationBar];
    
    self.blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
    self.blurView.frame = self.navigationBackgroundView.bounds;
    [self.navigationBackgroundView addSubview:self.blurView];
    
    // remove default hairline
    [self.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    [self.navigationBar setShadowImage:[UIImage new]];
    self.navigationBar.translucent = true;
    // add custom hairline
    self.hairline = [[UIView alloc] initWithFrame:CGRectMake(0, self.navigationBar.frame.size.height, self.navigationBar.frame.size.width, (1 / [UIScreen mainScreen].scale))];
    self.hairline.backgroundColor = [UIColor colorWithWhite:0 alpha:0.08f];
    [self.navigationBar addSubview:self.hairline];
}

- (void)hide:(BOOL)animated {
    [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.navigationBackgroundView.alpha = 0;
        self.hairline.alpha = 0;
        self.navigationItem.titleView.alpha = 0;
    } completion:nil];
}
- (void)show:(BOOL)animated {
    [UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.navigationBackgroundView.alpha = 1;
        self.hairline.alpha = 1;
        self.navigationItem.titleView.alpha = 1;
    } completion:nil];
}

- (UIBarButtonItem *)createBarButtonItemForType:(SNActionType)actionType {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    
    if (actionType == SNActionTypeCancel) {
        [button setTitle:@"Cancel" forState:UIControlStateNormal];
    }
    if (actionType == SNActionTypeCompose) {
        [button setImage:[[UIImage imageNamed:@"composeIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [button setImageEdgeInsets:UIEdgeInsetsMake(-2, 0, 0, -3)];
    }
    if (actionType == SNActionTypeMore) {
        [button setImage:[[UIImage imageNamed:@"navMoreIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    }
    if (actionType == SNActionTypeInvite) {
        [button setImage:[[UIImage imageNamed:@"inviteFriendIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    }
    if (actionType == SNActionTypeAdd) {
        [button setImage:[[UIImage imageNamed:@"navPlusIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    }
    
    if (button.currentTitle.length > 0) {
        [button.titleLabel setFont:[UIFont systemFontOfSize:17.f weight:UIFontWeightMedium]];
    }
    
    CGFloat padding = 16;
    button.frame = CGRectMake(0, 0, button.intrinsicContentSize.width + (padding * 2), self.navigationBar.frame.size.height);
    
    [button bk_whenTapped:^{
        switch (actionType) {
            case SNActionTypeCancel:
                break;
            case SNActionTypeCompose:
                [[Launcher sharedInstance] openComposePost];
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
                [[Launcher sharedInstance] openInviteFriends];
                break;
            case SNActionTypeAdd:
                [[Launcher sharedInstance] openCreateRoom];
                break;
            case SNActionTypeBack: {
                
                break;
            }
                
            default:
                break;
        }
    }];
    
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
    [UIView animateWithDuration:animation?0.25f:0 animations:^{
        self.hairline.alpha = visible ? 1 : 0;
    } completion:nil];
}
- (void)updateBarColor:(id)background withAnimation:(int)animationType statusBarUpdateDelay:(CGFloat)statusBarUpdateDelay {
    if ([background isKindOfClass:[NSString class]]) {
        background = [UIColor fromHex:background];
    }
    NSLog(@"updateBarColor");
    // generate foreground based on background
    UIColor *foreground;
    UIColor *originalBackground = background;
    if (background == nil || background == [UIColor whiteColor] || background == [UIColor clearColor]) {
        NSLog(@"ok ya change it");
        background = [[UIColor headerBackgroundColor] colorWithAlphaComponent:0.9];
        foreground = [Session sharedInstance].themeColor;
    }
    else if ([UIColor useWhiteForegroundForColor:background]) {
        NSLog(@"use white foreground!");
        foreground = [UIColor whiteColor];
    }
    else {
        foreground = [UIColor colorWithWhite:0.07f alpha:1];
    }
    
    UIView *newColorView = [[UIView alloc] init];
    if (animationType == 0 || animationType == 1) {
        // fade
        newColorView.frame = CGRectMake(0, 0, self.navigationBackgroundView.frame.size.width, self.navigationBackgroundView.frame.size.height);;
        newColorView.layer.cornerRadius = 0;
        newColorView.alpha = animationType == 0 ? 1 : 0;
        newColorView.backgroundColor = background;
    }
    else {
        // bubble burst
        newColorView.frame = CGRectMake(self.navigationBackgroundView.frame.size.width / 2 - 5, self.navigationBackgroundView.frame.size.height + 40, 10, 10);
        newColorView.layer.cornerRadius = 5.f;
        
        if (animationType == 2) {
            newColorView.backgroundColor = background;
        }
        else if (animationType == 3) {
            newColorView.backgroundColor = self.navigationBackgroundView.backgroundColor;
            newColorView.transform = CGAffineTransformMakeScale(self.navigationBackgroundView.frame.size.width / 10, self.navigationBackgroundView.frame.size.width / 10);
            self.navigationBackgroundView.backgroundColor = background;
        }
    }
    newColorView.layer.masksToBounds = true;
    [self.navigationBackgroundView addSubview:newColorView];
    
    [UIView animateWithDuration:(animationType != 0 ? 0.25f : 0) delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        // status bar
        if ([UIColor useWhiteForegroundForColor:background]) {
            self.navigationBar.barStyle = UIBarStyleBlack;
        }
        else {
            self.navigationBar.barStyle = UIBarStyleDefault;
        }
        
        [self setNeedsStatusBarAppearanceUpdate];
        
        // foreground items
        if (animationType == 1) {
            // fade
            newColorView.alpha = 1;
        }
        else if (animationType == 2) {
            // bubble burst
            newColorView.transform = CGAffineTransformMakeScale(self.navigationBackgroundView.frame.size.width / 8, self.navigationBackgroundView.frame.size.width / 8);
        }
        else if (animationType == 3) {
            // bubble roll back da burst
            newColorView.transform = CGAffineTransformMakeScale(1, 1);
        }
        
        self.navigationBar.tintColor = foreground;
        
        if (originalBackground == [UIColor clearColor]) {
            self.blurView.alpha = 1;
        }
        else {
            self.blurView.alpha = 0;
        }
        
        if ([UIColor useWhiteForegroundForColor:background]) {
            self.hairline.alpha = 0;
            self.titleLabel.textColor = foreground;
        }
        else {
            if (self.titleLabel.alpha == 0) {
                self.hairline.alpha = 0;
            }
            else {
                self.hairline.alpha = 1;
            }
            self.titleLabel.textColor = [UIColor colorWithWhite:0.07 alpha:1];
        }
    } completion:^(BOOL finished) {
        if (animationType != 3) {
            NSLog(@"set background: %@", background);
            self.navigationBackgroundView.backgroundColor = background;
        }
        [newColorView removeFromSuperview];
    }];
}

@end
