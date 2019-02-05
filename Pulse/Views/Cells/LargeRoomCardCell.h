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

@property (strong, nonatomic) Room *room;

@property (strong, nonatomic) UIView *roomHeaderView;

@property (strong, nonatomic) UIView *profilePictureContainerView;
@property (strong, nonatomic) BFAvatarView *profilePicture;

@property (strong, nonatomic) BFAvatarView *member1;
@property (strong, nonatomic) BFAvatarView *member2;
@property (strong, nonatomic) BFAvatarView *member3;
@property (strong, nonatomic) BFAvatarView *member4;

@property (strong, nonatomic) UILabel *roomTitleLabel;
@property (strong, nonatomic) UILabel *roomDescriptionLabel;

@property (strong, nonatomic) RoomFollowButton *followButton;

@property (strong, nonatomic) UIView *statsView;
@property (strong, nonatomic) UIView *statsViewTopSeparator;
@property (strong, nonatomic) UIView *statsViewMiddleSeparator;
@property (strong, nonatomic) UILabel *membersLabel;
@property (strong, nonatomic) UILabel *postsCountLabel;

@end

NS_ASSUME_NONNULL_END
