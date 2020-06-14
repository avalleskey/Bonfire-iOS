//
//  SmallMediumCampCardCell.h
//  Pulse
//
//  Created by Austin Valleskey on 9/16/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CampCardCell.h"
#import "BFDetailsCollectionView.h"
#import <MarqueeLabel/MarqueeLabel.h>

NS_ASSUME_NONNULL_BEGIN

#define SMALL_MEDIUM_CARD_HEIGHT 158

@interface SmallMediumCampCardCell : CampCardCell

@property (nonatomic, strong) UIView *campAvatarContainer;
@property (nonatomic, strong) BFAvatarView *campAvatar;
@property (nonatomic, strong) UIView *campAvatarReasonView;
@property (nonatomic, strong) UILabel *campAvatarReasonLabel;
@property (nonatomic, strong) UIImageView *campAvatarReasonImageView;

@property (nonatomic, strong) MarqueeLabel *campTitleLabel;
@property (nonatomic, strong) MarqueeLabel *campTagLabel;

@property (nonatomic, strong) UIView *membersSnaphotView;
@property (nonatomic, strong) BFAvatarView *membersSnaphotViewAvatar1;
@property (nonatomic, strong) BFAvatarView *membersSnaphotViewAvatar2;
@property (nonatomic, strong) BFAvatarView *membersSnaphotViewAvatar3;
@property (nonatomic, strong) UILabel *membersSnaphotViewLabel;

@property (nonatomic, strong) UIButton *shareButton;

@property (nonatomic) BOOL tapToJoin;
@property (nonatomic) BOOL joined;
- (void)setJoined:(BOOL)joined animated:(BOOL)animated;

@property (nonatomic, strong) UIImageView *backgroundImageView;

@end

NS_ASSUME_NONNULL_END
