//
//  MiniAvatarCell.h
//  Pulse
//
//  Created by Austin Valleskey on 12/22/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BFAvatarView.h"

NS_ASSUME_NONNULL_BEGIN

#define MINI_CARD_HEIGHT 100

@interface MiniAvatarCell : UICollectionViewCell

@property (nonatomic) BOOL loading;
@property (nonatomic) BOOL updates;

@property (nonatomic, strong) BFAvatarView *campAvatar;
@property (nonatomic, strong) UILabel *campTitleLabel;

@property (nonatomic, strong) UIImageView *updatesDotView;

@end

NS_ASSUME_NONNULL_END
