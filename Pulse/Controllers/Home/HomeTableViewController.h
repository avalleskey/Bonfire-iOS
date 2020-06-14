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
#import "ThemedTableViewController.h"

@interface HomeTableViewController : ThemedTableViewController <BFComponentSectionTableViewDelegate, SectionStreamDelegate>

enum {
    MAX_FEED_CACHED_POSTS = 100,
    MAX_FEED_CACHED_PAGES = 2
};

@property (nonatomic) CGFloat currentKeyboardHeight;

@property (nonatomic, strong) UIButton *morePostsIndicator;
- (void)hideMorePostsIndicator:(BOOL)animated;
- (void)showMorePostsIndicator:(BOOL)animated;

@property (nonatomic, strong) ComposeInputView *composeInputView;

@end
