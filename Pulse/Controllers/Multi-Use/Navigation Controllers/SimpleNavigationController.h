//
//  SimpleNavigationController.h
//  Pulse
//
//  Created by Austin Valleskey on 11/29/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SloppySwiper.h"
#import "BFAvatarView.h"

NS_ASSUME_NONNULL_BEGIN

@interface SimpleNavigationController : UINavigationController <SloppySwiperDelegate>

typedef enum {
    SNActionTypeNone,
    SNActionTypeProfile,
    SNActionTypeCancel,
    SNActionTypeCompose,
    SNActionTypeInvite,
    SNActionTypeMore,
    SNActionTypeAdd,
    SNActionTypeCreateCamp,
    SNActionTypeBack,
    SNActionTypeShare,
    SNActionTypeDone,
    SNActionTypeSettings,
    SNActionTypeSearch,
    SNActionTypeCamptag
} SNActionType;
- (void)setLeftAction:(SNActionType)actionType;
- (void)setRightAction:(SNActionType)actionType;

@property (nonatomic, strong) UIView *leftActionView;
@property (nonatomic, strong) UIView *rightActionView;

@property (nonatomic, strong) SloppySwiper *swiper;

- (void)setShadowVisibility:(BOOL)visible withAnimation:(BOOL)animated;
- (void)hideBottomHairline;
- (void)showBottomHairline;
@property (nonatomic, strong) UIView *bottomHairline;

- (void)updateBarColor:(id)background animated:(BOOL)animated;

@property (nonatomic, strong) UIColor *currentTheme;

// custom navigation bar views
@property (nonatomic, strong) UILabel *titleLabel;

@end

NS_ASSUME_NONNULL_END
