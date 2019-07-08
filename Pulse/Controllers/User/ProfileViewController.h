//
//  ProfileViewController.h
//
//
//  Created by Austin Valleskey on 9/19/18.
//

#import <UIKit/UIKit.h>
#import "Session.h"
#import "RSTableView.h"
#import "User.h"
#import "ThemedViewController.h"
#import "ComposeInputView.h"

@interface ProfileViewController : ThemedViewController <UITextViewDelegate, RSTableViewDelegate>

@property (strong, nonatomic) User *user;

@property (strong, nonatomic) UILabel *navTitle;

@property (strong, nonatomic) RSTableView *tableView;

@property (nonatomic) CGFloat currentKeyboardHeight;

@property (nonatomic, strong) ComposeInputView *composeInputView;

- (void)openProfileActions;

@end
