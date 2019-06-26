//
//  FeedViewController.m
//
//
//  Created by Austin Valleskey on 9/19/18.
//

#import "FeedViewController.h"
#import "ComplexNavigationController.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import "SimpleNavigationController.h"
#import "InsightsLogger.h"
#import "UIColor+Palette.h"
#import <PINCache/PINCache.h>
#import "TabController.h"
#import "HAWebService.h"
#import "MiniAvatarListCell.h"
@import Firebase;

#define tv ((RSTableView *)self.tableView)

@interface FeedViewController () {
    int previousTableViewYOffset;
    NSDate *lastFetch;
}

@property (nonatomic) BOOL loading;
@property (nonatomic) BOOL userDidRefresh;

@property CGFloat minHeaderHeight;
@property CGFloat maxHeaderHeight;
@property (nonatomic, strong) NSMutableArray *posts;

@property (nonatomic, strong) NSMutableArray *users;
@property (nonatomic) BOOL loadingUsers;
@property (nonatomic) BOOL errorLoadingUsers;

@end

@implementation FeedViewController

static NSString * const reuseIdentifier = @"Post";

- (id)initWithFeedType:(FeedType)feedType {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.feedType = feedType;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupTableView];
    [self setupErrorView];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userUpdated:) name:@"UserUpdated" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newPostBegan:) name:@"NewPostBegan" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newPostCompleted:) name:@"NewPostCompleted" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newPostFailed:) name:@"NewPostFailed" object:nil];
    
    if (self.feedType == FeedTypeTimeline) {
        //tv.parentObject = nil; // in the future set this to @[] or the users following cache
        
        // Google Analytics
        [FIRAnalytics setScreenName:@"Home" screenClass:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchNewPosts) name:@"FetchNewTimelinePosts" object:nil];
    }
    else if (self.feedType == FeedTypeTrending) {
        // Google Analytics
        [FIRAnalytics setScreenName:@"Trending" screenClass:nil];
    }
}

- (void)setupTableView {
    self.tableView = [[RSTableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    tv.separatorColor = [UIColor separatorColor];
    tv.dataType = RSTableViewTypeFeed;
    tv.tableViewStyle = RSTableViewStyleDefault;
    tv.dataSubType = (self.feedType == FeedTypeTimeline ? RSTableViewSubTypeHome : RSTableViewSubTypeTrending);
    tv.loading = true;
    tv.loadingMore = false;
    tv.paginationDelegate = self;
    tv.showsVerticalScrollIndicator = false;
    self.tableView.refreshControl = [[UIRefreshControl alloc] init];
    [self.tableView sendSubviewToBack:self.tableView.refreshControl];
    [self.tableView.refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsZero;
    
    [self setupContent];
}

- (void)userUpdated:(NSNotification *)notification {
    if ([notification.object isKindOfClass:[User class]]) {
        User *user = notification.object;
        if ([user.identifier isEqualToString:[Session sharedInstance].currentUser.identifier]) {
            [tv refresh];
        }
    }
}

- (void)newPostBegan:(NSNotification *)notification {
    if (self.feedType != FeedTypeTimeline) return;
    
    Post *tempPost = notification.object;
    
    if (tempPost != nil && tempPost.attributes.details.parentId == 0) {
        // TODO: Check for image as well
        self.errorView.hidden = true;

        [tv beginUpdates];
        if (tv.stream.tempPostPosition == PostStreamOptionTempPostPositionBottom) {
            // bottom
            [tv insertSections:[NSIndexSet indexSetWithIndex:[tv numberOfSections]] withRowAnimation:UITableViewRowAnimationNone];
        }
        else {
            // top
            [tv insertSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationNone];
        }
        [tv.stream addTempPost:tempPost];
        [tv endUpdates];
    }
}
- (void)newPostCompleted:(NSNotification *)notification {
    if (self.feedType != FeedTypeTimeline) return;
    
    NSDictionary *info = notification.object;
    NSString *tempId = info[@"tempId"];
    Post *post = info[@"post"];
    
    if (post != nil && post.attributes.details.parentId == 0) {
        // TODO: Check for image as well
        self.errorView.hidden = true;
        
        BOOL removedTempPost = [tv.stream removeTempPost:tempId];
        
        if (removedTempPost) {
            [self fetchNewPosts];
        }
    }
}
// TODO: Allow tap to retry for posts
- (void)newPostFailed:(NSNotification *)notification {
    if (self.feedType != FeedTypeTimeline) return;
    
    Post *tempPost = notification.object;
    
    if (tempPost != nil && tempPost.attributes.details.parentId == 0) {
        // TODO: Check for image as well
        [tv.stream removeTempPost:tempPost.tempId];
        [tv refresh];
        self.errorView.hidden = (tv.stream.posts.count != 0);
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.view.tag == 1) {
        if (self.feedType == FeedTypeTimeline) {
            [InsightsLogger.sharedInstance openAllVisiblePostInsightsInTableView:self.tableView seenIn:InsightSeenInHomeView];
        }
        else {
            [InsightsLogger.sharedInstance openAllVisiblePostInsightsInTableView:self.tableView seenIn:InsightSeenInTrendingView];
        }
        
        // fetch new posts after 2mins
        NSTimeInterval secondsSinceLastFetch = [lastFetch timeIntervalSinceNow];
        NSLog(@"seconds since last fetch: %f", -secondsSinceLastFetch);
        if (secondsSinceLastFetch < -(2 * 60)) {
            [self fetchNewPosts];
        }
    }
    else {
        self.view.tag = 1;
        
        self.tableView.backgroundColor = [UIColor whiteColor];
        
        self.morePostsIndicator = [UIButton buttonWithType:UIButtonTypeCustom];
        self.morePostsIndicator.frame = CGRectMake(self.view.frame.size.width / 2 - (156 / 2), self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height + 12, 156, 40);
        self.morePostsIndicator.layer.masksToBounds = false;
        self.morePostsIndicator.layer.shadowOffset = CGSizeMake(0, 1);
        self.morePostsIndicator.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.12f].CGColor;
        self.morePostsIndicator.layer.shadowOpacity = 1.f;
        self.morePostsIndicator.layer.shadowRadius = 2.f;
        self.morePostsIndicator.tag = 0; // inactive
        self.morePostsIndicator.layer.cornerRadius = self.morePostsIndicator.frame.size.height / 2;
        self.morePostsIndicator.backgroundColor = [UIColor colorWithWhite:1 alpha:0.96];
        [self.morePostsIndicator setTitle:@"See new Posts" forState:UIControlStateNormal];
        [self.morePostsIndicator setTitleColor:[UIColor bonfireBlack] forState:UIControlStateNormal];
        self.morePostsIndicator.titleLabel.font = [UIFont systemFontOfSize:16.f weight:UIFontWeightBold];
        self.morePostsIndicator.layer.shouldRasterize = true;
        self.morePostsIndicator.layer.rasterizationScale = [UIScreen mainScreen].scale;
        CGFloat intrinsticWidth = self.morePostsIndicator.intrinsicContentSize.width + (18*2);
        self.morePostsIndicator.frame = CGRectMake(self.view.frame.size.width / 2 - intrinsticWidth / 2, self.morePostsIndicator.frame.origin.y, intrinsticWidth, self.morePostsIndicator.frame.size.height);
        
        [self.navigationController.view insertSubview:self.morePostsIndicator belowSubview:self.navigationController.navigationBar];
        
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
            [self hideMorePostsIndicator:YES];
            
            [tv scrollToTop];
        }];
        
        [self hideMorePostsIndicator:false];
        
        tv.tableViewStyle = RSTableViewStyleDefault;
    }
    
    self.errorView.center = CGPointMake(self.view.frame.size.width / 2, self.tableView.frame.size.height / 2 - self.navigationController.navigationBar.frame.size.height - self.navigationController.navigationBar.frame.origin.y);
}

- (void)hideMorePostsIndicator:(BOOL)animated {
    NSLog(@"hide more posts indicator");
    if ([self.tabBarController isKindOfClass:[TabController class]]) {
        // remove dot from home tab
        [(TabController *)self.tabBarController setBadgeValue:nil forItem:self.navigationController.tabBarItem];
    }

    self.morePostsIndicator.tag = 0;
    [UIView animateWithDuration:(animated?0.8f:0) delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.morePostsIndicator.center = CGPointMake(self.morePostsIndicator.center.x, self.morePostsIndicator.frame.size.height * -.5);
    } completion:nil];
}
- (void)showMorePostsIndicator:(BOOL)animated {
    if ([self.tabBarController isKindOfClass:[TabController class]]) {
        // add dot to home tab
        [(TabController *)self.tabBarController setBadgeValue:@"1" forItem:self.navigationController.tabBarItem];
    }
    
    self.morePostsIndicator.tag = 1;
    [UIView animateWithDuration:(animated?1.2f:0) delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.morePostsIndicator.center = CGPointMake(self.morePostsIndicator.center.x, self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height + 12 + (self.morePostsIndicator.frame.size.height * 0.5));
    } completion:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [InsightsLogger.sharedInstance closeAllVisiblePostInsightsInTableView:self.tableView];
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.errorView.center = CGPointMake(self.view.frame.size.width / 2, self.tableView.frame.size.height / 2 - self.navigationController.navigationBar.frame.size.height - self.navigationController.navigationBar.frame.origin.y);
    
    // Register Siri intent
    NSString *activityTypeString = [NSString stringWithFormat:@"com.Ingenious.bonfire.open-feed-%@", self.feedType == FeedTypeTrending ? @"trending" : @"timeline"];
    NSUserActivity *activity = [[NSUserActivity alloc] initWithActivityType:activityTypeString];
    if (self.feedType == FeedTypeTrending) {
        activity.title = [NSString stringWithFormat:@"View recent trending posts"];
    }
    else if (self.feedType == FeedTypeTimeline) {
        activity.title = [NSString stringWithFormat:@"See what's new"];
    }
    activity.userInfo = @{@"feed": [NSNumber numberWithInt:self.feedType]};
    activity.eligibleForSearch = true;
    if (@available(iOS 12.0, *)) {
        activity.eligibleForPrediction = true;
        activity.persistentIdentifier = activityTypeString;
    } else {
        // Fallback on earlier versions
    }
    self.view.userActivity = activity;
    [activity becomeCurrent];
}

- (void)setupErrorView {
    self.errorView = [[ErrorView alloc] initWithFrame:CGRectMake(16, 0, self.view.frame.size.width - 32, 100) title:@"Error Loading" description:@"Check your network settings and tap here to try again" type:ErrorViewTypeNotFound];
    self.errorView.center = self.tableView.center;
    self.errorView.hidden = true;
    [self.tableView addSubview:self.errorView];
    
    [self.errorView bk_whenTapped:^{
        self.errorView.hidden = true;
        
        tv.loading = true;
        tv.loadingMore = false;
        [self.tableView reloadData];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            tv.stream = [[PostStream alloc] init];
            tv.stream.delegate = self;
            [self getPostsWithCursor:PostStreamPagingCursorTypeNone];
        });
    }];
}

- (void)setupContent {
    tv.stream = [[PostStream alloc] init];
    tv.stream.delegate = self;
    
    [self loadCache];
    [self fetchNewPosts];
}

- (void)loadCache {    
    NSArray *cache = @[];
    if (self.feedType == FeedTypeTimeline) {
        cache = [[PINCache sharedCache] objectForKey:@"home_feed_cache"];
    }
    if (self.feedType == FeedTypeTrending) {
        cache = [[PINCache sharedCache] objectForKey:@"trending_feed_cache"];
    }
    
//    NSLog(@"home feed cache:");
//    NSLog(@"%@", [[PINCache sharedCache] objectForKey:@"home_feed_cache"]);
    
    if (cache.count > 0) {
        tv.stream = [[PostStream alloc] init];
        tv.stream.delegate = self;
        
        for (NSDictionary *pageDict in cache) {
            PostStreamPage *page = [[PostStreamPage alloc] initWithDictionary:pageDict error:nil];
            [tv.stream appendPage:page];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [tv refresh];
        });
    }
    else {
        tv.stream = [[PostStream alloc] init];
        tv.stream.delegate = self;
    }
}
- (void)saveCache {
    NSString *cacheKey;
    if (self.feedType == FeedTypeTimeline) {
        cacheKey = @"home_feed_cache";
    }
    if (self.feedType == FeedTypeTrending) {
        cacheKey = @"trending_feed_cache";
    }
    
    if (cacheKey) {
        NSMutableArray *newCache = [[NSMutableArray alloc] init];

        NSInteger postsCount = 0;
        for (NSInteger i = 0; i < tv.stream.pages.count && postsCount < MAX_FEED_CACHED_POSTS; i++) {
            postsCount =+ tv.stream.pages[i].data.count;
            [newCache addObject:[tv.stream.pages[i] toDictionary]];
        }
        
        [[PINCache sharedCache] setObject:[newCache copy] forKey:cacheKey];
    }
}
- (void)postStreamDidUpdate:(PostStream *)stream {
    [self saveCache];
}

- (void)fetchNewPosts {
    lastFetch = [NSDate new];
    [self getPostsWithCursor:PostStreamPagingCursorTypePrevious];
}

- (void)tableViewDidScroll:(UITableView *)tableView {
    CGFloat normalizedScrollViewContentOffsetY = tableView.contentOffset.y + tableView.adjustedContentInset.top;
    
    if (normalizedScrollViewContentOffsetY <= 100 && self.morePostsIndicator.tag == 1) {
        [self hideMorePostsIndicator:YES];
    }
}

- (void)tableView:(id)tableView didRequestNextPageWithMaxId:(NSInteger)maxId {
    NSLog(@"has loaded cursor (%@):::: %@", tv.stream.nextCursor, [tv.stream hasLoadedCursor:tv.stream.nextCursor] ? @"true" : @"false");
    
    if (tv.stream.nextCursor.length > 0 && ![tv.stream hasLoadedCursor:tv.stream.nextCursor]) {
        NSLog(@"get next cursor:: %@", tv.stream.nextCursor);
        [self getPostsWithCursor:PostStreamPagingCursorTypeNext];
    }
}

- (void)refresh {
    self.userDidRefresh = true;
    [self fetchNewPosts];
}
- (void)getPostsWithCursor:(PostStreamPagingCursorType)cursorType {
    self.tableView.hidden = false;
    if ([self.tableView isKindOfClass:[RSTableView class]] && tv.stream.posts.count == 0) {
        self.errorView.hidden = true;
        tv.loading = true;
        [tv refresh];
    }
    
    NSString *url;
    if (self.feedType == FeedTypeTrending) {
        url = @"streams/trending";
    }
    else if (self.feedType == FeedTypeTimeline) {
        url = @"streams/me";
    }
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    if (cursorType == PostStreamPagingCursorTypeNext) {
        [params setObject:tv.stream.nextCursor forKey:@"cursor"];
    }
    else if (tv.stream.prevCursor.length > 0) {
        [params setObject:tv.stream.prevCursor forKey:@"cursor"];
    }
    if ([params objectForKey:@"cursor"]) {
        [tv.stream addLoadedCursor:params[@"cursor"]];
    }
    
    NSLog(@"GET -> %@", url);
    NSLog(@"params: %@", params);
    
    [[[HAWebService managerWithContentType:kCONTENT_TYPE_JSON] authenticate] GET:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSInteger postsBefore = tv.stream.posts.count;
        
        PostStreamPage *page = [[PostStreamPage alloc] initWithDictionary:responseObject error:nil];
        if (page.data.count > 0) {
            if (cursorType == PostStreamPagingCursorTypeNone || cursorType == PostStreamPagingCursorTypePrevious) {
                [tv.stream prependPage:page];
            }
            else if (cursorType == PostStreamPagingCursorTypeNext) {
                [tv.stream appendPage:page];
            }
            
            [self saveCache];
        }
        
        NSInteger postsAfter = tv.stream.posts.count;
        
        if (tv.stream.posts.count == 0 && self.feedType == FeedTypeTimeline) {
            // Error: No posts yet!
            self.errorView.hidden = false;
            
            [self.errorView updateType:ErrorViewTypeHeart];
            [self.errorView updateTitle:@"For You"];
            [self.errorView updateDescription:@"The posts you care about from the Camps and people you care about."];
        }
        else {
            self.errorView.hidden = true;
        }
        
        self.loading = false;
        tv.loading = false;
        if (cursorType == PostStreamPagingCursorTypeNext) {
            tv.loadingMore = false;
        }
        
        NSLog(@"new posts: %ld", postsAfter - postsBefore);
        
        [tv refresh];
        
        if (self.userDidRefresh) {
            self.userDidRefresh = false;
        }
        else {
            // DEBUG
            CGFloat normalizedScrollViewContentOffsetY = tv.contentOffset.y + tv.adjustedContentInset.top;
            
            if (postsAfter > postsBefore && normalizedScrollViewContentOffsetY > 100 && cursorType == PostStreamPagingCursorTypePrevious) {
                [self showMorePostsIndicator:YES];
            }
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        NSLog(@"FeedViewController / getPosts() - ErrorResponse: %@", ErrorResponse);
        
        // NSHTTPURLResponse *httpResponse = error.userInfo[AFNetworkingOperationFailingURLResponseErrorKey];
        // NSInteger statusCode = httpResponse.statusCode;
        // NSLog(@"status code: %ld", (long)statusCode);
        
        if (tv.stream.posts.count == 0) {
            self.errorView.hidden = false;
            
            if ([HAWebService hasInternet]) {
                [self.errorView updateType:ErrorViewTypeGeneral];
                [self.errorView updateTitle:@"Error Loading"];
                [self.errorView updateDescription:@"Check your network settings and tap here to try again"];
            }
            else {
                [self.errorView updateType:ErrorViewTypeNoInternet];
                [self.errorView updateTitle:@"No Internet"];
                [self.errorView updateDescription:@"Check your network settings and tap here to try again"];
            }
        }
        
        self.loading = false;
        tv.loading = false;
        if (cursorType == PostStreamPagingCursorTypeNext) {
            tv.loadingMore = false;
        }
        self.tableView.userInteractionEnabled = true;
        [tv refresh];
    }];
}

@end
