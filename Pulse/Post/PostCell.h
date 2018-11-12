//
//  PostCell.h
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

#define postImageHeight 140
#define seperator_color [UIColor colorWithWhite:0 alpha:0.04]

#define _postContentOffset UIEdgeInsetsMake(10, 62, 10, 12)
#define _textViewFont [UIFont systemFontOfSize:18.f weight:UIFontWeightRegular]

@interface PostCell : UITableViewCell <UITextFieldDelegate>

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

@property (strong, nonatomic) UIView *lineSeparator;

@property BOOL sparked;
- (void)setSparked:(BOOL)isSparked withAnimation:(BOOL)animated;

@end
