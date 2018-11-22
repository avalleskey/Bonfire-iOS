//
//  ChannelCell.h
//  Pulse
//
//  Created by Austin Valleskey on 9/16/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Room.h"
#import "UIImageView+WebCache.h"
#import <Shimmer/FBShimmeringView.h>

NS_ASSUME_NONNULL_BEGIN

@interface ChannelCell : UICollectionViewCell

@property (strong, nonatomic) Room *room;
@property (strong, nonatomic) FBShimmeringView *shimmerContainer;

@property (strong, nonatomic) UIImageView *profilePicture;

@property (strong, nonatomic) UILabel *title;

@property (strong, nonatomic) UILabel *bio;

@property (strong, nonatomic) UIButton *ticker;
@property (strong, nonatomic) UIView *tickerPulse;

@property (strong, nonatomic) UIView *membersView;
@property (strong, nonatomic) UILabel *andMoreLabel;

// if threshold for live isn't met
@property (strong, nonatomic) UIButton *inviteButton;

@end

NS_ASSUME_NONNULL_END
