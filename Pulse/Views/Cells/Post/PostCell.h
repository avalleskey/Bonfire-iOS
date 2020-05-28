//
//  PostCellh.h
//  Pulse
//
//  Created by Austin Valleskey on 5/30/18.
//  Copyright © 2018 Hallway App. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Post.h"

#import "BFAvatarView.h"
#import "PostTextView.h"
#import "PostImagesView.h"

#import "BFVideoPlayerAttachmentView.h"
#import "BFLinkAttachmentView.h"
#import "BFCampAttachmentView.h"
#import "BFIdentityAttachmentView.h"
#import "BFSmartLinkAttachmentView.h"
#import "BFPostDeletedAttachmentView.h"
#import "BFPostAttachmentView.h"

#import <BlocksKit/BlocksKit+UIKit.h>
#import "NSDate+NVTimeAgo.h"

#import <ResponsiveLabel/ResponsiveLabel.H>
#import <UIFont+Poppins.h>

#define POST_EMOJI_SIZE_MULTIPLIER 2.5

NS_ASSUME_NONNULL_BEGIN

@interface PostCell : UITableViewCell <UITextFieldDelegate, PostTextViewDelegate>

// Determines if the cell has been created or not
@property BOOL created;
@property BOOL loading;
@property BOOL selectable;

@property BOOL voted;
@property BOOL unread;

// @property (strong) NSDictionary *theme;
@property (nonatomic, strong) Post *post;

// Views
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic, strong) UIButton *moreButton;

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) PostTextView *textView;

@property (nonatomic, strong) BFAvatarView *primaryAvatarView;
@property (nonatomic, strong) BFAvatarView *secondaryAvatarView;

@property (nonatomic, strong) PostImagesView *imagesView;

@property (nonatomic, strong) BFLinkAttachmentView * _Nullable linkAttachmentView;
- (void)removeLinkAttachment;
- (void)initLinkAttachment;

@property (nonatomic, strong) BFVideoPlayerAttachmentView * _Nullable videoPlayerAttachmentView;
- (void)removeVideoPlayerAttachmentView;
- (void)initVideoPlayerAttachmentView;

@property (nonatomic, strong) BFSmartLinkAttachmentView * _Nullable smartLinkAttachmentView;
- (void)removeSmartLinkAttachment;
- (void)initSmartLinkAttachment;

@property (nonatomic, strong) BFIdentityAttachmentView * _Nullable identityAttachmentView;
- (void)removeIdentityAttachment;
- (void)initIdentityAttachment;

@property (nonatomic, strong) BFCampAttachmentView * _Nullable campAttachmentView;
- (void)removeCampAttachment;
- (void)initCampAttachment;

@property (nonatomic, strong) BFPostDeletedAttachmentView * _Nullable postRemovedAttachmentView;
- (void)removePostRemovedAttachment;
- (void)initPostRemovedAttachment;

@property (nonatomic, strong) BFPostAttachmentView * _Nullable postAttachmentView;
- (void)removePostAttachment;
- (void)initPostAttachment;

@property (nonatomic, strong) UIView *lineSeparator;

+ (NSAttributedString *)attributedCreatorStringForPost:(Post *)post includeTimestamp:(BOOL)includeTimestamp showCamptag:(BOOL)showCamptag primaryColor:(UIColor * _Nullable)primaryColor;

@property (nonatomic, strong) UIView *topLine;
@property (nonatomic, strong) UIView *bottomLine;

@end

NS_ASSUME_NONNULL_END
