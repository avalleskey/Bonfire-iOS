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

#define UIViewParentController(__view) ({ \
    UIResponder *__responder = __view; \
    while ([__responder isKindOfClass:[UIView class]]) \
    __responder = [__responder nextResponder]; \
    (UIViewController *)__responder; \
    })

#define expandedImageHeightDefault 180

#define expandedPostContentOffset UIEdgeInsetsMake(17, 12, 0, 12)
#define expandedTextViewFont [UIFont systemFontOfSize:20.f weight:UIFontWeightRegular]
#define expandedActionsViewHeight 44

@interface ExpandedPostCell : UITableViewCell <UITextFieldDelegate>

// Determines if the cell has been created or not
@property BOOL created;
@property BOOL loading;

// @property (strong) NSDictionary *theme;
@property (strong, nonatomic) Post *post;

// Views
@property (strong, nonatomic) UIView *leftBar;
@property (strong, nonatomic) PostTextView *textView;
@property (strong, nonatomic) UIImageView *profilePicture;
@property (strong, nonatomic) UILabel *dateLabel;
@property (strong, nonatomic) UIImageView *pictureView;
@property (strong, nonatomic) UILabel *nameLabel;
@property (strong, nonatomic) PostActionsView *actionsView;

@property (strong, nonatomic) UIView *lineSeparator;

@property BOOL sparked;
- (void)setSparked:(BOOL)isSparked withAnimation:(BOOL)animated;

@end
