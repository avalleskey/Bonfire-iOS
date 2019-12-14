//
//  UITabBar+Extras.h
//  Pulse
//
//  Created by Austin Valleskey on 12/12/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BFAvatarView.h"

NS_ASSUME_NONNULL_BEGIN

@interface UITabBar (Extras)

@property (nonatomic, strong) UIView *tabIndicator;
@property (nonatomic, strong) UIVisualEffectView *blurView;

@property (nonatomic, strong) BFAvatarView *currentUserAvatar;

- (UIView *)viewForTabWithIndex:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END
