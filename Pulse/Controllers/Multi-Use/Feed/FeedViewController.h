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
#import "Room.h"
#import "ErrorView.h"
#import "RSTableView.h"

@interface FeedViewController : UITableViewController <RSTableViewPaginationDelegate>

typedef enum {
    FeedTypeTimeline = 0,
    FeedTypeTrending = 1
} FeedType;

enum {
    MAX_FEED_CACHED_POSTS = 100
};

- (id)initWithFeedType:(FeedType)feedType;
@property (strong, nonatomic) HAWebService *manager;

@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) Room *room;
@property (nonatomic, strong) ErrorView *errorView;

@property (nonatomic) FeedType feedType;
@property (nonatomic) int previousScrollOffset;
@property (nonatomic) CGFloat currentKeyboardHeight;

@property (strong, nonatomic) UIButton *morePostsIndicator;

@end