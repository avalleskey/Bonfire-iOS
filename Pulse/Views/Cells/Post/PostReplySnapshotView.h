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

@property (nonatomic, strong) BFAvatarView *firstAvatar;
@property (nonatomic, strong) BFAvatarView *secondAvatar;
@property (nonatomic, strong) BFAvatarView *thirdAvatar;

@property (nonatomic, strong) UILabel *postPreviewLabel;

@property (nonatomic, strong) NSArray <Post *> *replies;

@end

NS_ASSUME_NONNULL_END
