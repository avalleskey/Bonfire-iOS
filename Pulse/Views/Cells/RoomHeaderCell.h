//
//  RoomHeaderCell.h
//  Pulse
//
//  Created by Austin Valleskey on 10/2/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RoomFollowButton.h"
#import <SpriteKit/SpriteKit.h>
#import "Room.h"
#import "BFAvatarView.h"
#import "BFDetailsLabel.h"

#define ROOM_HEADER_EDGE_INSETS UIEdgeInsetsMake(24, 24, 24, 24)
// avatar macros
#define ROOM_HEADER_AVATAR_SIZE 96
#define ROOM_HEADER_AVATAR_BOTTOM_PADDING 12
// display name macros
#define ROOM_HEADER_NAME_FONT [UIFont systemFontOfSize:28.f weight:UIFontWeightBold]
#define ROOM_HEADER_NAME_BOTTOM_PADDING 4
// #Camptag macros
#define ROOM_HEADER_TAG_FONT [UIFont systemFontOfSize:14.f weight:UIFontWeightRegular]
#define ROOM_HEADER_TAG_BOTTOM_PADDING 10
// description macros
#define ROOM_HEADER_DESCRIPTION_FONT [UIFont systemFontOfSize:16.f weight:UIFontWeightRegular]
#define ROOM_HEADER_DESCRIPTION_BOTTOM_PADDING 0
// details macros
#define ROOM_HEADER_DETAILS_EDGE_INSETS UIEdgeInsetsMake(12, 24, 12, 24)
// follow button macros
#define ROOM_HEADER_FOLLOW_BUTTON_TOP_PADDING 16

NS_ASSUME_NONNULL_BEGIN

@interface RoomHeaderCell : UITableViewCell

@property (strong, nonatomic) Room *room;

@property (strong, nonatomic) BFDetailsLabel *detailsLabel;

@property (strong, nonatomic) UILabel *descriptionLabel;
@property (strong, nonatomic) RoomFollowButton *followButton;

/*
@property (strong, nonatomic) UIView *statsView;
@property (strong, nonatomic) UIView *statsViewTopSeparator;
@property (strong, nonatomic) UIView *statsViewMiddleSeparator;
@property (strong, nonatomic) UIButton *membersLabel;
@property (strong, nonatomic) UILabel *postsCountLabel;

@property (strong, nonatomic) UIView *actionsBarView;
@property (strong, nonatomic) UIView *membersContainer;*/

@property (strong, nonatomic) BFAvatarView *roomPicture;
@property (strong, nonatomic) UIButton *infoButton;

@property (strong, nonatomic) BFAvatarView *member2;
@property (strong, nonatomic) BFAvatarView *member3;
@property (strong, nonatomic) BFAvatarView *member4;
@property (strong, nonatomic) BFAvatarView *member5;
@property (strong, nonatomic) BFAvatarView *member6;
@property (strong, nonatomic) BFAvatarView *member7;

@property (strong, nonatomic) UIView *lineSeparator;

@end

NS_ASSUME_NONNULL_END
