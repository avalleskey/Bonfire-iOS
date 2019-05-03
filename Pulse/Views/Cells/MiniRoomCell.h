//
//  MiniRoomCell.h
//  Pulse
//
//  Created by Austin Valleskey on 12/22/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BFAvatarView.h"

NS_ASSUME_NONNULL_BEGIN

@interface MiniRoomCell : UICollectionViewCell

@property (nonatomic) BOOL loading;
@property (nonatomic) BOOL updates;

@property (nonatomic, strong) BFAvatarView *roomPicture;
@property (nonatomic, strong) UILabel *roomTitleLabel;

@property (nonatomic, strong) UIImageView *updatesDotView;

@end

NS_ASSUME_NONNULL_END
