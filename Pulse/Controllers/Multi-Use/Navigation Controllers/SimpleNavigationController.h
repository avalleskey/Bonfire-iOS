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
    SNActionTypeBack = 6,
    SNActionTypeShare = 7,
    SNActionTypeDone = 8,
    SNActionTypeSettings = 9
} SNActionType;
- (void)setLeftAction:(SNActionType)actionType;
- (void)setRightAction:(SNActionType)actionType;

- (void)setShadowVisibility:(BOOL)visible withAnimation:(BOOL)animated;
- (void)hideBottomHairline;
- (void)showBottomHairline;

- (void)updateBarColor:(id)background;

@property (nonatomic, strong) UIColor *currentTheme;

@end

NS_ASSUME_NONNULL_END
