//
//  ProfileHeaderCell.m
//  Pulse
//
//  Created by Austin Valleskey on 10/2/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UserFollowButton.h"
#import "User.h"

NS_ASSUME_NONNULL_BEGIN

@interface ProfileHeaderCell : UITableViewCell

@property (strong, nonatomic) UIImageView *profilePicture;

@property (strong, nonatomic) UIView *statsView;
@property (strong, nonatomic) UIView *statsViewTopSeparator;
@property (strong, nonatomic) UIView *statsViewMiddleSeparator;
@property (strong, nonatomic) UIButton *statActionButton;
@property (strong, nonatomic) UILabel *postsCountLabel;

@property (strong, nonatomic) UserFollowButton *followButton;

@property (strong, nonatomic) UIView *lineSeparator;
@property (strong, nonatomic) User *user;

@end

NS_ASSUME_NONNULL_END
