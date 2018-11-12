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

@property (strong, nonatomic) Room *room;
@property (strong, nonatomic) UILabel *title;

@property (strong, nonatomic) UIButton *ticker;
@property (strong, nonatomic) UIView *tickerPulse;

@property (strong, nonatomic) UIView *membersView;
@property (strong, nonatomic) UILabel *andMoreLabel;

@end

NS_ASSUME_NONNULL_END
