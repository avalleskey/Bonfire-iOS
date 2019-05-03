//
//  RoomHeaderCell.h
//  Pulse
//
//  Created by Austin Valleskey on 10/2/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Room.h"
#import "BFAvatarView.h"

NS_ASSUME_NONNULL_BEGIN

@interface InviteFriendHeaderCell : UITableViewCell

@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *descriptionLabel;

@property (nonatomic, strong) BFAvatarView *member1;
@property (nonatomic, strong) UIImageView *member2;
@property (nonatomic, strong) UIImageView *member3;
@property (nonatomic, strong) UIImageView *member4;
@property (nonatomic, strong) UIImageView *member5;
@property (nonatomic, strong) UIImageView *member6;
@property (nonatomic, strong) UIImageView *member7;

@property (nonatomic, strong) UIView *lineSeparator;

@end

NS_ASSUME_NONNULL_END
