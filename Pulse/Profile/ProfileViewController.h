//
//  ProfileViewController.h
//
//
//  Created by Austin Valleskey on 9/19/18.
//

#import <UIKit/UIKit.h>
#import "ComposeInputView.h"
#import "HAWebService.h"
#import "Session.h"
#import "RSTableView.h"
#import "User.h"

@interface ProfileViewController : UIViewController <UITextViewDelegate>

@property (strong, nonatomic) HAWebService *manager;

@property (strong, nonatomic) User *user;
@property (strong, nonatomic) UIColor *theme;

@property (strong, nonatomic) UILabel *navTitle;

@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) RSTableView *tableView;
@property (strong, nonatomic) ComposeInputView *composeInputView;

@property (nonatomic) CGFloat currentKeyboardHeight;

- (void)openProfileActions;

@end