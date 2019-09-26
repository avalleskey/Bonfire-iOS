//
//  PostTextView.h
//  Pulse
//
//  Created by Austin Valleskey on 9/20/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <TTTAttributedLabel/TTTAttributedLabel.h>
#import "Post.h"

#define kDefaultBubbleBackgroundColor [UIColor colorWithRed:0.89 green:0.89 blue:0.92 alpha:1.00]
#define textViewFont [UIFont systemFontOfSize:18.f weight:UIFontWeightRegular]
#define postTextViewInset UIEdgeInsetsZero

NS_ASSUME_NONNULL_BEGIN

@class PostTextView;

@protocol PostTextViewDelegate <NSObject>

@optional
- (void)postTextViewDidDoubleTap:(PostTextView *)postTextView;

@end

@interface PostTextView : UIView <UITextViewDelegate, TTTAttributedLabelDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) TTTAttributedLabel *messageLabel;

@property (nonatomic, strong) NSString *message;
@property (nonatomic, strong) NSArray <PostEntity *> <PostEntity> *entities;

// we use a combined setter to ensure that message and entities are both current when setting the text and updating its links
- (void)setMessage:(NSString *)message entities:(NSArray<PostEntity *><PostEntity> *)entities;

@property (nonatomic) UIEdgeInsets edgeInsets;

@property (nonatomic, strong) NSString *postId;

@property (nonatomic, assign) NSInteger maxCharacters;
@property (nonatomic, assign) NSInteger entityBasedMaxCharacters;
+ (NSInteger)entityBasedMaxCharactersForMessage:(NSString *)message maxCharacters:(NSInteger)maxCharacters entities:(NSArray <PostEntity *> <PostEntity> *)entities;

- (void)update;

+ (CGSize)sizeOfBubbleWithMessage:(NSString *)message withConstraints:(CGSize)constraints font:(UIFont *)font maxCharacters:(CGFloat)maxCharacters;

@property (nonatomic, weak, nullable) id <PostTextViewDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
