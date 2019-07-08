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

#define postContentOffset UIEdgeInsetsMake(10, 70, 10, 12)

@interface StreamPostCell : PostCell <UITextFieldDelegate, PostTextViewDelegate>

@property (nonatomic, strong) PostContextView *contextView;

@property (nonatomic) BOOL showContext;
@property (nonatomic) BOOL showCamptag;
@property (nonatomic) BOOL hideActions;

@property (nonatomic, strong) PostActionsView *actionsView;
@property (nonatomic, strong) UIView *bottomLine;

- (void)setVoted:(BOOL)isVoted animated:(BOOL)animated;

+ (CGFloat)heightForPost:(Post *)post showContext:(BOOL)showContext showActions:(BOOL)showActions;

@end
