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
#define textViewFont [UIFont systemFontOfSize:[UIFont preferredFontForTextStyle:UIFontTextStyleBody].pointSize+1.f weight:UIFontWeightRegular]
#define textViewReplyFont [UIFont systemFontOfSize:[UIFont preferredFontForTextStyle:UIFontTextStyleBody].pointSize weight:UIFontWeightRegular]
#define postTextViewInset UIEdgeInsetsMake(6, 10, 6, 10)


NS_ASSUME_NONNULL_BEGIN

@class PostTextView;

@protocol PostTextViewDelegate <NSObject>

- (void)postTextViewDidDoubleTap:(PostTextView *)postTextView;

@end

@interface PostTextView : UIView <UITextViewDelegate, TTTAttributedLabelDelegate, UIGestureRecognizerDelegate>

@property (nonatomic) UIView *backgroundView;
@property (strong, nonatomic) TTTAttributedLabel *messageLabel;
@property (strong, nonatomic) UIImageView *bubbleTip;

@property (strong, nonatomic) NSString *message;

- (CGSize)messageSize;
- (void)resize;
- (void)resizeTip;

+ (void)createRoundedCornersForView:(UIView*)parentView tl:(BOOL)tl tr:(BOOL)tr br:(BOOL)br bl:(BOOL)bl;
+ (CGSize)sizeOfBubbleWithMessage:(NSString *)text withConstraints:(CGSize)constraints font:(UIFont *)font;

@property (nonatomic, weak, nullable) id <PostTextViewDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
