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
#import "ExpandedPostActionsView.h"
#import "TappableView.h"

#define expandedImageHeightDefault 240

#define expandedPostContentOffset UIEdgeInsetsMake(12, 12, 0, 12)
#define expandedTextViewFont [UIFont systemFontOfSize:[UIFont preferredFontForTextStyle:UIFontTextStyleBody].pointSize+1.f weight:UIFontWeightRegular]
#define expandedActionsViewHeight 40
#define expandedActivityViewHeight 30

@interface ExpandedPostCell : PostCell <UITextFieldDelegate, PostTextViewDelegate>

// Views
@property (nonatomic, strong) TappableView *creatorView;
@property (nonatomic, strong) UILabel *creatorTitleLabel;
@property (nonatomic, strong) UILabel *creatorTagLabel;

@property (nonatomic, strong) UIButton *replyingToButton;

@property (nonatomic, strong) UIImageView *postedInArrow;
@property (nonatomic, strong) UIButton *postedInButton;

@property (nonatomic, strong) ExpandedPostActionsView *actionsView;
@property (nonatomic, strong) PostActivityView *activityView;

- (void)setVoted:(BOOL)isVoted withAnimation:(BOOL)animated;

+ (CGFloat)heightForPost:(Post *)post width:(CGFloat)contentWidth;

@end
