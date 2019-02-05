//
//  BubblePostCell.h
//  Pulse
//
//  Created by Austin Valleskey on 5/30/18.
//  Copyright © 2018 Hallway App. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIImageView+WebCache.h"
#import <BlocksKit/BlocksKit+UIKit.h>
#import "NSDate+NVTimeAgo.h"
#import "Post.h"
#import "PostTextView.h"
#import "PostImagesView.h"
#import "PostSurveyView.h"
#import "PostActionsView.h"
#import <Messages/Messages.h>
#import <MessageUI/MessageUI.h>
#import <ResponsiveLabel/ResponsiveLabel.H>
#import "BFAvatarView.h"
#import "PostContextView.h"

#define seperator_color [UIColor colorWithWhite:0 alpha:0.04]

#define postContentOffset UIEdgeInsetsMake(10, 68, 10, 12)
#define replyContentOffset UIEdgeInsetsMake(postContentOffset.top, postContentOffset.left + 38, postContentOffset.bottom, postContentOffset.right)
#define postTextViewInset UIEdgeInsetsMake(6, 10, 6, 10)

@interface BubblePostCell : UITableViewCell <UITextFieldDelegate, PostTextViewDelegate>

typedef enum {
    SparkAnimationTypeNone = 0,
    SparkAnimationTypeButton = 1,
    SparkAnimationTypeRipple = 2,
    SparkAnimationTypeAll = 3
} SparkAnimationType;

// Determines if the cell has been created or not
@property BOOL created;
@property BOOL loading;
@property BOOL selectable;

// @property (strong) NSDictionary *theme;
@property (strong, nonatomic) Post *post;

- (BOOL)isReply; // automatically set
@property (nonatomic) BOOL themed; // needs to be manually set. defaults to grey bubblew with black text
@property (nonatomic) BOOL threaded;

// Views
@property (strong, nonatomic) PostContextView *contextView;
@property (strong, nonatomic) PostTextView *textView;
@property (strong, nonatomic) BFAvatarView *profilePicture;
@property (strong, nonatomic) UIImageView *pictureView;
@property (strong, nonatomic) UILabel *nameLabel;
@property (strong, nonatomic) UIButton *postedInButton;

@property (strong, nonatomic) UIView *repliesSnapshotView;
@property (strong, nonatomic) BFAvatarView *repliesSnapshotAvatar;
@property (strong, nonatomic) UILabel *repliesSnapshotLabel;

// @property (strong, nonatomic) PostURLPreviewView *urlPreviewView;

@property (strong, nonatomic) UIView *detailsView;
@property (strong, nonatomic) UILabel *detailDateLabel;
@property (strong, nonatomic) UIButton *detailSparkButton;
@property (strong, nonatomic) UIButton *detailReplyButton;

@property (strong, nonatomic) UIView *lineSeparator;

@property BOOL sparked;
- (void)setSparked:(BOOL)isSparked withAnimation:(SparkAnimationType)animationType;

+ (NSAttributedString *)attributedCreatorStringForPost:(Post *)post;

@end
