//
//  EmptyChannelCell.h
//  Pulse
//
//  Created by Austin Valleskey on 10/5/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface EmptyChannelCell : UICollectionViewCell

@property (strong, nonatomic) UIView *container;

@property (strong, nonatomic) UIImageView *circleImageView;
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UILabel *descriptionLabel;

@end

NS_ASSUME_NONNULL_END
