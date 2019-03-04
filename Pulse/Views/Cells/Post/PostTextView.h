//
//  PostTextView.h
//  Pulse
//
//  Created by Austin Valleskey on 9/20/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <TTTAttributedLabel/TTTAttributedLabel.h>

#define kDefaultBubbleBackgroundColor [UIColor colorWithRed:0.89 green:0.89 blue:0.92 alpha:1.00]
#define textViewFont [UIFont systemFontOfSize:18.f weight:UIFontWeightRegular]
#define postTextViewInset UIEdgeInsetsZero

NS_ASSUME_NONNULL_BEGIN

@class PostTextView;

@protocol PostTextViewDelegate <NSObject>

- (void)postTextViewDidDoubleTap:(PostTextView *)postTextView;

@end

@interface PostTextView : UIView <UITextViewDelegate, TTTAttributedLabelDelegate, UIGestureRecognizerDelegate>

@property (strong, nonatomic) TTTAttributedLabel *messageLabel;

@property (strong, nonatomic) NSString *message;

@property (nonatomic) UIEdgeInsets edgeInsets;

- (void)update;

+ (CGSize)sizeOfBubbleWithMessage:(NSString *)text withConstraints:(CGSize)constraints font:(UIFont *)font;

@property (nonatomic, weak, nullable) id <PostTextViewDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
