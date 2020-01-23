//
//  FeedViewController.m
//
//
//  Created by Austin Valleskey on 9/19/18.
//

#import "HomeTableViewController.h"
#import "ComplexNavigationController.h"
#import "SectionStream.h"
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
        
        [self mockSectionedData];
    }
    else {
        [InsightsLogger.sharedInstance openAllVisiblePostInsightsInTableView:self.bf_tableView seenIn:InsightSeenInHomeView];
        
        // fetch new posts after 2mins
        NSTimeInterval secondsSinceLastFetch = [self.lastFetch timeIntervalSinceNow];
        NSLog(@"seconds since last fetch: %f", -secondsSinceLastFetch);
        if (secondsSinceLastFetch < -60) {
            [self fetchNewPosts];
        }
    }
    
//    if (self.morePostsIndicator.tag == 1) {
//        // more posts indicator is visible
//        // ensure the animation didn't get caught off
//        [self showMorePostsIndicator:false];
//    }
    
    [self showComposeInputView];
}

- (void)mockSectionedData {
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"SectionFeed_Sample" ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:bundlePath];
    
    if (data) {
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                
        SectionStreamPage *page = [[SectionStreamPage alloc] initWithDictionary:json error:nil];
        
        [self.bf_tableView.stream appendPage:page];
        [self.bf_tableView reloadData];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if ([self isBeingPresented] || [self isMovingToParentViewController]) {
        [self setupContent];
    }
    
    if (self.bf_tableView.stream.sections.count == 0 && !self.loading) {
        [self fetchNewPosts];
    }
    
    self.errorView.center = CGPointMake(self.view.frame.size.width / 2, self.bf_tableView.frame.size.height / 2 - self.navigationController.navigationBar.frame.size.height - self.navigationController.navigationBar.frame.origin.y);
    
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
    
    [InsightsLogger.sharedInstance closeAllVisiblePostInsightsInTableView:self.bf_tableView];
}

#pragma mark - Setup
- (void)setup {
    [self setupTableView];
    [self setupErrorView];
    [self setupComposeInputView];
}
- (void)setupTableView {
    self.bf_tableView = [[BFComponentSectionTableView alloc] initWithFrame:CGRectMake(100, self.view.bounds.origin.y, self.view.frame.size.width - 200, self.view.bounds.size.height) style:UITableViewStyleGrouped];
    self.bf_tableView.insightSeenInLabel = InsightSeenInHomeView;
    self.bf_tableView.separatorColor = [UIColor tableViewSeparatorColor];
    self.bf_tableView.loadingMore = false;
    self.bf_tableView.extendedDelegate = self;
    self.bf_tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    self.bf_tableView.refreshControl = [[UIRefreshControl alloc] init];
    [self.bf_tableView sendSubviewToBack:self.bf_tableView.refreshControl];
    [self.bf_tableView.refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    
    self.bf_tableView.scrollIndicatorInsets = UIEdgeInsetsZero;
}
- (void)setupContent {
//    [self loadCache];
    
    // load most up to date content
    self.lastFetch = [NSDate new];
    if (self.bf_tableView.stream.prevCursor.length > 0) {
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
    self.errorView.center = self.bf_tableView.center;
    self.errorView.hidden = true;
    [self.bf_tableView addSubview:self.errorView];
}
- (void)setupTitleView {
    UIButton *titleButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [titleButton setImage:[[UIImage imageNamed:@"navBonfireLogo"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [titleButton setImageEdgeInsets:UIEdgeInsetsMake(-1, 0, 0, 0)];
    titleButton.tintColor = [UIColor bonfirePrimaryColor];
    titleButton.frame = CGRectMake(0, 0, [titleButton intrinsicContentSize].width, self.navigationController.navigationBar.frame.size.height);
    [titleButton bk_whenTapped:^{
        [self.bf_tableView scrollToTopWithCompletion:^{
            if (!self.loading) {
                // fetch new posts after 2mins
                NSTimeInterval secondsSinceLastFetch = [self.lastFetch timeIntervalSinceNow];
                // NSLog(@"seconds since last fetch: %f", -secondsSinceLastFetch);
                if (secondsSinceLastFetch < -60) {
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
    self.morePostsIndicator.frame = CGRectMake(self.view.frame.size.width / 2 - (116 / 2), - 50, 116, 40);
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
    self.morePostsIndicator.center = CGPointMake(self.morePostsIndicator.center.x, self.morePostsIndicator.frame.size.height * -.6);
    
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
        [self.bf_tableView scrollToTop];
    }];
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
- (void)privacySelectionDidSelectToPost:(Camp *)selection {
    [self postMessageInCamp:selection];
}

- (void)openPrivacySelector {
    PrivacySelectorTableViewController *sitvc = [[PrivacySelectorTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    sitvc.delegate = self;
    sitvc.postOnSelection = true;
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
- (void)newPostBegan:(NSNotification *)notification {
    Post *tempPost = notification.object;
    
    if (tempPost != nil && !tempPost.attributes.parent) {
        //        // TODO: Check for image as well
        //        self.errorView.hidden = true;
        //
        //        [self.bf_tableView.stream addTempPost:tempPost];
        //        [self.bf_tableView refreshAtTop];
        if (self.navigationController && [self.navigationController isKindOfClass:[SimpleNavigationController class]]) {
            [(SimpleNavigationController *)self.navigationController setProgress:0.7 animated:YES];
        }
    }
}
- (void)newPostCompleted:(NSNotification *)notification {
    NSDictionary *info = notification.object;
    Post *post = info[@"post"];
    
    if (post != nil) {
        self.errorView.hidden = true;
                
        wait(3.5f, ^{
            [self.bf_tableView.stream removeLoadedCursor:self.bf_tableView.stream.prevCursor];
            [self fetchNewPosts];
        });
        
        if (self.navigationController && [self.navigationController isKindOfClass:[SimpleNavigationController class]]) {
            [(SimpleNavigationController *)self.navigationController setProgress:1 animated:YES hideOnCompletion:true];
        }
    }
}
- (void)newPostFailed:(NSNotification *)notification {
    Post *tempPost = notification.object;
    
    if (tempPost != nil) {
        if (self.navigationController && [self.navigationController isKindOfClass:[SimpleNavigationController class]]) {
            [(SimpleNavigationController *)self.navigationController setProgress:0 animated:YES hideOnCompletion:true];
        }
    }
}

#pragma mark - Error View
- (void)showErrorViewWithType:(ErrorViewType)type title:(NSString *)title description:(NSString *)description actionTitle:(nullable NSString *)actionTitle actionBlock:(void (^ __nullable)(void))actionBlock {
    self.errorView.hidden = false;
    self.errorView.visualError = [BFVisualError visualErrorOfType:type title:title description:description actionTitle:actionTitle actionBlock:actionBlock];
    [self.bf_tableView reloadData];
}
- (void)positionErrorView {
    self.errorView.center = CGPointMake(self.view.frame.size.width / 2, self.bf_tableView.frame.size.height / 2 - self.navigationController.navigationBar.frame.size.height - self.navigationController.navigationBar.frame.origin.y);
}

#pragma mark - More Posts Indicator
- (void)hideMorePostsIndicator:(BOOL)animated {
    if ([self.tabBarController isKindOfClass:[TabController class]]) {
        // remove dot from home tab
        [(TabController *)self.tabBarController setBadgeValue:nil forItem:self.navigationController.tabBarItem];
    }
    
    if (self.morePostsIndicator.tag != 0) {
        self.morePostsIndicator.tag = 0;
        
        [UIView animateWithDuration:(animated?0.8f:0) delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.morePostsIndicator.center = CGPointMake(self.morePostsIndicator.center.x, self.morePostsIndicator.frame.size.height * -.6);
            self.morePostsIndicator.alpha = 0;
        } completion:^(BOOL finished) {
            self.morePostsIndicator.hidden = true;
        }];
    }
}
- (void)showMorePostsIndicator:(BOOL)animated {
    if ([self.tabBarController isKindOfClass:[TabController class]]) {
        // remove dot from home tab
        [(TabController *)self.tabBarController setBadgeValue:@" " forItem:self.navigationController.tabBarItem];
    }
    
    if (self.morePostsIndicator.tag != 1) {
        self.morePostsIndicator.tag = 1;
        
        // reset state to ensure it's correct
        self.morePostsIndicator.hidden = false;
        self.morePostsIndicator.alpha = 1;
        self.morePostsIndicator.center = CGPointMake(self.morePostsIndicator.center.x, self.morePostsIndicator.frame.size.height * -.6);
        [UIView animateWithDuration:(animated?1.2f:0) delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:(UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionAllowUserInteraction) animations:^{
            self.morePostsIndicator.center = CGPointMake(self.morePostsIndicator.center.x, self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height + 12 + (self.morePostsIndicator.frame.size.height * 0.5));
        } completion:nil];
    }
}

#pragma mark - Cache Management
- (void)loadCache {
    [self.bf_tableView.stream flush];
    
    // load feed cache
    NSArray *cache = [[PINCache sharedCache] objectForKey:@"home_stream_cache"];
    if (cache && cache.count > 0) {
        for (NSDictionary *pageDict in cache) {
            SectionStreamPage *page = [[SectionStreamPage alloc] initWithDictionary:pageDict error:nil];
            [self.bf_tableView.stream appendPage:page];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.bf_tableView.loading = (self.bf_tableView.stream.sections.count == 0);
            [self.bf_tableView hardRefresh:true];
        });
    }
    
}
- (void)saveCache {
    DLog(@"save cache !");
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *cacheKey = @"home_feed_cache";
        
        if (cacheKey) {
            NSMutableArray *newCache = [[NSMutableArray alloc] init];
            
            NSInteger postsCount = 0;
            
            for (NSInteger i = 0; i < self.bf_tableView.stream.pages.count && postsCount < MAX_FEED_CACHED_POSTS; i++) {
                postsCount += self.bf_tableView.stream.pages[i].data.count;
                [newCache addObject:[self.bf_tableView.stream.pages[i] toDictionary]];
            }
            
            [[PINCache sharedCache] setObject:[newCache copy] forKey:cacheKey];
        }
    });
}
- (void)postStreamDidUpdate:(PostStream *)stream {
    // TODO: RE-enable this
    //    [self saveCache];
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
    
    [self.bf_tableView reloadData];
}
- (void)recentsUpdated:(NSNotification *)sender {
    [self loadSuggestedCamps];
    
    [self.bf_tableView reloadData];
}
// Fetch posts
- (void)getPostsWithCursor:(StreamPagingCursorType)cursorType {
    return;
    
    NSString *url = @"streams/me";
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    if (cursorType == StreamPagingCursorTypeNext) {
        [params setObject:self.bf_tableView.stream.nextCursor forKey:@"cursor"];
    }
    else if (self.bf_tableView.stream.prevCursor.length > 0) {
        [params setObject:self.bf_tableView.stream.prevCursor forKey:@"cursor"];
    }
    
    if ([params objectForKey:@"cursor"]) {
        if ([self.bf_tableView.stream hasLoadedCursor:params[@"cursor"]]) {
            return;
        }
        else {
            [self.bf_tableView.stream addLoadedCursor:params[@"cursor"]];
        }
    }
    else if (cursorType == StreamPagingCursorTypePrevious) {
        cursorType = StreamPagingCursorTypeNone;
    }
    
    self.bf_tableView.loading = (self.bf_tableView.stream.sections.count == 0);
    if (self.bf_tableView.loading) {
        self.errorView.hidden = true;
        [self.bf_tableView hardRefresh:false];
    }
    
    if (cursorType == StreamPagingCursorTypePrevious && self.bf_tableView.stream.sections.count > 0) {
        self.titleView.shimmering = true;
    }
    
    [[[HAWebService managerWithContentType:kCONTENT_TYPE_JSON] authenticate] GET:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        self.loading = false;
        self.bf_tableView.loading = false;
        self.userDidRefresh = false;
        
        NSInteger sectionsBefore = self.bf_tableView.stream.sections.count;
        CGFloat normalizedScrollViewContentOffsetY = self.bf_tableView.contentOffset.y + self.bf_tableView.adjustedContentInset.top;
        self.previousOffset = normalizedScrollViewContentOffsetY;
        
        SectionStreamPage *page = [[SectionStreamPage alloc] initWithDictionary:responseObject error:nil];
        
        BOOL newPosts = false;
        if (page.data.count > 0) {
            if (!self.bf_tableView.stream) {
                // This should never call, but it's here as a safeguard
                [self.bf_tableView scrollToTop];
                self.bf_tableView.stream = [[SectionStream alloc] init];
                self.bf_tableView.delegate = self.bf_tableView;
            }
            
            if (cursorType == StreamPagingCursorTypeNext) {
                [self.bf_tableView.stream appendPage:page];
            }
            else {
                newPosts = (self.bf_tableView.stream.sections > 0 && page.data.count > 0);
                [self.bf_tableView.stream prependPage:page];
            }
            
            if (self.userDidRefresh || sectionsBefore == 0 || cursorType == StreamPagingCursorTypeNone) {
                [self.bf_tableView hardRefresh:self.userDidRefresh];
                
                [self hideMorePostsIndicator:true];
            }
            else if (cursorType == StreamPagingCursorTypeNext) {
                self.bf_tableView.loadingMore = false;
                
                [self.bf_tableView refreshAtBottom];
            }
            else {
                // previous currsor
                [self.bf_tableView refreshAtTop];
                
                normalizedScrollViewContentOffsetY = self.bf_tableView.contentOffset.y + self.bf_tableView.adjustedContentInset.top;
                
                if (newPosts && normalizedScrollViewContentOffsetY > 0) {
                    [self showMorePostsIndicator:YES];
                }
            }
        }
        
        if (self.bf_tableView.stream.sections.count == 0) {
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
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (self.bf_tableView.stream.sections.count == 0) {
            self.errorView.hidden = false;
            
            [self showErrorViewWithType:([HAWebService hasInternet] ? ErrorViewTypeGeneral : ErrorViewTypeNoInternet) title:([HAWebService hasInternet] ? @"Error Loading" : @"No Internet") description:@"Check your network settings and tap below to try again" actionTitle:@"Refresh" actionBlock:^{
                [self refresh];
            }];
            
            [self positionErrorView];
        }
        
        self.loading = false;
        self.bf_tableView.loading = false;
        if (cursorType == StreamPagingCursorTypeNext) {
            self.bf_tableView.loadingMore = false;
        }
        else if (self.userDidRefresh) {
            self.userDidRefresh = false;
        }
        self.bf_tableView.userInteractionEnabled = true;
        [self.bf_tableView refreshAtTop];
    }];
}
// Management
- (void)refresh {
    if (!self.userDidRefresh) {
        [self.bf_tableView.stream removeLoadedCursor:self.bf_tableView.stream.prevCursor];
        
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
        [self.refreshControl performSelector:@selector(endRefreshing) withObject:nil afterDelay:0.0];
        [self.bf_tableView.refreshControl performSelector:@selector(endRefreshing) withObject:nil afterDelay:0.0];
        
        self.titleView.shimmering = false;
    }
}

#pragma mark - RSTableViewDelegate
- (UIView *)viewForFirstSectionHeader {
    return nil;
    
    UIView *buttons = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 80)];
    
    UIButton *updateSection = [UIButton buttonWithType:UIButtonTypeSystem];
    [updateSection setTitle:@"Update Section" forState:UIControlStateNormal];
    updateSection.frame = CGRectMake(0, 0, buttons.frame.size.width, 40);
    [updateSection bk_whenTapped:^{
        Section *firstSection = [self.bf_tableView.stream.sections firstObject];
        firstSection.attributes.title = @"Updated Section!";
        [self.bf_tableView.stream performEventType:SectionStreamEventTypeSectionUpdated object:firstSection];
        
        [self.bf_tableView reloadData];
    }];
    [buttons addSubview:updateSection];
    
    UIButton *removeSection = [UIButton buttonWithType:UIButtonTypeSystem];
    [removeSection setTitle:@"Remove Section" forState:UIControlStateNormal];
    removeSection.frame = CGRectMake(0, updateSection.frame.size.height, buttons.frame.size.width, 40);
    [removeSection bk_whenTapped:^{
        Section *firstSection = [self.bf_tableView.stream.sections firstObject];
        [self.bf_tableView.stream performEventType:SectionStreamEventTypeSectionRemoved object:firstSection];
        
        [self.bf_tableView reloadData];
    }];
    [buttons addSubview:removeSection];
    
    UIButton *updateTopPost = [UIButton buttonWithType:UIButtonTypeSystem];
    [updateTopPost setTitle:@"Update Top Post" forState:UIControlStateNormal];
    updateTopPost.frame = CGRectMake(0, removeSection.frame.origin.y + removeSection.frame.size.height, buttons.frame.size.width, 40);
    [updateTopPost bk_whenTapped:^{
        Section *firstSection = [self.bf_tableView.stream.sections firstObject];
        Post *firstPostInFirstSection = [[firstSection.attributes.posts firstObject] copy];
        firstPostInFirstSection.attributes.message = @"Updated post!";
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"PostUpdated" object:firstPostInFirstSection];
    }];
    [buttons addSubview:updateTopPost];
    
    UIButton *removeTopPost = [UIButton buttonWithType:UIButtonTypeSystem];
    [removeTopPost setTitle:@"Remove Top Post" forState:UIControlStateNormal];
    removeTopPost.frame = CGRectMake(0, updateTopPost.frame.origin.y + updateTopPost.frame.size.height, buttons.frame.size.width, 40);
    [removeTopPost bk_whenTapped:^{
        Section *firstSection = [self.bf_tableView.stream.sections firstObject];
        Post *firstPostInFirstSection = [firstSection.attributes.posts objectAtIndex:0];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"PostDeleted" object:firstPostInFirstSection];
    }];
    [buttons addSubview:removeTopPost];
    
    UIButton *updateUser = [UIButton buttonWithType:UIButtonTypeSystem];
    [updateUser setTitle:@"Update Top Post User" forState:UIControlStateNormal];
    updateUser.frame = CGRectMake(0, removeTopPost.frame.origin.y + removeTopPost.frame.size.height, buttons.frame.size.width, 40);
    [updateUser bk_whenTapped:^{
        Section *firstSection = [self.bf_tableView.stream.sections firstObject];
        Post *firstPostInFirstSection = [firstSection.attributes.posts objectAtIndex:0];
        User *creator = [[User alloc] initWithDictionary:[firstPostInFirstSection.attributes.creator toDictionary] error:nil];
        creator.attributes.identifier = @"jackieboy";
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UserUpdated" object:creator];
    }];
    [buttons addSubview:updateUser];
    
    UIButton *updateCamp = [UIButton buttonWithType:UIButtonTypeSystem];
    [updateCamp setTitle:@"Update Top Post Camp" forState:UIControlStateNormal];
    updateCamp.frame = CGRectMake(0, updateUser.frame.origin.y + updateUser.frame.size.height, buttons.frame.size.width, 40);
    [updateCamp bk_whenTapped:^{
        Section *firstSection = [self.bf_tableView.stream.sections firstObject];
        Post *firstPostInFirstSection = [firstSection.attributes.posts objectAtIndex:0];
        Camp *postedIn = [[Camp alloc] initWithDictionary:[firstPostInFirstSection.attributes.postedIn toDictionary] error:nil];
        postedIn.attributes.identifier = @"suhdudes";
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"CampUpdated" object:postedIn];
    }];
    [buttons addSubview:updateCamp];
    
    return buttons;
}
- (CGFloat)heightForFirstSectionHeader {
    return CGFLOAT_MIN; // 240
}
- (UIView *)viewForFirstSectionFooter {
    return nil;
}
- (CGFloat)heightForFirstSectionFooter {
    return CGFLOAT_MIN;
}
- (void)tableView:(nonnull id)tableView didRequestNextPageWithMaxId:(NSInteger)maxId {
    if (self.bf_tableView.stream.nextCursor.length > 0 && ![self.bf_tableView.stream hasLoadedCursor:self.bf_tableView.stream.nextCursor]) {
        [self getPostsWithCursor:StreamPagingCursorTypeNext];
    }
}

#pragma mark - UIScrollViewDelegate
- (void)tableViewDidScroll:(UITableView *)tableView {
    CGFloat normalizedScrollViewContentOffsetY = tableView.contentOffset.y + tableView.adjustedContentInset.top;
    
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
        
        if (self.composeInputView.tag != 1) {
            if (self.yTranslation < -80) {
                [self hideComposeInputView];
            }
            else if (self.yTranslation > 0) {
                [self showComposeInputView];
            }
        }
    }
    else {
        self.scrollingDownwards = false;
        self.previousOffset = normalizedScrollViewContentOffsetY;
        self.yTranslation = 0;
    }
    
    if (self.yTranslation > 10 || normalizedScrollViewContentOffsetY < 80) {
        // hide the scroll indicator
        [self hideMorePostsIndicator:true];
    }
    
    //    DLog(@"scrollingDownwards: %@", _scrollingDownwards ? @"YES" : @"NO");
    //    DLog(@"self.previousOffset: %f", self.previousOffset);
    //    DLog(@"self.yTranslation: %f", self.yTranslation);
    //    DLog(@"normalizedContentOffset: %f", normalizedScrollViewContentOffsetY);
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    UIView *tapToDismissView = [self.view viewWithTag:888];
    if (!tapToDismissView) {
        tapToDismissView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.bf_tableView.frame.size.width, self.bf_tableView.frame.size.height)];
        tapToDismissView.tag = 888;
        tapToDismissView.alpha = 0;
        tapToDismissView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.75];
        
        [self.view insertSubview:tapToDismissView aboveSubview:self.bf_tableView];
    }
    
    self.bf_tableView.scrollEnabled = false;
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
        self.bf_tableView.scrollEnabled = false;
    }
    else {
        self.bf_tableView.scrollEnabled = true;
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
    
    self.bf_tableView.contentInset = UIEdgeInsetsMake(self.bf_tableView.contentInset.top, 0, self.composeInputView.frame.size.height - safeAreaInsets.bottom, 0);
    self.bf_tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, self.bf_tableView.contentInset.left, self.bf_tableView.contentInset.bottom, self.bf_tableView.contentInset.right);
    
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
    
    self.bf_tableView.contentInset = UIEdgeInsetsMake(self.bf_tableView.contentInset.top, self.bf_tableView.contentInset.left, 0, self.bf_tableView.contentInset.right);
    self.bf_tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, self.bf_tableView.contentInset.left, self.bf_tableView.contentInset.bottom, self.bf_tableView.contentInset.right);
    
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
