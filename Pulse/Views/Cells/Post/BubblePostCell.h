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
#import "PostURLPreviewView.h"
#import <Messages/Messages.h>
#import <MessageUI/MessageUI.h>

#define seperator_color [UIColor colorWithWhite:0 alpha:0.04]

#define postContentOffset UIEdgeInsetsMake(12, 62, 12, 12)
#define textViewFont [UIFont preferredFontForTextStyle:UIFontTextStyleBody]

@interface BubblePostCell : UITableViewCell <UITextFieldDelegate, MFMessageComposeViewControllerDelegate>

// Determines if the cell has been created or not
@property BOOL created;
@property BOOL loading;
@property BOOL selectable;

// @property (strong) NSDictionary *theme;
@property (strong, nonatomic) Post *post;

@property (strong, nonatomic) UIImageView *sparkIndicator;
@property (strong, nonatomic) UIImageView *replyIndicator;

// Views
@property (strong, nonatomic) UIView *leftBar;
@property (strong, nonatomic) PostTextView *textView;
@property (strong, nonatomic) UIImageView *profilePicture;
@property (strong, nonatomic) UIButton *moreButton;
@property (strong, nonatomic) UIImageView *pictureView;
@property (strong, nonatomic) UILabel *nameLabel;
@property (strong, nonatomic) UILabel *dateLabel;
@property (strong, nonatomic) UIImageView *sparkedIcon;
@property (strong, nonatomic) UIButton *postDetailsButton;
@property (strong, nonatomic) PostActionsView *actionsView;
@property (strong, nonatomic) PostURLPreviewView *urlPreviewView;

@property (strong, nonatomic) UIView *lineSeparator;

@property BOOL sparked;
- (void)setSparked:(BOOL)isSparked withAnimation:(BOOL)animated;

@end
