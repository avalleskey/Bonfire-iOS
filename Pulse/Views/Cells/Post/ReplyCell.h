//
//  StreamPostCell.h
//  Pulse
//
//  Created by Austin Valleskey on 5/30/18.
//  Copyright © 2018 Hallway App. All rights reserved.
//

#import "PostCell.h"
#import "PostActionsView.h"

#define replyTextViewFont [UIFont systemFontOfSize:textViewFont.pointSize+1.f weight:UIFontWeightRegular]
#define REPLY_BUBBLE_INSETS UIEdgeInsetsMake(replyTextViewFont.pointSize*.4, replyTextViewFont.pointSize*.65, replyTextViewFont.pointSize*.4, replyTextViewFont.pointSize*.65)
#define replyContentOffset UIEdgeInsetsMake(0, 12, ceilf(replyTextViewFont.pointSize*.6), 12)

@interface ReplyCell : PostCell <UITextFieldDelegate, PostTextViewDelegate>

// @property (nonatomic, strong) PostActionsView *actionsView;

@property (nonatomic) NSInteger levelsDeep;

@property (nonatomic, strong) UIView *bubbleBackgroundView;
@property (nonatomic, strong) UIView *bubbleBackgroundDot1;
@property (nonatomic, strong) UIView *bubbleBackgroundDot2;

@property (nonatomic, strong) UIButton *topLevelReplyButton;

+ (CGFloat)avatarSizeForLevel:(NSInteger)level;
+ (CGFloat)avatarPaddingForLevel:(NSInteger)level;
+ (UIEdgeInsets)edgeInsetsForLevel:(NSInteger)level;
+ (UIEdgeInsets)contentEdgeInsetsForLevel:(NSInteger)level;

+ (CGFloat)heightForPost:(Post *)post levelsDeep:(NSInteger)levelsDeep;

@end
