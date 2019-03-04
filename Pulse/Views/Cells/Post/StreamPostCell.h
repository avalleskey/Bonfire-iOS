//
//  StreamPostCell.h
//  Pulse
//
//  Created by Austin Valleskey on 5/30/18.
//  Copyright © 2018 Hallway App. All rights reserved.
//

#import "PostCell.h"

#define postContentOffset UIEdgeInsetsMake(14, 72, 12, 12)

@interface StreamPostCell : PostCell <UITextFieldDelegate, PostTextViewDelegate>

@property (strong, nonatomic) UIView *detailsView;
@property (strong, nonatomic) UIButton *detailReplyButton;
@property (strong, nonatomic) UIButton *detailSparkButton;
@property (strong, nonatomic) UIButton *detailShareButton;
@property (strong, nonatomic) UIButton *detailMoreButton;

@property BOOL sparked;
- (void)setSparked:(BOOL)isSparked animated:(BOOL)animated;

+ (CGFloat)heightForPost:(Post *)post;

@end
