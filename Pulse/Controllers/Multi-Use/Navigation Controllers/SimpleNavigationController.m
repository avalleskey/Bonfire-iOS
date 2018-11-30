//
//  SimpleNavigationController.m
//  Pulse
//
//  Created by Austin Valleskey on 11/29/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "SimpleNavigationController.h"
#import "Session.h"
#import "UIColor+Palette.h"
#import "UINavigationItem+Margin.h"

@interface SimpleNavigationController ()

@end

@implementation SimpleNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupNavigationBar];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTheme:) name:@"UserUpdated" object:nil];
}
- (void)viewDidAppear:(BOOL)animated {
    self.blurView.frame = CGRectMake(0, 0, self.navigationBar.frame.size.width, self.navigationBar.frame.origin.y + self.navigationBar.frame.size.height);
}
- (void)updateTheme:(id)sender {
    self.navigationBar.tintColor = [Session sharedInstance].themeColor;
    self.navigationBar.barTintColor = [UIColor redColor];
}
- (void)setupNavigationBar {
    // setup items
    [self.navigationBar setTitleTextAttributes:
     @{NSForegroundColorAttributeName:[UIColor colorWithWhite:0.07f alpha:1],
       NSFontAttributeName:[UIFont systemFontOfSize:17.f weight:UIFontWeightBold]}];
    
    //
    self.navigationBar.translucent = true;
    [self updateTheme:nil];
    
    // add blur view background
    self.blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
    self.blurView.backgroundColor = [[UIColor headerBackgroundColor] colorWithAlphaComponent:0.9];
    [self.view insertSubview:self.blurView belowSubview:self.navigationBar];
    
    // remove default hairline
    [self.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    [self.navigationBar setShadowImage:[UIImage new]];
    // add custom hairline
    self.hairline = [[UIView alloc] initWithFrame:CGRectMake(0, self.navigationBar.frame.size.height - (1 / [UIScreen mainScreen].scale), self.navigationBar.frame.size.width, (1 / [UIScreen mainScreen].scale))];
    self.hairline.backgroundColor = [UIColor colorWithWhite:0 alpha:0.08f];
    [self.navigationBar addSubview:self.hairline];
    
    
}

- (void)hide:(BOOL)animated {
    
}
- (void)show:(BOOL)animated {
    
}

- (UIBarButtonItem *)createBarButtonItemForType:(SNActionType)actionType {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    
    if (actionType == SNActionTypeCancel) {
        [button setTitle:@"Cancel" forState:UIControlStateNormal];
    }
    if (actionType == SNACtionTypeCompose) {
        NSLog(@"create compose");
        [button setImage:[[UIImage imageNamed:@"composeIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [button setImageEdgeInsets:UIEdgeInsetsMake(-2, 0, 0, -3)];
    }
    if (actionType == SNACtionTypeMore) {
        [button setImage:[[UIImage imageNamed:@"moreIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    }
    if (actionType == SNACtionTypeInvite) {
        [button setImage:[[UIImage imageNamed:@"inviteFriendIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    }
    if (actionType == SNACtionTypeAdd) {
        [button setImage:[[UIImage imageNamed:@"navPlusIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    }
    
    if (button.currentTitle.length > 0) {
        [button.titleLabel setFont:[UIFont systemFontOfSize:17.f weight:UIFontWeightMedium]];
    }
    
    CGFloat padding = 16;
    button.frame = CGRectMake(0, 0, button.intrinsicContentSize.width + (padding * 2), self.navigationBar.frame.size.height);
    
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:button];
    
    return item;
}
- (void)setLeftAction:(SNActionType)actionType {
    self.visibleViewController.navigationItem.leftBarButtonItem = [self createBarButtonItemForType:actionType];
    self.visibleViewController.navigationItem.leftMargin = 0;
}
- (void)setRightAction:(SNActionType)actionType {
    self.visibleViewController.navigationItem.rightBarButtonItem = [self createBarButtonItemForType:actionType];
    self.visibleViewController.navigationItem.rightMargin = 0;
}


@end
