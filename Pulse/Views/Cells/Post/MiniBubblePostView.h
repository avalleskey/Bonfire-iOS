//
//  MiniBubblePostView.h
//  Pulse
//
//  Created by Austin Valleskey on 1/3/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Post.h"
#import "BFAvatarView.h"

NS_ASSUME_NONNULL_BEGIN

@interface MiniBubblePostView : UIView

enum {
    MINI_BUBBLE_HEIGHT = 32,
    MINI_BUBBLE_SPACING = 8
};

@property (strong, nonatomic) Post *post;

@property (strong, nonatomic) BFAvatarView *profilePicture;

@property (strong, nonatomic) CAGradientLayer *gradientLayer;
@property (strong, nonatomic) UIView *messageBubble;
@property (strong, nonatomic) UILabel *messageBubbleText;

@end

NS_ASSUME_NONNULL_END
