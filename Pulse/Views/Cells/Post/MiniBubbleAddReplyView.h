//
//  MiniBubbleAddReplyView.h
//  Pulse
//
//  Created by Austin Valleskey on 1/5/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BFAvatarView.h"

NS_ASSUME_NONNULL_BEGIN

@interface MiniBubbleAddReplyView : UIView

@property (strong, nonatomic) BFAvatarView *profilePicture;

@property (strong, nonatomic) UIView *messageBubble;
@property (strong, nonatomic) UILabel *messageBubbleText;

@end

NS_ASSUME_NONNULL_END
