    //
//  FeedViewController.h
//
//
//  Created by Austin Valleskey on 9/19/18.
//

#import <UIKit/UIKit.h>
#import "ComposeInputView.h"
#import "Session.h"
#import "ComposeInputView.h"
#import "Camp.h"
#import "RSTableView.h"

@interface MyFeedViewController : UITableViewController <RSTableViewDelegate, PostStreamDelegate>

enum {
    MAX_FEED_CACHED_POSTS = 100,
    MAX_FEED_CACHED_PAGES = 2
};

@property (nonatomic, strong) UIScrollView *scrollView;

@property (nonatomic) int previousScrollOffset;
@property (nonatomic) CGFloat currentKeyboardHeight;

@property (nonatomic, strong) UIButton *morePostsIndicator;

@property (nonatomic, strong) UIImageView *launchLogo;

@end
