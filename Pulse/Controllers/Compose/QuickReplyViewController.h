//
//  QuickReplyViewController.h
//  Pulse
//
//  Created by Austin Valleskey on 2/24/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ComposeInputView.h"
#import "Post.h"

NS_ASSUME_NONNULL_BEGIN

@interface QuickReplyViewController : UIViewController <UITextViewDelegate>

@property (nonatomic, strong) UIButton *closeButton;

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) ComposeInputView *composeInputView;

@property (nonatomic, strong) Post *replyingTo;
@property (nonatomic) CGPoint fromCenter;

@property (nonatomic) CGFloat currentKeyboardHeight;

@end

NS_ASSUME_NONNULL_END
