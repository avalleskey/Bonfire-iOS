//
//  ChannelCell.h
//  Pulse
//
//  Created by Austin Valleskey on 9/16/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Room.h"
#import <SDWebImage/UIImageView+WebCache.h>

NS_ASSUME_NONNULL_BEGIN

@interface MiniChannelCell : UICollectionViewCell

@property (nonatomic, strong) Room *room;
@property (nonatomic, strong) UIImageView *profilePicture;
@property (nonatomic, strong) UILabel *title;

@property (nonatomic, strong) UIButton *ticker;
@property (nonatomic, strong) UIView *tickerPulse;

@property (nonatomic, strong) UIView *membersView;
@property (nonatomic, strong) UILabel *andMoreLabel;

@end

NS_ASSUME_NONNULL_END
