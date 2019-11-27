//
//  BotHeaderCell.m
//  Pulse
//
//  Created by Austin Valleskey on 10/2/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UserFollowButton.h"
#import "Bot.h"
#import "BFAvatarView.h"
#import "BFDetailsCollectionView.h"
#import <TTTAttributedLabel/TTTAttributedLabel.h>

NS_ASSUME_NONNULL_BEGIN

// mock data
#define BOT_HEADER_MOCK_BIO true

// avatar macros
#define BOT_HEADER_AVATAR_SIZE 128
#define BOT_HEADER_AVATAR_BOTTOM_PADDING 16

#define BOT_HEADER_EDGE_INSETS UIEdgeInsetsMake(BOT_HEADER_AVATAR_SIZE * -0.65, 24, 24, 24)

// display name macros
#define BOT_HEADER_DISPLAY_NAME_FONT [UIFont systemFontOfSize:24.f weight:UIFontWeightHeavy]
#define BOT_HEADER_DISPLAY_NAME_BOTTOM_PADDING 4
// username macros
#define BOT_HEADER_USERNAME_FONT [UIFont systemFontOfSize:16.f weight:UIFontWeightBold]
#define BOT_HEADER_USERNAME_BOTTOM_PADDING 10
// bio macros
#define BOT_HEADER_BIO_FONT [UIFont systemFontOfSize:16.f weight:UIFontWeightMedium]
#define BOT_HEADER_BIO_BOTTOM_PADDING 0
// details macros
#define BOT_HEADER_DETAILS_EDGE_INSETS UIEdgeInsetsMake(12, 24, 10, 24)
// follow button macros
#define BOT_HEADER_FOLLOW_BUTTON_TOP_PADDING 16

@interface BotHeaderCell : UITableViewCell <TTTAttributedLabelDelegate>

@property (strong, nonatomic) Bot *bot;

@property (strong, nonatomic) BFAvatarView *profilePicture;
@property (strong, nonatomic) UIView *profilePictureContainer;

@property (strong, nonatomic) TTTAttributedLabel *bioLabel;
@property (strong, nonatomic) BFDetailsCollectionView *detailsCollectionView;

@property (strong, nonatomic) UserFollowButton *followButton;

@property (strong, nonatomic) UIView *lineSeparator;

+ (CGFloat)heightForBot:(Bot *)bot isLoading:(BOOL)loading;

@end

NS_ASSUME_NONNULL_END
