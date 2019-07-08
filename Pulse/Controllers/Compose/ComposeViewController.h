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
#import "ComposeTextViewCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface ComposeViewController : UIViewController <UITextViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, PrivacySelectorDelegate, UIScrollViewDelegate, UITableViewDelegate, UITableViewDataSource, ComposeTextViewCellDelegate>

@property (nonatomic, strong) Camp *postingIn;
@property (nonatomic, strong) Post *replyingTo;
@property (nonatomic, strong) NSString *prefillMessage;

@property (nonatomic) BOOL replyingToIcebreaker;

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic) CGFloat currentKeyboardHeight;

@property (nonatomic, strong) TappableView *titleView;
@property (nonatomic, strong) BFAvatarView *titleAvatar;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIImageView *titleCaret;

@property (nonatomic, strong) UIVisualEffectView *toolbarView;

@property (nonatomic, strong) UIView *toolbarButtonsContainer;
@property (nonatomic, strong) UILabel *characterCountdownLabel;
@property (nonatomic, strong) UIButton *takePictureButton;
@property (nonatomic, strong) UIButton *choosePictureButton;

@property (nonatomic, strong) UITableView *autoCompleteTableView;

@end

NS_ASSUME_NONNULL_END
