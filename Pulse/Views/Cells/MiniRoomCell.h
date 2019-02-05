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

@property (strong, nonatomic) BFAvatarView *roomPicture;
@property (strong, nonatomic) UILabel *roomTitleLabel;

@property (strong, nonatomic) UIImageView *updatesDotView;

@end

NS_ASSUME_NONNULL_END
