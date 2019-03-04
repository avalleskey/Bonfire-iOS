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

@interface QuickReplyViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UITextViewDelegate>

@property (strong, nonatomic) UIButton *closeButton;

@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) ComposeInputView *composeInputView;

@property (strong, nonatomic) Post *replyingTo;
@property (nonatomic) CGPoint fromCenter;

@property (nonatomic) CGFloat currentKeyboardHeight;

@end

NS_ASSUME_NONNULL_END
