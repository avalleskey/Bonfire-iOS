//
//  ProfileViewController.h
//
//
//  Created by Austin Valleskey on 9/19/18.
//

#import <UIKit/UIKit.h>
#import "HAWebService.h"
#import "Session.h"
#import "RSTableView.h"
#import "User.h"
#import "ThemedViewController.h"

@interface ProfileViewController : ThemedViewController <UITextViewDelegate, RSTableViewPaginationDelegate>

@property (strong, nonatomic) HAWebService *manager;

@property (strong, nonatomic) User *user;

@property (strong, nonatomic) UILabel *navTitle;

@property (strong, nonatomic) RSTableView *tableView;

@property (nonatomic) CGFloat currentKeyboardHeight;

- (void)openProfileActions;

@end