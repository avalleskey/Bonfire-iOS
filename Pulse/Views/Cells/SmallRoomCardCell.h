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

@property (strong, nonatomic) Room *room;

@property (strong, nonatomic) UIView *themeLine;
@property (strong, nonatomic) BFAvatarView *profilePicture;

@property (strong, nonatomic) UILabel *roomTitleLabel;
@property (strong, nonatomic) UILabel *roomDescriptionLabel;

@property (strong, nonatomic) BFAvatarView *member1;
@property (strong, nonatomic) BFAvatarView *member2;
@property (strong, nonatomic) BFAvatarView *member3;

@property (strong, nonatomic) UILabel *membersLabel;

@end

NS_ASSUME_NONNULL_END
