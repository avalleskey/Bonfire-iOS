//
//  ComposeInputView.h
//  Pulse
//
//  Created by Austin Valleskey on 9/25/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PostTextView.h"
#import "Post.h"
#import "UITextView+Placeholder.h"
#import "TappableButton.h"
#import "BFMedia.h"
#import <HapticHelper/HapticHelper.h>

@protocol ComposeInputViewDelegate <NSObject>

@optional
- (void)composeInputViewMessageDidChange:(UITextView *)textView;
- (void)composeInputViewReplyingToDidChange;

@end

@interface ComposeInputView : UIView <UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, BFMediaDelegate> {
    BOOL _active;
}
    
@property (nonatomic, strong) Post *post;
@property (nonatomic, strong) Post *replyingTo;

@property (nonatomic, strong) UIVisualEffectView *contentView;
@property (nonatomic, strong) UIButton *addMediaButton;
@property (nonatomic, strong) UITextView *textView;

@property (nonatomic, strong) TappableButton *postButton;
@property (nonatomic, strong) UIButton *expandButton;
@property (nonatomic, strong) UILabel *charRemainingLabel;

@property (nonatomic, strong) UIViewController *parentViewController;

- (void)removeImageAtIndex:(NSInteger)index;
- (void)hideMediaTray;
@property (nonatomic, strong) BFMedia *media;
@property (nonatomic, strong) UIView *mediaLineSeparator;
@property (nonatomic, strong) UIScrollView *mediaScrollView;
@property (nonatomic, strong) UIStackView *mediaContainerView;

@property (nonatomic, strong) UIButton *replyingToLabel;

@property (nonatomic, strong) UIView *autoCompleteTableViewContainer;
@property (nonatomic, strong) UITableView *autoCompleteTableView;

@property (nonatomic, strong) NSArray *mediaTypes;
@property (nonatomic, strong) NSString *defaultPlaceholder;

@property (nonatomic, strong) UIView *topSeparator;

- (void)reset;

- (void)setActive:(BOOL)isActive;
- (BOOL)isActive;

- (void)resize:(BOOL)animated;

- (void)showPostButton;
- (void)hidePostButton;

- (void)updatePlaceholders;

@property (nonatomic, weak) id <ComposeInputViewDelegate> delegate;

@end
