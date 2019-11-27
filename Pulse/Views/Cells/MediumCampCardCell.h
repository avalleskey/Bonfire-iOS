//
//  MediumCampCardCell
//  Pulse
//
//  Created by Austin Valleskey on 9/16/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CampCardCell.h"
#import "BFDetailsCollectionView.h"

NS_ASSUME_NONNULL_BEGIN

#define MEDIUM_CARD_HEIGHT 296

@interface MediumCampCardCell : CampCardCell

@property (nonatomic, strong) UIView *campHeaderView;

@property (nonatomic, strong) UIView *campAvatarContainer;
@property (nonatomic, strong) BFAvatarView *campAvatar;
@property (nonatomic, strong) UIView *campAvatarReasonView;
@property (nonatomic, strong) UILabel *campAvatarReasonLabel;
@property (nonatomic, strong) UIImageView *campAvatarReasonImageView;

@property (nonatomic, strong) BFAvatarView *member1;
@property (nonatomic, strong) BFAvatarView *member2;
@property (nonatomic, strong) BFAvatarView *member3;
@property (nonatomic, strong) BFAvatarView *member4;

@property (nonatomic, strong) UILabel *campTitleLabel;
@property (nonatomic, strong) UILabel *campTagLabel;
@property (nonatomic, strong) UILabel *campDescriptionLabel;

@property (nonatomic, strong) BFDetailsCollectionView *detailsCollectionView;

@end

NS_ASSUME_NONNULL_END
