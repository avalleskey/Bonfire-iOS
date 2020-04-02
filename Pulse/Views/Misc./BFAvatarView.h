//
//  BFAvatarView.h
//  Pulse
//
//  Created by Austin Valleskey on 12/15/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"
#import "Camp.h"
#import "Bot.h"

NS_ASSUME_NONNULL_BEGIN

// Macro that defines how much lighter/darker the marshmallow icon is than the profile picture background
#define BFAvatarViewIconContrast 0.4

@interface BFAvatarView : UIView <UIContextMenuInteractionDelegate>

@property (nonatomic, nullable) User *user;
@property (nonatomic, nullable) Bot *bot;
@property (nonatomic, nullable) Camp *camp;

@property (nonatomic) BOOL online;
@property (nonatomic) BOOL placeholderAvatar;

@property (nonatomic) BOOL dimsViewOnTap;
@property (nonatomic) BOOL openOnTap;
@property (nonatomic) BOOL touchDown;
@property (nonatomic) BOOL allowOnlineDot;

@property (nonatomic, strong) UIView *highlightView;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIImageView *onlineDotView;

@end

NS_ASSUME_NONNULL_END
