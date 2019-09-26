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
#import "BFLinkAttachmentView.h"
#import "BFCampAttachmentView.h"
#import "BFUserAttachmentView.h"
#import "BFSmartLinkAttachmentView.h"

#import <BlocksKit/BlocksKit+UIKit.h>
#import "NSDate+NVTimeAgo.h"

#import <Messages/Messages.h>
#import <MessageUI/MessageUI.h>
#import <ResponsiveLabel/ResponsiveLabel.H>
#import <UIFont+Poppins.h>

#define POST_EMOJI_SIZE_MULTIPLIER 2

@interface PostCell : UITableViewCell <UITextFieldDelegate, PostTextViewDelegate>

// Determines if the cell has been created or not
@property BOOL created;
@property BOOL loading;
@property BOOL selectable;

@property BOOL voted;

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

@property (nonatomic, strong) BFLinkAttachmentView *linkAttachmentView;
- (void)removeLinkAttachment;
- (void)initLinkAttachment;

@property (nonatomic, strong) BFSmartLinkAttachmentView *smartLinkAttachmentView;
- (void)removeSmartLinkAttachment;
- (void)initSmartLinkAttachment;

@property (nonatomic, strong) BFUserAttachmentView *userAttachmentView;
- (void)removeUserAttachment;
- (void)initUserAttachment;

@property (nonatomic, strong) BFCampAttachmentView *campAttachmentView;
- (void)removeCampAttachment;
- (void)initCampAttachment;

@property (nonatomic, strong) UIView *lineSeparator;

+ (NSAttributedString *)attributedCreatorStringForPost:(Post *)post includeTimestamp:(BOOL)includeTimestamp showCamptag:(BOOL)showCamptag;

@end
