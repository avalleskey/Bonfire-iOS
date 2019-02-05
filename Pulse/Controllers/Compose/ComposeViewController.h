//
//  ComposeViewController.h
//  Pulse
//
//  Created by Austin Valleskey on 12/14/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Post.h"
#import "TappableView.h"
#import "BFAvatarView.h"
#import "PrivacySelectorTableViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface ComposeViewController : UIViewController <UITextViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, PrivacySelectorDelegate, UIScrollViewDelegate>

@property (strong, nonatomic) Room *postingIn;
@property (strong, nonatomic) Post *replyingTo;
@property (strong, nonatomic) NSString *prefillMessage;
@property (strong, nonatomic) NSMutableArray *media;

@property (nonatomic) CGFloat currentKeyboardHeight;
@property (strong, nonatomic) UITextView *textView;
@property (strong, nonatomic) UIScrollView *contentScrollView;
@property (strong, nonatomic) BFAvatarView *contentAvatar;
@property (strong, nonatomic) UIScrollView *mediaScrollView;
@property (strong, nonatomic) UIStackView *mediaContainerView;

@property (strong, nonatomic) TappableView *titleView;
@property (strong, nonatomic) BFAvatarView *titleAvatar;
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UIImageView *titleCaret;

@property (strong, nonatomic) UIVisualEffectView *toolbarView;
@property (strong, nonatomic) UILabel *characterCountdownLabel;
@property (strong, nonatomic) UIButton *takePictureButton;
@property (strong, nonatomic) UIButton *choosePictureButton;

@end

NS_ASSUME_NONNULL_END
