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

NS_ASSUME_NONNULL_BEGIN

@interface RoomHeaderCell : UITableViewCell

@property (strong, nonatomic) Room *room;

@property (strong, nonatomic) UILabel *nameLabel;
@property (strong, nonatomic) UILabel *descriptionLabel;

@property (strong, nonatomic) RoomFollowButton *followButton;

@property (strong, nonatomic) UIView *statsView;
@property (strong, nonatomic) UIView *statsViewTopSeparator;
@property (strong, nonatomic) UIView *statsViewMiddleSeparator;
@property (strong, nonatomic) UIButton *membersLabel;
@property (strong, nonatomic) UILabel *postsCountLabel;

@property (strong, nonatomic) UIView *actionsBarView;
@property (strong, nonatomic) UIView *membersContainer;

@property (strong, nonatomic) UIImageView *member1;
@property (strong, nonatomic) UIButton *infoButton;

@property (strong, nonatomic) UIImageView *member2;
@property (strong, nonatomic) UIImageView *member3;
@property (strong, nonatomic) UIImageView *member4;
@property (strong, nonatomic) UIImageView *member5;
@property (strong, nonatomic) UIImageView *member6;
@property (strong, nonatomic) UIImageView *member7;

@property (strong, nonatomic) UIView *lineSeparator;

@end

NS_ASSUME_NONNULL_END
