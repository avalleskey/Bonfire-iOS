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

@interface ComposeInputView : UIVisualEffectView <UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate> {
    BOOL _active;
}
    
@property (strong, nonatomic) Post *post;

@property (strong, nonatomic) UIButton *addMediaButton;
@property (strong, nonatomic) UITextView *textView;

@property (strong, nonatomic) UIButton *postButton;

@property (strong, nonatomic) UIViewController *parentViewController;

- (void)removeImageAtIndex:(NSInteger)index;
- (void)hideMediaTray;
@property (strong, nonatomic) NSMutableArray *media;
@property (strong, nonatomic) UIView *mediaLineSeparator;
@property (strong, nonatomic) UIScrollView *mediaScrollView;
@property (strong, nonatomic) UIStackView *mediaContainerView;

- (void)setActive:(BOOL)isActive;
- (BOOL)isActive;

- (void)resize:(BOOL)aniamted;

- (void)showPostButton;
- (void)hidePostButton;

- (void)updatePlaceholders;


@end
