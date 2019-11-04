//
//  ComposeTextViewCell.h
//  Pulse
//
//  Created by Austin Valleskey on 3/19/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BFAvatarView.h"
#import "UITextView+Placeholder.h"
#import "UIImageView+WebCache.h"
#import "BFMedia.h"
#import "BFSmartLinkAttachmentView.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ComposeTextViewCellDelegate <NSObject>

- (void)mediaDidChange;

@end

@interface ComposeTextViewCell : UITableViewCell <BFMediaDelegate>

// MEDIA
@property (nonatomic, strong) BFMedia *media;
@property (nonatomic, strong) NSURL *url;

@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) BFAvatarView *creatorAvatar;
@property (nonatomic, strong) UIScrollView *mediaScrollView;
@property (nonatomic, strong) UIStackView *mediaContainerView;
@property (nonatomic, strong) BFSmartLinkAttachmentView * _Nullable smartLinkAttachmentView;

@property (nonatomic, strong) UIView *lineSeparator;

- (void)resizeTextView;

@property (nonatomic, weak) id <ComposeTextViewCellDelegate> delegate;

- (CGFloat)height;

@end

NS_ASSUME_NONNULL_END
