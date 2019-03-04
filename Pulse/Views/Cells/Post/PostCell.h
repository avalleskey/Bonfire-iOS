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
#import "PostSurveyView.h"
#import "PostActionsView.h"

#import <BlocksKit/BlocksKit+UIKit.h>
#import "NSDate+NVTimeAgo.h"

#import <Messages/Messages.h>
#import <MessageUI/MessageUI.h>
#import <ResponsiveLabel/ResponsiveLabel.H>

@interface PostCell : UITableViewCell <UITextFieldDelegate, PostTextViewDelegate>

// Determines if the cell has been created or not
@property BOOL created;
@property BOOL loading;
@property BOOL selectable;

// @property (strong) NSDictionary *theme;
@property (strong, nonatomic) Post *post;

// Views
@property (strong, nonatomic) PostContextView *contextView;
@property (strong, nonatomic) UILabel *nameLabel;
@property (strong, nonatomic) UILabel *dateLabel;

@property (strong, nonatomic) PostTextView *textView;
@property (strong, nonatomic) BFAvatarView *profilePicture;
@property (strong, nonatomic) PostImagesView *imagesView;

// @property (strong, nonatomic) PostURLPreviewView *urlPreviewView;

@property (strong, nonatomic) UIView *lineSeparator;

+ (NSAttributedString *)attributedCreatorStringForPost:(Post *)post includeTimestamp:(BOOL)includeTimestamp includePostedIn:(BOOL)includePostedIn;

- (void)openPostActions;

@end
