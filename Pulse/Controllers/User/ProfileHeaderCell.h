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
#import "BFDetailsCollectionView.h"
#import <TTTAttributedLabel/TTTAttributedLabel.h>

NS_ASSUME_NONNULL_BEGIN

// avatar macros
#define PROFILE_HEADER_AVATAR_SIZE 128
#define PROFILE_HEADER_AVATAR_BORDER_WIDTH 8
#define PROFILE_HEADER_AVATAR_BOTTOM_PADDING 6

#define PROFILE_HEADER_EDGE_INSETS UIEdgeInsetsMake(32, 24, 24, 24)

// display name macros
#define PROFILE_HEADER_DISPLAY_NAME_FONT [UIFont systemFontOfSize:26.f weight:UIFontWeightHeavy]
#define PROFILE_HEADER_DISPLAY_NAME_BOTTOM_PADDING 4
// username macros
#define PROFILE_HEADER_USERNAME_FONT [UIFont systemFontOfSize:16.f weight:UIFontWeightBold]
#define PROFILE_HEADER_USERNAME_BOTTOM_PADDING 12
// bio macros
#define PROFILE_HEADER_BIO_FONT [UIFont systemFontOfSize:16.f weight:UIFontWeightMedium]
#define PROFILE_HEADER_BIO_BOTTOM_PADDING 12
// follow button macros
#define PROFILE_HEADER_FOLLOW_BUTTON_TOP_PADDING 16

@interface ProfileHeaderCell : UITableViewCell <TTTAttributedLabelDelegate>

@property (strong, nonatomic) User *user;

@property (strong, nonatomic) BFAvatarView *profilePicture;
@property (strong, nonatomic) UIView *profilePictureContainer;

@property (nonatomic, strong) UIView *campAvatarReasonView;
@property (nonatomic, strong) UILabel *campAvatarReasonLabel;
@property (nonatomic, strong) UIImageView *campAvatarReasonImageView;

// @property (strong, nonatomic) UILabel *textLabel
// @property (strong, nonatomic) UILabel *detailTextLabel

@property (strong, nonatomic) TTTAttributedLabel *bioLabel;
@property (strong, nonatomic) BFDetailsCollectionView *detailsCollectionView;

@property (strong, nonatomic) UserFollowButton *actionButton;

@property (strong, nonatomic) UIView *lineSeparator;

+ (CGFloat)heightForUser:(User *)user isLoading:(BOOL)loading;
+ (CGFloat)heightForUser:(User *)user isLoading:(BOOL)loading showDetails:(BOOL)details showActionButton:(BOOL)actionButton;

@end

NS_ASSUME_NONNULL_END
