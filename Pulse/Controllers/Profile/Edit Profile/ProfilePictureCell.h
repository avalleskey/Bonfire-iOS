//
//  ProfilePictureCell.h
//  Pulse
//
//  Created by Austin Valleskey on 10/24/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <UIImageView+WebCache.h>

NS_ASSUME_NONNULL_BEGIN

@interface ProfilePictureCell : UITableViewCell

@property (strong, nonatomic) UIImageView *profilePicture;
@property (strong, nonatomic) UILabel *changeProfilePictureLabel;

@end

NS_ASSUME_NONNULL_END
