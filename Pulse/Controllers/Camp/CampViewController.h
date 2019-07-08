//
//  CampViewController.h
//  
//
//  Created by Austin Valleskey on 9/19/18.
//

#import <UIKit/UIKit.h>
#import "ComposeInputView.h"
#import "Session.h"
#import "RSTableView.h"
#import "Camp.h"
#import "ComposeInputView.h"
#import <Messages/Messages.h>
#import <MessageUI/MessageUI.h>
#import "ThemedViewController.h"

@interface CampViewController : ThemedViewController <UITextViewDelegate, RSTableViewDelegate, MFMessageComposeViewControllerDelegate>

@property (nonatomic, strong) Camp *camp;

@property (nonatomic, strong) UILabel *navTitle;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) RSTableView *tableView;
@property (nonatomic, strong) ComposeInputView *composeInputView;

@property (nonatomic) CGFloat currentKeyboardHeight;
    
- (void)openCampActions;

@end
