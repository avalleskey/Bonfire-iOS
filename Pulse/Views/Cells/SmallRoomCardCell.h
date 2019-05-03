//
//  SmallRoomCardCell.h
//  Pulse
//
//  Created by Austin Valleskey on 9/16/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Room.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "RoomFollowButton.h"
#import "BFAvatarView.h"

NS_ASSUME_NONNULL_BEGIN

@interface SmallRoomCardCell : UICollectionViewCell

@property (nonatomic) BOOL loading;

@property (nonatomic, strong) Room *room;

@property (nonatomic, strong) UIView *themeLine;
@property (nonatomic, strong) BFAvatarView *profilePicture;

@property (nonatomic, strong) UILabel *roomTitleLabel;
@property (nonatomic, strong) UILabel *roomDescriptionLabel;

@property (nonatomic, strong) BFAvatarView *member1;
@property (nonatomic, strong) BFAvatarView *member2;
@property (nonatomic, strong) BFAvatarView *member3;

@property (nonatomic, strong) UILabel *membersLabel;

@end

NS_ASSUME_NONNULL_END
