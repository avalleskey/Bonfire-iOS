//
//  StreamPostCell.h
//  Pulse
//
//  Created by Austin Valleskey on 5/30/18.
//  Copyright © 2018 Hallway App. All rights reserved.
//

#import "PostCell.h"
#import "PostActionsView.h"
#import "PostContextView.h"

#define postContentOffset UIEdgeInsetsMake(12, 70, 10, 12)

@interface StreamPostCell : PostCell <UITextFieldDelegate, PostTextViewDelegate>

@property (nonatomic, strong) PostContextView *contextView;

@property (nonatomic) BOOL showContext;
@property (nonatomic) BOOL showCamptag;
@property (nonatomic) BOOL hideActions;
@property (nonatomic) BOOL minimizeLinks;

@property (nonatomic, strong) CALayer *avatarOutline;

@property (nonatomic, strong) UIView *repliesSnaphotView;
@property (nonatomic, strong) BFAvatarView *repliesSnaphotViewAvatar1;
@property (nonatomic, strong) BFAvatarView *repliesSnaphotViewAvatar2;
@property (nonatomic, strong) BFAvatarView *repliesSnaphotViewAvatar3;
@property (nonatomic, strong) UILabel *repliesSnaphotViewLabel;

@property (nonatomic, strong) PostActionsView *actionsView;

- (void)setVoted:(BOOL)isVoted animated:(BOOL)animated;

+ (CGFloat)heightForPost:(Post *)post showContext:(BOOL)showContext showActions:(BOOL)showActions minimizeLinks:(BOOL)minimizeLinks;

@end
