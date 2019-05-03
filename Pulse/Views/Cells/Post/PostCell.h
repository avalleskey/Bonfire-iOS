//
//  PostCellh.h
//  Pulse
//
//  Created by Austin Valleskey on 5/30/18.
//  Copyright © 2018 Hallway App. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Post.h"

#import "PostContextView.h"
#import "BFAvatarView.h"
#import "PostTextView.h"
#import "PostImagesView.h"
// #import "PostURLPreviewView.h"

#import <BlocksKit/BlocksKit+UIKit.h>
#import "NSDate+NVTimeAgo.h"

#import <Messages/Messages.h>
#import <MessageUI/MessageUI.h>
#import <ResponsiveLabel/ResponsiveLabel.H>

#define POST_EMOJI_SIZE_MULTIPLIER 2

@interface PostCell : UITableViewCell <UITextFieldDelegate, PostTextViewDelegate>

// Determines if the cell has been created or not
@property BOOL created;
@property BOOL loading;
@property BOOL selectable;

@property BOOL sparked;

// @property (strong) NSDictionary *theme;
@property (nonatomic, strong) Post *post;

// Views
@property (nonatomic, strong) PostContextView *contextView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic, strong) UIButton *moreButton;

@property (nonatomic, strong) PostTextView *textView;
@property (nonatomic, strong) BFAvatarView *profilePicture;
@property (nonatomic, strong) PostImagesView *imagesView;
// @property (nonatomic, strong) PostURLPreviewView *urlPreviewView;

@property (nonatomic, strong) UIView *lineSeparator;

+ (NSAttributedString *)attributedCreatorStringForPost:(Post *)post includeTimestamp:(BOOL)includeTimestamp includeContext:(BOOL)includeContext;

- (void)openPostActions;

@end
