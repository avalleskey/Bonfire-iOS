//
//  BFLinkAttachmentView.h
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

@interface BFLinkAttachmentView : BFAttachmentView <UIContextMenuInteractionDelegate>

@property (nonatomic, strong) SDAnimatedImageView *imageView;
@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UIImageView *sourceImageView;

@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong) UILabel *detailTextLabel;
@property (nonatomic, strong) UILabel *sourceLabel;

@property (nonatomic, strong) BFLink *link;

typedef enum {
    BFLinkAttachmentContentTypeGeneric = 1,
    BFLinkAttachmentContentTypeImage = 2,
    BFLinkAttachmentContentTypeVideo = 3,
    BFLinkAttachmentContentTypeAudio = 4,
    // BFLinkAttachmentContentTypePost (included in future update)
} BFLinkAttachmentContentType;
@property (nonatomic) BFLinkAttachmentContentType contentType;

+ (CGFloat)heightForLink:(BFLink *)link width:(CGFloat)width;

@end

NS_ASSUME_NONNULL_END
