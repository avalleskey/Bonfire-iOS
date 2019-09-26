//
//  StreamPostCell.h
//  Pulse
//
//  Created by Austin Valleskey on 5/30/18.
//  Copyright © 2018 Hallway App. All rights reserved.
//

#import "PostCell.h"
#import "PostActionsView.h"

#define replyContentOffset UIEdgeInsetsMake(10, 114, 8, 12)
#define replyTextViewFont [UIFont systemFontOfSize:textViewFont.pointSize-1.f weight:UIFontWeightRegular]

@interface ReplyCell : PostCell <UITextFieldDelegate, PostTextViewDelegate>

// @property (nonatomic, strong) PostActionsView *actionsView;

@property (nonatomic, strong) UIView *topLine;
@property (nonatomic, strong) UIView *bottomLine;

@property (nonatomic) BOOL topCell;
@property (nonatomic) BOOL bottomCell;

+ (CGFloat)heightForPost:(Post *)post;

@end
