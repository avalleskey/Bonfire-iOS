//
//  TabController.h
//  Hallway App
//
//  Created by Austin Valleskey on 8/20/18.
//  Copyright © 2018 Hallway App. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TabController : UITabBarController

- (void)addPillWithTitle:(NSString *)title andImage:(UIImage *)image;
- (void)hidePill:(UIButton *)pill;
- (void)showPill:(BOOL)withDelay;
- (UIButton *)currentPill;
@property (nonatomic) BOOL hasPill;

@property (nonatomic, strong) NSMutableDictionary *pills;

@property (nonatomic, strong) UIView *notificationContainer;
@property (nonatomic, strong) UIVisualEffectView *notification;
@property (nonatomic, strong) UILabel *notificationLabel;
@property (nonatomic, strong) UIView *tabIndicator;
@property (nonatomic, strong) UIVisualEffectView *blurView;
@property (nonatomic) BOOL isShowingNotification;

- (void)dismissNotificationWithText:(NSString *)textBeforeDismissing;
- (void)showNotificationWithText:(NSString *)text;

@end
