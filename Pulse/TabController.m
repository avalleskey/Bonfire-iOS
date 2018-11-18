//
//  TabController.m
//  Hallway App
//
//  Created by Austin Valleskey on 8/20/18.
//  Copyright © 2018 Hallway App. All rights reserved.
//

#import "TabController.h"
#import "Session.h"
#import <BlocksKit+UIKit.h>

#define IS_IPHONE        (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define IS_IPHONE_5 ([[UIScreen mainScreen] bounds].size.height == 568.0)
#define IS_IPHONE_X (IS_IPHONE && [[UIScreen mainScreen] bounds].size.height == 812.0)
#define IS_TINY ([[UIScreen mainScreen] bounds].size.height == 480)

@interface TabController () <UITabBarControllerDelegate> {
    NSMutableArray *activeOverlays;
}

@end

@implementation TabController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    activeOverlays = [[NSMutableArray alloc] init];
    self.pills = [[NSMutableDictionary alloc] init];
    
    self.tabIndicator = [[UIView alloc] initWithFrame:CGRectMake(20, 0, 22, 2)];
    self.tabIndicator.layer.cornerRadius = 1.f;
    self.tabIndicator.backgroundColor = [UIColor blackColor];
    [self.tabBar addSubview:self.tabIndicator];
    
    [self.tabBar setBackgroundImage:[UIImage new]];
    [self.tabBar setShadowImage:[UIImage new]];
    [self.tabBar setTranslucent:true];
    [self.tabBar setBarTintColor:[UIColor whiteColor]];
    [self.tabBar setTintColor:[Session sharedInstance].themeColor];
    
    self.blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
    self.blurView.frame = CGRectMake(0, 0, self.tabBar.frame.size.width, self.tabBar.frame.size.height);
    self.blurView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.92];
    [self.tabBar insertSubview:self.blurView atIndex:0];
    /*
    self.tabBar.layer.shadowOffset = CGSizeMake(0, -1 * (1.0 / [UIScreen mainScreen].scale));
    self.tabBar.layer.shadowRadius = 0;
    self.tabBar.layer.shadowColor = [UIColor blackColor].CGColor;
    self.tabBar.layer.shadowOpacity = 0.12f;
    self.tabBar.layer.masksToBounds = false;*/
    
    [self setupNotification];
}
- (void)setupNotification {
    self.isShowingNotification = false;
    
    self.notificationContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 0)];
    self.notificationContainer.clipsToBounds = true;
    [self.tabBar addSubview:self.notificationContainer];
    
    self.notification = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleProminent]];
    self.notification.frame = CGRectMake(0, 0, self.view.frame.size.width, 52);
    self.notification.backgroundColor = [UIColor colorWithWhite:1 alpha:0.7f];
    [self.notificationContainer insertSubview:self.notification atIndex:0];
    
    self.notificationLabel = [[UILabel alloc] initWithFrame:self.notification.bounds];
    self.notificationLabel.textAlignment = NSTextAlignmentCenter;
    self.notificationLabel.font = [UIFont systemFontOfSize:16.f weight:UIFontWeightSemibold];
    self.notificationLabel.textColor = [UIColor colorWithHue:(240/360) saturation:0.03f brightness:0.25f alpha:1];
    self.notificationLabel.text = @"Submitting verification request...";
    [self.notification.contentView addSubview:self.notificationLabel];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSLog(@"view will appear");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self addTabBarPressEffects];
    });
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.blurView.frame = CGRectMake(0, 0, self.tabBar.frame.size.width, self.tabBar.frame.size.height);
}

- (void)addTabBarPressEffects {
    UIView *tabBarItemView = [self viewForTabInTabBar:self.tabBar withIndex:self.selectedIndex];
    UIImageView *tabBarImageView = nil;
    for (UIImageView *subview in [tabBarItemView subviews]) {
        if ([subview isKindOfClass:[UIImageView class]]) {
            tabBarImageView = subview;
            break;
        }
    }
    self.tabIndicator.frame = CGRectMake(tabBarItemView.frame.origin.x + tabBarImageView.frame.origin.x, self.tabIndicator.frame.origin.y, tabBarImageView.frame.size.width, self.tabIndicator.frame.size.height);
    self.tabIndicator.center = CGPointMake(tabBarItemView.center.x, self.tabIndicator.center.y);
}

/*
- (UILabel *)createBubbleWithTitle:(NSString *)title {
    UILabel *bubble = [[UIView alloc] initwith]
}*/

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item {
    NSInteger index = [tabBar.items indexOfObject:item];
    
    UIView *tabBarItemView = [self viewForTabInTabBar:tabBar withIndex:index];
    UIImageView *tabBarImageView = nil;
    for (UIImageView *subview in [tabBarItemView subviews]) {
        if ([subview isKindOfClass:[UIImageView class]]) {
            tabBarImageView = subview;
            break;
        }
    }
    
    [UIView animateWithDuration:0.28f delay:0 usingSpringWithDamping:0.9f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.tabIndicator.frame = CGRectMake(tabBarItemView.frame.origin.x + tabBarImageView.frame.origin.x, self.tabIndicator.frame.origin.y, tabBarImageView.frame.size.width, self.tabIndicator.frame.size.height);
    } completion:^(BOOL finished) {
    }];
}

- (UIView *)viewForTabInTabBar:(UITabBar* )tabBar withIndex:(NSUInteger)index
{
    NSMutableArray *tabBarItems = [NSMutableArray arrayWithCapacity:[tabBar.items count]];
    for (UIView *view in tabBar.subviews) {
        if ([view isKindOfClass:NSClassFromString(@"UITabBarButton")] && [view respondsToSelector:@selector(frame)]) {
            // check for the selector -frame to prevent crashes in the very unlikely case that in the future
            // objects thar don't implement -frame can be subViews of an UIView
            [tabBarItems addObject:view];
        }
    }
    if ([tabBarItems count] == 0) {
        // no tabBarItems means either no UITabBarButtons were in the subView, or none responded to -frame
        // return CGRectZero to indicate that we couldn't figure out the frame
        return nil;
    }
    
    // sort by origin.x of the frame because the items are not necessarily in the correct order
    [tabBarItems sortUsingComparator:^NSComparisonResult(UIView *view1, UIView *view2) {
        if (view1.frame.origin.x < view2.frame.origin.x) {
            return NSOrderedAscending;
        }
        if (view1.frame.origin.x > view2.frame.origin.x) {
            return NSOrderedDescending;
        }
        return NSOrderedSame;
    }];
    
    UIView *retVal = nil;
    if (index < [tabBarItems count]) {
        // viewController is in a regular tab
        UIView *tabView = tabBarItems[index];
        if ([tabView respondsToSelector:@selector(frame)]) {
            retVal = tabView;
        }
    }
    else {
        // our target viewController is inside the "more" tab
        UIView *tabView = [tabBarItems lastObject];
        if ([tabView respondsToSelector:@selector(frame)]) {
            retVal = tabView;
        }
    }
    return retVal;
}

- (void)openView:(NSString *)view options:(NSDictionary *)options {
    if ([view isEqualToString:@"report_problem"]) {
        
    }
    else if ([view isEqualToString:@"create_post"]) {
        
    }
    else if ([view isEqualToString:@"bells_settings"]) {
        
    }
}

- (void)showNotificationWithText:(NSString *)text {
    if (!self.isShowingNotification) {
        self.isShowingNotification = true;
        [UIView animateWithDuration:0.25f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.notificationContainer.frame = CGRectMake(self.notificationContainer.frame.origin.x, -1 * self.notification.frame.size.height, self.notificationContainer.frame.size.width, self.notification.frame.size.height);
        } completion:nil];
    }
}
- (void)dismissNotificationWithText:(NSString *)textBeforeDismissing {
    if (self.isShowingNotification) {
        float delay = 0;
        if (textBeforeDismissing.length > 0) {
            delay = 1.2f;
            
            self.notificationLabel.text = textBeforeDismissing;
        }
        
        [UIView animateWithDuration:0.25f delay:delay options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.notificationContainer.frame = CGRectMake(self.notificationContainer.frame.origin.x, 0, self.notificationContainer.frame.size.width, 0);
        } completion:nil];
    }
}

- (void)addPillWithTitle:(NSString *)title andImage:(UIImage *)image {
    
    UIButton *pill = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width  / 2 - 78, -46 - 20, 156, 46)];
    [pill setTitle:title forState:UIControlStateNormal];
    [pill setTitleColor:[UIColor colorWithWhite:0 alpha:1] forState:UIControlStateNormal];
    [pill.titleLabel setFont:[UIFont systemFontOfSize:16.f weight:UIFontWeightBold]];
    pill.adjustsImageWhenHighlighted = false;
    [pill setImage:image forState:UIControlStateNormal];
    [pill setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 10)];
    [pill setTitleEdgeInsets:UIEdgeInsetsMake(0, 10, 0, 0)];
    pill.backgroundColor = [UIColor whiteColor];
    pill.layer.cornerRadius = pill.frame.size.height / 2;
    pill.layer.shadowOffset = CGSizeMake(0, 1);
    pill.layer.shadowRadius = 1.f;
    pill.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.06f].CGColor;
    pill.layer.shadowOpacity = 1.f;
    pill.layer.shouldRasterize = true;
    pill.layer.rasterizationScale = [[UIScreen mainScreen] scale];
    pill.layer.borderWidth = 1.f;
    pill.layer.masksToBounds = false;
    pill.layer.borderColor = [UIColor colorWithWhite:0 alpha:0.08f].CGColor;
    pill.userInteractionEnabled = true;
    CGFloat intrinsticWidth = pill.intrinsicContentSize.width + (24*2);
    pill.frame = CGRectMake(self.view.frame.size.width / 2 - intrinsticWidth / 2, pill.frame.origin.y, intrinsticWidth, pill.frame.size.height);
    [self.tabBar insertSubview:pill atIndex:0];
    
    [pill bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.25f delay:0 usingSpringWithDamping:0.8f initialSpringVelocity:0.4f options:UIViewAnimationOptionCurveEaseOut animations:^{
            pill.transform = CGAffineTransformMakeScale(0.9, 0.9);
        } completion:^(BOOL finished) {
            
        }];
    } forControlEvents:UIControlEventTouchDown];
    [pill bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.25f delay:0 usingSpringWithDamping:0.9f initialSpringVelocity:0.4f options:UIViewAnimationOptionCurveEaseOut animations:^{
            pill.transform = CGAffineTransformMakeScale(1, 1);
        } completion:^(BOOL finished) {
            
        }];
    } forControlEvents:UIControlEventTouchCancel|UIControlEventTouchDragExit];
    
    pill.center = CGPointMake(pill.center.x, self.tabBarController.tabBar.frame.size.height / 2);;
    pill.transform = CGAffineTransformMakeScale(0.6, 0.6);
    pill.alpha = 0;
    
    NSInteger index = [self.tabBar.items indexOfObject:self.tabBar.selectedItem];
    [self.pills setObject:pill forKey:[NSString stringWithFormat:@"%ld", (long)index]];
    
    [self showPillIfNeeded];
}
- (void)hidePill:(UIButton *)pill {
    if (pill == nil) {
        pill = [self presentedPill];
    }
    [UIView animateWithDuration:0.7f delay:0 usingSpringWithDamping:0.8f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseIn animations:^{
        pill.center = CGPointMake(pill.center.x, self.tabBar.frame.size.height / 2);
        pill.transform = CGAffineTransformMakeScale(0.6, 0.6);
        pill.alpha = 0;
    } completion:^(BOOL finished) {
        //        self.addPeriodButton.userInteractionEnabled = false;
    }];
}
- (void)showPill:(BOOL)withDelay {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(withDelay ? 0.4f : 0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self showPillIfNeeded];
    });
}
- (void)showPillIfNeeded {
    NSInteger index = [self.tabBar.items indexOfObject:self.tabBar.selectedItem];
    if ([self.pills objectForKey:[NSString stringWithFormat:@"%ld", (long)index]]) {
        UIButton *pill = [self currentPill];
        
        self.hasPill = true;
        
        // hdie other pills
        BOOL previousPill = [self presentedPill] != nil;
        [self hidePill:[self presentedPill]];
        
        [UIView animateWithDuration:0.6f delay:(previousPill ? 0.3f : 0) usingSpringWithDamping:0.75f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseIn animations:^{
            pill.alpha = 1;
            pill.transform = CGAffineTransformIdentity;
            pill.center = CGPointMake(pill.center.x, -68 + pill.frame.size.height / 2);
        } completion:nil];
    }
    else if (self.hasPill) {
        self.hasPill = false;
        [self hidePill:[self presentedPill]];
    }
}
- (UIButton *)currentPill {
    NSInteger index = [self.tabBar.items indexOfObject:self.tabBar.selectedItem];
    
    if ([self.pills objectForKey:[NSString stringWithFormat:@"%ld", (long)index]]) {
        NSLog(@"current pill!");
        return [self.pills objectForKey:[NSString stringWithFormat:@"%ld", (long)index]];
    }
    else {
        NSLog(@"no current pill ;(");
        return nil;
    }
}
- (UIButton *)presentedPill {
    NSArray *pillsKeys = [self.pills allKeys];
    for (int i = 0; i < [pillsKeys count]; i++) {
        UIButton *pill = self.pills[pillsKeys[i]];
        if (pill.alpha == 1) {
            NSLog(@"presented pill!");
            return pill;
        }
    }
    NSLog(@"nah no presented pill :(");
    return nil;
}

@end
