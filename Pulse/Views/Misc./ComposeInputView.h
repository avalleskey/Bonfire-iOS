//
//  ComposeInputView.h
//  Pulse
//
//  Created by Austin Valleskey on 9/25/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PostTextView.h"
#import "PostActionsView.h"
#import "Post.h"
#import <UITextView+Placeholder.h>
#import "TappableButton.h"
#import <FLAnimatedImage/FLAnimatedImageView.h>

@interface ComposeInputView : UIView <UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate> {
    BOOL _active;
}
    
@property (strong, nonatomic) Post *post;
@property (strong, nonatomic) Post *replyingTo;

@property (strong, nonatomic) UIView *contentView;
@property (strong, nonatomic) UIButton *addMediaButton;
@property (strong, nonatomic) UITextView *textView;

@property (strong, nonatomic) TappableButton *postButton;
@property (strong, nonatomic) UIButton *expandButton;

@property (strong, nonatomic) UIViewController *parentViewController;

@property (nonatomic) NSInteger maxImages;
- (void)removeImageAtIndex:(NSInteger)index;
- (void)hideMediaTray;
@property (strong, nonatomic) NSMutableArray *media;
@property (strong, nonatomic) UIView *mediaLineSeparator;
@property (strong, nonatomic) UIScrollView *mediaScrollView;
@property (strong, nonatomic) UIStackView *mediaContainerView;

@property (strong, nonatomic) UIButton *replyingToLabel;

- (void)setActive:(BOOL)isActive;
- (BOOL)isActive;

- (void)resize:(BOOL)aniamted;

- (void)showPostButton;
- (void)hidePostButton;

- (void)updatePlaceholders;

@end
