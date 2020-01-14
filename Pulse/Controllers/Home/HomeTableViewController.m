//
//  FeedViewController.m
//
//
//  Created by Austin Valleskey on 9/19/18.
//

#import "HomeTableViewController.h"
#import "ComplexNavigationController.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import <Shimmer/FBShimmeringView.h>
#import "SimpleNavigationController.h"
#import "InsightsLogger.h"
#import "UIColor+Palette.h"
#import <PINCache/PINCache.h>
#import "TabController.h"
#import "HAWebService.h"
#import "MiniAvatarListCell.h"
#import "Launcher.h"
#import "NSArray+Clean.h"
#import "BFTipsManager.h"
#import "SearchResultCell.h"
#import "ButtonCell.h"
#import "CampCardsListCell.h"
#import "BFVisualErrorView.h"
#import "ComposeViewController.h"
#import "PrivacySelectorTableViewController.h"
@import Firebase;

#define startConversationHeaderHeight 80

@interface HomeTableViewController () <PrivacySelectorDelegate> {
    int previousTableViewYOffset;
}

//@property (nonatomic) BOOL loading;
@property (nonatomic) BOOL userDidRefresh;
@property (nonatomic, strong) NSDate *lastFetch;

@property (nonatomic, strong) BFVisualErrorView *errorView;

@property CGFloat minHeaderHeight;
@property CGFloat maxHeaderHeight;
@property (nonatomic, strong) NSMutableArray *posts;

@property (nonatomic, strong) NSMutableArray <Camp *> *suggestedCamps;

@property (nonatomic, strong) FBShimmeringView *titleView;

@property (nonatomic) CGFloat previousOffset;
@property (nonatomic) CGFloat yTranslation;

@property (nonatomic) BOOL scrollingDownwards;

@end

@implementation HomeTableViewController

static NSString * const recentCardsCellReuseIdentifier = @"RecentCampsCell";

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setup];
    
    self.view.backgroundColor = [UIColor contentBackgroundColor];
    self.navigationController.view.backgroundColor = [UIColor contentBackgroundColor];
    
    // Google Analytics
    [FIRAnalytics setScreenName:@"My Feed" screenClass:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userUpdated:) name:@"UserUpdated" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newPostBegan:) name:@"NewPostBegan" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newPostCompleted:) name:@"NewPostCompleted" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newPostFailed:) name:@"NewPostFailed" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchNewPosts) name:@"FetchNewTimelinePosts" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillDismiss:) name:UIKeyboardWillHideNotification object:nil];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if ([self isBeingPresented] || [self isMovingToParentViewController]) {
        // first time
        [self setupTitleView];
        [self setupMorePostsIndicator];
                
        [self positionErrorView];
        
        if ([BFTipsManager hasSeenTip:@"about_sparks_info"] == false) {
            BFTipObject *tipObject = [BFTipObject tipWithCreatorType:BFTipCreatorTypeBonfireTip creator:nil title:@"Sparks help posts go viral 🚀" text:@"Sparks show a post to more people. Only the creator can see who sparks a post." cta:nil imageUrl:nil action:^{
                NSLog(@"tip tapped");
            }];
            [[BFTipsManager manager] presentTip:tipObject completion:^{
                NSLog(@"presentTip() completion");
            }];
        }
    }
    else {
        [InsightsLogger.sharedInstance openAllVisiblePostInsightsInTableView:self.rs_tableView seenIn:InsightSeenInHomeView];
        
        // fetch new posts after 2mins
        NSTimeInterval secondsSinceLastFetch = [self.lastFetch timeIntervalSinceNow];
        // NSLog(@"seconds since last fetch: %f", -secondsSinceLastFetch);
        if (secondsSinceLastFetch < -(2 * 60)) {
            [self fetchNewPosts];
        }
    }
    
//    if (self.morePostsIndicator.tag == 1) {
//        // more posts indicator is visible
//        // ensure the animation didn't get caught off
//        [self showMorePostsIndicator:false];
//    }
    
//    [self showComposeInputView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if ([self isBeingPresented] || [self isMovingToParentViewController]) {
        [self setupContent];
    }
    
    if (self.rs_tableView.stream.posts.count == 0 && !self.loading) {
        [self fetchNewPosts];
    }
    
    self.errorView.center = CGPointMake(self.view.frame.size.width / 2, self.rs_tableView.frame.size.height / 2 - self.navigationController.navigationBar.frame.size.height - self.navigationController.navigationBar.frame.origin.y);
    
    // Register Siri intent
    NSString *activityTypeString = @"com.Ingenious.bonfire.open-feed-timeline";
    NSUserActivity *activity = [[NSUserActivity alloc] initWithActivityType:activityTypeString];
    activity.title = [NSString stringWithFormat:@"See what's new"];
    activity.eligibleForSearch = true;
    if (@available(iOS 12.0, *)) {
        activity.eligibleForPrediction = true;
        activity.persistentIdentifier = activityTypeString;
    }
    self.view.userActivity = activity;
    [activity becomeCurrent];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [InsightsLogger.sharedInstance closeAllVisiblePostInsightsInTableView:self.rs_tableView];
    
    [self hideMorePostsIndicator:true];
    [self addQueuedPosts];
}

#pragma mark - Setup
- (void)setup {
    self.rs_tableView.queuedStream = [PostStream new];
    
    [self setupTableView];
    [self setupErrorView];
//    [self setupComposeInputView];
}
- (void)setupTableView {
    self.rs_tableView = [[RSTableView alloc] initWithFrame:CGRectMake(100, self.view.bounds.origin.y, self.view.frame.size.width - 200, self.view.bounds.size.height) style:UITableViewStyleGrouped];
    self.rs_tableView.separatorColor = [UIColor tableViewSeparatorColor];
    self.rs_tableView.dataType = RSTableViewTypeFeed;
    self.rs_tableView.tableViewStyle = RSTableViewStyleDefault;
    self.rs_tableView.loadingMore = false;
    self.rs_tableView.extendedDelegate = self;
    self.rs_tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    self.rs_tableView.backgroundColor = [UIColor contentBackgroundColor];
    [self.rs_tableView registerClass:[CampCardsListCell class] forCellReuseIdentifier:recentCardsCellReuseIdentifier];
//    self.rs_tableView.showsVerticalScrollIndicator = false;
    self.rs_tableView.refreshControl = [[UIRefreshControl alloc] init];
    [self.rs_tableView sendSubviewToBack:self.rs_tableView.refreshControl];
    [self.rs_tableView.refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    
    self.rs_tableView.scrollIndicatorInsets = UIEdgeInsetsZero;
}
- (void)setupContent {
    self.rs_tableView.stream.delegate = self;
    self.rs_tableView.queuedStream.delegate = self;
    
    [self loadCache];
    
    // load most up to date content
    self.lastFetch = [NSDate new];
    if (self.rs_tableView.stream.prevCursor.length > 0) {
        [self getPostsWithCursor:StreamPagingCursorTypePrevious];
    }
    else {
        [self getPostsWithCursor:StreamPagingCursorTypeNone];
    }
}
- (void)setupErrorView {
    BFVisualError *visualError = [BFVisualError visualErrorOfType:ErrorViewTypeNotFound title:@"Error Loading" description:@"Check your network settings and tap here to try again" actionTitle:@"Reload" actionBlock:^{
        [self refresh];
    }];
    
    self.errorView = [[BFVisualErrorView alloc] initWithVisualError:visualError];
    self.errorView.center = self.rs_tableView.center;
    self.errorView.hidden = true;
    [self.rs_tableView addSubview:self.errorView];
}
- (void)setupTitleView {
    UIButton *titleButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [titleButton setImage:[[UIImage imageNamed:@"navBonfireLogo"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [titleButton setImageEdgeInsets:UIEdgeInsetsMake(-1, 0, 0, 0)];
    titleButton.tintColor = [UIColor bonfirePrimaryColor];
    titleButton.frame = CGRectMake(0, 0, [titleButton intrinsicContentSize].width, self.navigationController.navigationBar.frame.size.height);
    [titleButton bk_whenTapped:^{
        [self.rs_tableView scrollToTopWithCompletion:^{
            [self addQueuedPosts];
                    
            if (!self.loading) {
                // fetch new posts after 2mins
                NSTimeInterval secondsSinceLastFetch = [self.lastFetch timeIntervalSinceNow];
                // NSLog(@"seconds since last fetch: %f", -secondsSinceLastFetch);
                if (secondsSinceLastFetch < -(2 * 60)) {
                    [self fetchNewPosts];
                }
            }
        }];
    }];
    
    self.titleView = [[FBShimmeringView alloc] initWithFrame:titleButton.frame];
    [self.titleView addSubview:titleButton];
    self.titleView.contentView = titleButton;
    
    self.navigationItem.titleView = titleButton;
}
- (void)setupMorePostsIndicator {
    self.morePostsIndicator = [UIButton buttonWithType:UIButtonTypeCustom];
    self.morePostsIndicator.frame = CGRectMake(self.view.frame.size.width / 2 - (116 / 2), self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height + 12, 116, 40);
    self.morePostsIndicator.layer.masksToBounds = false;
    self.morePostsIndicator.layer.shadowOffset = CGSizeMake(0, 1);
    self.morePostsIndicator.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.16].CGColor;
    self.morePostsIndicator.layer.shadowOpacity = 2.f;
    self.morePostsIndicator.layer.shadowRadius = 3.f;
    self.morePostsIndicator.tag = 0; // inactive
    self.morePostsIndicator.hidden = true;
    self.morePostsIndicator.layer.cornerRadius = self.morePostsIndicator.frame.size.height / 2;
    self.morePostsIndicator.backgroundColor = [UIColor colorNamed:@"PillBackgroundColor"];
    [self.morePostsIndicator setTitle:@"New Posts" forState:UIControlStateNormal];
    [self.morePostsIndicator setTitleColor:[UIColor bonfirePrimaryColor] forState:UIControlStateNormal];
    self.morePostsIndicator.titleLabel.font = [UIFont systemFontOfSize:16.f weight:UIFontWeightBold];
    self.morePostsIndicator.layer.shouldRasterize = true;
    self.morePostsIndicator.layer.rasterizationScale = [UIScreen mainScreen].scale;
    CGFloat intrinsticWidth = self.morePostsIndicator.intrinsicContentSize.width + (18*2);
    self.morePostsIndicator.frame = CGRectMake(self.view.frame.size.width / 2 - intrinsticWidth / 2, self.morePostsIndicator.frame.origin.y, intrinsticWidth, self.morePostsIndicator.frame.size.height);
    
    [self.navigationController.view insertSubview:self.morePostsIndicator aboveSubview:self.view];
    
    [self.morePostsIndicator bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.25f delay:0 usingSpringWithDamping:0.8f initialSpringVelocity:0.4f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.morePostsIndicator.transform = CGAffineTransformMakeScale(0.9, 0.9);
        } completion:nil];
    } forControlEvents:UIControlEventTouchDown];
    
    [self.morePostsIndicator bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.25f delay:0 usingSpringWithDamping:0.9f initialSpringVelocity:0.4f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.morePostsIndicator.transform = CGAffineTransformMakeScale(1, 1);
        } completion:nil];
    } forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit)];
    
    [self.morePostsIndicator bk_whenTapped:^{
        [self hideMorePostsIndicator:true];
        
        [self.rs_tableView scrollToTopWithCompletion:^{
            [self addQueuedPosts];
        }];
    }];
}
- (void)addQueuedPosts {
    if (self.rs_tableView.queuedStream.pages.count > 0) {
        __block CGFloat newPosts = 0;
        BOOL replaceCache = false;
        __block PostStream *newStream = [self.rs_tableView.stream copy];
        for (PostStreamPage *page in self.rs_tableView.queuedStream.pages) {
            if (page.meta.paging.replaceCache) {
                replaceCache = true;
                newStream = [[PostStream alloc] init];
            }
            
            [newStream prependPage:page];
            
            newPosts += page.data.count;
        }
        
        void (^refreshView)(void) = ^void(void) {
            self.rs_tableView.stream = newStream;
            
            DLog(@"new posts ! %f", newPosts);
            if (newPosts > 0) {
                self.rs_tableView.cellHeightsDictionary = @{}.mutableCopy;
                
                [self.rs_tableView hardRefresh:true];
            }
            
            self.rs_tableView.queuedStream = [PostStream new];
        };
        
        if (replaceCache) {
            // force a scroll to top if a replace_cache occurred
            [self.rs_tableView scrollToTopWithCompletion:^{
                refreshView();
            }];
        }
        else {
            refreshView();
        }
    }
}

- (void)setupComposeInputView {
    CGFloat collapsed_inputViewHeight = ((self.composeInputView.textView.frame.origin.y * 2) + self.composeInputView.textView.frame.size.height);
    
    self.composeInputView = [[ComposeInputView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - collapsed_inputViewHeight - self.view.safeAreaInsets.bottom - 50, self.view.frame.size.width, collapsed_inputViewHeight)];
    self.composeInputView.defaultPlaceholder = @"Start a conversation...";
    [self.composeInputView setMediaTypes:@[BFMediaTypeGIF, BFMediaTypeText, BFMediaTypeImage]];
    self.composeInputView.postButton.backgroundColor = [UIColor bonfirePrimaryColor];
    self.composeInputView.postButton.tintColor = [UIColor whiteColor];
    self.composeInputView.textView.tintColor = self.composeInputView.postButton.backgroundColor;
    [self.composeInputView updatePlaceholders];
    [self.composeInputView bk_whenTapped:^{
        if (![self.composeInputView isActive]) {
            [self.composeInputView setActive:true];
        }
    }];
    [self.composeInputView.postButton setImage:[[UIImage imageNamed:@"nextButtonIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [self.composeInputView.postButton bk_whenTapped:^{
        [self openPrivacySelector];
    }];
    [self.composeInputView.expandButton bk_whenTapped:^{
        [Launcher openComposePost:nil inReplyTo:nil withMessage:self.composeInputView.textView.text media:nil  quotedObject:nil];
    }];
    
    [self.view addSubview:self.composeInputView];
    
    self.composeInputView.tintColor = self.view.tintColor;
}
- (void)privacySelectionDidChange:(Camp * _Nullable)selection {
    [self postMessageInCamp:selection];
}
- (void)openPrivacySelector {
    PrivacySelectorTableViewController *sitvc = [[PrivacySelectorTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    sitvc.delegate = self;
    sitvc.title = @"Post in...";
    sitvc.shareOnProfile = false;
    
    SimpleNavigationController *simpleNav = [[SimpleNavigationController alloc] initWithRootViewController:sitvc];
    simpleNav.transitioningDelegate = [Launcher sharedInstance];
    simpleNav.modalPresentationStyle = UIModalPresentationFullScreen;
    [self.navigationController presentViewController:simpleNav animated:YES completion:nil];
}
- (void)postMessageInCamp:(Camp *)camp {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    NSString *message = self.composeInputView.textView.text;
    if (message.length > 0) {
        [params setObject:[Post trimString:message] forKey:@"message"];
    }
    if (self.composeInputView.media.objects.count > 0) {
        [params setObject:self.composeInputView.media forKey:@"media"];
    }
    
    if ([params objectForKey:@"message"] || [params objectForKey:@"media"]) {
        // meets min. requirements
        [BFAPI createPost:params postingIn:camp replyingTo:nil attachments:nil];
        
        [self.composeInputView reset];
        
        [self.view endEditing:true];
    }
}

#pragma mark - NSNotification Handlers
- (void)userUpdated:(NSNotification *)notification {
    if ([notification.object isKindOfClass:[User class]]) {
        User *user = notification.object;
        if ([user.identifier isEqualToString:[Session sharedInstance].currentUser.identifier]) {
            [self.rs_tableView refreshAtTop];
        }
    }
}
- (void)newPostBegan:(NSNotification *)notification {
    Post *tempPost = notification.object;
    
    if (tempPost != nil && !tempPost.attributes.parent) {
//        // TODO: Check for image as well
//        self.errorView.hidden = true;
//
//        [self.rs_tableView.stream addTempPost:tempPost];
//        [self.rs_tableView refreshAtTop];
        if (self.navigationController && [self.navigationController isKindOfClass:[SimpleNavigationController class]]) {
            [(SimpleNavigationController *)self.navigationController setProgress:0.8 animated:YES];
        }
    }
}
- (void)newPostCompleted:(NSNotification *)notification {
    NSDictionary *info = notification.object;
    NSString *tempId = info[@"tempId"];
    Post *post = info[@"post"];
    
    if (post != nil) {
        // TODO: Check for image as well
        self.errorView.hidden = true;
        
        BOOL removedTempPost = [self.rs_tableView.stream removeTempPost:tempId];
        
        NSLog(@"removed temp post?? %@", removedTempPost ? @"YES" : @"NO");
        
        [self.rs_tableView.stream removeLoadedCursor:self.rs_tableView.stream.prevCursor];
        
        [self fetchNewPosts];
        
        if (self.navigationController && [self.navigationController isKindOfClass:[SimpleNavigationController class]]) {
            [(SimpleNavigationController *)self.navigationController setProgress:1 animated:YES hideOnCompletion:true];
        }
    }
}
- (void)newPostFailed:(NSNotification *)notification {
    Post *tempPost = notification.object;
    
    if (tempPost != nil) {
        // TODO: Check for image as well
        [self.rs_tableView.stream removeTempPost:tempPost.tempId];
        [self.rs_tableView refreshAtTop];
        self.errorView.hidden = (self.rs_tableView.stream.posts.count != 0);
        
        if (self.navigationController && [self.navigationController isKindOfClass:[SimpleNavigationController class]]) {
            [(SimpleNavigationController *)self.navigationController setProgress:0 animated:YES hideOnCompletion:true];
        }
    }
}

#pragma mark - Error View
- (void)showErrorViewWithType:(ErrorViewType)type title:(NSString *)title description:(NSString *)description actionTitle:(nullable NSString *)actionTitle actionBlock:(void (^ __nullable)(void))actionBlock {
    self.errorView.hidden = false;
    self.errorView.visualError = [BFVisualError visualErrorOfType:type title:title description:description actionTitle:actionTitle actionBlock:actionBlock];
    [self.rs_tableView reloadData];
}
- (void)positionErrorView {
    self.errorView.center = CGPointMake(self.view.frame.size.width / 2, self.rs_tableView.frame.size.height / 2 - self.navigationController.navigationBar.frame.size.height - self.navigationController.navigationBar.frame.origin.y);
}

#pragma mark - More Posts Indicator
- (void)hideMorePostsIndicator:(BOOL)animated {
    if ([self.tabBarController isKindOfClass:[TabController class]]) {
        // remove dot from home tab
        [(TabController *)self.tabBarController setBadgeValue:nil forItem:self.navigationController.tabBarItem];
    }

    self.morePostsIndicator.tag = 0;
    [UIView animateWithDuration:(animated?0.8f:0) delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.morePostsIndicator.center = CGPointMake(self.morePostsIndicator.center.x, self.morePostsIndicator.frame.size.height * -.5);
        self.morePostsIndicator.alpha = 0;
    } completion:^(BOOL finished) {
        self.morePostsIndicator.hidden = true;
    }];
}
- (void)showMorePostsIndicator:(BOOL)animated {
    if (self.rs_tableView.queuedStream.posts.count > 0) {
        CGFloat normalizedScrollViewContentOffsetY = self.rs_tableView.contentOffset.y + self.rs_tableView.adjustedContentInset.top;
        CGFloat morePostsOffsetY = MAX(0, startConversationHeaderHeight - normalizedScrollViewContentOffsetY);
        
        self.morePostsIndicator.hidden = false;
        
        self.morePostsIndicator.tag = 1;
        self.morePostsIndicator.alpha = 1;
        [UIView animateWithDuration:(animated?1.2f:0) delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:(UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionAllowUserInteraction) animations:^{
            self.morePostsIndicator.center = CGPointMake(self.morePostsIndicator.center.x, self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height + 12 + (self.morePostsIndicator.frame.size.height * 0.5) + morePostsOffsetY);
        } completion:nil];
    }
}

#pragma mark - Cache Management
- (void)loadCache {
    self.rs_tableView.stream = [[PostStream alloc] init];
    self.rs_tableView.stream.delegate = nil;
    
    // load feed cache
    NSArray *cache = [[PINCache sharedCache] objectForKey:@"home_feed_cache"];
    if (cache && cache.count > 0) {
        for (NSDictionary *pageDict in cache) {
            PostStreamPage *page = [[PostStreamPage alloc] initWithDictionary:pageDict error:nil];
            [self.rs_tableView.stream appendPage:page];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.rs_tableView.stream.delegate = self;
            self.rs_tableView.loading = (self.rs_tableView.stream.posts.count == 0);
            [self.rs_tableView hardRefresh:true];
        });
    }
    else {
        self.rs_tableView.stream.delegate = self;
    }
    
}
- (void)saveCache {
    DLog(@"save cache !");
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *cacheKey = @"home_feed_cache";
        
        if (cacheKey) {
            NSMutableArray *newCache = [[NSMutableArray alloc] init];

            NSInteger postsCount = 0;
            
            // add queued pages first
            for (NSInteger i = 0; i < self.rs_tableView.queuedStream.pages.count && postsCount < MAX_FEED_CACHED_POSTS; i++) {
                postsCount += self.rs_tableView.queuedStream.pages[i].data.count;
                [newCache addObject:[self.rs_tableView.queuedStream.pages[i] toDictionary]];
            }
            
            for (NSInteger i = 0; i < self.rs_tableView.stream.pages.count && postsCount < MAX_FEED_CACHED_POSTS; i++) {
                postsCount += self.rs_tableView.stream.pages[i].data.count;
                [newCache addObject:[self.rs_tableView.stream.pages[i] toDictionary]];
            }
            
            [[PINCache sharedCache] setObject:[newCache copy] forKey:cacheKey];
        }
    });
}
- (void)postStreamDidUpdate:(PostStream *)stream {
    DLog(@"postStreamDidUpdate :: %@", stream == self.rs_tableView.queuedStream ? @"queued stream" : @"post stream");
    [self saveCache];
    
    if (self.rs_tableView.queuedStream.posts.count == 0) {
        [self hideMorePostsIndicator:true];
    }
}

#pragma mark - Stream Requests & Management
// Get suggested camps (if any)
- (void)loadSuggestedCamps {
    NSArray *recentCamps = [[NSUserDefaults standardUserDefaults] arrayForKey:@"recents_camps"];
    
    if (recentCamps.count == 0) {
        return;
    }
    else if (recentCamps.count > 5) {
        recentCamps = [recentCamps subarrayWithRange:NSMakeRange(0, 8)];
    }
    
    self.suggestedCamps = [NSMutableArray new];
    for (id object in recentCamps) {
        if ([object isKindOfClass:[NSDictionary class]]) {
            NSError *error;
            Camp *camp = [[Camp alloc] initWithDictionary:(NSDictionary *)object error:&error];
            if (!error) {
                [self.suggestedCamps addObject:camp];
                return;
            }
        }
        else if ([object isKindOfClass:[Camp class]]) {
            [self.suggestedCamps addObject:(Camp *)object];
            return;
        }
    }
    
    [self.rs_tableView reloadData];
}
- (void)recentsUpdated:(NSNotification *)sender {
    [self loadSuggestedCamps];
    
    [self.rs_tableView reloadData];
}
// Fetch posts
- (void)getPostsWithCursor:(StreamPagingCursorType)cursorType {
    NSString *url = @"streams/me";
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    if (cursorType == StreamPagingCursorTypeNext) {
        [params setObject:self.rs_tableView.stream.nextCursor forKey:@"cursor"];
    }
    else if (self.rs_tableView.stream.prevCursor.length > 0) {
        if (self.rs_tableView.queuedStream.prevCursor.length > 0) {
            [params setObject:self.rs_tableView.queuedStream.prevCursor forKey:@"cursor"];
        }
        else {
            [params setObject:self.rs_tableView.stream.prevCursor forKey:@"cursor"];
        }
    }
    
    if ([params objectForKey:@"cursor"]) {
        if ([self.rs_tableView.stream hasLoadedCursor:params[@"cursor"]]) {
            return;
        }
        else {
            [self.rs_tableView.stream addLoadedCursor:params[@"cursor"]];
        }
    }
    else if (cursorType == StreamPagingCursorTypePrevious) {
        cursorType = StreamPagingCursorTypeNone;
    }
    
    self.rs_tableView.loading = (self.rs_tableView.stream.posts.count == 0);
    if (self.rs_tableView.loading) {
        self.errorView.hidden = true;
        [self.rs_tableView hardRefresh:false];
    }
    
    if (cursorType == StreamPagingCursorTypePrevious && self.rs_tableView.stream.posts.count > 0) {
        self.titleView.shimmering = true;
    }
    
    [[[HAWebService managerWithContentType:kCONTENT_TYPE_JSON] authenticate] GET:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSInteger postsBefore = self.rs_tableView.stream.posts.count;
        
        PostStreamPage *page = [[PostStreamPage alloc] initWithDictionary:responseObject error:nil];

        if (page.data.count > 0) {
            if (!self.rs_tableView.stream) {
                [self.rs_tableView scrollToTop];
                self.rs_tableView.stream = [[PostStream alloc] init];
            }
            
            if (self.userDidRefresh || cursorType == StreamPagingCursorTypeNone) {
                [self.rs_tableView.stream prependPage:page];
            }
            else if (cursorType == StreamPagingCursorTypePrevious && postsBefore > 0) {
                if (!self.rs_tableView.queuedStream) {
                    self.rs_tableView.queuedStream = [[PostStream alloc] init];
                }
                [self.rs_tableView.queuedStream appendPage:page];
                
                // manually call the postStreamDidUpdate method since it won't call otherwise
                [self postStreamDidUpdate:self.rs_tableView.stream];
            }
            else {
                [self.rs_tableView.stream appendPage:page];
            }
        }
        
        
        self.loading = false;
        self.rs_tableView.loading = false;
        
        if (self.userDidRefresh || cursorType == StreamPagingCursorTypeNone) {
            self.userDidRefresh = false;
            [self.rs_tableView hardRefresh:self.userDidRefresh];
            
            [self hideMorePostsIndicator:true];
        }
        else if (self.rs_tableView.queuedStream.pages.count > 0) {
            [self showMorePostsIndicator:YES];
        }
        else if (cursorType == StreamPagingCursorTypeNext) {
            self.rs_tableView.loadingMore = false;
            
            [self.rs_tableView refreshAtBottom];
        }
        
        if (self.rs_tableView.stream.posts.count == 0) {
            // Error: No posts yet!
            self.errorView.hidden = false;
            
            BFVisualError *visualError = [BFVisualError visualErrorOfType:ErrorViewTypeHeart title:@"For You" description:@"The posts you care about from the Camps and people you care about" actionTitle:@"Discover Camps" actionBlock:^{
                TabController *tabVC = (TabController *)[Launcher activeTabController];
                if (tabVC) {
                    tabVC.selectedIndex = [tabVC.viewControllers indexOfObject:tabVC.storeNavVC];
                    [tabVC tabBar:tabVC.tabBar didSelectItem:tabVC.storeNavVC.tabBarItem];
                }
                else {
                    [Launcher openDiscover];
                }
            }];
            self.errorView.visualError = visualError;
            
            [self positionErrorView];
        }
        else {
            self.errorView.hidden = true;
        }

        CGFloat normalizedScrollViewContentOffsetY = self.rs_tableView.contentOffset.y + self.rs_tableView.adjustedContentInset.top;
//        if (self.userDidRefresh) {
//            self.userDidRefresh = false;
//        }
//        else {
//            // DEBUG
//            if (postsAfter > postsBefore && normalizedScrollViewContentOffsetY > 0 && cursorType == StreamPagingCursorTypePrevious) {
//                [self showMorePostsIndicator:YES];
//            }
//        }
        self.previousOffset = normalizedScrollViewContentOffsetY;
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (self.rs_tableView.stream.posts.count == 0) {
            self.errorView.hidden = false;
            
            [self showErrorViewWithType:([HAWebService hasInternet] ? ErrorViewTypeGeneral : ErrorViewTypeNoInternet) title:([HAWebService hasInternet] ? @"Error Loading" : @"No Internet") description:@"Check your network settings and tap below to try again" actionTitle:@"Refresh" actionBlock:^{
                [self refresh];
            }];
            
            [self positionErrorView];
        }
        
        self.loading = false;
        self.rs_tableView.loading = false;
        if (cursorType == StreamPagingCursorTypeNext) {
            self.rs_tableView.loadingMore = false;
        }
        else if (self.userDidRefresh) {
            self.userDidRefresh = false;
        }
        self.rs_tableView.userInteractionEnabled = true;
        [self.rs_tableView refreshAtTop];
    }];
}
// Management
- (void)refresh {
    if (!self.userDidRefresh) {
        [self.rs_tableView.stream removeLoadedCursor:self.rs_tableView.stream.prevCursor];
        
        self.userDidRefresh = true;
        [self fetchNewPosts];
    }
}
- (void)fetchNewPosts {
    self.lastFetch = [NSDate new];
    [self getPostsWithCursor:StreamPagingCursorTypePrevious];
}
- (void)setLoading:(BOOL)loading {
    [super setLoading:loading];
    
    if (!self.loading) {
        [self.refreshControl endRefreshing];
        self.titleView.shimmering = false;
    }
}

#pragma mark - RSTableViewDelegate
- (UIView *)viewForFirstSectionHeader {
    UIButton *header = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, startConversationHeaderHeight)];
    header.backgroundColor = [UIColor contentBackgroundColor];
    BFAvatarView *profilePic = [[BFAvatarView alloc] initWithFrame:CGRectMake(12, 12, 48, 48)];
    profilePic.user = [Session sharedInstance].currentUser;
    profilePic.userInteractionEnabled = false;
    
    UIButton *takePictureButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [takePictureButton setImage:[[UIImage imageNamed:@"composeToolbarTakePicture"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    takePictureButton.frame = CGRectMake(header.frame.size.width - 12 - 40, profilePic.frame.origin.y + ((profilePic.frame.size.height - 40) / 2), 40, 40);
    takePictureButton.backgroundColor = [UIColor bonfireDetailColor];
    takePictureButton.layer.cornerRadius = takePictureButton.frame.size.height / 2;
    takePictureButton.contentMode = UIViewContentModeCenter;
    takePictureButton.tintColor = [UIColor bonfirePrimaryColor];
    [takePictureButton bk_whenTapped:^{
        [Launcher openComposeCamera];
    }];
    takePictureButton.adjustsImageWhenHighlighted = false;
    [takePictureButton bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            takePictureButton.alpha = 0.5;
        } completion:nil];
    } forControlEvents:UIControlEventTouchDown];
    [takePictureButton bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            takePictureButton.alpha = 1;
        } completion:nil];
    } forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit)];
    [header addSubview:takePictureButton];
    
    UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(70, profilePic.frame.origin.y, self.view.frame.size.width - 70 - 12, profilePic.frame.size.height)];
    textLabel.font = textViewFont;
    textLabel.textColor = [UIColor bonfireSecondaryColor];
//    textLabel.alpha = 0.25;
    textLabel.text = @"Start a conversation...";
    
    UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(0, header.frame.size.height - 8, self.view.frame.size.width, 8)];
    separator.backgroundColor = [UIColor tableViewBackgroundColor];
    
    UIView *line_t = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, HALF_PIXEL)];
    line_t.backgroundColor = [UIColor tableViewSeparatorColor];
    [separator addSubview:line_t];
    
    UIView *line_b = [[UIView alloc] initWithFrame:CGRectMake(0, separator.frame.size.height - HALF_PIXEL, self.view.frame.size.width, HALF_PIXEL)];
    line_b.backgroundColor = [UIColor tableViewSeparatorColor];
    [separator addSubview:line_b];
    
    [header addSubview:textLabel];
    [header addSubview:profilePic];
    [header addSubview:separator];
    
    [header bk_whenTapped:^{
        [Launcher openComposePost:nil inReplyTo:nil withMessage:nil media:nil quotedObject:nil];
    }];
    
    [header bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            profilePic.alpha = 0.5;
            textLabel.alpha = 0.5;
        } completion:nil];
    } forControlEvents:UIControlEventTouchDown];
    [header bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            profilePic.alpha = 1;
            textLabel.alpha = 1;
        } completion:nil];
    } forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit)];
    
    return header;
}
- (CGFloat)heightForFirstSectionHeader {
    return startConversationHeaderHeight;
}
- (UIView *)viewForFirstSectionFooter {
    return nil;
}
- (CGFloat)heightForFirstSectionFooter {
    return CGFLOAT_MIN;
}
- (void)tableView:(nonnull id)tableView didRequestNextPageWithMaxId:(NSInteger)maxId {
    if (self.rs_tableView.stream.nextCursor.length > 0 && ![self.rs_tableView.stream hasLoadedCursor:self.rs_tableView.stream.nextCursor]) {
        [self getPostsWithCursor:StreamPagingCursorTypeNext];
    }
}

#pragma mark - UIScrollViewDelegate
- (void)tableViewDidScroll:(UITableView *)tableView {
    CGFloat normalizedScrollViewContentOffsetY = tableView.contentOffset.y + tableView.adjustedContentInset.top;
    
    if (![self.morePostsIndicator isHidden]) {
        CGFloat normalizedScrollViewContentOffsetY = tableView.contentOffset.y + tableView.adjustedContentInset.top;
        CGFloat morePostsOffsetY = MAX(0, startConversationHeaderHeight - normalizedScrollViewContentOffsetY);
        self.morePostsIndicator.center = CGPointMake(self.morePostsIndicator.center.x, self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height + 12 + (self.morePostsIndicator.frame.size.height * 0.5) + morePostsOffsetY);
    }
    
    if (![self.composeInputView.textView isFirstResponder] && normalizedScrollViewContentOffsetY > 80) {
        CGFloat diff = self.previousOffset - normalizedScrollViewContentOffsetY;
        
        self.previousOffset = normalizedScrollViewContentOffsetY;
        
        BOOL scrollingDownwards = diff < 0;
        if (scrollingDownwards != self.scrollingDownwards) {
            self.scrollingDownwards = scrollingDownwards;
            
            // scroll direction changed -- set the ytranslation back to 0
            self.yTranslation = 0;
        }
        else if (self.composeInputView.postButton.alpha == 0) {
            self.yTranslation += diff;
        }
        else {
            self.yTranslation = 0;
        }
    }
    else {
        self.scrollingDownwards = false;
        self.previousOffset = normalizedScrollViewContentOffsetY;
        self.yTranslation = 0;
    }
    
//    DLog(@"scrollingDownwards: %@", _scrollingDownwards ? @"YES" : @"NO");
//    DLog(@"self.previousOffset: %f", self.previousOffset);
//    DLog(@"self.yTranslation: %f", self.yTranslation);
//    DLog(@"normalizedContentOffset: %f", normalizedScrollViewContentOffsetY);
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    UIView *tapToDismissView = [self.view viewWithTag:888];
    if (!tapToDismissView) {
        tapToDismissView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.rs_tableView.frame.size.width, self.rs_tableView.frame.size.height)];
        tapToDismissView.tag = 888;
        tapToDismissView.alpha = 0;
        tapToDismissView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.75];
        
        [self.view insertSubview:tapToDismissView aboveSubview:self.rs_tableView];
    }
    
    self.rs_tableView.scrollEnabled = false;
    [UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        tapToDismissView.alpha = 1;
    } completion:nil];
    
    
    [tapToDismissView bk_whenTapped:^{
        [textView resignFirstResponder];
    }];
    UISwipeGestureRecognizer *swipeDownGesture = [[UISwipeGestureRecognizer alloc] bk_initWithHandler:^(UIGestureRecognizer *sender, UIGestureRecognizerState state, CGPoint location) {
        [textView resignFirstResponder];
    }];
    swipeDownGesture.direction = UISwipeGestureRecognizerDirectionDown;
    [tapToDismissView addGestureRecognizer:swipeDownGesture];
    
    return true;
}
- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
    UIView *tapToDismissView = [self.view viewWithTag:888];
    
    if (self.loading) {
        self.rs_tableView.scrollEnabled = false;
    }
    else {
        self.rs_tableView.scrollEnabled = true;
    }
    
    [UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        tapToDismissView.alpha = 0;
    } completion:^(BOOL finished) {
        [tapToDismissView removeFromSuperview];
    }];
    
    return true;
}
- (void)keyboardWillChangeFrame:(NSNotification *)notification {
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
    _currentKeyboardHeight = keyboardFrameBeginRect.size.height;
    _yTranslation = 0;
    self.composeInputView.transform = CGAffineTransformIdentity;
    
    UIEdgeInsets safeAreaInsets = [[[UIApplication sharedApplication] delegate] window].safeAreaInsets;
        
    CGFloat newComposeInputViewY = self.view.frame.size.height - self.currentKeyboardHeight - self.composeInputView.frame.size.height + safeAreaInsets.bottom;
    
    self.composeInputView.frame = CGRectMake(self.composeInputView.frame.origin.x, newComposeInputViewY, self.composeInputView.frame.size.width, self.composeInputView.frame.size.height);
}

- (void)keyboardWillDismiss:(NSNotification *)notification {
    _currentKeyboardHeight = 0;
    _yTranslation = 0;
    self.composeInputView.transform = CGAffineTransformIdentity;
    
    UIEdgeInsets safeAreaInsets = [[[UIApplication sharedApplication] delegate] window].safeAreaInsets;
    
    NSNumber *duration = notification.userInfo ? [notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] : @(0);
    [UIView animateWithDuration:[duration floatValue] delay:0 options:(notification.userInfo?[[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue] << 16:UIViewAnimationOptionCurveEaseOut) animations:^{
        [self.composeInputView resize:false];
        
        self.composeInputView.frame = CGRectMake(self.composeInputView.frame.origin.x, self.view.frame.size.height - self.composeInputView.frame.size.height - self.tabBarController.tabBar.frame.size.height + safeAreaInsets.bottom, self.composeInputView.frame.size.width, self.composeInputView.frame.size.height);
    } completion:nil];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    return textView.text.length + (text.length - range.length) <= [Session sharedInstance].defaults.post.maxLength;
}
- (void)showComposeInputView {
    _yTranslation = 0;
    self.composeInputView.transform = CGAffineTransformIdentity;
    
    UIEdgeInsets safeAreaInsets = [[[UIApplication sharedApplication] delegate] window].safeAreaInsets;
    
    CGFloat newComposeInputViewY = self.view.frame.size.height - self.currentKeyboardHeight - self.composeInputView.frame.size.height - self.tabBarController.tabBar.frame.size.height + safeAreaInsets.bottom;
    self.composeInputView.frame = CGRectMake(self.composeInputView.frame.origin.x, newComposeInputViewY, self.composeInputView.frame.size.width, self.composeInputView.frame.size.height);
    
    self.rs_tableView.contentInset = UIEdgeInsetsMake(self.rs_tableView.contentInset.top, 0, self.composeInputView.frame.size.height - safeAreaInsets.bottom, 0);
    self.rs_tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, self.rs_tableView.contentInset.left, self.rs_tableView.contentInset.bottom, self.rs_tableView.contentInset.right);
    
    if ([self.composeInputView isHidden]) {
        self.composeInputView.tag = 1;
        self.composeInputView.transform = CGAffineTransformMakeTranslation(0, self.composeInputView.frame.size.height);
        self.composeInputView.hidden = false;
        [UIView animateWithDuration:0.4f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.composeInputView.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            self.composeInputView.tag = 0;
        }];
    }
}
- (void)hideComposeInputView {
    _yTranslation = 0;
    _scrollingDownwards = false;
    self.composeInputView.transform = CGAffineTransformIdentity;
    
    self.rs_tableView.contentInset = UIEdgeInsetsMake(self.rs_tableView.contentInset.top, self.rs_tableView.contentInset.left, 0, self.rs_tableView.contentInset.right);
    self.rs_tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, self.rs_tableView.contentInset.left, self.rs_tableView.contentInset.bottom, self.rs_tableView.contentInset.right);
    
    if (![self.composeInputView isHidden]) {
        self.composeInputView.tag = 1;
        [UIView animateWithDuration:0.5f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.composeInputView.transform = CGAffineTransformMakeTranslation(0, self.composeInputView.frame.size.height);
        } completion:^(BOOL finished) {
            self.composeInputView.tag = 0;
            self.composeInputView.hidden = true;
        }];
    }
}

@end
