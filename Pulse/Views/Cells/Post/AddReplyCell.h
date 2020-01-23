//
//  AddReplyCell.h
//  Pulse
//
//  Created by Austin Valleskey on 6/26/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BFAvatarView.h"
#import "Post.h"

NS_ASSUME_NONNULL_BEGIN

@interface AddReplyCell : UITableViewCell

@property (nonatomic, strong) Post *post;

@property (nonatomic, strong) BFAvatarView *profilePicture;

@property (nonatomic) NSInteger levelsDeep;
@property (nonatomic) BOOL unread;

@property (nonatomic, strong) UIButton *addReplyButton;

@property (nonatomic, strong) UIView *lineSeparator;

+ (CGFloat)height;

@end

NS_ASSUME_NONNULL_END
