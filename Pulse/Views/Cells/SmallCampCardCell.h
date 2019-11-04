//
//  SmallCampCardCell.h
//  Pulse
//
//  Created by Austin Valleskey on 9/16/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CampCardCell.h"

NS_ASSUME_NONNULL_BEGIN

#define SMALL_CARD_HEIGHT 100

@interface SmallCampCardCell : CampCardCell

@property (nonatomic) BOOL loading;


@property (nonatomic, strong) BFAvatarView *profilePicture;

@property (nonatomic, strong) UILabel *campTitleLabel;
@property (nonatomic, strong) UILabel *campDescriptionLabel;

@property (nonatomic, strong) BFAvatarView *member1;
@property (nonatomic, strong) BFAvatarView *member2;
@property (nonatomic, strong) BFAvatarView *member3;

@property (nonatomic, strong) UILabel *membersLabel;

@end

NS_ASSUME_NONNULL_END
