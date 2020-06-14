//
//  MediumCampCardCell.h
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

#define MEDIUM_CARD_HEIGHT 272

@interface MediumCampCardCell : CampCardCell

@property (nonatomic, strong) UIView *campAvatarContainer;
@property (nonatomic, strong) BFAvatarView *campAvatar;
@property (nonatomic, strong) UIView *campAvatarReasonView;
@property (nonatomic, strong) UILabel *campAvatarReasonLabel;
@property (nonatomic, strong) UIImageView *campAvatarReasonImageView;

@property (nonatomic, strong) MarqueeLabel *campTitleLabel;
@property (nonatomic, strong) MarqueeLabel *campTagLabel;
@property (nonatomic, strong) UILabel *campDescriptionLabel;

@property (nonatomic, strong) UIView *membersSnaphotView;
@property (nonatomic, strong) UIButton *memberCountButton;
@property (nonatomic, strong) UIButton *shareButton;

@property (nonatomic, strong) UIImageView *backgroundImageView;

@end

NS_ASSUME_NONNULL_END
