//
//  StreamPostCell.h
//  Pulse
//
//  Created by Austin Valleskey on 5/30/18.
//  Copyright © 2018 Hallway App. All rights reserved.
//

#import "PostCell.h"

#define replyContentOffset UIEdgeInsetsMake(10, 72, 6, 12)
#define replyBubbleInset UIEdgeInsetsZero
#define replyTextViewFont [UIFont systemFontOfSize:18.f weight:UIFontWeightRegular]

@interface ReplyCell : PostCell <UITextFieldDelegate, PostTextViewDelegate>

@property (strong, nonatomic) UIView *detailsView;
@property (strong, nonatomic) UIButton *detailReplyButton;
@property (strong, nonatomic) UIButton *detailSparkButton;
@property (strong, nonatomic) UIButton *detailShareButton;
@property (strong, nonatomic) UIButton *detailMoreButton;

@property BOOL sparked;
- (void)setSparked:(BOOL)isSparked animated:(BOOL)animated;

+ (CGFloat)heightForPost:(Post *)post;

@end
