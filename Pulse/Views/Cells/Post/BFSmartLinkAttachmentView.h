//
//  BFSmartLinkAttachmentView.h
//  Pulse
//
//  Created by Austin Valleskey on 8/6/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "BFAttachmentView.h"
#import "PostImagesView.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "Post.h"

NS_ASSUME_NONNULL_BEGIN

@interface BFSmartLinkAttachmentView : BFAttachmentView <UIContextMenuInteractionDelegate>

@property (nonatomic, strong) SDAnimatedImageView *imageView;
@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UIImageView *sourceImageView;

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *summaryLabel;

@property (nonatomic, strong) UIButton *postedInButton;

@property (nonatomic, strong) UIView *shareLinkButtonSeparator;
@property (nonatomic, strong) UIButton *shareLinkButton;

@property (nonatomic, strong) BFLink *link;

+ (CGFloat)heightForSmartLink:(BFLink *)link width:(CGFloat)width showActionButton:(BOOL)showActionButton;

@end

NS_ASSUME_NONNULL_END
