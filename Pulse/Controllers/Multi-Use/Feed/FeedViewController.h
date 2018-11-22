//
//  FeedViewController.h
//
//
//  Created by Austin Valleskey on 9/19/18.
//

#import <UIKit/UIKit.h>
#import "ComposeInputView.h"
#import "HAWebService.h"
#import "Session.h"
#import "ComposeInputView.h"
#import "RSTableView.h"
#import "Room.h"
#import "ErrorView.h"

@interface FeedViewController : UIViewController <RSTableViewPaginationDelegate>

- (id)initWithFeedId:(NSString *)feedId;
@property (strong, nonatomic) HAWebService *manager;

@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) Room *room;
@property (strong, nonatomic) NSMutableArray *content;
@property (strong, nonatomic) RSTableView *tableView;
@property (nonatomic, strong) ErrorView *errorView;

@property (nonatomic) NSString *feedId;
@property (nonatomic) int previousScrollOffset;
@property (nonatomic) CGFloat currentKeyboardHeight;

@end
