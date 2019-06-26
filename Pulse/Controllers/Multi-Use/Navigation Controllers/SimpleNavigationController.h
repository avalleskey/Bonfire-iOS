//
//  SimpleNavigationController.h
//  Pulse
//
//  Created by Austin Valleskey on 11/29/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BFAvatarView.h"

NS_ASSUME_NONNULL_BEGIN

@interface SimpleNavigationController : UINavigationController

typedef enum {
    SNActionTypeNone,
    SNActionTypeProfile,
    SNActionTypeCancel,
    SNActionTypeCompose,
    SNActionTypeInvite,
    SNActionTypeMore,
    SNActionTypeAdd,
    SNActionTypeBack,
    SNActionTypeShare,
    SNActionTypeDone,
    SNActionTypeSettings,
    SNActionTypeSearch
} SNActionType;
- (void)setLeftAction:(SNActionType)actionType;
- (void)setRightAction:(SNActionType)actionType;

- (void)setShadowVisibility:(BOOL)visible withAnimation:(BOOL)animated;
- (void)hideBottomHairline;
- (void)showBottomHairline;

- (void)updateBarColor:(id)background animated:(BOOL)animated;

@property (nonatomic, strong) UIColor *currentTheme;

// custom navigation bar views
@property (nonatomic, strong) UILabel *titleLabel;

@end

NS_ASSUME_NONNULL_END
