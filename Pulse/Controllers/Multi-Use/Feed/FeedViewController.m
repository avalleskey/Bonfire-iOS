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

@end

@implementation FeedViewController

static NSString * const reuseIdentifier = @"Post";
static NSString * const suggestionsCellIdentifier = @"ChannelSuggestionsCell";

- (id)initWithFeedType:(FeedType)feedType {
    self = [super init];
    if (self) {
        self.feedType = feedType;
        [self setupTableView];
        [self setupErrorView];
    }
    
    return self;
}
- (void)setupTableView {
    self.tableView = [[RSTableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    tv.separatorColor = [UIColor separatorColor];
    tv.separatorInset = UIEdgeInsetsZero;
    tv.dataType = RSTableViewTypeFeed;
    tv.dataSubType = (self.feedType == FeedTypeTimeline ? RSTableViewSubTypeHome : RSTableViewSubTypeTrending);
    tv.loading = true;
    tv.loadingMore = false;
    tv.paginationDelegate = self;
    self.tableView.refreshControl = [[UIRefreshControl alloc] init];
    [self.tableView sendSubviewToBack:self.tableView.refreshControl];
    [self.tableView.refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsZero;
    
    self.manager = [HAWebService manager];
    [self setupContent];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor colorWithWhite:1 alpha:1];
    self.navigationItem.hidesBackButton = true;
    
    [self setupNavigationBar];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userUpdated:) name:@"UserUpdated" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newPostBegan:) name:@"NewPostBegan" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newPostCompleted:) name:@"NewPostCompleted" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newPostFailed:) name:@"NewPostFailed" object:nil];
}

- (void)userUpdated:(NSNotification *)notification {
    if ([notification.object isKindOfClass:[User class]]) {
        User *user = notification.object;
        if ([user.identifier isEqualToString:[Session sharedInstance].currentUser.identifier]) {
            [self.tableView reloadData];
        }
    }
}

- (void)newPostBegan:(NSNotification *)notification {
    Post *tempPost = notification.object;
    
    if (tempPost != nil && tempPost.attributes.details.parent == 0) {
        // TODO: Check for image as well
        self.errorView.hidden = true;
        [tv.stream addTempPost:tempPost];
        [tv refresh];
        [tv scrollToTop];
    }
}
- (void)newPostCompleted:(NSNotification *)notification {
    NSDictionary *info = notification.object;
    NSString *tempId = info[@"tempId"];
    Post *post = info[@"post"];
    
    if (post != nil && post.attributes.details.parent == 0) {
        // TODO: Check for image as well
        self.errorView.hidden = true;
        
        [tv.stream updateTempPost:tempId withFinalPost:post];
        [tv refresh];
    }
}
// TODO: Allow tap to retry for posts
- (void)newPostFailed:(NSNotification *)notification {
    Post *tempPost = notification.object;
    
    if (tempPost != nil && tempPost.attributes.details.parent == 0) {
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
        
        // fetch new posts after 5mins
        NSTimeInterval secondsSinceLastFetch = [lastFetch timeIntervalSinceNow];
        NSLog(@"seconds since last fetch: %f", secondsSinceLastFetch);
        if (secondsSinceLastFetch < -(2 * 60)) {
            [self fetchNewPosts];
        }
    }
    else {
        self.view.tag = 1;
        
        self.morePostsIndicator = [UIButton buttonWithType:UIButtonTypeCustom];
        self.morePostsIndicator.frame = CGRectMake(self.view.frame.size.width / 2 - (134 / 2), self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height + 12, 134, 34);
        self.morePostsIndicator.layer.masksToBounds = false;
        self.morePostsIndicator.layer.shadowOffset = CGSizeMake(0, 1);
        self.morePostsIndicator.layer.shadowColor = [UIColor blackColor].CGColor;
        self.morePostsIndicator.layer.shadowOpacity = 0.1;
        self.morePostsIndicator.layer.shadowRadius = 2.f;
        self.morePostsIndicator.tag = 0; // inactive
        self.morePostsIndicator.layer.cornerRadius = self.morePostsIndicator.frame.size.height / 2;
        self.morePostsIndicator.backgroundColor = [[UIColor bonfireBrand] colorWithAlphaComponent:0.98];
        [self.morePostsIndicator setTitle:@"See new Posts" forState:UIControlStateNormal];
        [self.morePostsIndicator setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.morePostsIndicator.titleLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightSemibold];
        [self.navigationController.view insertSubview:self.morePostsIndicator belowSubview:self.navigationController.navigationBar];
        
        [self.morePostsIndicator bk_addEventHandler:^(id sender) {
            [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.morePostsIndicator.transform = CGAffineTransformMakeScale(0.9, 0.9);
            } completion:nil];
        } forControlEvents:UIControlEventTouchDown];
        
        [self.morePostsIndicator bk_addEventHandler:^(id sender) {
            [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.morePostsIndicator.transform = CGAffineTransformMakeScale(1, 1);
            } completion:nil];
        } forControlEvents:(UIControlEventTouchCancel|UIControlEventTouchDragExit)];
        
        [self.morePostsIndicator bk_whenTapped:^{
            [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.morePostsIndicator.transform = CGAffineTransformMakeScale(1, 1);
            } completion:nil];
            
            [self hideMorePostsIndicator:YES];
            
            [tv scrollToTop];
        }];
        
        [self hideMorePostsIndicator:false];
    }
    
    [self styleOnAppear];
}

- (void)hideMorePostsIndicator:(BOOL)animated {
    NSLog(@"hide more posts indicator");
    self.morePostsIndicator.tag = 0;
    [UIView animateWithDuration:(animated?0.8f:0) delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.morePostsIndicator.center = CGPointMake(self.morePostsIndicator.center.x, self.morePostsIndicator.frame.size.height * -.5);
    } completion:nil];
}
- (void)showMorePostsIndicator:(BOOL)animated {
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

- (void)styleOnAppear {
    self.errorView.center = CGPointMake(self.view.frame.size.width / 2, self.tableView.frame.size.height / 2 - self.navigationController.navigationBar.frame.size.height - self.navigationController.navigationBar.frame.origin.y);
}

- (void)setupErrorView {
    self.errorView = [[ErrorView alloc] initWithFrame:CGRectMake(16, 0, self.view.frame.size.width - 32, 100) title:@"Room Not Found" description:@"We couldn’t find the Room you were looking for" type:ErrorViewTypeNotFound];
    self.errorView.center = self.tableView.center;
    self.errorView.hidden = true;
    [self.tableView addSubview:self.errorView];
    
    [self.errorView bk_whenTapped:^{
        self.errorView.hidden = true;
        
        tv.loading = true;
        tv.loadingMore = false;
        [self.tableView reloadData];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self getPostsWithSinceId:0 maxId:0];
        });
    }];
}

- (void)setupContent {
    tv.stream = [[PostStream alloc] init];
    
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
    
    if (cache.count > 0) {
        NSLog(@"cache count: %ld", cache.count);
        
        tv.stream.posts = @[];
        tv.stream.pages = [[NSMutableArray alloc] init];
        
        PostStreamPage *page = [[PostStreamPage alloc] initWithDictionary:@{@"data": cache} error:nil];
        [tv.stream appendPage:page];
        
        NSLog(@"add cache'd page with top id: %ld", (long)page.topId);
        
        [tv refresh];
    }
    else {
        tv.stream = [[PostStream alloc] init];
    }
}

- (void)fetchNewPosts {
    NSLog(@"fetchNewPosts()");
    lastFetch = [NSDate new];
    [self getPostsWithSinceId:tv.stream.topId maxId:0];
}

- (void)setupNavigationBar {
    self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)tableViewDidScroll:(UITableView *)tableView {
    /*
    if (tableView.contentOffset.y <= 100 && self.morePostsIndicator.tag == 1) {
        NSLog(@"hide that post indicator");
        [self hideMorePostsIndicator:YES];
    }
     */
}

- (void)tableView:(id)tableView didRequestNextPageWithMaxId:(NSInteger)maxId {
    if (tv.stream.posts.count > 0) {
        Post *lastPost = [tv.stream.posts lastObject];
        
        [self getPostsWithSinceId:0 maxId:lastPost.identifier];
    }
}

- (void)refresh {
    self.userDidRefresh = true;
    [self fetchNewPosts];
}
- (void)getPostsWithSinceId:(NSInteger)sinceId maxId:(NSInteger)maxId {
    self.tableView.hidden = false;
    if ([self.tableView isKindOfClass:[RSTableView class]] && tv.stream.posts.count == 0) {
        self.errorView.hidden = true;
        tv.loading = true;
        [tv refresh];
    }
    
    NSString *url;
    if (self.feedType == FeedTypeTrending) {
        url = [NSString stringWithFormat:@"%@/%@/streams/trending", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"]];
    }
    else if (self.feedType == FeedTypeTimeline) {
        url = [NSString stringWithFormat:@"%@/%@/streams/me", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"]];
    }
    
    [self.manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    self.manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [[Session sharedInstance] authenticate:^(BOOL success, NSString *token) {
        if (success) {
            [self.manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
            
            NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
            if (sinceId != 0 || maxId == 0) {
                [params setObject:[NSNumber numberWithInteger:sinceId] forKey:@"since_id"];
            }
            if (maxId != 0) {
                [params setObject:[NSNumber numberWithInteger:maxId-1] forKey:@"max_id"];
            }
            
            NSLog(@"params: %@", params);
            
            [self.manager GET:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                PostStreamPage *page = [[PostStreamPage alloc] initWithDictionary:responseObject error:nil];
                if (page.data.count > 0) {
                    if (sinceId != 0) {
                        [tv.stream prependPage:page];
                    }
                    else {
                        [tv.stream appendPage:page];
                    }
                    
                    // save cache
                    NSString *cacheKey;
                    if (self.feedType == FeedTypeTimeline) {
                        cacheKey = @"home_feed_cache";
                    }
                    if (self.feedType == FeedTypeTrending) {
                        cacheKey = @"trending_feed_cache";
                    }
                    
                    if (cacheKey) {
                        NSArray *newCache = tv.stream.posts;
                        if (newCache.count > MAX_FEED_CACHED_POSTS) {
                            newCache = [newCache subarrayWithRange:NSMakeRange(0, MAX_FEED_CACHED_POSTS)];
                        }
                        
                        [[PINCache sharedCache] setObject:newCache forKey:cacheKey];
                    }
                }
                
                if (tv.stream.posts.count == 0) {
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
                tv.loadingMore = false;
                
                [tv refresh];
                
                if (self.userDidRefresh) {
                    self.userDidRefresh = false;
                }
                else {
                    /* DEBUG
                    NSLog(@"posts count: %ld", tv.stream.posts.count);
                    NSLog(@"posts count: %ld", page.data.count);
                    NSLog(@"posts count: %f", self.tableView.contentOffset.y);
                     */
                    
                    if (tv.stream.posts.count > 0 && page.data.count > 0 && self.tableView.contentOffset.y > 100 && sinceId != 0) {
                        NSLog(@"show more posts indicator");
                        [self showMorePostsIndicator:YES];
                    }
                }
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                NSLog(@"FeedViewController / getPosts() - ErrorResponse: %@", ErrorResponse);
                
                [self loadCache];
                
                if (tv.stream.posts.count == 0) {
                    self.errorView.hidden = false;
                    [self.errorView updateType:ErrorViewTypeGeneral];
                    [self.errorView updateTitle:@"Error Loading"];
                    [self.errorView updateDescription:@"Check your network settings and tap here to try again"];
                }
                
                self.loading = false;
                tv.loading = false;
                tv.loadingMore = false;
                self.tableView.userInteractionEnabled = true;
                [tv refresh];
            }];
        }
    }];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

@end
