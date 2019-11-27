//
//  BFPostAttachmentView.h
//  Pulse
//
//  Created by Austin Valleskey on 8/6/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "BFAttachmentView.h"
#import "PostImagesView.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "Post.h"
#import "BFAvatarView.h"

NS_ASSUME_NONNULL_BEGIN

@interface BFPostAttachmentView : BFAttachmentView <UIContextMenuInteractionDelegate>

@property (nonatomic, strong) BFAvatarView *avatarView;
@property (nonatomic, strong) UILabel *creatorLabel;
@property (nonatomic, strong) UILabel *dateLabel;

@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong) PostImagesView *imagesView;

@property (nonatomic, strong) Post *post;

+ (CGFloat)heightForPost:(Post *)post width:(CGFloat)width;

@end

NS_ASSUME_NONNULL_END
