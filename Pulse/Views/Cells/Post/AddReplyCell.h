//
//  AddReplyCell.h
//  Pulse
//
//  Created by Austin Valleskey on 6/26/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BFAvatarView.h"

NS_ASSUME_NONNULL_BEGIN

@interface AddReplyCell : UITableViewCell

@property (nonatomic, strong) BFAvatarView *profilePicture;

@property (nonatomic, strong) UILabel *addReplyLabel;

@property (nonatomic, strong) UIView *topLine;
@property (nonatomic, strong) UIView *lineSeparator;

+ (CGFloat)height;

@end

NS_ASSUME_NONNULL_END
