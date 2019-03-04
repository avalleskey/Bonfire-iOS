//
//  PostReplySnapshotView.h
//  Pulse
//
//  Created by Austin Valleskey on 2/8/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BFAvatarView.h"
#import "Post.h"

NS_ASSUME_NONNULL_BEGIN

@interface PostReplySnapshotView : UIView

@property (strong, nonatomic) BFAvatarView *firstAvatar;
@property (strong, nonatomic) BFAvatarView *secondAvatar;
@property (strong, nonatomic) BFAvatarView *thirdAvatar;

@property (strong, nonatomic) UILabel *postPreviewLabel;

@property (strong, nonatomic) NSArray <Post *> *replies;

@end

NS_ASSUME_NONNULL_END
