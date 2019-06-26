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

#define CONVERSATION_ADD_REPLY_CELL_HEIGHT 48

@interface PostViewController : ThemedViewController <UITextViewDelegate, MFMessageComposeViewControllerDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) Post *parentPost;
@property (nonatomic, strong) Post *post;

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) PostStream *stream;
@property (nonatomic, strong) ComposeInputView *composeInputView;
@property (nonatomic, strong) TappableView *parentPostScrollIndicator;

@property (nonatomic) CGFloat currentKeyboardHeight;

@property (nonatomic) BOOL showKeyboardOnOpen;

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
