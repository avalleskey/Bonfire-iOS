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
#import "Post.h"
#import "ComposeInputView.h"
#import <Messages/Messages.h>
#import <MessageUI/MessageUI.h>
#import "ThemedViewController.h"
#import "PostStream.h"

#define CONVERSATION_ADD_REPLY_CELL_HEIGHT 48

@interface PostViewController : ThemedViewController <UITextViewDelegate, MFMessageComposeViewControllerDelegate, UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) HAWebService *manager;

@property (strong, nonatomic) Post *post;

@property (strong, nonatomic) UILabel *navTitle;

@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) PostStream *stream;
@property (strong, nonatomic) ComposeInputView *composeInputView;

@property (nonatomic) CGFloat currentKeyboardHeight;

@property (nonatomic) BOOL showKeyboardOnOpen;

- (void)openPostActions;

typedef enum {
    ConversationCellTypeBlank = 0,
    ConversationCellTypeParent = 1,
    ConversationCellTypeReply = 2,
    ConversationCellTypeSubReply = 3,
    ConversationCellTypeSubReplyTopActionCell = 4,
    ConversationCellTypeSubReplyBottomActionCell = 5,
    ConversationCellTypeAddReply = 6
} ConversationCellType;

@end
