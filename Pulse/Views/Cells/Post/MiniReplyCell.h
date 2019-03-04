//
//  StreamPostCell.h
//  Pulse
//
//  Created by Austin Valleskey on 5/30/18.
//  Copyright © 2018 Hallway App. All rights reserved.
//

#import "PostCell.h"

#define miniReplyContentOffset UIEdgeInsetsMake(6, 118, 6, 12)
#define miniReplyBubbleInset UIEdgeInsetsZero
#define miniReplyTextViewFont [UIFont systemFontOfSize:16.f weight:UIFontWeightRegular]

@interface MiniReplyCell : PostCell <UITextFieldDelegate, PostTextViewDelegate>

@property BOOL sparked;
- (void)setSparked:(BOOL)isSparked animated:(BOOL)animated;

+ (CGFloat)heightForPost:(Post *)post;

@end
