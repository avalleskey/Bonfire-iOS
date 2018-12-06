//
//  SimpleNavigationController.h
//  Pulse
//
//  Created by Austin Valleskey on 11/29/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SimpleNavigationController : UINavigationController

typedef enum {
    SNActionTypeNone = 0,
    SNActionTypeCancel = 1,
    SNActionTypeCompose = 2,
    SNActionTypeInvite = 3,
    SNActionTypeMore = 4,
    SNActionTypeAdd = 5,
    SNActionTypeBack = 6
} SNActionType;
- (void)setLeftAction:(SNActionType)actionType;
- (void)setRightAction:(SNActionType)actionType;

@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UIView *navigationBackgroundView;
@property (strong, nonatomic) UIVisualEffectView *blurView;
@property (strong, nonatomic) UIView *hairline;

- (void)hide:(BOOL)animated;
- (void)show:(BOOL)animated;

- (void)setShadowVisibility:(BOOL)visible withAnimation:(BOOL)animation;
- (void)updateBarColor:(id)background withAnimation:(int)animationType statusBarUpdateDelay:(CGFloat)statusBarUpdateDelay;

@property (strong, nonatomic) UIColor *currentTheme;

@end

NS_ASSUME_NONNULL_END
