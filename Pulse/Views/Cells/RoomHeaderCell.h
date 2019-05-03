//
//  RoomHeaderCell.h
//  Pulse
//
//  Created by Austin Valleskey on 10/2/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RoomFollowButton.h"
#import "Room.h"
#import "BFAvatarView.h"
#import "BFDetailsCollectionView.h"

#define ROOM_HEADER_EDGE_INSETS UIEdgeInsetsMake(24, 24, 24, 24)
// avatar macros
#define ROOM_HEADER_AVATAR_SIZE 96
#define ROOM_HEADER_AVATAR_BOTTOM_PADDING 12
// display name macros
#define ROOM_HEADER_NAME_FONT [UIFont systemFontOfSize:30.f weight:UIFontWeightHeavy]
#define ROOM_HEADER_NAME_BOTTOM_PADDING 4
// #Camptag macros
#define ROOM_HEADER_TAG_FONT [UIFont systemFontOfSize:16.f weight:UIFontWeightHeavy]
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

@property (nonatomic, strong) Room *room;

@property (nonatomic, strong) BFDetailsCollectionView *detailsCollectionView;

@property (nonatomic, strong) UILabel *descriptionLabel;
@property (nonatomic, strong) RoomFollowButton *followButton;

@property (nonatomic, strong) BFAvatarView *roomPicture;
@property (nonatomic, strong) UIButton *infoButton;

@property (nonatomic, strong) BFAvatarView *member2;
@property (nonatomic, strong) BFAvatarView *member3;
@property (nonatomic, strong) BFAvatarView *member4;
@property (nonatomic, strong) BFAvatarView *member5;
@property (nonatomic, strong) BFAvatarView *member6;
@property (nonatomic, strong) BFAvatarView *member7;

@property (nonatomic, strong) UIView *lineSeparator;

@end

NS_ASSUME_NONNULL_END
