//
//  CampCardCell.h
//  Pulse
//
//  Created by Austin Valleskey on 10/2/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Camp.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "BFAvatarView.h"

NS_ASSUME_NONNULL_BEGIN

@interface CampCardCell : UICollectionViewCell

@property (nonatomic, strong) Camp *camp;

@end

NS_ASSUME_NONNULL_END
