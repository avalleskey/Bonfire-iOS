//
//  FeedViewController.m
//
//
//  Created by Austin Valleskey on 9/19/18.
//

#import "MyFeedViewController.h"
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
@import Firebase;

#define tv ((RSTableView *)self.tableView)

@interface MyFeedViewController () {
    int previousTableViewYOffset;
}

@property (nonatomic) BOOL loading;
@property (nonatomic) BOOL userDidRefresh;
@property (nonatomic, strong) NSDate *lastFetch;

@property (nonatomic, strong) BFVisualErrorView *errorView;

@property CGFloat minHeaderHeight;
@property CGFloat maxHeaderHeight;
@property (nonatomic, strong) NSMutableArray *posts;

@property (nonatomic, strong) NSMutableArray <Camp *> *suggestedCamps;

@property (nonatomic, strong) FBShimmeringView *titleView;

@end

@implementation MyFeedViewController

static NSString * const recentCardsCellReuseIdentifier = @"RecentCampsCell";

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setup];
    
    self.view.backgroundColor = [UIColor contentBackgroundColor];
    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recentsUpdated:) name:@"RecentsUpdated" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userUpdated:) name:@"UserUpdated" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newPostBegan:) name:@"NewPostBegan" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newPostCompleted:) name:@"NewPostCompleted" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newPostFailed:) name:@"NewPostFailed" object:nil];
    
    // Google Analytics
    [FIRAnalytics setScreenName:@"My Feed" screenClass:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchNewPosts) name:@"FetchNewTimelinePosts" object:nil];
    
    self.tableView.alpha = 0;
    self.navigationController.view.backgroundColor = [UIColor contentBackgroundColor];
    
    self.launchLogo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bonfire_wordmark"]];
    self.launchLogo.frame = CGRectMake(self.navigationController.view.frame.size.width / 2 - 102, self.navigationController.view.frame.size.height / 2 - 25, 204, 50);
    self.launchLogo.alpha = 0.25;
    [self.navigationController.view addSubview:self.launchLogo];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if ([self isBeingPresented] || [self isMovingToParentViewController]) {
        // first time
        [self setupTitleView];
        [self setupMorePostsIndicator];
        
        tv.tableViewStyle = RSTableViewStyleDefault;
        
        [self positionErrorView];
        
        if ([BFTipsManager hasSeenTip:@"about_sparks_info"] == false) {
            BFTipObject *tipObject = [BFTipObject tipWithCreatorType:BFTipCreatorTypeBonfireTip creator:nil title:@"Sparks help posts go viral 🚀" text:@"Sparks show a post to more people. Only the creator can see who sparks a post." cta:nil imageUrl:nil action:^{
                NSLog(@"tip tapped");
            }];
            [[BFTipsManager manager] presentTip:tipObject completion:^{
                NSLog(@"presentTip() completion");
            }];
        }
        
        // present
        self.tableView.transform = CGAffineTransformMakeTranslation(0, 56);
        self.tableView.userInteractionEnabled = false;
        [UIView animateWithDuration:0.35f delay:0 usingSpringWithDamping:0.95f initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.launchLogo.alpha = 0;
            self.launchLogo.transform = CGAffineTransformMakeScale(0.92, 0.92);
        } completion:nil];
        [UIView animateWithDuration:0.56f delay:0.3f usingSpringWithDamping:0.7f initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.tableView.transform = CGAffineTransformMakeTranslation(0, 0);
            self.tableView.alpha = 1;
        } completion:^(BOOL finished) {
            self.tableView.userInteractionEnabled = true;
        }];
    }
    else {
        [InsightsLogger.sharedInstance openAllVisiblePostInsightsInTableView:self.tableView seenIn:InsightSeenInHomeView];
        
        // fetch new posts after 2mins
        NSTimeInterval secondsSinceLastFetch = [self.lastFetch timeIntervalSinceNow];
        // NSLog(@"seconds since last fetch: %f", -secondsSinceLastFetch);
        if (secondsSinceLastFetch < -(2 * 60)) {
            [self fetchNewPosts];
        }
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if ([self isBeingPresented] || [self isMovingToParentViewController]) {
        [self setupContent];
    }
    
    self.errorView.center = CGPointMake(self.view.frame.size.width / 2, self.tableView.frame.size.height / 2 - self.navigationController.navigationBar.frame.size.height - self.navigationController.navigationBar.frame.origin.y);
    
    // Register Siri intent
    NSString *activityTypeString = @"com.Ingenious.bonfire.open-feed-timeline";
    NSUserActivity *activity = [[NSUserActivity alloc] initWithActivityType:activityTypeString];
    activity.title = [NSString stringWithFormat:@"See what's new"];
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
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [InsightsLogger.sharedInstance closeAllVisiblePostInsightsInTableView:self.tableView];
}

#pragma mark - Setup
- (void)setup {
    [self setupTableView];
    [self setupErrorView];
}
- (void)setupTableView {
    self.tableView = [[RSTableView alloc] initWithFrame:CGRectMake(100, self.view.bounds.origin.y, self.view.frame.size.width - 200, self.view.bounds.size.height) style:UITableViewStyleGrouped];
    tv.separatorColor = [UIColor tableViewSeparatorColor];
    tv.dataType = RSTableViewTypeFeed;
    tv.tableViewStyle = RSTableViewStyleDefault;
    tv.loading = true;
    tv.loadingMore = false;
    tv.extendedDelegate = self;
    tv.backgroundColor = [UIColor contentBackgroundColor];
    [self.tableView registerClass:[CampCardsListCell class] forCellReuseIdentifier:recentCardsCellReuseIdentifier];
    tv.showsVerticalScrollIndicator = false;
    self.tableView.refreshControl = [[UIRefreshControl alloc] init];
    [self.tableView sendSubviewToBack:self.tableView.refreshControl];
    [self.tableView.refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsZero;
}
- (void)setupContent {
    tv.stream = [[PostStream alloc] init];
    tv.stream.delegate = self;
    
    [self loadCache];
    
    // load most up to date content
    self.lastFetch = [NSDate new];
    if (tv.stream.prevCursor.length > 0) {
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
    self.errorView.center = self.tableView.center;
    self.errorView.hidden = true;
    [self.tableView addSubview:self.errorView];
}
- (void)setupTitleView {
    UIButton *titleButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [titleButton setTitleColor:[UIColor bonfirePrimaryColor] forState:UIControlStateNormal];
    titleButton.titleLabel.font = ([self.navigationController.navigationBar.titleTextAttributes objectForKey:NSFontAttributeName] ? self.navigationController.navigationBar.titleTextAttributes[NSFontAttributeName] : [UIFont systemFontOfSize:18.f weight:UIFontWeightBold]);
    [titleButton setTitle:self.title forState:UIControlStateNormal];
    titleButton.frame = CGRectMake(0, 0, [titleButton intrinsicContentSize].width, self.navigationController.navigationBar.frame.size.height);
    [titleButton bk_whenTapped:^{
        [tv scrollToTop];
        
        if (!self.loading) {
            // fetch new posts after 2mins
            NSTimeInterval secondsSinceLastFetch = [self.lastFetch timeIntervalSinceNow];
            // NSLog(@"seconds since last fetch: %f", -secondsSinceLastFetch);
            if (secondsSinceLastFetch < -(2 * 60)) {
                [self fetchNewPosts];
            }
        }
    }];
    
    self.titleView = [[FBShimmeringView alloc] initWithFrame:titleButton.frame];
    [self.titleView addSubview:titleButton];
    self.titleView.contentView = titleButton;
    
    self.navigationItem.titleView = titleButton;
}
- (void)setupMorePostsIndicator {
    self.morePostsIndicator = [UIButton buttonWithType:UIButtonTypeCustom];
    self.morePostsIndicator.frame = CGRectMake(self.view.frame.size.width / 2 - (156 / 2), self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height + 12, 156, 40);
    self.morePostsIndicator.layer.masksToBounds = false;
    self.morePostsIndicator.layer.shadowOffset = CGSizeMake(0, 1);
    self.morePostsIndicator.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.12].CGColor;
    self.morePostsIndicator.layer.shadowOpacity = 1.f;
    self.morePostsIndicator.layer.shadowRadius = 2.f;
    self.morePostsIndicator.tag = 0; // inactive
    self.morePostsIndicator.hidden = true;
    self.morePostsIndicator.layer.cornerRadius = self.morePostsIndicator.frame.size.height / 2;
    self.morePostsIndicator.backgroundColor = [UIColor cardBackgroundColor];
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
        [self hideMorePostsIndicator:YES];
        
        [tv scrollToTop];
    }];
    
    [self hideMorePostsIndicator:false];
}

#pragma mark - NSNotification Handlers
- (void)userUpdated:(NSNotification *)notification {
    if ([notification.object isKindOfClass:[User class]]) {
        User *user = notification.object;
        if ([user.identifier isEqualToString:[Session sharedInstance].currentUser.identifier]) {
            [tv refreshAtTop];
        }
    }
}
- (void)newPostBegan:(NSNotification *)notification {
    Post *tempPost = notification.object;
    
    if (tempPost != nil && !tempPost.attributes.parent) {
        // TODO: Check for image as well
        self.errorView.hidden = true;

        [tv.stream addTempPost:tempPost];
        [tv refreshAtTop];
    }
}
- (void)newPostCompleted:(NSNotification *)notification {
    NSDictionary *info = notification.object;
    NSString *tempId = info[@"tempId"];
    Post *post = info[@"post"];
    
    NSLog(@"temp id: %@", tempId);
    NSLog(@"new post:: %@", post.identifier);
    
    if (post != nil) {
        // TODO: Check for image as well
        self.errorView.hidden = true;
        
        BOOL removedTempPost = [tv.stream removeTempPost:tempId];
        
        NSLog(@"removed temp post?? %@", removedTempPost ? @"YES" : @"NO");
        
        if (removedTempPost) {
            [tv.stream removeLoadedCursor:tv.stream.prevCursor];
            [self fetchNewPosts];
        }
    }
}
- (void)newPostFailed:(NSNotification *)notification {
    Post *tempPost = notification.object;
    
    if (tempPost != nil) {
        // TODO: Check for image as well
        [tv.stream removeTempPost:tempPost.tempId];
        [tv refreshAtTop];
        self.errorView.hidden = (tv.stream.posts.count != 0);
    }
}

#pragma mark - Error View
- (void)showErrorViewWithType:(ErrorViewType)type title:(NSString *)title description:(NSString *)description actionTitle:(nullable NSString *)actionTitle actionBlock:(void (^ __nullable)(void))actionBlock {
    self.errorView.hidden = false;
    self.errorView.visualError = [BFVisualError visualErrorOfType:type title:title description:description actionTitle:actionTitle actionBlock:actionBlock];
    [self.tableView reloadData];
}
- (void)positionErrorView {
    self.errorView.center = CGPointMake(self.view.frame.size.width / 2, self.tableView.frame.size.height / 2 - self.navigationController.navigationBar.frame.size.height - self.navigationController.navigationBar.frame.origin.y);
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
    } completion:^(BOOL finished) {
        self.morePostsIndicator.hidden = true;
    }];
}
- (void)showMorePostsIndicator:(BOOL)animated {
    self.morePostsIndicator.hidden = false;
//    if ([self.tabBarController isKindOfClass:[TabController class]]) {
//        // add dot to home tab
//        [(TabController *)self.tabBarController setBadgeValue:@"1" forItem:self.navigationController.tabBarItem];
//    }
    
    self.morePostsIndicator.tag = 1;
    [UIView animateWithDuration:(animated?1.2f:0) delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:(UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionAllowUserInteraction) animations:^{
        self.morePostsIndicator.center = CGPointMake(self.morePostsIndicator.center.x, self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height + 12 + (self.morePostsIndicator.frame.size.height * 0.5));
    } completion:nil];
}

#pragma mark - Cache Management
- (void)loadCache {
    tv.stream = [[PostStream alloc] init];
    tv.stream.delegate = self;
    
    // load feed cache
    NSArray *cache = [[PINCache sharedCache] objectForKey:@"home_feed_cache"];
    if (cache && cache.count > 0) {
        for (NSDictionary *pageDict in cache) {
            PostStreamPage *page = [[PostStreamPage alloc] initWithDictionary:pageDict error:nil];
            [tv.stream appendPage:page];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [tv refreshAtTop];
        });
    }
}
- (void)saveCache {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *cacheKey = @"home_feed_cache";
        
        if (cacheKey) {
            NSMutableArray *newCache = [[NSMutableArray alloc] init];

            NSInteger postsCount = 0;
            for (NSInteger i = 0; i < tv.stream.pages.count && postsCount < MAX_FEED_CACHED_POSTS; i++) {
                postsCount =+ tv.stream.pages[i].data.count;
                [newCache addObject:[tv.stream.pages[i] toDictionary]];
            }
            
            [[PINCache sharedCache] setObject:[newCache copy] forKey:cacheKey];
        }
    });
}
- (void)postStreamDidUpdate:(PostStream *)stream {
    [self saveCache];
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
    
    [self.tableView reloadData];
}
- (void)recentsUpdated:(NSNotification *)sender {
    [self loadSuggestedCamps];
    
    [self.tableView reloadData];
}
// Fetch posts
- (void)getPostsWithCursor:(StreamPagingCursorType)cursorType {
    NSString *url = @"streams/me";
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    if (cursorType == StreamPagingCursorTypeNext) {
        [params setObject:tv.stream.nextCursor forKey:@"cursor"];
    }
    else if (tv.stream.prevCursor.length > 0) {
        [params setObject:tv.stream.prevCursor forKey:@"cursor"];
    }
    if ([params objectForKey:@"cursor"]) {
        if ([tv.stream hasLoadedCursor:params[@"cursor"]]) {
            return;
        }
        else {
            [tv.stream addLoadedCursor:params[@"cursor"]];
        }
    }
    
    if ([self.tableView isKindOfClass:[RSTableView class]] && tv.stream.posts.count == 0) {
        self.errorView.hidden = true;
        tv.loading = true;
        [tv hardRefresh];
    }
    
    if (cursorType == StreamPagingCursorTypePrevious && tv.stream.posts.count > 0) {
        self.titleView.shimmering = true;
    }
    
    [[[HAWebService managerWithContentType:kCONTENT_TYPE_JSON] authenticate] GET:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSInteger postsBefore = tv.stream.posts.count;
        
        PostStreamPage *page = [[PostStreamPage alloc] initWithDictionary:responseObject error:nil];
        if (page.data.count > 0) {
            if (!tv.stream) {
                tv.stream = [[PostStream alloc] init];
            }
            
            if (cursorType == StreamPagingCursorTypeNone || cursorType == StreamPagingCursorTypePrevious) {
                [tv.stream prependPage:page];
            }
            else if (cursorType == StreamPagingCursorTypeNext) {
                [tv.stream appendPage:page];
            }
        }
                
        NSInteger postsAfter = tv.stream.posts.count;
        
        if (tv.stream.posts.count == 0) {
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
        
        self.loading = false;
        tv.loading = false;
        if (cursorType == StreamPagingCursorTypeNext) {
            tv.loadingMore = false;
            
            [tv refreshAtBottom];
        }
        else if (self.userDidRefresh || cursorType == StreamPagingCursorTypeNone) {
            [tv hardRefresh];
        }
        else {
            [tv refreshAtTop];
        }
        
        if (self.userDidRefresh) {
            self.userDidRefresh = false;
        }
        else {
            // DEBUG
            CGFloat normalizedScrollViewContentOffsetY = tv.contentOffset.y + tv.adjustedContentInset.top;
            
            if (postsAfter > postsBefore && normalizedScrollViewContentOffsetY > 0 && cursorType == StreamPagingCursorTypePrevious) {
                [self showMorePostsIndicator:YES];
            }
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (tv.stream.posts.count == 0) {
            self.errorView.hidden = false;
            
            [self showErrorViewWithType:([HAWebService hasInternet] ? ErrorViewTypeGeneral : ErrorViewTypeNoInternet) title:([HAWebService hasInternet] ? @"Error Loading" : @"No Internet") description:@"Check your network settings and tap below to try again" actionTitle:@"Refresh" actionBlock:^{
                [self refresh];
            }];
            
            [self positionErrorView];
        }
        
        self.loading = false;
        tv.loading = false;
        if (cursorType == StreamPagingCursorTypeNext) {
            tv.loadingMore = false;
        }
        self.tableView.userInteractionEnabled = true;
        [tv refreshAtTop];
    }];
}
// Management
- (void)refresh {
    [tv.stream removeLoadedCursor:tv.stream.prevCursor];
    
    self.userDidRefresh = true;
    [self fetchNewPosts];
}
- (void)fetchNewPosts {
    self.lastFetch = [NSDate new];
    [self getPostsWithCursor:StreamPagingCursorTypePrevious];
}
- (void)setLoading:(BOOL)loading {
    if (loading != _loading) {
        _loading = loading;
    }
    
    if (!_loading) {
        [self.refreshControl endRefreshing];
        self.titleView.shimmering = false;
    }
}

#pragma mark - RSTableViewDelegate
- (UIView *)viewForFirstSectionHeader {
//    if (tv.stream.posts.count > 0) {
//        UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, HALF_PIXEL)];
//        separator.backgroundColor = [UIColor tableViewSeparatorColor];
//        return separator;
//    }
    
    return nil;
}
- (CGFloat)heightForFirstSectionHeader {
//    if (tv.stream.posts.count > 0) {
//        return HALF_PIXEL;
//    }
    
    return CGFLOAT_MIN; //52;
}
- (UITableViewCell * _Nullable)cellForRowInFirstSection:(NSInteger)row {
    if (row == 0 && self.suggestedCamps.count > 0) {
        CampCardsListCell *cell = [self.tableView dequeueReusableCellWithIdentifier:recentCardsCellReuseIdentifier forIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
        
        if (cell == nil) {
            cell = [[CampCardsListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:recentCardsCellReuseIdentifier];
        }
        
        cell.size = CAMP_CARD_SIZE_SMALL_MEDIUM;
        
        cell.loading = false;
        cell.camps = [[NSMutableArray alloc] initWithArray:self.suggestedCamps];
        
        return cell;
    }
    
    return nil;
}
- (CGFloat)heightForRowInFirstSection:(NSInteger)row {
    if (row == 0 && self.suggestedCamps.count > 0) {
        return SMALL_MEDIUM_CARD_HEIGHT;
    }
    
    return 0;
}
- (CGFloat)numberOfRowsInFirstSection {
    return 1;
}
- (UIView *)viewForFirstSectionFooter {
    return nil;
}
- (CGFloat)heightForFirstSectionFooter {
    return CGFLOAT_MIN;
}
- (void)tableView:(nonnull id)tableView didRequestNextPageWithMaxId:(NSInteger)maxId {
    if (tv.stream.nextCursor.length > 0 && ![tv.stream hasLoadedCursor:tv.stream.nextCursor]) {
        [self getPostsWithCursor:StreamPagingCursorTypeNext];
    }
}

#pragma mark - UIScrollViewDelegate
- (void)tableViewDidScroll:(UITableView *)tableView {
    CGFloat normalizedScrollViewContentOffsetY = tableView.contentOffset.y + tableView.adjustedContentInset.top;

    if (normalizedScrollViewContentOffsetY <= 100 && self.morePostsIndicator.tag == 1) {
        [self hideMorePostsIndicator:YES];
    }
}

@end
