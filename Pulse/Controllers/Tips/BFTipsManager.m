//
//  TipsManager.m
//  Pulse
//
//  Created by Austin Valleskey on 5/2/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "BFTipsManager.h"
#import "Camp.h"
#import "User.h"
#import "Launcher.h"
#import <HapticHelper/HapticHelper.h>

@implementation BFTipsManager

+ (BFTipsManager *)sharedInstance {
    static BFTipsManager *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    
    return _sharedInstance;
}

- (id)init {
    self = [super init];
    
    if (self) {
        self.presenting = false;
        
        self.tips = [[NSMutableArray alloc] init];
    }
    
    return self;
}

+ (BFTipsManager *)manager {
    return [BFTipsManager sharedInstance];
}

- (BOOL)isPresenting {
    return self.presenting;
}

- (void)presentTip:(BFTipObject *)tipObject completion:(void (^)(void))completion {
    BFTipView *tipView = [[BFTipView alloc] initWithObject:tipObject];
    [self presentTipView:tipView completion:completion];
}

- (void)presentTipView:(BFTipView *)tipView completion:(void (^ __nullable)(void))completion {
    self.presenting = true;
    
    CGFloat yTop = [UIScreen mainScreen].bounds.size.height;
    CGFloat tipViewHeight = tipView.frame.size.height;
    CGFloat safeAreaInsetBottom = [[[UIApplication sharedApplication] delegate] window].safeAreaInsets.bottom;
    
    UINavigationController *activeNavVC = [Launcher activeNavigationController];
    UITabBarController *activeTabVC = [Launcher activeTabController];
    UIViewController *activeViewController = [Launcher activeViewController];
    
    for (BFTipView *subview in self.tips) {
        if ([@[activeNavVC.view, activeViewController.view] containsObject:subview.superview]) {
            NSLog(@"one is already shown.... bleh");
            return;
        }
    }
    
    if (activeNavVC) {
        UINavigationController *activeNavVC = [Launcher activeNavigationController];
        [activeNavVC.view addSubview:tipView];
        
        if (activeTabVC) {
            yTop = activeTabVC.tabBar.frame.origin.y;
        }
        else if ([activeNavVC.visibleViewController isKindOfClass:[UITableViewController class]]) {
            yTop = activeNavVC.view.frame.size.height - ((UITableViewController *)activeNavVC.visibleViewController).tableView.adjustedContentInset.bottom;
        }
        else {
            yTop = activeNavVC.view.frame.size.height - safeAreaInsetBottom;
        }
    }
    else {
        [activeViewController.view addSubview:tipView];
        
        yTop = activeViewController.view.frame.size.height;
    }
    yTop = yTop - tipViewHeight - 12;
    
    [self.tips addObject:tipView];
    
    tipView.center = CGPointMake([UIScreen mainScreen].bounds.size.width / 2, yTop + (tipViewHeight * 2));
    tipView.alpha = 0;
    tipView.transform = CGAffineTransformMakeScale(0.8, 0.8);
    [UIView animateWithDuration:0.8 delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
        tipView.transform = CGAffineTransformMakeScale(1, 1);
        tipView.alpha = 1;
        tipView.center = CGPointMake([UIScreen mainScreen].bounds.size.width / 2, yTop + (tipViewHeight / 2));
    } completion:^(BOOL finished) {
        
    }];
    [HapticHelper generateFeedback:FeedbackType_Impact_Medium];
}
- (void)hideAllTips {
    for (BFTipView *tipView in self.tips) {
        [UIView animateWithDuration:1.2 delay:0 usingSpringWithDamping:0.6f initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            tipView.center = CGPointMake(tipView.center.x, tipView.center.y + (tipView.frame.size.height * 2));
            //tipView.transform = CGAffineTransformMakeScale(0.8, 0.8);
        } completion:^(BOOL finished) {
            [tipView removeFromSuperview];
            [self.tips removeObject:tipView];
        }];
    }
    self.presenting = false;
}

+ (BOOL)hasSeenTip:(NSString *)tipId {
    NSString *tipsDefaultsPrefix = @"tips";
    NSString *key = [NSString stringWithFormat:@"%@/%@", tipsDefaultsPrefix, tipId];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:key]) {
        return true;
    }
    else {
        [[NSUserDefaults standardUserDefaults] setBool:true forKey:key];
        return false;
    }
}

@end
