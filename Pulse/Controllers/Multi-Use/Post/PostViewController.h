//
//  PostViewController.h
//
//
//  Created by Austin Valleskey on 9/19/18.
//

#import <UIKit/UIKit.h>
#import "ComposeInputView.h"
#import "HAWebService.h"
#import "Session.h"
#import "RSTableView.h"
#import "Post.h"
#import "ComposeInputView.h"
#import <Messages/Messages.h>
#import <MessageUI/MessageUI.h>
#import "ThemedViewController.h"

@interface PostViewController : ThemedViewController <UITextViewDelegate, MFMessageComposeViewControllerDelegate, RSTableViewPaginationDelegate>

@property (strong, nonatomic) HAWebService *manager;

@property (strong, nonatomic) Post *post;

@property (strong, nonatomic) UILabel *navTitle;

@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) RSTableView *tableView;
@property (strong, nonatomic) ComposeInputView *composeInputView;

@property (nonatomic) CGFloat currentKeyboardHeight;

@property (nonatomic) BOOL showKeyboardOnOpen;

- (void)openPostActions;

@end
