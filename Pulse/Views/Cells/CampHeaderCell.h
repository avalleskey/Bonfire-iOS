//
//  CampHeaderCell.h
//  Pulse
//
//  Created by Austin Valleskey on 10/2/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CampFollowButton.h"
#import "Camp.h"
#import "BFAvatarView.h"
#import "BFDetailsCollectionView.h"

// avatar macros
#define CAMP_HEADER_AVATAR_SIZE 128
#define CAMP_HEADER_AVATAR_BOTTOM_PADDING 16

#define CAMP_HEADER_EDGE_INSETS UIEdgeInsetsMake(ceilf(CAMP_HEADER_AVATAR_SIZE * -0.65), 24, 24, 24)
// display name macros
#define CAMP_HEADER_NAME_FONT [UIFont systemFontOfSize:26.f weight:UIFontWeightHeavy]
#define CAMP_HEADER_NAME_BOTTOM_PADDING 6
// #Camptag macros
#define CAMP_HEADER_TAG_FONT [UIFont systemFontOfSize:16.f weight:UIFontWeightBold]
#define CAMP_HEADER_TAG_BOTTOM_PADDING 12
// description macros
#define CAMP_HEADER_DESCRIPTION_FONT [UIFont systemFontOfSize:16.f weight:UIFontWeightRegular]
#define CAMP_HEADER_DESCRIPTION_BOTTOM_PADDING 16
// details macros
#define CAMP_HEADER_DETAILS_EDGE_INSETS UIEdgeInsetsMake(16, 24, 12, 24)
// follow button macros
#define CAMP_HEADER_FOLLOW_BUTTON_TOP_PADDING 16

NS_ASSUME_NONNULL_BEGIN

@interface CampHeaderCell : UITableViewCell

@property (nonatomic, strong) Camp *camp;

@property (nonatomic, strong) BFDetailsCollectionView *detailsCollectionView;

@property (nonatomic, strong) UILabel *descriptionLabel;

@property (nonatomic, strong) CampFollowButton *actionButton;
@property (strong, nonatomic) UIButton *secondaryActionButton;

@property (nonatomic, strong) BFAvatarView *campAvatar;
@property (strong, nonatomic) UIView *avatarContainer;

@property (nonatomic, strong) UIView *campAvatarReasonView;
@property (nonatomic, strong) UILabel *campAvatarReasonLabel;
@property (nonatomic, strong) UIImageView *campAvatarReasonImageView;

@property (nonatomic, strong) BFAvatarView *member2;
@property (nonatomic, strong) BFAvatarView *member3;
@property (nonatomic, strong) BFAvatarView *member4;
@property (nonatomic, strong) BFAvatarView *member5;
@property (nonatomic, strong) BFAvatarView *member6;
@property (nonatomic, strong) BFAvatarView *member7;

@property (nonatomic, strong) UIView *lineSeparator;

+ (CGFloat)heightForCamp:(Camp *)camp isLoading:(BOOL)loading;

@end

NS_ASSUME_NONNULL_END
