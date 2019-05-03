//
//  StreamPostCell.h
//  Pulse
//
//  Created by Austin Valleskey on 5/30/18.
//  Copyright © 2018 Hallway App. All rights reserved.
//

#import "PostCell.h"
#import "PostActionsView.h"

#define replyContentOffset UIEdgeInsetsMake(8, 120, 8, 12)

@interface ReplyCell : PostCell <UITextFieldDelegate, PostTextViewDelegate>

@property (nonatomic, strong) PostActionsView *actionsView;

@property (nonatomic, strong) UIView *insetLine;

@property (nonatomic) BOOL topCell;
@property (nonatomic) BOOL bottomCell;

- (void)setSparked:(BOOL)isSparked animated:(BOOL)animated;

+ (CGFloat)heightForPost:(Post *)post;

@end
