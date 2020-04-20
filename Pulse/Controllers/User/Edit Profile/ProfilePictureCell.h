//
//  ProfilePictureCell.h
//  Pulse
//
//  Created by Austin Valleskey on 10/24/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIImageView+WebCache.h"
#import "BFAvatarView.h"

NS_ASSUME_NONNULL_BEGIN

@interface ProfilePictureCell : UITableViewCell

@property (strong, nonatomic) UIView *profilePictureContainer;
@property (strong, nonatomic) BFAvatarView *profilePicture;

@property (strong, nonatomic) UIView *editPictureImageViewContainer;
@property (strong, nonatomic) UIImageView *editPictureImageView;

@property (strong, nonatomic) UIView *editCoverPhotoImageViewContainer;
@property (strong, nonatomic) UIImageView *editCoverPhotoImageView;

+ (CGFloat)height;

@end

NS_ASSUME_NONNULL_END
