//
//  LargeCampCardCell.h
//  Pulse
//
//  Created by Austin Valleskey on 12/22/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "CampCardCell.h"
#import "CampFollowButton.h"
#import "BFDetailsCollectionView.h"

NS_ASSUME_NONNULL_BEGIN

#define LARGE_CARD_HEIGHT 348

@interface LargeCampCardCell : CampCardCell

@property (nonatomic) BOOL loading;

@property (nonatomic, strong) UIView *campHeaderView;

@property (nonatomic, strong) UIView *profilePictureContainerView;
@property (nonatomic, strong) BFAvatarView *profilePicture;

@property (nonatomic, strong) BFAvatarView *member1;
@property (nonatomic, strong) BFAvatarView *member2;
@property (nonatomic, strong) BFAvatarView *member3;
@property (nonatomic, strong) BFAvatarView *member4;

@property (nonatomic, strong) UILabel *campTitleLabel;
@property (nonatomic, strong) UILabel *campTagLabel;
@property (nonatomic, strong) UILabel *campDescriptionLabel;

@property (nonatomic, strong) BFDetailsCollectionView *detailsCollectionView;
- (void)updateDetailsView;

@property (nonatomic, strong) CampFollowButton *followButton;

@end

NS_ASSUME_NONNULL_END
