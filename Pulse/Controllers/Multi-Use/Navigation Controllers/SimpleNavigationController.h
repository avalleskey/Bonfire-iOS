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
    SNActionTypeCancel = 0,
    SNACtionTypeCompose = 1,
    SNACtionTypeInvite = 2,
    SNACtionTypeMore = 3,
    SNACtionTypeAdd = 4
} SNActionType;
- (void)setLeftAction:(SNActionType)actionType;
- (void)setRightAction:(SNActionType)actionType;

@property (strong, nonatomic) UIVisualEffectView *blurView;
@property (strong, nonatomic) UIView *hairline;

- (void)hide:(BOOL)animated;
- (void)show:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
