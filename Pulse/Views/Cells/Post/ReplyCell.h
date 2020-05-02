//
//  StreamPostCell.h
//  Pulse
//
//  Created by Austin Valleskey on 5/30/18.
//  Copyright © 2018 Hallway App. All rights reserved.
//

#import "PostCell.h"
#import "PostActionsView.h"

#define replyTextViewFont textViewFont
#define replyNameLabelFont [UIFont systemFontOfSize:replyTextViewFont.pointSize-2.f weight:UIFontWeightSemibold]
#define REPLY_BUBBLE_INSETS UIEdgeInsetsMake(roundf(replyTextViewFont.pointSize*.5), roundf(replyTextViewFont.pointSize*.65), roundf(replyTextViewFont.pointSize*.4), roundf(replyTextViewFont.pointSize*.65))
#define REPLY_NAME_BOTTOM_PADDING 3
#define replyContentOffset UIEdgeInsetsMake(4, 10, 4, 10)

@interface ReplyCell : PostCell <UITextFieldDelegate, PostTextViewDelegate>

// @property (nonatomic, strong) PostActionsView *actionsView;

@property (nonatomic) NSInteger levelsDeep;

@property (nonatomic, strong) UIButton *topLevelReplyButton;
@property (nonatomic, strong) UIButton *repliesButton;

+ (CGFloat)avatarSizeForLevel:(NSInteger)level;
+ (CGFloat)avatarPaddingForLevel:(NSInteger)level;
+ (UIEdgeInsets)edgeInsetsForLevel:(NSInteger)level;
+ (UIEdgeInsets)contentEdgeInsetsForLevel:(NSInteger)level;

+ (CGFloat)heightForPost:(Post *)post levelsDeep:(NSInteger)levelsDeep;

@end
