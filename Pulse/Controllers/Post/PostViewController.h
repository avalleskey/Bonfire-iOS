//
//  PostViewController.h
//
//
//  Created by Austin Valleskey on 9/19/18.
//

#import <UIKit/UIKit.h>
#import "ComposeInputView.h"
#import "Session.h"
#import "Post.h"
#import "ComposeInputView.h"
#import <Messages/Messages.h>
#import <MessageUI/MessageUI.h>
#import "ThemedViewController.h"
#import "PostStream.h"
#import "TappableView.h"

@interface PostViewController : ThemedViewController <ComposeInputViewDelegate, MFMessageComposeViewControllerDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) Post *parentPost;
@property (nonatomic, strong) Post *post;

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) PostStream *stream;
@property (nonatomic, strong) ComposeInputView *composeInputView;
@property (nonatomic, strong) TappableView *parentPostScrollIndicator;

@property (nonatomic) CGFloat currentKeyboardHeight;

@property (nonatomic) BOOL showKeyboardOnOpen;

@end
