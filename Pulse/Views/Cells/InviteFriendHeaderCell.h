//
//  RoomHeaderCell.h
//  Pulse
//
//  Created by Austin Valleskey on 10/2/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Room.h"

NS_ASSUME_NONNULL_BEGIN

@interface InviteFriendHeaderCell : UITableViewCell

@property (strong, nonatomic) UILabel *nameLabel;
@property (strong, nonatomic) UILabel *descriptionLabel;

@property (strong, nonatomic) UIImageView *member1;
@property (strong, nonatomic) UIImageView *member2;
@property (strong, nonatomic) UIImageView *member3;
@property (strong, nonatomic) UIImageView *member4;
@property (strong, nonatomic) UIImageView *member5;
@property (strong, nonatomic) UIImageView *member6;
@property (strong, nonatomic) UIImageView *member7;

@property (strong, nonatomic) UIView *lineSeparator;

@end

NS_ASSUME_NONNULL_END
