//
//  ProfileHeaderCell.m
//  Pulse
//
//  Created by Austin Valleskey on 10/2/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FollowButton.h"
#import "User.h"

NS_ASSUME_NONNULL_BEGIN

@interface ProfileHeaderCell : UITableViewCell

@property (strong, nonatomic) UIImageView *profilePicture;
@property (strong, nonatomic) FollowButton *followButton;

@property (strong, nonatomic) UIView *lineSeparator;
@property (strong, nonatomic) User *user;

@end

NS_ASSUME_NONNULL_END
