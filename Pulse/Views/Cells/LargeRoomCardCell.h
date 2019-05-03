//
//  LargeRoomCardCell.h
//  Pulse
//
//  Created by Austin Valleskey on 12/22/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "Room.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "RoomFollowButton.h"
#import "BFAvatarView.h"

NS_ASSUME_NONNULL_BEGIN

@interface LargeRoomCardCell : UICollectionViewCell

@property (nonatomic) BOOL loading;

@property (nonatomic, strong) Room *room;

@property (nonatomic, strong) UIView *roomHeaderView;

@property (nonatomic, strong) UIView *profilePictureContainerView;
@property (nonatomic, strong) BFAvatarView *profilePicture;

@property (nonatomic, strong) BFAvatarView *member1;
@property (nonatomic, strong) BFAvatarView *member2;
@property (nonatomic, strong) BFAvatarView *member3;
@property (nonatomic, strong) BFAvatarView *member4;

@property (nonatomic, strong) UILabel *roomTitleLabel;
@property (nonatomic, strong) UILabel *roomDescriptionLabel;

@property (nonatomic, strong) RoomFollowButton *followButton;

@property (nonatomic, strong) UIView *statsView;
@property (nonatomic, strong) UIView *statsViewTopSeparator;
@property (nonatomic, strong) UIView *statsViewMiddleSeparator;
@property (nonatomic, strong) UILabel *membersLabel;
@property (nonatomic, strong) UILabel *postsCountLabel;

@end

NS_ASSUME_NONNULL_END
