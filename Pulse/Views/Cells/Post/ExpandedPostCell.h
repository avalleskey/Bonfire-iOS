//
//  ExpandedPostCell.h
//  Hallway App
//
//  Created by Austin Valleskey on 5/30/18.
//  Copyright © 2018 Hallway App. All rights reserved.
//

#import "PostCell.h"
#import <UIKit/UIKit.h>
#import "UIImageView+WebCache.h"

#import <BlocksKit/BlocksKit+UIKit.h>
#import <ResponsiveLabel/ResponsiveLabel.h>
#import "BFAvatarView.h"
#import "PostActivityView.h"

#define UIViewParentController(__view) ({ \
    UIResponder *__responder = __view; \
    while ([__responder isKindOfClass:[UIView class]]) \
    __responder = [__responder nextResponder]; \
    (UIViewController *)__responder; \
    })

#define expandedImageHeightDefault 180

#define expandedPostContentOffset UIEdgeInsetsMake(12, 12, 0, 12)
#define expandedTextViewFont [UIFont systemFontOfSize:20.f weight:UIFontWeightRegular]
#define expandedActionsViewHeight 44

@interface ExpandedPostCell : PostCell <UITextFieldDelegate, PostTextViewDelegate>

// Views
@property (strong, nonatomic) UIButton *postedInButton;
@property (strong, nonatomic) UIButton *nameButton;

@property (strong, nonatomic) PostActionsView *actionsView;
@property (strong, nonatomic) PostActivityView *activityView;

@property BOOL sparked;
- (void)setSparked:(BOOL)isSparked withAnimation:(BOOL)animated;

+ (CGFloat)heightForPost:(Post *)post;

@end
