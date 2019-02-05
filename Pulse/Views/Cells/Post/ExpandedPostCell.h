//
//  ExpandedPostCell.h
//  Hallway App
//
//  Created by Austin Valleskey on 5/30/18.
//  Copyright © 2018 Hallway App. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIImageView+WebCache.h"
#import <BlocksKit/BlocksKit+UIKit.h>
#import "Post.h"
#import "PostTextView.h"
#import "PostImagesView.h"
#import "PostSurveyView.h"
#import "PostActionsView.h"
#import <ResponsiveLabel/ResponsiveLabel.h>
#import "BFAvatarView.h"

#define UIViewParentController(__view) ({ \
    UIResponder *__responder = __view; \
    while ([__responder isKindOfClass:[UIView class]]) \
    __responder = [__responder nextResponder]; \
    (UIViewController *)__responder; \
    })

#define expandedImageHeightDefault 180

#define expandedPostContentOffset UIEdgeInsetsMake(12, 12, 0, 12)
#define expandedTextViewFont [UIFont systemFontOfSize:18.f weight:UIFontWeightRegular]
#define expandedActionsViewHeight 44

@interface ExpandedPostCell : UITableViewCell <UITextFieldDelegate, PostTextViewDelegate>

// Determines if the cell has been created or not
@property BOOL created;
@property BOOL loading;

// @property (strong) NSDictionary *theme;
@property (strong, nonatomic) Post *post;

// Views
@property (strong, nonatomic) PostTextView *textView;
@property (strong, nonatomic) BFAvatarView *profilePicture;
@property (strong, nonatomic) UIButton *postedInButton;
@property (strong, nonatomic) UIImageView *pictureView;
@property (strong, nonatomic) ResponsiveLabel *nameLabel;

@property (strong, nonatomic) UILabel *detailsLabel;
@property (strong, nonatomic) PostActionsView *actionsView;

@property (strong, nonatomic) UIView *lineSeparator;

@property BOOL sparked;
- (void)setSparked:(BOOL)isSparked withAnimation:(BOOL)animated;

@end
