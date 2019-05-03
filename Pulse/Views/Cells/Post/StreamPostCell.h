//
//  StreamPostCell.h
//  Pulse
//
//  Created by Austin Valleskey on 5/30/18.
//  Copyright © 2018 Hallway App. All rights reserved.
//

#import "PostCell.h"
#import "PostActionsView.h"

#define postContentOffset UIEdgeInsetsMake(10, 80, 10, 12)

@interface StreamPostCell : PostCell <UITextFieldDelegate, PostTextViewDelegate>

@property (nonatomic) BOOL includeContext;

@property (nonatomic, strong) PostActionsView *actionsView;

- (void)setSparked:(BOOL)isSparked animated:(BOOL)animated;

+ (CGFloat)heightForPost:(Post *)post;

@end
