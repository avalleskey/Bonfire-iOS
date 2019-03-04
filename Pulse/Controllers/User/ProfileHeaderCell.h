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
#import "BFAvatarView.h"
#import "BFDetailsLabel.h"

NS_ASSUME_NONNULL_BEGIN

// mock data
#define PROFILE_HEADER_MOCK_BIO true
#define PROFILE_HEADER_BIO_SAMPLE_TEXT @"Working on something new. Prev. Design Intern @cashapp, Designer @gifscom, Creator of Impossible Rush (1m+ downloads)."

#define PROFILE_HEADER_EDGE_INSETS UIEdgeInsetsMake(24, 24, 24, 24)
// avatar macros
#define PROFILE_HEADER_AVATAR_SIZE 96
#define PROFILE_HEADER_AVATAR_BOTTOM_PADDING 12
// display name macros
#define PROFILE_HEADER_DISPLAY_NAME_FONT [UIFont systemFontOfSize:30.f weight:UIFontWeightHeavy]
#define PROFILE_HEADER_DISPLAY_NAME_BOTTOM_PADDING 4
// username macros
#define PROFILE_HEADER_USERNAME_FONT [UIFont systemFontOfSize:16.f weight:UIFontWeightHeavy]
#define PROFILE_HEADER_USERNAME_BOTTOM_PADDING 10
// bio macros
#define PROFILE_HEADER_BIO_FONT [UIFont systemFontOfSize:13.f weight:UIFontWeightMedium]
#define PROFILE_HEADER_BIO_BOTTOM_PADDING 0
// details macros
#define PROFILE_HEADER_DETAILS_EDGE_INSETS UIEdgeInsetsMake(12, 24, 12, 24)
// follow button macros
#define PROFILE_HEADER_FOLLOW_BUTTON_TOP_PADDING 16

@interface ProfileHeaderCell : UITableViewCell

@property (strong, nonatomic) User *user;


@property (strong, nonatomic) BFAvatarView *profilePicture;
@property (strong, nonatomic) UIButton *followingButton;
@property (strong, nonatomic) UIButton *campsButton;

// @property (strong, nonatomic) UILabel *textLabel
// @property (strong, nonatomic) UILabel *detailTextLabel

@property (strong, nonatomic) UILabel *bioLabel;
@property (strong, nonatomic) BFDetailsLabel *detailsLabel;

@property (strong, nonatomic) UserFollowButton *followButton;

@property (strong, nonatomic) UIView *lineSeparator;

@end

NS_ASSUME_NONNULL_END
